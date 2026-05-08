# frozen_string_literal: true

module DiscourseSurveys
  class PostValidator
    def initialize(post)
      @post = post
    end

    def validate_post
      acting_user = @post&.acting_user || @post&.user
      allowed =
        acting_user.present? &&
          (acting_user.admin? || acting_user.in_any_groups?(SiteSetting.surveys_allowed_groups_map))

      if allowed
        true
      else
        @post.errors.add(:base, I18n.t("survey.insufficient_rights_to_create"))
        false
      end
    end
  end
end
