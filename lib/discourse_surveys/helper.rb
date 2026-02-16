# frozen_string_literal: true

module DiscourseSurveys
  class Helper
    VALID_FIELD_TYPES = %w[radio checkbox dropdown textarea number star thumbs].freeze
    FIELDS_WITH_OPTIONS = %w[radio checkbox dropdown].freeze

    class << self
      def cook_question(text)
        return "" if text.blank?
        doc = Nokogiri::HTML5.fragment(PrettyText.cook(text))
        # PrettyText wraps content in <p>, unwrap it for inline display
        doc.at("p")&.inner_html&.strip || ""
      end

      def extract_attribute_value(name, value)
        if name == "question"
          cook_question(value || "")
        else
          CGI.escapeHTML(value || "")
        end
      end

      def create!(post_id, survey = nil)
        if Survey.where(post_id: post_id).exists?
          raise StandardError.new I18n.t("survey.post_survey_exists")
        end

        Survey.transaction do
          created_survey =
            Survey.create!(
              post_id: post_id,
              survey_number: survey["survey_number"].presence || 1,
              name: survey["name"].presence || "survey",
              title: survey["title"].presence || nil,
              active: survey["active"].presence || true,
              visibility:
                (
                  if survey["public"] == "true"
                    Survey.visibility[:everyone]
                  else
                    Survey.visibility[:secret]
                  end
                ),
            )

          survey["fields"].each.with_index do |field, position|
            created_survey_field =
              SurveyField.create!(
                survey_id: created_survey.id,
                digest: field["field-id"].presence,
                question: field["question"],
                position: position,
                response_type:
                  SurveyField.response_type[field["type"].to_sym] ||
                    SurveyField.response_type[:radio],
                response_required: field["required"].presence || true,
                field_class: field["class"].presence,
              )

            if field["options"].present?
              field["options"].each do |option|
                SurveyFieldOption.create!(
                  survey_field_id: created_survey_field.id,
                  digest: option["id"].presence,
                  html: option["html"].presence&.strip,
                )
              end
            end
          end
        end
      end

      def submit_response(post_id, survey_name, response, user)
        Survey.transaction do
          post = Post.find_by(id: post_id)

          # post must not be deleted
          raise StandardError.new I18n.t("survey.post_is_deleted") if post.nil? || post.trashed?

          # topic must not be archived
          if post.topic&.archived
            raise StandardError.new I18n.t("survey.topic_must_be_open_to_vote")
          end

          # user must be allowed to post in topic
          guardian = Guardian.new(user)
          if !guardian.can_create_post?(post.topic)
            raise StandardError.new I18n.t("survey.user_cant_post_in_topic")
          end

          survey =
            Survey.includes(survey_fields: :survey_field_options).find_by(
              post_id: post_id,
              name: survey_name,
            )
          unless survey
            raise StandardError.new I18n.t("survey.no_survey_with_this_name", name: survey_name)
          end
          if survey.has_responded?(user)
            raise StandardError.new I18n.t("survey.user_already_responded")
          end

          # remove fields that aren't available in the survey
          available_fields = survey.survey_fields.map { |o| o.digest }.to_set
          response.select! { |k| available_fields.include?(k) }
          if response.empty?
            raise StandardError.new I18n.t("survey.requires_at_least_1_valid_field")
          end

          fields =
            survey
              .survey_fields
              .each_with_object({}) do |field, obj|
                if response.include?(field.digest)
                  if field.has_options?
                    option_ids =
                      SurveyFieldOption.where(
                        survey_field_id: field.id,
                        digest: response[field.digest],
                      ).pluck(:id)
                    if option_ids.empty?
                      raise StandardError.new I18n.t(
                                                "survey.invalid_option",
                                                question: field.question,
                                              )
                    end
                    obj[field.id] = { option_ids: option_ids, has_options: true }
                  else
                    value = response[field.digest]
                    if field.response_required && value.blank?
                      raise StandardError.new I18n.t(
                                                "survey.field_is_required",
                                                question: field.question,
                                              )
                    end
                    obj[field.id] = { value: value, has_options: false }
                  end
                elsif field.response_required
                  raise StandardError.new I18n.t(
                                            "survey.field_is_required",
                                            question: field.question,
                                          )
                end
              end

          # save response
          fields.each do |field_id, field_response|
            if field_response[:has_options]
              field_response[:option_ids].each do |option_id|
                SurveyResponse.create!(
                  survey_field_id: field_id,
                  user_id: user.id,
                  survey_field_option_id: option_id,
                )
              end
            else
              SurveyResponse.create!(
                survey_field_id: field_id,
                user_id: user.id,
                value: field_response[:value],
              )
            end
          end
        end
      end

      def extract(raw, topic_id, user_id = nil)
        cooked = PrettyText.cook(raw, topic_id: topic_id, user_id: user_id)

        Nokogiri
          .HTML5(cooked)
          .css("div.survey")
          .map do |s|
            survey = { "name" => DiscourseSurveys::DEFAULT_SURVEY_NAME, "fields" => Set.new }

            s.attributes.values.each do |attribute|
              if attribute.name.start_with?(DATA_PREFIX)
                attr_name = attribute.name[DATA_PREFIX.length..-1]
                survey[attr_name] = extract_attribute_value(attr_name, attribute.value)
              end
            end

            type_attribute = "#{DATA_PREFIX}type"

            s
              .css("div[#{type_attribute}]")
              .each
              .with_index do |element, position|
                type = element.attributes[type_attribute].value.to_s
                next if VALID_FIELD_TYPES.exclude?(type)
                survey["fields"] << extract_field(element, type, position)
              end

            survey
          end
      end

      private

      def extract_field(element, type, position)
        hash = { "type" => type, "position" => position }

        element.attributes.values.each do |attribute|
          if attribute.name.start_with?(DATA_PREFIX)
            attr_name = attribute.name[DATA_PREFIX.length..-1]
            hash[attr_name] = extract_attribute_value(attr_name, attribute.value)
          end
        end

        if FIELDS_WITH_OPTIONS.include?(type)
          hash["options"] = element
            .css("li[#{DATA_PREFIX}option-id]")
            .map do |o|
              {
                "id" => o.attributes[DATA_PREFIX + "option-id"].value.to_s,
                "html" => o.inner_html.strip,
              }
            end
        end

        hash
      end
    end
  end
end
