# frozen_string_literal: true

module DiscourseSurveys
  class AdminSurveysController < ::Admin::AdminController
    requires_plugin PLUGIN_NAME

    PAGE_SIZE = 50

    skip_before_action :check_xhr, only: [:export_csv]

    def index
      page = params[:page].to_i
      page = 0 if page < 0

      base_scope =
        Survey
          .includes({ post: :topic }, survey_fields: :survey_field_options)
          .joins(:post)
          .where(posts: { deleted_at: nil })
          .order(created_at: :desc)

      total_count = base_scope.count
      surveys = base_scope.limit(PAGE_SIZE).offset(page * PAGE_SIZE)

      response_counts =
        SurveyResponse
          .joins(:survey_field)
          .where(survey_fields: { survey_id: surveys.map(&:id) })
          .group("survey_fields.survey_id")
          .distinct
          .count(:user_id)

      result = {
        surveys:
          serialize_data(surveys, AdminSurveyListSerializer, response_counts: response_counts),
        total_rows_surveys: total_count,
      }

      if (page + 1) * PAGE_SIZE < total_count
        result[
          :load_more_surveys
        ] = "#{Discourse.base_path}/admin/plugins/discourse-surveys/surveys?page=#{page + 1}"
      end

      render_json_dump(result)
    end

    def update_invitation
      survey = Survey.find(params[:id])
      enabled = params.require(:enabled)
      raise Discourse::InvalidParameters.new(:enabled) if %w[true false].exclude?(enabled.to_s)

      survey.update!(
        invitation_enabled: enabled,
        invitation_group_id: invitation_target_id(:group_id, Group),
        invitation_category_id: invitation_target_id(:category_id, Category),
      )
      render_json_dump(invitation_config: survey.invitation_config)
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

    private

    def invitation_target_id(key, model)
      value = params.fetch(key)
      return if value.nil? || value == ""
      unless value.to_s.match?(/\A\d+\z/) && model.exists?(id: value)
        raise Discourse::InvalidParameters.new(key)
      end
      value
    end
  end
end
