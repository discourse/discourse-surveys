# frozen_string_literal: true

# name: discourse-surveys
# about: Discourse plugin to create surveys.
# version: 0.1
# authors: Arpit Jalan
# url: https://github.com/discourse-org/discourse-surveys

enabled_site_setting :surveys_enabled

register_asset "stylesheets/common/survey.scss"
register_asset "stylesheets/desktop/survey.scss"

register_svg_icon "far-check-circle" if respond_to?(:register_svg_icon)

require_relative "lib/discourse_surveys/engine"

after_initialize do
  require_relative "app/controller/discourse_surveys/survey_controller"
  require_relative "app/models/survey"
  require_relative "app/models/survey_field"
  require_relative "app/models/survey_field_option"
  require_relative "app/models/survey_response"
  require_relative "lib/discourse_surveys/post_validator"
  require_relative "lib/discourse_surveys/helper"
  require_relative "lib/discourse_surveys/survey_updater"
  require_relative "lib/discourse_surveys/survey_validator"
  require_relative "lib/discourse_surveys/post_extension"
  require_relative "lib/discourse_surveys/user_extension"

  reloadable_patch do
    Post.prepend(DiscourseSurveys::PostExtension)
    User.prepend(DiscourseSurveys::UserExtension)
  end

  validate(:post, :validate_surveys) do |force = nil|
    return unless self.raw_changed? || force

    validator = DiscourseSurveys::SurveyValidator.new(self)
    return unless (surveys = validator.validate_surveys)

    if surveys.present?
      validator = DiscourseSurveys::PostValidator.new(self)
      return unless validator.validate_post
    end

    if self.id && Survey.where(post_id: self.id).exists?
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

  topic_view_post_custom_fields_allowlister { [DiscourseSurveys::HAS_SURVEYS] }

  add_to_class(:topic_view, :surveys) do
    @surveys ||=
      begin
        surveys = {}

        post_with_surveys =
          @post_custom_fields.each_with_object([]) do |fields, obj|
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

  add_to_serializer(
    :post,
    :preloaded_surveys,
    respect_plugin_enabled: false,
    include_condition: -> { false },
  ) do
    @preloaded_surveys ||=
      if @topic_view.present?
        @topic_view.surveys[object.id]
      else
        Survey.includes(survey_fields: :survey_field_options).where(post: object)
      end
  end

  add_to_serializer(
    :post,
    :surveys,
    respect_plugin_enabled: true,
    include_condition: -> { preloaded_surveys.present? },
  ) { preloaded_surveys.map { |s| SurveySerializer.new(s, root: false, scope: self.scope) } }

  # Remove surveys from topic excerpts
  on(:reduce_excerpt) { |doc, post| doc.css(".survey").remove }
end
