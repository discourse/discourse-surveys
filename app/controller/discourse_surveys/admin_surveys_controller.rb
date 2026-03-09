# frozen_string_literal: true

module DiscourseSurveys
  class AdminSurveysController < ::Admin::AdminController
    requires_plugin PLUGIN_NAME

    skip_before_action :check_xhr, only: [:export_csv]

    def index
      surveys =
        Survey
          .includes({ post: :topic }, survey_fields: :survey_field_options)
          .joins(:post)
          .where(posts: { deleted_at: nil })
          .order(created_at: :desc)

      response_counts =
        SurveyResponse
          .joins(:survey_field)
          .where(survey_fields: { survey_id: surveys.map(&:id) })
          .group("survey_fields.survey_id")
          .distinct
          .count(:user_id)

      render json: {
               surveys:
                 serialize_data(
                   surveys,
                   AdminSurveyListSerializer,
                   response_counts: response_counts,
                 ),
             }
    end

    def export_csv
      survey = Survey.find_by(id: params[:id])
      raise Discourse::NotFound unless survey

      csv_data = CsvExporter.new(survey).export
      filename = "survey-#{survey.id}-#{survey.name}-#{Date.today}.csv"

      send_data csv_data,
                filename: filename,
                type: "text/csv; charset=utf-8",
                disposition: "attachment"
    end
  end
end
