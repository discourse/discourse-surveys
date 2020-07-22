# frozen_string_literal: true

module DiscourseSurveys
  class Engine < ::Rails::Engine
    engine_name "discourse-surveys".freeze
    isolate_namespace DiscourseSurveys

    config.after_initialize do
      Discourse::Application.routes.append do
        mount ::DiscourseSurveys::Engine, at: "/"
      end
    end
  end
end
