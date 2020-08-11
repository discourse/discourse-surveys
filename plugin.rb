# frozen_string_literal: true

# name: discourse-surveys
# about: Discourse plugin to create surveys.
# version: 0.1
# authors: Arpit Jalan
# url: https://github.com/discourse-org/discourse-surveys

enabled_site_setting :surveys_enabled

register_asset "stylesheets/common/survey.scss"
register_asset "stylesheets/desktop/survey.scss"

load File.expand_path('lib/discourse-surveys/engine.rb', __dir__)

after_initialize do
  %w{
    ../app/controller/discourse_surveys/survey_controller.rb
    ../app/models/survey.rb
    ../app/models/survey_field.rb
    ../app/models/survey_field_option.rb
    ../app/models/survey_response.rb
    ../lib/discourse-surveys/post_validator.rb
    ../lib/discourse-surveys/helper.rb
    ../lib/discourse-surveys/survey_updater.rb
    ../lib/discourse-surveys/survey_validator.rb
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
            DiscourseSurveys::Helper.create!(post.id, survey)
          end
          post.custom_fields[DiscourseSurveys::HAS_SURVEYS] = true
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

    validator = DiscourseSurveys::SurveyValidator.new(self)
    return unless (surveys = validator.validate_surveys)

    if surveys.present?
      validator = DiscourseSurveys::PostValidator.new(self)
      return unless validator.validate_post
    end

    if Survey.where(post_id: self.id).exists?
      begin
        DiscourseSurveys::SurveyUpdater.update(self, surveys)
      rescue StandardError => e
        self.errors.add(:base, e.message)
        return false
      end
    else
      self.extracted_surveys = surveys
    end

    true
  end

  register_post_custom_field_type(DiscourseSurveys::HAS_SURVEYS, :boolean)

  topic_view_post_custom_fields_whitelister { [DiscourseSurveys::HAS_SURVEYS] }

  add_to_class(:topic_view, :surveys) do
    @surveys ||= begin
      surveys = {}

      post_with_surveys = @post_custom_fields.each_with_object([]) do |fields, obj|
        obj << fields[0] if fields[1][DiscourseSurveys::HAS_SURVEYS]
      end

      if post_with_surveys.present?
        Survey
          .includes(survey_fields: :survey_field_options)
          .where(post_id: post_with_surveys)
          .each do |p|
            surveys[p.post_id] ||= []
            surveys[p.post_id] << p
          end
      end

      surveys
    end
  end

  add_to_serializer(:post, :preloaded_surveys, false) do
    @preloaded_surveys ||= if @topic_view.present?
      @topic_view.surveys[object.id]
    else
      Survey.includes(survey_fields: :survey_field_options).where(post: object)
    end
  end

  add_to_serializer(:post, :include_preloaded_surveys?) do
    false
  end

  add_to_serializer(:post, :surveys, false) do
    preloaded_surveys.map { |s| SurveySerializer.new(s, root: false, scope: self.scope) }
  end

  add_to_serializer(:post, :include_surveys?) do
    SiteSetting.surveys_enabled && preloaded_surveys.present?
  end

end
