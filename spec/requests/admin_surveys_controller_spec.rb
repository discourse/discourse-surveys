# frozen_string_literal: true

RSpec.describe DiscourseSurveys::AdminSurveysController do
  fab!(:admin)
  fab!(:user)

  before { SiteSetting.surveys_enabled = true }

  let(:create_survey) do
    lambda do |post_record, raw|
      surveys = DiscourseSurveys::Helper.extract(raw, post_record.topic_id, post_record.user_id)
      surveys.each { |survey| DiscourseSurveys::Helper.create!(post_record.id, survey) }
      Survey.find_by(post_id: post_record.id)
    end
  end

  describe "#index" do
    context "when not logged in" do
      it "returns 404" do
        get "/admin/plugins/discourse-surveys/surveys.json"
        expect(response.status).to eq(404)
      end
    end

    context "when logged in as a regular user" do
      before { sign_in(user) }

      it "returns 404" do
        get "/admin/plugins/discourse-surveys/surveys.json"
        expect(response.status).to eq(404)
      end
    end

    context "when logged in as admin" do
      before { sign_in(admin) }

      it "returns an empty list when no surveys exist" do
        get "/admin/plugins/discourse-surveys/surveys.json"
        expect(response.status).to eq(200)
        expect(response.parsed_body["surveys"]).to eq([])
      end

      it "returns surveys with metadata" do
        post_record = Fabricate(:post, user: admin)
        survey = create_survey.call(post_record, <<~MD)
          [survey name="feedback"]
          [radio question="Rating:"]
          - Good
          - Bad
          [/radio]
          [/survey]
        MD

        get "/admin/plugins/discourse-surveys/surveys.json"
        expect(response.status).to eq(200)

        surveys = response.parsed_body["surveys"]
        expect(surveys.length).to eq(1)
        expect(surveys[0]["name"]).to eq("feedback")
        expect(surveys[0]["field_count"]).to eq(1)
        expect(surveys[0]["response_count"]).to eq(0)
        expect(surveys[0]["topic_id"]).to eq(post_record.topic_id)
      end

      it "returns correct response counts" do
        post_record = Fabricate(:post, user: admin)
        survey = create_survey.call(post_record, <<~MD)
          [survey name="test"]
          [radio question="Pick one:"]
          - Alpha
          - Beta
          [/radio]
          [/survey]
        MD

        field = survey.survey_fields.first
        option = field.survey_field_options.first
        DiscourseSurveys::Helper.submit_response(
          post_record.id,
          survey.name,
          { field.digest => option.digest },
          user,
        )

        get "/admin/plugins/discourse-surveys/surveys.json"
        expect(response.parsed_body["surveys"][0]["response_count"]).to eq(1)
      end

      it "paginates results and includes load_more_surveys URL" do
        (DiscourseSurveys::AdminSurveysController::PAGE_SIZE + 1).times do |i|
          post_record = Fabricate(:post, user: admin)

          create_survey.call(post_record, <<~MD)
            [survey name="s#{i}"]
            [radio question="Q:"]
            - A
            [/radio]
            [/survey]
          MD
        end

        get "/admin/plugins/discourse-surveys/surveys.json"
        body = response.parsed_body
        expect(body["surveys"].length).to eq(DiscourseSurveys::AdminSurveysController::PAGE_SIZE)
        expect(body["total_rows_surveys"]).to eq(
          DiscourseSurveys::AdminSurveysController::PAGE_SIZE + 1,
        )
        expect(body["load_more_surveys"]).to include("page=1")

        get "/admin/plugins/discourse-surveys/surveys.json?page=1"
        body = response.parsed_body
        expect(body["surveys"].length).to eq(1)
        expect(body["load_more_surveys"]).to be_nil
      end

      it "excludes surveys on deleted posts" do
        post_record = Fabricate(:post, user: admin)
        create_survey.call(post_record, <<~MD)
          [survey name="deleted"]
          [radio question="Q:"]
          - A
          [/radio]
          [/survey]
        MD

        post_record.trash!

        get "/admin/plugins/discourse-surveys/surveys.json"
        expect(response.parsed_body["surveys"]).to eq([])
      end
    end
  end

  describe "#export_csv" do
    context "when not logged in" do
      it "returns 404" do
        get "/admin/plugins/discourse-surveys/surveys/999/export-csv"
        expect(response.status).to eq(404)
      end
    end

    context "when logged in as admin" do
      before { sign_in(admin) }

      it "returns 404 for non-existent survey" do
        get "/admin/plugins/discourse-surveys/surveys/999/export-csv"
        expect(response.status).to eq(404)
      end

      it "exports CSV with no-responses message for a survey without responses" do
        post_record = Fabricate(:post, user: admin)
        survey = create_survey.call(post_record, <<~MD)
          [survey name="empty"]
          [radio question="Q:"]
          - A
          [/radio]
          [/survey]
        MD

        get "/admin/plugins/discourse-surveys/surveys/#{survey.id}/export-csv"
        expect(response.status).to eq(200)
        expect(response.headers["Content-Type"]).to include("text/csv")
        expect(response.headers["Content-Disposition"]).to include("attachment")

        csv = CSV.parse(response.body)
        expect(csv[0]).to eq([I18n.t("survey.csv.no_responses")])
      end

      it "exports CSV with user responses" do
        post_record = Fabricate(:post, user: admin)
        survey = create_survey.call(post_record, <<~MD)
          [survey name="full"]
          [radio question="Favorite color:"]
          - Red
          - Blue
          [/radio]
          [textarea question="Comments:"]
          [/textarea]
          [/survey]
        MD

        radio_field = survey.survey_fields.find { |f| f.question.include?("Favorite color") }
        text_field = survey.survey_fields.find { |f| f.question.include?("Comments") }
        red_option = radio_field.survey_field_options.find { |o| o.html.include?("Red") }

        DiscourseSurveys::Helper.submit_response(
          post_record.id,
          survey.name,
          { radio_field.digest => red_option.digest, text_field.digest => "Great survey!" },
          user,
        )

        get "/admin/plugins/discourse-surveys/surveys/#{survey.id}/export-csv"
        expect(response.status).to eq(200)

        csv = CSV.parse(response.body)
        expect(csv[0]).to include(I18n.t("survey.csv.username"), I18n.t("survey.csv.email"))
        expect(csv[1]).to include(user.username, user.email)
        expect(csv[1]).to include("Red")
        expect(csv[1]).to include("Great survey!")
      end
    end
  end
end
