# frozen_string_literal: true

RSpec.describe "Completing a post survey" do
  fab!(:admin)
  fab!(:member, :user)
  fab!(:source_post) { Fabricate(:post, user: admin) }
  let(:survey) do
    raw = <<~MD
      [survey name="feedback"]
      [textarea question="What should change?"]
      [/textarea]
      [/survey]
    MD
    definition = DiscourseSurveys::Helper.extract(raw, source_post.topic_id, admin.id).first
    DiscourseSurveys::Helper.create!(source_post.id, definition)
    Survey.find_by!(post: source_post)
  end
  let(:answer) { "Synthetic private feedback" }
  let(:payload) do
    {
      post_id: source_post.id,
      survey_name: survey.name,
      response: {
        survey.survey_fields.first.digest => answer,
      },
    }
  end

  before do
    SiteSetting.surveys_enabled = true
    sign_in(member)
    survey.update!(invitation_enabled: true)
  end

  it "requires a live invitation for the modal, and uses the original submission and export" do
    put "/surveys/submit-response.json", params: payload.merge(via_invitation: true)
    expect(response.status).to eq(403)
    post "/surveys/invitation/claim.json"
    expect(response.parsed_body.dig("invitation", "survey", "id")).to eq(survey.id), response.body

    logged_params = []
    callback = ->(*, data) { logged_params << data.fetch(:params) }
    ActiveSupport::Notifications.subscribed(callback, "process_action.action_controller") do
      put "/surveys/submit-response.json", params: payload.merge(via_invitation: true)
    end
    expect(response.status).to eq(200)
    expect(logged_params.last.fetch("response")).to eq("[FILTERED]")
    expect(survey.has_responded?(member)).to be(true)
    put "/surveys/submit-response.json", params: payload
    expect(response).not_to be_successful
    expect(CSV.parse(DiscourseSurveys::CsvExporter.new(survey).export).drop(1)).to eq(
      [[member.username, member.email, answer]],
    )
  end

  it "erases both delivery history and answers on account anonymization even when disabled" do
    post "/surveys/invitation/claim.json"
    put "/surveys/submit-response.json", params: payload
    expect(response.status).to eq(200)
    expect(SurveyInvitation.exists?(user: member)).to be(true)
    SiteSetting.surveys_enabled = false
    UserAnonymizer.make_anonymous(member, admin)
    expect(SurveyResponse.exists?(user_id: member.id)).to be(false)
    expect(SurveyInvitation.exists?(user: member)).to be(false)
  end
end
