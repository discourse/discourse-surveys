# frozen_string_literal: true

RSpec.describe "Survey Validation" do
  before { enable_current_plugin }

  fab!(:admin)
  let(:survey) { PageObjects::Components::Survey.new }

  before { sign_in admin }

  describe "required fields" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="required-survey"]
          [radio question="Required question:"]
          - Option 1
          - Option 2
          [/radio]
          [textarea question="Optional question:" required="false"]
          [/textarea]
          [/survey]
        MD

    it "disables submit button when required fields are not filled" do
      visit post.url

      expect(survey.submit_button_disabled?).to eq(true)
    end

    it "enables submit button when all required fields are filled" do
      visit post.url

      survey.field("Required question:").select_radio_option("Option 1")

      expect(survey.submit_button_enabled?).to eq(true)
    end

    it "allows submission with only required fields filled" do
      visit post.url

      survey.field("Required question:").select_radio_option("Option 2")
      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }
    end

    it "allows submission with both required and optional fields" do
      visit post.url

      survey.field("Required question:").select_radio_option("Option 1")
      survey.field("Optional question:").fill_textarea("Optional answer")
      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(2) }
    end
  end

  describe "multiple required fields" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="multi-required-survey"]
          [radio question="First required:"]
          - A
          - B
          [/radio]
          [checkbox question="Second required:"]
          - X
          - Y
          [/checkbox]
          [number question="Third required:"]
          [/number]
          [/survey]
        MD

    it "requires all required fields to be filled" do
      visit post.url

      expect(survey.submit_button_disabled?).to eq(true)

      survey.field("First required:").select_radio_option("A")
      expect(survey.submit_button_disabled?).to eq(true)

      survey.field("Second required:").select_checkbox_option("X")
      expect(survey.submit_button_disabled?).to eq(true)

      survey.field("Third required:").select_number(5)
      expect(survey.submit_button_enabled?).to eq(true)
    end

    it "allows submission when all required fields are filled" do
      visit post.url

      survey.field("First required:").select_radio_option("B")
      survey.field("Second required:").select_checkbox_option("Y")
      survey.field("Third required:").select_number(8)
      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(3) }
    end
  end

  describe "all optional fields" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="all-optional-survey"]
          [textarea question="Optional 1:" required="false"]
          [/textarea]
          [textarea question="Optional 2:" required="false"]
          [/textarea]
          [/survey]
        MD

    it "allows submission with no fields filled" do
      visit post.url

      expect(survey.submit_button_enabled?).to eq(true)

      survey.submit

      expect(SurveyResponse.count).to eq(0)
    end

    it "allows submission with some fields filled" do
      visit post.url

      survey.field("Optional 1:").fill_textarea("Answer 1")
      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }
    end
  end
end
