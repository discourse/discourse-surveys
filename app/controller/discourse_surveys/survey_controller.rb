# frozen_string_literal: true

require_relative "../../../lib/discourse_surveys/invitation_delivery"

module DiscourseSurveys
  class SurveyController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    use DiscourseSurveys::FilterSurveyResponse, only: :submit_response

    before_action :ensure_logged_in

    def claim
      category_id = params[:category_id]
      if !category_id.nil? &&
           (!category_id.to_s.match?(/\A[1-9]\d{0,18}\z/) || category_id.to_i > 2**63 - 1)
        raise Discourse::InvalidParameters.new(:category_id)
      end

      survey = InvitationDelivery.claim(current_user, category_id)
      invitation =
        if survey
          { survey: serialize_data(survey, SurveySerializer, root: false), post_id: survey.post_id }
        end
      render_json_dump(invitation: invitation)
    end

    def dismiss
      current_user.with_lock do
        SurveyInvitation.where(
          user_id: current_user.id,
          survey_id: params[:survey_id],
          dismissed_at: nil,
        ).update_all(dismissed_at: Time.current)
      end
      head :no_content
    end

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
          via_invitation: params[:via_invitation].to_s == "true",
        )
        render json: success_json
      rescue Discourse::InvalidAccess
        raise
      rescue StandardError => e
        render_json_error e.message
      end
    end
  end
end
