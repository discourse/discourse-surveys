# frozen_string_literal: true

describe DiscourseSurveys::PostValidator do
  before { SiteSetting.surveys_enabled = true }

  let(:survey_raw) { <<~MD }
      [survey name="test"]
      [radio question="Pick one:"]
      - A
      - B
      [/radio]
      [/survey]
    MD

  describe "#validate_post" do
    fab!(:staff) { Fabricate(:admin) }
    fab!(:user)

    it "allows creation when the post author is staff" do
      post = Fabricate(:post, user: staff, raw: survey_raw)
      expect(post).to be_valid
    end

    it "rejects creation when the post author is not staff" do
      post = Fabricate.build(:post, user: user, raw: survey_raw)
      expect(post).not_to be_valid
      expect(post.errors[:base]).to include(I18n.t("survey.insufficient_rights_to_create"))
    end

    it "renders a real translation (no missing-translation fallback)" do
      post = Fabricate.build(:post, user: user, raw: survey_raw)
      post.valid?
      expect(post.errors[:base].join).not_to include("translation missing")
      expect(post.errors[:base].join).not_to include("Translation missing")
    end

    it "allows staff to edit a survey on a post owned by a non-staff user" do
      post = Fabricate(:post, user: staff, raw: survey_raw)
      PostOwnerChanger.new(
        post_ids: [post.id],
        topic_id: post.topic_id,
        new_owner: user,
        acting_user: staff,
      ).change_owner!
      post.reload

      revisor = PostRevisor.new(post)
      result =
        revisor.revise!(
          staff,
          { raw: survey_raw + "\nedited by staff" },
          force_new_version: true,
        )

      expect(result).to eq(true)
      expect(post.errors[:base]).to be_empty
    end

    it "rejects edits by a non-staff user on a post they own after transfer" do
      post = Fabricate(:post, user: staff, raw: survey_raw)
      PostOwnerChanger.new(
        post_ids: [post.id],
        topic_id: post.topic_id,
        new_owner: user,
        acting_user: staff,
      ).change_owner!
      post.reload

      revisor = PostRevisor.new(post)
      result =
        revisor.revise!(user, { raw: survey_raw + "\nedited by user" }, force_new_version: true)

      expect(result).to eq(false)
      expect(post.errors[:base]).to include(I18n.t("survey.insufficient_rights_to_create"))
    end
  end
end
