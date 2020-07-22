# frozen_string_literal: true

module DiscourseSurvey
  class SurveysUpdater

    SURVEY_ATTRIBUTES ||= %w{status visibility}

    def self.update(post, surveys)
      #
    end

    private

    def self.is_different?(old_survey, new_survey, new_options)
      # an attribute was changed?
      SURVEY_ATTRIBUTES.each do |attr|
        return true if old_survey.public_send(attr) != new_survey.public_send(attr)
      end

      # an option was changed?
      return true if old_survey.survey_options.map { |o| o.digest }.sort != new_options.map { |o| o["id"] }.sort

      # it's the same!
      false
    end

  end
end
