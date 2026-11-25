# frozen_string_literal: true

RSpec.describe "Answering a survey while browsing" do
  fab!(:author, :admin)
  fab!(:member, :user)

  it "submits once from the step modal, marks the post answered and exports one respondent" do
    enable_current_plugin
    source = Fabricate(:post, user: author, raw: <<~MD)
      [survey name="check-in" title="Community check-in"]
      [radio question="How is it going?"]
      - Good
      - Bad
      [/radio]
      [textarea question="Any details?" required="false"]
      [/textarea]
      [/survey]
    MD
    survey = Survey.find_by!(post: source)
    survey.update!(invitation_enabled: true, invitation_placement: "bottom_right")
    sign_in(member)
    visit "/latest"
    expect(page).to have_css(
      ".survey-invitation-banner.--bottom-right",
      style: {
        position: "fixed",
      },
    )
    click_button "Take survey"
    within(".d-modal") do
      expect(page).to have_text("Question 1 of 2")
      find(".survey-field-option", text: "Good").click
      click_button "Next"
      expect(page).to have_text("Question 2 of 2")
      expect(survey.has_responded?(member)).to be(false)
      click_button "Back"
      click_button "Next"
      find("textarea").fill_in(with: "Synthetic feedback")
      click_button "Finish survey"
    end
    expect(page).to have_no_css(".d-modal")
    visit source.url
    expect(page).to have_css(".survey-submitted")
    expect(CSV.parse(DiscourseSurveys::CsvExporter.new(survey).export).drop(1)).to eq(
      [[member.username, member.email, "Good", "Synthetic feedback"]],
    )
  end
end
