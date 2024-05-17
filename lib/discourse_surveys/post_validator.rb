# frozen_string_literal: true

module DiscourseSurveys
  class PostValidator
    def initialize(post)
      @post = post
    end

    def validate_post
      if @post&.user&.staff? || @post&.topic&.pm_with_non_human_user?
        true
      else
        @post.errors.add(:base, I18n.t("survey.insufficient_rights_to_create"))
        false
      end
    end
  end
end
