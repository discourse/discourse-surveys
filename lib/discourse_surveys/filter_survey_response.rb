# frozen_string_literal: true

module DiscourseSurveys
  class FilterSurveyResponse
    def initialize(app)
      @app = app
    end

    def call(env)
      key = "action_dispatch.parameter_filter"
      env[key] = Array(env[key]) + [/\Aresponse\z/i]
      @app.call(env)
    end
  end
end
