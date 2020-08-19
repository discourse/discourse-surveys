# frozen_string_literal: true

module DiscourseSurveys
  class Helper
    class << self
      def create!(post_id, survey = nil)
        if Survey.where(post_id: post_id).exists?
          raise StandardError.new I18n.t("survey.post_survey_exists")
        end

        Survey.transaction do
          created_survey = Survey.create!(
            post_id: post_id,
            survey_number: survey["survey_number"].presence || 1,
            name: survey["name"].presence || "survey",
            active: survey["active"].presence || true,
            visibility: survey["public"] == "true" ? Survey.visibility[:everyone] : Survey.visibility[:secret]
          )

          survey["fields"].each do |field|
            created_survey_field = SurveyField.create!(
              survey_id: created_survey.id,
              digest:  field["field-id"].presence,
              question: field["question"],
              position: field["position"],
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

      def extract(raw, topic_id, user_id = nil)
        cooked = PrettyText.cook(raw, topic_id: topic_id, user_id: user_id)

        Nokogiri::HTML5(cooked).css("div.survey").map do |s|
          survey = { "name" => DiscourseSurveys::DEFAULT_SURVEY_NAME, "fields" => [] }

          s.attributes.values.each do |attribute|
            if attribute.name.start_with?(DATA_PREFIX)
              survey[attribute.name[DATA_PREFIX.length..-1]] = CGI.escapeHTML(attribute.value || "")
            end
          end

          # radio field
          s.css("div[#{DATA_PREFIX}type='radio']").each do |radio|
            radio_hash = { "type" => "radio", "options" => [] }

            # attributes
            radio.attributes.values.each do |attribute|
              if attribute.name.start_with?(DATA_PREFIX)
                radio_hash[attribute.name[DATA_PREFIX.length..-1]] = CGI.escapeHTML(attribute.value || "")
              end
            end

            # options
            radio.css("li[#{DATA_PREFIX}option-id]").each do |o|
              option_id = o.attributes[DATA_PREFIX + "option-id"].value.to_s
              radio_hash["options"] << { "id" => option_id, "html" => o.inner_html.strip }
            end

            survey["fields"] << radio_hash
          end

          # checkbox field
          s.css("div[#{DATA_PREFIX}type='checkbox']").each do |checkbox|
            checkbox_hash = { "type" => "checkbox", "options" => [] }

            # attributes
            checkbox.attributes.values.each do |attribute|
              if attribute.name.start_with?(DATA_PREFIX)
                checkbox_hash[attribute.name[DATA_PREFIX.length..-1]] = CGI.escapeHTML(attribute.value || "")
              end
            end

            # options
            checkbox.css("li[#{DATA_PREFIX}option-id]").each do |o|
              option_id = o.attributes[DATA_PREFIX + "option-id"].value.to_s
              checkbox_hash["options"] << { "id" => option_id, "html" => o.inner_html.strip }
            end

            survey["fields"] << checkbox_hash
          end

          # dropdown field
          s.css("div[#{DATA_PREFIX}type='dropdown']").each do |dropdown|
            dropdown_hash = { "type" => "dropdown", "options" => [] }

            # attributes
            dropdown.attributes.values.each do |attribute|
              if attribute.name.start_with?(DATA_PREFIX)
                dropdown_hash[attribute.name[DATA_PREFIX.length..-1]] = CGI.escapeHTML(attribute.value || "")
              end
            end

            # options
            dropdown.css("li[#{DATA_PREFIX}option-id]").each do |o|
              option_id = o.attributes[DATA_PREFIX + "option-id"].value.to_s
              dropdown_hash["options"] << { "id" => option_id, "html" => o.inner_html.strip }
            end

            survey["fields"] << dropdown_hash
          end

          # textarea field
          s.css("div[#{DATA_PREFIX}type='textarea']").each do |textarea|
            textarea_hash = { "type" => "textarea" }

            # attributes
            textarea.attributes.values.each do |attribute|
              if attribute.name.start_with?(DATA_PREFIX)
                textarea_hash[attribute.name[DATA_PREFIX.length..-1]] = CGI.escapeHTML(attribute.value || "")
              end
            end

            survey["fields"] << textarea_hash
          end

          # number field
          s.css("div[#{DATA_PREFIX}type='number']").each do |number|
            number_hash = { "type" => "number" }

            # attributes
            number.attributes.values.each do |attribute|
              if attribute.name.start_with?(DATA_PREFIX)
                number_hash[attribute.name[DATA_PREFIX.length..-1]] = CGI.escapeHTML(attribute.value || "")
              end
            end

            survey["fields"] << number_hash
          end

          # star field
          s.css("div[#{DATA_PREFIX}type='star']").each do |star|
            star_hash = { "type" => "star" }

            # attributes
            star.attributes.values.each do |attribute|
              if attribute.name.start_with?(DATA_PREFIX)
                star_hash[attribute.name[DATA_PREFIX.length..-1]] = CGI.escapeHTML(attribute.value || "")
              end
            end

            survey["fields"] << star_hash
          end

          survey
        end
      end

      def submit_response(post_id, survey_name, response, user)
        Survey.transaction do
          post = Post.find_by(id: post_id)

          # post must not be deleted
          if post.nil? || post.trashed?
            raise StandardError.new I18n.t("survey.post_is_deleted")
          end

          # topic must not be archived
          if post.topic&.archived
            raise StandardError.new I18n.t("survey.topic_must_be_open_to_vote")
          end

          # user must be allowed to post in topic
          guardian = Guardian.new(user)
          if !guardian.can_create_post?(post.topic)
            raise StandardError.new I18n.t("survey.user_cant_post_in_topic")
          end

          survey = Survey.includes(survey_fields: :survey_field_options).find_by(post_id: post_id, name: survey_name)
          raise StandardError.new I18n.t("survey.no_survey_with_this_name", name: survey_name) unless survey
          raise StandardError.new I18n.t("survey.user_already_responded") if survey.has_responded?(user)

          # remove fields that aren't available in the survey
          available_fields = survey.survey_fields.map { |o| o.digest }.to_set
          response.select! { |k| available_fields.include?(k) }
          raise StandardError.new I18n.t("survey.requires_at_least_1_valid_field") if response.empty?

          fields = survey.survey_fields.each_with_object({}) do |field, obj|
            if response.include?(field.digest)
              if field.has_options?
                option_ids = SurveyFieldOption.where(survey_field_id: field.id, digest: response[field.digest]).pluck(:id)
                obj[field.id] = { option_ids: option_ids, has_options: true }
              else
                obj[field.id] = { value: response[field.digest], has_options: false }
              end
            end
          end

          # save response
          fields.each do |field_id, response|
            if response[:has_options]
              response[:option_ids].each do |option_id|
                SurveyResponse.create!(survey_field_id: field_id, user_id: user.id, survey_field_option_id: option_id)
              end
            else
              SurveyResponse.create!(survey_field_id: field_id, user_id: user.id, value: response[:value])
            end
          end
        end
      end
    end
  end
end
