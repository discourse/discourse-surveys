# frozen_string_literal: true

module DiscourseSurveys
  class SurveyValidator
    MAX_VALUE = 2_147_483_647

    def initialize(post)
      @post = post
    end

    def validate_surveys
      surveys = {}
      survey_count = 0

      DiscourseSurveys::Helper::extract(@post.raw, @post.topic_id, @post.user_id).each do |survey|
        return false unless unique_questions?(survey)
        return false unless any_blank_questions?(survey)
        surveys["survey"] = survey
        survey_count += 1
      end

      if survey_count > 1
        @post.errors.add(:base, I18n.t("survey.max_one_survey_per_post"))
        return false
      end

      surveys
    end

    private

    def unique_questions?(survey)
      if survey["fields"].map { |f| f["question"] }.uniq.size != survey["fields"].size
        @post.errors.add(:base, I18n.t("survey.survey_must_have_different_questions"))
        return false
      end

      true
    end

    def any_blank_questions?(survey)
      if survey["fields"].any? { |f| f["question"].blank? }
        @post.errors.add(:base, I18n.t("survey.survey_must_not_have_any_empty_questions"))
        return false
      end

      true
    end
  end
end
