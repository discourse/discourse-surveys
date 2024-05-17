# frozen_string_literal: true

module DiscourseSurveys
  module PostExtension
    extend ActiveSupport::Concern

    prepended do
      attr_accessor :extracted_surveys

      has_many :surveys

      after_save do
        surveys = self.extracted_surveys
        next if surveys.blank? || !surveys.is_a?(Hash)
        post = self

        Survey.transaction do
          surveys.values.each { |survey| DiscourseSurveys::Helper.create!(post.id, survey) }
          post.custom_fields[DiscourseSurveys::HAS_SURVEYS] = true
          post.save_custom_fields(true)
        end
      end
    end
  end
end
