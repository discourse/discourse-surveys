# frozen_string_literal: true

describe DiscourseSurveys::PostValidator do
  before { SiteSetting.surveys_enabled = true }

  fab!(:staff, :admin)
  fab!(:user)
  fab!(:topic)
  fab!(:post) { Fabricate(:post, topic: topic, user: user) }

  describe "#validate_post" do
    it "passes when the acting user is staff" do
      post.acting_user = staff
      expect(described_class.new(post).validate_post).to eq(true)
      expect(post.errors[:base]).to be_empty
    end

    it "fails when the acting user is not staff" do
      post.acting_user = user
      expect(described_class.new(post).validate_post).to eq(false)
      expect(post.errors[:base]).to include(I18n.t("survey.insufficient_rights_to_create"))
    end

    it "renders a real translation (no missing-translation fallback)" do
      post.acting_user = user
      described_class.new(post).validate_post
      expect(post.errors[:base].join.downcase).not_to include("translation missing")
    end

    it "passes when staff edits a post owned by a non-staff user" do
      post.acting_user = staff
      expect(post.user).to eq(user)
      expect(described_class.new(post).validate_post).to eq(true)
    end

    it "falls back to post.user when acting_user is not set (e.g. background jobs)" do
      staff_post = Fabricate(:post, user: staff)
      staff_post.acting_user = nil
      expect(described_class.new(staff_post).validate_post).to eq(true)
    end

    it "passes for posts in PMs with a non-human user even without staff" do
      bot = Discourse.system_user
      pm_topic =
        Fabricate(
          :private_message_topic,
          topic_allowed_users: [
            Fabricate.build(:topic_allowed_user, user: user),
            Fabricate.build(:topic_allowed_user, user: bot),
          ],
        )
      pm_post = Fabricate(:post, topic: pm_topic, user: user)
      pm_post.acting_user = user

      expect(described_class.new(pm_post).validate_post).to eq(true)
    end
  end
end
