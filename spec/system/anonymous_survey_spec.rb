# frozen_string_literal: true

RSpec.describe "Anonymous survey submissions" do
  before { enable_current_plugin }

  # `let` rather than `fab!` so the post cooks after `enable_current_plugin`,
  # otherwise the survey BBCode is not active yet and the raw text renders verbatim
  let(:post) { Fabricate(:post, user: Fabricate(:admin), raw: <<~MD) }
        [survey name="anon-survey" title="Anonymous Survey"]
        [radio question="Best pet:"]
        - cat
        - dog
        [/radio]
        [/survey]
      MD

  let(:survey) { PageObjects::Components::Survey.new }

  it "redirects to login when anonymous submissions are disabled" do
    SiteSetting.surveys_allow_anonymous_submissions = false

    visit post.url
    survey.field("Best pet:").select_radio_option("dog")

    expect(page).to have_current_path("/login")
    expect(SurveyResponse.count).to eq(0)
  end

  it "lets an anonymous visitor submit and remembers it across a reload" do
    SiteSetting.surveys_allow_anonymous_submissions = true

    visit post.url
    expect(survey).to have_no_submitted_message

    survey.field("Best pet:").select_radio_option("dog")
    expect(survey.component).to have_css("button.submit-response:not([disabled])")
    survey.submit

    try_until_success { expect(SurveyResponse.count).to eq(1) }

    response = SurveyResponse.first
    expect(response.user_id).to be_blank
    expect(response.anon_token).to be_present
    expect(survey).to have_submitted_message

    visit post.url
    expect(survey).to have_submitted_message
    expect(SurveyResponse.count).to eq(1)
  end
end
