# frozen_string_literal: true

RSpec.describe DiscourseSurveys::SurveyController do
  fab!(:user)
  fab!(:source_post, :post)
  fab!(:survey) { Survey.create!(post: source_post, invitation_enabled: true) }

  before { SiteSetting.surveys_enabled = true }

  def claim(category_id = nil)
    post "/surveys/invitation/claim.json", params: { category_id: category_id }.compact
    expect(response.status).to eq(200)
    response.parsed_body.fetch("invitation")
  end

  describe "#claim" do
    it "requires a signed-in user" do
      post "/surveys/invitation/claim.json"
      expect(response.status).to eq(403)
    end

    it "claims at most one survey per user in a rolling 24 hours" do
      sign_in(user)
      freeze_time
      expect(claim).to eq(
        {
          "post_id" => source_post.id,
          "survey" =>
            SurveySerializer
              .new(survey, scope: user.guardian, root: false)
              .as_json
              .deep_stringify_keys,
        },
      )
      Survey.create!(post: Fabricate(:post), invitation_enabled: true)
      expect(claim).to be_nil
      freeze_time(24.hours.from_now - 1.second)
      expect(claim).to be_nil
      freeze_time(1.second.from_now)
      expect(claim).to be_present
    end

    it "requires both group membership and the exact browsing category" do
      group = Fabricate(:group)
      category = Fabricate(:category)
      child = Fabricate(:category, parent_category: category)
      survey.update!(invitation_category_id: category.id, invitation_group_id: group.id)
      sign_in(user)
      expect(claim(category.id)).to be_nil
      group.add(user)
      expect(claim).to be_nil
      expect(claim(child.id)).to be_nil
      expect(claim(category.id)).to include("post_id" => source_post.id)
    end

    it "rejects a browsing category the claimant cannot see" do
      category = Fabricate(:category)
      category.set_permissions(staff: :full)
      category.save!
      survey.update!(invitation_category_id: category.id)
      sign_in(user)
      expect(claim(category.id)).to be_nil
    end

    it "skips inactive, disabled and previously answered surveys" do
      sign_in(user)
      survey.update!(active: false)
      expect(claim).to be_nil
      survey.update!(active: true, invitation_enabled: false)
      expect(claim).to be_nil
      survey.update!(invitation_enabled: true)
      field = survey.survey_fields.create!(digest: "question", question: "Why?")
      field.survey_responses.create!(user_id: user.id, value: "Yes")
      expect(claim).to be_nil
    end

    it "skips hidden, non-regular and deleted posts" do
      sign_in(user)
      source_post.update!(hidden: true)
      expect(claim).to be_nil
      source_post.update!(hidden: false, post_type: Post.types[:whisper])
      expect(claim).to be_nil
      source_post.update!(post_type: Post.types[:regular])
      source_post.trash!
      expect(claim).to be_nil
    end

    it "never delivers on closed, archived, or private message topics, even to staff" do
      sign_in(Fabricate(:admin))
      topic = source_post.topic
      topic.update!(closed: true)
      expect(claim).to be_nil
      topic.update!(closed: false, archived: true)
      expect(claim).to be_nil
      topic.update!(archived: false, archetype: Archetype.private_message, category_id: nil)
      expect(claim).to be_nil
    end

    it "requires topic access and reply permission" do
      category = Fabricate(:category)
      source_post.topic.update!(category: category)
      sign_in(user)
      category.set_permissions(staff: :full)
      category.save!
      expect(claim).to be_nil
      category.set_permissions(everyone: :readonly)
      category.save!
      expect(claim).to be_nil
    end
  end

  describe "#dismiss" do
    it "remembers dismissal after cooldown without affecting other users" do
      sign_in(user)
      expect(claim).to be_present
      post "/surveys/invitations/#{survey.id}/dismiss.json"
      expect(response.status).to eq(204)
      freeze_time(2.days.from_now)
      expect(claim).to be_nil
      sign_in(Fabricate(:user))
      expect(claim).to be_present
    end
  end
end
