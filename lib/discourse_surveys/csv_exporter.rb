# frozen_string_literal: true

require "csv"

module DiscourseSurveys
  class CsvExporter
    def initialize(survey)
      @survey = survey
    end

    def export
      fields = @survey.survey_fields.order(:position).to_a

      responses =
        SurveyResponse.where(survey_field_id: fields.map(&:id)).includes(:survey_field_option).to_a

      return empty_csv if responses.empty?

      grouped = responses.group_by { |r| respondent_key(r) }
      users = load_users(grouped.keys)
      fields_by_id = fields.index_by(&:id)
      lookup = responses.group_by { |r| [respondent_key(r), r.survey_field_id] }

      CSV.generate do |csv|
        csv << [I18n.t("survey.csv.username"), I18n.t("survey.csv.email")] +
          fields.map { |f| strip_html(f.question) }

        grouped.each_key do |key|
          user = key[:user_id] && users[key[:user_id]]
          csv << [user ? user.username : I18n.t("survey.csv.anonymous"), user&.email.to_s] +
            fields.map { |f| format_response(lookup[[key, f.id]], fields_by_id[f.id]) }
        end
      end
    end

    private

    def empty_csv
      CSV.generate { |csv| csv << [I18n.t("survey.csv.no_responses")] }
    end

    def respondent_key(response)
      { user_id: response.user_id, anon_token: response.anon_token }
    end

    def load_users(keys)
      user_ids = keys.filter_map { |key| key[:user_id] }
      user_ids.empty? ? {} : User.where(id: user_ids).index_by(&:id)
    end

    def format_response(responses, field)
      return "" if responses.blank? || field.nil?

      if field.has_options?
        responses.filter_map { |r| strip_html(r.survey_field_option&.html) }.join(", ")
      else
        responses.first&.value || ""
      end
    end

    def strip_html(html)
      return "" if html.blank?
      ActionController::Base.helpers.strip_tags(html).strip
    end
  end
end
