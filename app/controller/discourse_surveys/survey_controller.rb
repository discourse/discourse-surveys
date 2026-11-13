# frozen_string_literal: true

module DiscourseSurveys
  class SurveyController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    # The dedupe key for an anonymous respondent is chosen by the client, so the IP is the
    # only handle we have against scripted flooding of an unauthenticated write endpoint.
    ANONYMOUS_SUBMISSIONS_PER_HOUR = 20

    before_action :ensure_logged_in, unless: :anonymous_submissions_allowed?
    before_action :rate_limit_anonymous_submissions, if: :anonymous_submission?

    def submit_response
      post_id = params.require(:post_id)
      survey_name = params.require(:survey_name)
      response = params.require(:response)
      begin
        DiscourseSurveys::Helper.submit_response(
          post_id,
          survey_name,
          response,
          current_user,
          params[:anon_token],
        )
        render json: success_json
      rescue ActiveRecord::RecordNotUnique
        render_json_error I18n.t("survey.user_already_responded")
      rescue StandardError => e
        render_json_error e.message
      end
    end

    private

    def anonymous_submissions_allowed?
      SiteSetting.surveys_allow_anonymous_submissions
    end

    def anonymous_submission?
      current_user.blank? && anonymous_submissions_allowed?
    end

    def rate_limit_anonymous_submissions
      RateLimiter.new(
        nil,
        "survey-anonymous-submission-#{request.remote_ip}",
        ANONYMOUS_SUBMISSIONS_PER_HOUR,
        1.hour,
      ).performed!
    end
  end
end
