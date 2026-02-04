# frozen_string_literal: true

RSpec.describe "Survey Field Types" do
  before { enable_current_plugin }

  fab!(:admin)
  let(:survey) { PageObjects::Components::Survey.new }

  before { sign_in admin }

  describe "radio field" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="radio-survey"]
          [radio question="Choose an option:"]
          - Option A
          - Option B
          - Option C
          [/radio]
          [/survey]
        MD

    it "allows selecting a single option" do
      visit post.url

      expect(page).to have_css(".survey", wait: 10)
      expect(page).to have_css(".field-question", text: "Choose an option:")

      survey.field("Choose an option:").select_radio_option("Option B")

      expect(survey.submit_button_enabled?).to eq(true)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.survey_field_option.html).to eq("Option B")
    end

    it "allows changing selection" do
      visit post.url

      survey.field("Choose an option:").select_radio_option("Option A")
      survey.field("Choose an option:").select_radio_option("Option C")

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.survey_field_option.html).to eq("Option C")
    end
  end

  describe "checkbox field" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="checkbox-survey"]
          [checkbox question="Select multiple:"]
          - Item_1
          - Item_2
          - Item_3
          [/checkbox]
          [/survey]
        MD

    it "allows selecting multiple options" do
      visit post.url

      survey.field("Select multiple:").select_checkbox_option("Item_1")
      survey.field("Select multiple:").select_checkbox_option("Item_3")

      expect(survey.submit_button_enabled?).to eq(true)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(2) }

      responses = SurveyResponse.all.map { |r| r.survey_field_option.html }.sort
      expect(responses).to eq(%w[Item_1 Item_3])
    end

    it "allows deselecting options" do
      visit post.url

      survey.field("Select multiple:").select_checkbox_option("Item_1")
      survey.field("Select multiple:").select_checkbox_option("Item_2")
      survey.field("Select multiple:").select_checkbox_option("Item_1")

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.survey_field_option.html).to eq("Item_2")
    end
  end

  describe "dropdown field" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="dropdown-survey"]
          [dropdown question="Select one:"]
          - First
          - Second
          - Third
          [/dropdown]
          [/survey]
        MD

    it "allows selecting from dropdown" do
      visit post.url

      survey.field("Select one:").select_dropdown_option("Second")

      expect(survey.submit_button_enabled?).to eq(true)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.survey_field_option.html).to eq("Second")
    end
  end

  describe "number field" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="number-survey"]
          [number question="Rate from 1 to 10:"]
          [/number]
          [/survey]
        MD

    it "allows selecting a number" do
      visit post.url

      survey.field("Rate from 1 to 10:").select_number(7)

      expect(survey.submit_button_enabled?).to eq(true)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.value).to eq("7")
    end

    it "allows changing number selection" do
      visit post.url

      survey.field("Rate from 1 to 10:").select_number(3)
      survey.field("Rate from 1 to 10:").select_number(9)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.value).to eq("9")
    end
  end

  describe "textarea field" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="textarea-survey"]
          [textarea question="Enter your feedback:" required="false"]
          [/textarea]
          [/survey]
        MD

    it "allows entering text" do
      visit post.url

      survey.field("Enter your feedback:").fill_textarea("This is my feedback text")

      expect(survey.submit_button_enabled?).to eq(true)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.value).to eq("This is my feedback text")
    end

    it "allows clearing text" do
      visit post.url

      survey.field("Enter your feedback:").fill_textarea("Initial text")
      survey.field("Enter your feedback:").fill_textarea("")

      survey.submit

      expect(SurveyResponse.count).to eq(0)
    end
  end

  describe "star rating field" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="star-survey"]
          [star question="Rate your experience:"]
          [/star]
          [/survey]
        MD

    it "allows selecting a star rating" do
      visit post.url

      survey.field("Rate your experience:").select_star_rating(4)

      expect(survey.submit_button_enabled?).to eq(true)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.value).to eq("4")
    end

    it "allows changing star rating" do
      visit post.url

      survey.field("Rate your experience:").select_star_rating(2)
      survey.field("Rate your experience:").select_star_rating(5)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.value).to eq("5")
    end
  end

  describe "multiple star rating fields" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="multi-star-survey"]
          [star question="Rate the product:"]
          [/star]
          [star question="Rate the service:"]
          [/star]
          [/survey]
        MD

    it "allows selecting different ratings for each star field independently" do
      visit post.url

      survey.field("Rate the product:").select_star_rating(3)
      survey.field("Rate the service:").select_star_rating(5)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(2) }

      product_field = Survey.last.survey_fields.find { |f| f.question == "Rate the product:" }
      service_field = Survey.last.survey_fields.find { |f| f.question == "Rate the service:" }

      product_response = SurveyResponse.find_by(survey_field: product_field)
      service_response = SurveyResponse.find_by(survey_field: service_field)

      expect(product_response.value).to eq("3")
      expect(service_response.value).to eq("5")
    end
  end

  describe "thumbs field" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="thumbs-survey"]
          [thumbs question="Do you like this?"]
          [/thumbs]
          [/survey]
        MD

    it "allows selecting thumbs up" do
      visit post.url

      survey.field("Do you like this?").select_thumbs_up

      expect(survey.submit_button_enabled?).to eq(true)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.value).to eq("+1")
    end

    it "allows selecting thumbs down" do
      visit post.url

      survey.field("Do you like this?").select_thumbs_down

      expect(survey.submit_button_enabled?).to eq(true)

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.value).to eq("-1")
    end

    it "allows changing from thumbs up to thumbs down" do
      visit post.url

      survey.field("Do you like this?").select_thumbs_up
      survey.field("Do you like this?").select_thumbs_down

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      response = SurveyResponse.first
      expect(response.value).to eq("-1")
    end
  end

  describe "multiple thumbs fields" do
    let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
          [survey name="multi-thumbs-survey"]
          [thumbs question="Do you like the product?"]
          [/thumbs]
          [thumbs question="Do you like the service?"]
          [/thumbs]
          [/survey]
        MD

    it "allows selecting different values for each thumbs field independently" do
      visit post.url

      survey.field("Do you like the product?").select_thumbs_up
      survey.field("Do you like the service?").select_thumbs_down

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(2) }

      product_field =
        Survey.last.survey_fields.find { |f| f.question == "Do you like the product?" }
      service_field =
        Survey.last.survey_fields.find { |f| f.question == "Do you like the service?" }

      product_response = SurveyResponse.find_by(survey_field: product_field)
      service_response = SurveyResponse.find_by(survey_field: service_field)

      expect(product_response.value).to eq("+1")
      expect(service_response.value).to eq("-1")
    end
  end
end
