# frozen_string_literal: true

RSpec.describe "Survey Error Cases", type: :system do
  before { enable_current_plugin }

  fab!(:admin) { Fabricate(:admin) }
  fab!(:user) { Fabricate(:user) }
  let(:survey) { PageObjects::Components::Survey.new }

  describe "already responded" do
    let(:post) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="response-test"]
          [radio question="Choose:"]
          - Option A
          - Option B
          [/radio]
          [/survey]
        MD
      )
    end

    it "shows submitted message after responding" do
      sign_in user
      visit post.url

      survey.field("Choose:").select_radio_option("Option A")
      survey.submit

      try_until_success { expect(survey.has_submitted_message?).to eq(true) }
      expect(page).to have_no_css("button.submit-response")
    end

    it "prevents submitting again after responding" do
      sign_in user
      visit post.url

      survey.field("Choose:").select_radio_option("Option A")
      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }

      visit post.url

      expect(survey.has_submitted_message?).to eq(true)
      expect(page).to have_no_css("button.submit-response")
    end
  end

  describe "login requirement" do
    let(:post) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="login-test"]
          [radio question="Choose:"]
          - Option A
          [/radio]
          [/survey]
        MD
      )
    end

    it "shows login prompt when not logged in" do
      visit post.url

      survey.field("Choose:").select_radio_option("Option A")

      expect(page).to have_content("Welcome back")
    end

    it "allows submission after logging in" do
      user.update!(password: "supersecurepassword")
      EmailToken.confirm(Fabricate(:email_token, user: user).token)

      visit post.url

      survey.field("Choose:").select_radio_option("Option A")

      login_form = PageObjects::Pages::Login.new
      login_form.fill(username: user.username, password: "supersecurepassword").click_login

      # Re-select the option after login since the page may have refreshed
      survey.field("Choose:").select_radio_option("Option A")

      try_until_success { expect(survey.submit_button_enabled?).to eq(true) }

      survey.submit

      try_until_success { expect(SurveyResponse.count).to eq(1) }
    end
  end

  describe "deleted post" do
    let(:post) do
      Fabricate(
        :post,
        user: admin,
        raw: <<~MD,
          [survey name="deleted-test"]
          [radio question="Choose:"]
          - Option A
          [/radio]
          [/survey]
        MD
      )
    end

    it "prevents submission when post is deleted" do
      sign_in user
      visit post.url

      survey.field("Choose:").select_radio_option("Option A")

      PostDestroyer.new(admin, post).destroy

      survey.submit

      expect(page).to have_content(I18n.t("survey.post_is_deleted"))
    end
  end

  describe "archived topic" do
    fab!(:topic) { Fabricate(:topic, archived: true) }
    let(:post) do
      Fabricate(
        :post,
        topic: topic,
        user: admin,
        raw: <<~MD,
          [survey name="archived-test"]
          [radio question="Choose:"]
          - Option A
          [/radio]
          [/survey]
        MD
      )
    end

    it "prevents submission when topic is archived" do
      sign_in user
      visit post.url

      survey.field("Choose:").select_radio_option("Option A")

      survey.submit

      expect(page).to have_content(I18n.t("survey.topic_must_be_open_to_vote"))
    end
  end

  describe "permission checks" do
    fab!(:group) { Fabricate(:group) }
    fab!(:category) do
      category = Fabricate(:category)
      category.set_permissions(group => :readonly, everyone: :readonly)
      category.save!
      category
    end
    let(:post) do
      Fabricate(
        :post,
        topic: Fabricate(:topic, category: category),
        user: admin,
        raw: <<~MD,
          [survey name="permission-test"]
          [radio question="Choose:"]
          - Option A
          [/radio]
          [/survey]
        MD
      )
    end

    it "prevents submission when user cannot post in topic" do
      sign_in user
      visit post.url

      survey.field("Choose:").select_radio_option("Option A")

      survey.submit

      expect(page).to have_content(I18n.t("survey.user_cant_post_in_topic"))
    end
  end
end

