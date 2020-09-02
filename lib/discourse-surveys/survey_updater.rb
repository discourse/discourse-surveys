# frozen_string_literal: true

module DiscourseSurveys
  class SurveyUpdater

    SURVEY_ATTRIBUTES ||= %w{name active visibility}

    def self.update(post, surveys)
      return false unless post.present?

      ActiveRecord::Base.transaction do
        has_changed = false

        survey = surveys['survey']
        survey_record = ::Survey.where(post_id: post.id).first
        survey_id = survey_record.id

        unless survey.present?
          # disassociate survey with post
          survey_record.post_id = nil
          survey_record.save!
          return true
        end

        # update survey
        survey_record.name = survey["name"].presence || "survey"
        survey_record.visibility = survey["public"] == "true" ? Survey.visibility[:everyone] : Survey.visibility[:secret]
        survey_record.active = survey["active"].presence || true
        survey_record.save!

        response = ::SurveyResponse
          .includes(:survey_field)
          .where("survey_fields.survey_id = ?", survey_id)
          .references(:survey_field)
          .first
        has_response = response.present?

        old_field_digests = SurveyField.where(survey_id: survey_id).pluck(:digest)
        new_field_digests = []
        survey["fields"].each do |field|
          new_field_digests << field["field-id"]
        end

        deleted_field_digests = old_field_digests - new_field_digests
        created_field_digests = new_field_digests - old_field_digests

        # delete survey fields
        if deleted_field_digests.present?
          raise StandardError.new I18n.t("survey.cannot_edit") if has_response
          has_changed = true
          ::SurveyField.where(survey_id: survey_id, digest: deleted_field_digests).destroy_all
        end

        # create survey fields
        if created_field_digests.present?
          raise StandardError.new I18n.t("survey.cannot_edit") if has_response
          has_changed = true
          survey["fields"].each do |field|
            if created_field_digests.include?(field["field-id"])
              created_survey_field = SurveyField.create!(
                survey_id: survey_id,
                digest:  field["field-id"],
                question: field["question"],
                response_type: SurveyField.response_type[field["type"].to_sym] || SurveyField.response_type[:radio]
              )

              if field["options"].present?
                field["options"].each do |option|
                  SurveyFieldOption.create!(
                    survey_field_id: created_survey_field.id,
                    digest: option["id"].presence,
                    html: option["html"].presence&.strip
                  )
                end
              end
            end
          end
        end

        # update survey fields
        ::SurveyField.includes(:survey_field_options).where(survey_id: survey_id).find_each do |old_field|
          new_field = survey["fields"].select { |key| key.values.include?(old_field.digest) }
          new_field = new_field.first
          new_field_options = new_field["options"]

          # update field position and required attribute
          old_field["position"] = new_field["position"]
          old_field["response_required"] = new_field["required"].presence || true
          old_field.save!

          # update field attributes
          if is_different?(old_field, new_field, new_field_options)
            raise StandardError.new I18n.t("survey.cannot_edit") if has_response

            # destroy existing field and options
            ::SurveyField.where(survey_id: survey_id, digest: old_field.digest).destroy_all

            # create new field
            created_survey_field = SurveyField.create!(
              survey_id: survey_id,
              digest:  new_field["field-id"].presence,
              question: new_field["question"],
              response_type: SurveyField.response_type[new_field["type"].to_sym] || SurveyField.response_type[:radio]
            )

            if new_field["options"].present?
              new_field["options"].each do |option|
                SurveyFieldOption.create!(
                  survey_field_id: created_survey_field.id,
                  digest: option["id"].presence,
                  html: option["html"].presence&.strip
                )
              end
            end

            has_changed = true
          end
        end

        if has_changed && has_response
          raise StandardError.new I18n.t("survey.cannot_edit")
        end

        if ::Survey.exists?(post_id: post.id)
          post.custom_fields[HAS_SURVEYS] = true
        else
          post.custom_fields.delete(HAS_SURVEYS)
        end

        post.save_custom_fields(true)
      end
    end

    private

    def self.is_different?(old_field, new_field, new_field_options)
      # field response type was changed?
      return true if old_field.response_type != SurveyField.response_type[new_field["type"].to_sym]
      # field has no options
      return false if old_field.survey_field_options.blank? && new_field_options.blank?
      # an option was changed?
      return true if old_field.survey_field_options.map { |o| o.digest }.sort != new_field_options.map { |o| o["id"] }.sort

      # it's the same!
      false
    end

  end
end
