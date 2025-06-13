# frozen_string_literal: true

RSpec.describe "Survey plugin UI", type: :system do
  before { enable_current_plugin }

  let(:admin) { Fabricate(:admin) }

  let(:post) { Fabricate(:post, user: admin, raw: <<~MD) }
      [survey name="awesome-survey-thumbs" title="Awesome Survey"]

      [radio question="Best pet:"]
      - cat
      - dog
      [/radio]

      [checkbox question="Preferred colours:"]
      - red
      - blue
      - green
      [/checkbox]

      [dropdown question="Gender:"]
      - Male
      - Female
      [/dropdown]

      [number question="Rate this survey from 1 to 10:"]
      [/number]

      [textarea question="What is your feedback about xyz?" required="false"]
      [/textarea]

      [star question="How would you rate overall experience?"]
      [/star]

      [thumbs question="Were you satisfied with our services?"]
      [/thumbs]

      [/survey]
    MD

  it "works" do
    sign_in admin

    visit post.url

    expect(page).to have_css(".survey-title", text: "Awesome Survey")
    expect(page).to have_css("button.submit-response[disabled]")

    find(".field-radio li:nth-of-type(2)").click
    find(".field-checkbox li:first-of-type").click
    find(".field-checkbox li:nth-of-type(2)").click
    find(".field-dropdown select").select("Male")
    find(".field-number li:nth-of-type(3)").click
    find(".field-textarea textarea").fill_in with: "This is my answer"
    find(".field-star label:nth-of-type(4)").click
    find(".field-thumbs label:nth-of-type(1)").click

    expect(page).to have_css("button.submit-response:not([disabled])")
    find("button.submit-response:not([disabled])").click

    try_until_success { expect(SurveyResponse.count).to eq(8) }

    assembled_response =
      SurveyResponse
        .all
        .group_by { |s| s.survey_field.question }
        .transform_values { |answers| answers.map { |a| a.value || a.survey_field_option&.html } }

    expect(assembled_response).to eq(
      "Best pet:" => ["dog"],
      "Preferred colours:" => %w[red blue],
      "Gender:" => ["Male"],
      "How would you rate overall experience?" => ["4"],
      "Rate this survey from 1 to 10:" => ["3"],
      "What is your feedback about xyz?" => ["This is my answer"],
      "Were you satisfied with our services?" => ["+1"],
    )
  end
end
