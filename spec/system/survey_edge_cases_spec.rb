# frozen_string_literal: true

RSpec.describe "Survey Edge Cases", type: :system do
  before { enable_current_plugin }

  fab!(:admin) { Fabricate(:admin) }
  let(:survey) { PageObjects::Components::Survey.new }

  before { sign_in admin }

  describe "survey without title" do
    let(:post) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="no-title-survey"]
          [radio question="Choose:"]
          - Option A
          [/radio]
          [/survey]
        MD
      )
    end

    it "displays survey without title section" do
      visit post.url

      expect(survey.has_no_title?).to eq(true)
      expect(survey.has_field?("Choose:")).to eq(true)
    end
  end

  describe "survey with title" do
    let(:post) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="titled-survey" title="My Survey Title"]
          [radio question="Choose:"]
          - Option A
          [/radio]
          [/survey]
        MD
      )
    end

    it "displays survey title" do
      visit post.url

      expect(survey.has_title?("My Survey Title")).to eq(true)
    end
  end

  describe "survey with emoji in options" do
    let(:post) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="emoji-survey"]
          [radio question="Choose:"]
          - 🐈 Cat
          - 🐕 Dog
          - 🐦 Bird
          [/radio]
          [/survey]
        MD
      )
    end

    it "handles emoji in option text" do
      visit post.url

      survey.field("Choose:").select_radio_option("Dog")
      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.survey_field_option.html).to include("dog")
    end
  end

  describe "survey with HTML in options" do
    let(:post) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="html-survey"]
          [radio question="Choose:"]
          - <strong>Bold</strong> option
          - <em>Italic</em> option
          [/radio]
          [/survey]
        MD
      )
    end

    it "renders HTML in options safely" do
      visit post.url

      expect(page).to have_css(".field-radio", text: "Bold")
      expect(page).to have_css(".field-radio", text: "Italic")
    end
  end

  describe "survey with many options" do
    let(:post) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="many-options-survey"]
          [checkbox question="Select many:"]
          - Option 1
          - Option 2
          - Option 3
          - Option 4
          - Option 5
          - Option 6
          - Option 7
          - Option 8
          - Option 9
          - Option 10
          [/checkbox]
          [/survey]
        MD
      )
    end

    it "allows selecting many options" do
      visit post.url

      (1..10).each do |i|
        survey.field("Select many:").select_checkbox_option("Option #{i}")
      end

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(10) }
    end
  end

  describe "survey with long textarea" do
    let(:post) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="long-text-survey"]
          [textarea question="Enter long text:" required="false"]
          [/textarea]
          [/survey]
        MD
      )
    end

    it "handles long text input" do
      visit post.url

      long_text = "A" * 1000
      survey.field("Enter long text:").fill_textarea(long_text)
      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.value.length).to eq(1000)
    end
  end

  describe "multiple surveys in different posts" do
    let(:post1) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="survey-1"]
          [radio question="Question 1:"]
          - A
          [/radio]
          [/survey]
        MD
      )
    end

    let(:post2) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="survey-2"]
          [radio question="Question 2:"]
          - B
          [/radio]
          [/survey]
        MD
      )
    end

    it "allows responding to multiple surveys independently" do
      visit post1.url

      survey.field("Question 1:").select_radio_option("A")
      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      visit post2.url

      survey.field("Question 2:").select_radio_option("B")
      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(2) }
    end
  end

  describe "survey with all field types" do
    let(:post) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="all-types-survey" title="Complete Survey"]
          [radio question="Radio question:"]
          - Radio A
          - Radio B
          [/radio]
          [checkbox question="Checkbox question:"]
          - Check A
          - Check B
          [/checkbox]
          [dropdown question="Dropdown question:"]
          - Drop A
          - Drop B
          [/dropdown]
          [number question="Number question:"]
          [/number]
          [textarea question="Textarea question:" required="false"]
          [/textarea]
          [star question="Star question:"]
          [/star]
          [thumbs question="Thumbs question:"]
          [/thumbs]
          [/survey]
        MD
      )
    end

    it "allows completing all field types in one survey" do
      visit post.url

      survey.field("Radio question:").select_radio_option("Radio B")
      survey.field("Checkbox question:").select_checkbox_option("Check A")
      survey.field("Checkbox question:").select_checkbox_option("Check B")
      survey.field("Dropdown question:").select_dropdown_option("Drop A")
      survey.field("Number question:").select_number(7)
      survey.field("Textarea question:").fill_textarea("My feedback")
      survey.field("Star question:").select_star_rating(4)
      survey.field("Thumbs question:").select_thumbs_up

      expect(survey.submit_button_enabled?).to eq(true)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(8) }
    end
  end
end

