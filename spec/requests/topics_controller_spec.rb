# frozen_string_literal: true

RSpec.describe TopicsController do
  fab!(:author, :admin)

  fab!(:topic) { Fabricate(:topic_with_op, user: author) }

  fab!(:hidden_post) do
    Fabricate(
      :post,
      topic: topic,
      user: author,
      hidden: true,
      hidden_at: 1.hour.ago,
      hidden_reason_id: Post.hidden_reasons[:flag_threshold_reached],
    )
  end

  before { SiteSetting.surveys_enabled = true }

  def create_survey(post_record)
    surveys = DiscourseSurveys::Helper.extract(<<~MD, post_record.topic_id, post_record.user_id)
      [survey name="private-feedback"]
      [radio question="Secret hidden question?"]
      - Secret alpha
      - Secret beta
      [/radio]
      [/survey]
    MD

    surveys.each { |survey| DiscourseSurveys::Helper.create!(post_record.id, survey) }
    post_record.custom_fields[DiscourseSurveys::HAS_SURVEYS] = true
    post_record.save_custom_fields(true)

    Survey.find_by!(post_id: post_record.id)
  end

  describe "#show" do
    it "omits surveys for hidden post content", :aggregate_failures do
      survey = create_survey(hidden_post)
      survey_field = survey.survey_fields.first
      survey_option = survey_field.survey_field_options.first

      get "/t/#{topic.slug}/#{topic.id}.json"

      hidden_post_response =
        response.parsed_body["post_stream"]["posts"].find { |post| post["id"] == hidden_post.id }

      expect(response.status).to eq(200)
      expect(hidden_post_response).to include("cooked_hidden" => true)
      expect(hidden_post_response).not_to have_key("surveys")
      expect(response.body).not_to include(survey_field.question)
      expect(response.body).not_to include(survey_option.html)

      sign_in(author)
      get "/t/#{topic.slug}/#{topic.id}.json"

      hidden_post_response =
        response.parsed_body["post_stream"]["posts"].find { |post| post["id"] == hidden_post.id }

      expect(response.status).to eq(200)
      expect(hidden_post_response["surveys"].first["fields"].first["question"]).to eq(
        survey_field.question,
      )
    end
  end
end
