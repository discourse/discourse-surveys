# frozen_string_literal: true

RSpec.describe DiscourseSurveys::SurveyController do
  SURVEY_RAW = <<~MD
    [survey name="test"]
    [radio question="Pick one:"]
    - A
    - B
    [/radio]
    [/survey]
  MD

  fab!(:user)
  fab!(:post)

  before { SiteSetting.surveys_enabled = true }

  let!(:survey) do
    DiscourseSurveys::Helper
      .extract(SURVEY_RAW, post.topic_id, post.user_id)
      .each { |extracted| DiscourseSurveys::Helper.create!(post.id, extracted) }
    Survey.find_by(post_id: post.id)
  end

  let(:field) { survey.survey_fields.first }
  let(:option) { field.survey_field_options.first }
  let(:anon_token) { "0f8fad5bd9cb469fa165408f73b07c9e" }

  def submit(token: nil)
    params = {
      post_id: post.id,
      survey_name: survey.name,
      response: {
        field.digest => option.digest,
      },
    }
    params[:anon_token] = token if token

    put "/surveys/submit-response.json", params: params
  end

  def with_rate_limiting(max_per_hour)
    RateLimiter.enable
    stub_const(DiscourseSurveys::SurveyController, :ANONYMOUS_SUBMISSIONS_PER_HOUR, max_per_hour) do
      yield
    end
  ensure
    RateLimiter.disable
  end

  describe "#submit_response" do
    context "when logged in" do
      before { sign_in(user) }

      it "records the response against the user" do
        expect { submit }.to change(SurveyResponse, :count).by(1)
        expect(response.status).to eq(200)

        saved = SurveyResponse.last
        expect(saved.user_id).to eq(user.id)
        expect(saved.anon_token).to be_blank
      end

      it "is not rate limited by the anonymous submission limit" do
        with_rate_limiting(0) do
          expect { submit }.to change(SurveyResponse, :count).by(1)
          expect(response.status).to eq(200)
        end
      end
    end

    context "when not logged in and anonymous submissions are disabled" do
      before { SiteSetting.surveys_allow_anonymous_submissions = false }

      it "returns 403" do
        expect { submit(token: anon_token) }.to not_change(SurveyResponse, :count)
        expect(response.status).to eq(403)
      end
    end

    context "when not logged in and anonymous submissions are enabled" do
      before { SiteSetting.surveys_allow_anonymous_submissions = true }

      it "records the response against the anonymous token" do
        expect { submit(token: anon_token) }.to change(SurveyResponse, :count).by(1)
        expect(response.status).to eq(200)

        saved = SurveyResponse.last
        expect(saved.user_id).to be_blank
        expect(saved.anon_token).to eq(anon_token)
      end

      it "returns an error when the anonymous token is missing" do
        expect { submit }.to not_change(SurveyResponse, :count)
        expect(response.status).to eq(422)
        expect(response.parsed_body["errors"]).to contain_exactly(
          I18n.t("survey.invalid_anonymous_token"),
        )
      end

      it "returns an error when the same anonymous token submits twice" do
        submit(token: anon_token)

        expect { submit(token: anon_token) }.to not_change(SurveyResponse, :count)
        expect(response.parsed_body["errors"]).to contain_exactly(
          I18n.t("survey.user_already_responded"),
        )
      end

      it "rate limits anonymous submissions" do
        with_rate_limiting(0) do
          expect { submit(token: anon_token) }.to not_change(SurveyResponse, :count)
          expect(response.status).to eq(429)
        end
      end
    end
  end
end
