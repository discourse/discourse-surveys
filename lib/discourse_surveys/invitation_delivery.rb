# frozen_string_literal: true

module DiscourseSurveys
  class InvitationDelivery
    def self.claim(user, category_id)
      new(user).claim(category_id)
    end

    def self.can_submit?(survey, user)
      return false unless SiteSetting.surveys_enabled && user && survey

      new(user).can_submit?(survey)
    end

    def initialize(user)
      @user = user
      @guardian = user.guardian
    end

    def claim(category_id)
      unless Survey.exists?(
               active: true,
               invitation_enabled: true,
               invitation_category_id: [nil, category_id],
             )
        return
      end

      # Serialize even the first two claims, before the user has a delivery row to lock.
      @user.with_lock do
        invitations = SurveyInvitation.where(user_id: @user.id)
        next if invitations.where("last_claimed_at > ?", 24.hours.ago).exists?

        survey =
          eligible_surveys(category_id)
            .where.not(id: invitations.where.not(dismissed_at: nil).select(:survey_id))
            .find_each
            .detect { |candidate| accessible?(candidate) }
        next unless survey

        invitation = invitations.find_or_initialize_by(survey_id: survey.id)
        invitation.update!(last_claimed_at: Time.current, browsing_category_id: category_id)
        survey
      end
    end

    def can_submit?(survey)
      invitation =
        SurveyInvitation.find_by(user_id: @user.id, survey_id: survey.id, dismissed_at: nil)
      return false unless invitation

      candidate = eligible_surveys(invitation.browsing_category_id).find_by(id: survey.id)
      candidate.present? && accessible?(candidate)
    end

    private

    def eligible_surveys(category_id)
      if category_id && !@guardian.can_see_category?(Category.find_by(id: category_id))
        return Survey.none
      end

      answered =
        SurveyField
          .joins(:survey_responses)
          .where(survey_responses: { user_id: @user.id })
          .select(:survey_id)
      Survey
        .joins(post: :topic)
        .preload(post: { topic: :category })
        .where(
          active: true,
          invitation_enabled: true,
          invitation_category_id: [nil, category_id],
          posts: {
            deleted_at: nil,
            hidden: false,
            post_type: Post.types[:regular],
          },
          topics: {
            deleted_at: nil,
            visible: true,
            closed: false,
            archived: false,
            archetype: Archetype.default,
          },
        )
        .where.not(id: answered)
    end

    def accessible?(survey)
      post = survey.post
      (!survey.invitation_group_id || @user.in_any_groups?([survey.invitation_group_id])) &&
        !@user.silenced? && @guardian.can_see_topic?(post.topic) && @guardian.can_see_post?(post) &&
        @guardian.can_create_post_on_topic?(post.topic)
    end
  end
end
