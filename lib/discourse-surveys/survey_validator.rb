# frozen_string_literal: true

module DiscourseSurvey
  class SurveyValidator

    MAX_VALUE = 2_147_483_647

    def initialize(post)
      @post = post
    end

    def validate_surveys
      surveys = {}

      DiscourseSurvey::Helper::extract(@post.raw, @post.topic_id, @post.user_id).each do |survey|
        # return false unless valid_arguments?(survey)
        # return false unless unique_options?(survey)
        # return false unless any_blank_options?(survey)
        # return false unless at_least_one_option?(survey)

        surveys[survey["name"]] = survey
      end

      surveys
    end

    private

    def valid_arguments?(survey)
      valid = true

      survey["fields"].each do |field|
        if field["response_type"].present? && !::SurveyField.response_type.has_key?(field["response_type"])
          @post.errors.add(:base, I18n.t("survey.invalid_argument", argument: "response_type", value: field["response_type"]))
          valid = false
        end

        unless field["question"].present?
          @post.errors.add(:base, I18n.t("survey.blank_question"))
          valid = false
        end
      end

      valid
    end

    def unique_options?(survey)
      if survey["options"].map { |o| o["id"] }.uniq.size != survey["options"].size
        if survey["name"] == ::DiscourseSurvey::DEFAULT_SURVEY_NAME
          @post.errors.add(:base, I18n.t("survey.default_survey_must_have_different_options"))
        else
          @post.errors.add(:base, I18n.t("survey.named_survey_must_have_different_options", name: survey["name"]))
        end

        return false
      end

      true
    end

    def any_blank_options?(survey)
      if survey["options"].any? { |o| o["html"].blank? }
        if survey["name"] == ::DiscourseSurvey::DEFAULT_SURVEY_NAME
          @post.errors.add(:base, I18n.t("survey.default_survey_must_not_have_any_empty_options"))
        else
          @post.errors.add(:base, I18n.t("survey.named_survey_must_not_have_any_empty_options", name: survey["name"]))
        end

        return false
      end

      true
    end

    def at_least_one_option?(survey)
      if survey["options"].size < 1
        if survey["name"] == ::DiscourseSurvey::DEFAULT_SURVEY_NAME
          @post.errors.add(:base, I18n.t("survey.default_survey_must_have_at_least_1_option"))
        else
          @post.errors.add(:base, I18n.t("survey.named_survey_must_have_at_least_1_option", name: survey["name"]))
        end

        return false
      end

      true
    end

  end
end
