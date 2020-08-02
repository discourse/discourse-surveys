# frozen_string_literal: true

module DiscourseSurvey
  class Helper
    class << self

      def create!(post_id, survey = nil)
        created_survey = Survey.create!(
          post_id: post_id,
          survey_number: survey["survey_number"].presence || 1,
          name: survey["name"].presence || "survey",
          active: survey["active"].presence || true,
          visibility: survey["public"] == "true" ? "everyone" : "secret",
        )

        survey["fields"].each do |field|
          created_survey_field = SurveyField.create!(
            survey_id: created_survey.id,
            digest:  field["field-id"].presence,
            question: field["question"],
            response_type: field["type"] || "radio",
          )

          field["options"].each do |option|
            SurveyFieldOption.create!(
              survey_field_id: created_survey_field.id,
              digest: option["id"].presence,
              html: option["html"].presence&.strip
            )
          end
        end
      end

      def extract(raw, topic_id, user_id = nil)
        cooked = PrettyText.cook(raw, topic_id: topic_id, user_id: user_id)

        Nokogiri::HTML5(cooked).css("div.survey").map do |s|
          survey = { "name" => DiscourseSurvey::DEFAULT_SURVEY_NAME, "fields" => [] }

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

          survey
        end
      end
    end
  end
end
