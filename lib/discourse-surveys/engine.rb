# frozen_string_literal: true

module DiscourseSurvey
  HAS_SURVEYS ||= "has_surveys"
  DEFAULT_SURVEY_NAME ||= "survey"

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseSurvey

    config.after_initialize do
      Discourse::Application.routes.append do
        mount ::DiscourseSurvey::Engine, at: "/"
      end
    end
  end
end
