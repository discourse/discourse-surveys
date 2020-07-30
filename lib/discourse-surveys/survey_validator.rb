# frozen_string_literal: true

module DiscourseSurvey
  class SurveyValidator

    MAX_VALUE = 2_147_483_647

    def initialize(post)
      @post = post
    end

    def validate_surveys
      surveys = {}

      DiscourseSurvey::Survey::extract(@post.raw, @post.topic_id, @post.user_id).each do |survey|
        # return false unless valid_arguments?(survey)
        # return false unless valid_numbers?(survey)
        # return false unless unique_survey_name?(surveys, survey)
        # return false unless unique_options?(survey)
        # return false unless any_blank_options?(survey)
        # return false unless at_least_one_option?(survey)
        # return false unless valid_number_of_options?(survey)
        # return false unless valid_multiple_choice_settings?(survey)

        surveys[survey["name"]] = survey
      end

      surveys
    end

  end
end
