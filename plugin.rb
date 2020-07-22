# frozen_string_literal: true

# name: discourse-surveys
# about: Discourse plugin to create surveys.
# version: 0.1
# authors: Arpit Jalan
# url: https://github.com/discourse-org/discourse-surveys

enabled_site_setting :surveys_enabled

PLUGIN_NAME ||= 'discourse-surveys'.freeze

load File.expand_path('lib/discourse-surveys/engine.rb', __dir__)

after_initialize do
  %w{
    ../app/models/survey.rb
    ../app/models/survey_field.rb
    ../app/models/survey_field_option.rb
    ../app/models/survey_response.rb
    ../app/lib/discourse-surveys/survey.rb
  }.each do |path|
    load File.expand_path(path, __FILE__)
  end

  reloadable_patch do
    Post.class_eval do
      attr_accessor :extracted_surveys

      has_many :surveys

      after_save do
        surveys = self.extracted_surveys
        next if surveys.blank? || !surveys.is_a?(Hash)
        post = self

        Survey.transaction do
          surveys.values.each do |survey|
            DiscourseSurvey::Survey.create!(post.id, survey)
          end
          post.custom_fields[DiscourseSurvey::HAS_SURVEYS] = true
          post.save_custom_fields(true)
        end
      end
    end

    User.class_eval do
      has_many :survey_response, dependent: :delete_all
    end
  end

  validate(:post, :validate_surveys) do |force = nil|
    return unless self.raw_changed? || force

    validator = DiscourseSurvey::SurveysValidator.new(self)
    return unless (surveys = validator.validate_surveys)

    if surveys.present?
      validator = DiscourseSurvey::PostValidator.new(self)
      return unless validator.validate_post
    end

    # are we updating a post?
    if self.id.present?
      DiscourseSurvey::SurveysUpdater.update(self, surveys)
    else
      self.extracted_surveys = surveys
    end

    true
  end
end

