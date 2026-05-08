# frozen_string_literal: true

describe DiscourseSurveys::PostValidator do
  before { SiteSetting.surveys_enabled = true }

  fab!(:staff, :admin)
  fab!(:moderator)
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

    it "passes when the acting user belongs to one of the allowed groups" do
      group = Fabricate(:group)
      group.add(user)
      SiteSetting.surveys_allowed_groups = "#{Group::AUTO_GROUPS[:staff]}|#{group.id}"
      post.acting_user = user
      expect(described_class.new(post).validate_post).to eq(true)
      expect(post.errors[:base]).to be_empty
    end

    it "fails when a non-admin staff member is not in any allowed group" do
      SiteSetting.surveys_allowed_groups = ""
      post.acting_user = moderator
      expect(described_class.new(post).validate_post).to eq(false)
      expect(post.errors[:base]).to include(I18n.t("survey.insufficient_rights_to_create"))
    end

    it "always allows admin users regardless of the allowed groups setting" do
      SiteSetting.surveys_allowed_groups = ""
      post.acting_user = staff
      expect(described_class.new(post).validate_post).to eq(true)
      expect(post.errors[:base]).to be_empty
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
  end
end
