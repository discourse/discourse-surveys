# frozen_string_literal: true

module DiscourseSurveys
  class SurveyController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in

    def submit_response
      post_id   = params.require(:post_id)
      survey_name = params.require(:survey_name)
      response = params.require(:response)
      begin
      DiscourseSurveys::Helper.submit_response(post_id, survey_name, response, current_user)
        render json: success_json
      rescue StandardError => e
        render_json_error e.message
      end
    end
  end
end
