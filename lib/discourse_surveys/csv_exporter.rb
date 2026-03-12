# frozen_string_literal: true

require "csv"

module DiscourseSurveys
  class CsvExporter
    def initialize(survey)
      @survey = survey
    end

    def export
      fields = @survey.survey_fields.order(:position)
      field_ids = fields.map(&:id)

      user_ids = SurveyResponse.where(survey_field_id: field_ids).distinct.pluck(:user_id)

      return CSV.generate { |csv| csv << [I18n.t("survey.csv.no_responses")] } if user_ids.empty?

      users = User.where(id: user_ids).index_by(&:id)
      responses_by_user = build_responses_lookup(fields, field_ids, user_ids)

      CSV.generate do |csv|
        csv << [I18n.t("survey.csv.username"), I18n.t("survey.csv.email")] +
          fields.map { |f| strip_html(f.question) }

        user_ids.each do |uid|
          user = users[uid]
          next unless user

          csv << [user.username, user.email] + fields.map { |f| responses_by_user[uid][f.id] || "" }
        end
      end
    end

    private

    def build_responses_lookup(fields, field_ids, user_ids)
      responses_by_user = user_ids.each_with_object({}) { |uid, h| h[uid] = {} }
      fields_by_id = fields.index_by(&:id)

      SurveyResponse
        .where(survey_field_id: field_ids, user_id: user_ids)
        .includes(:survey_field_option)
        .group_by(&:user_id)
        .each do |uid, user_responses|
          user_responses
            .group_by(&:survey_field_id)
            .each do |fid, field_responses|
              field = fields_by_id[fid]
              next unless field

              responses_by_user[uid][fid] = if field.has_options?
                field_responses
                  .filter_map { |r| strip_html(r.survey_field_option&.html) }
                  .join(", ")
              else
                field_responses.first&.value || ""
              end
            end
        end

      responses_by_user
    end

    def strip_html(html)
      return "" if html.blank?
      ActionController::Base.helpers.strip_tags(html).strip
    end
  end
end
