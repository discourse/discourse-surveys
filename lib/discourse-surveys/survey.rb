# frozen_string_literal: true

module DiscourseSurvey
  class Survey
    class << self

      def extract(raw, topic_id, user_id = nil)
        cooked = PrettyText.cook(raw, topic_id: topic_id, user_id: user_id)

        Nokogiri::HTML5(cooked).css("div.survey").map do |p|
          poll = { "options" => [], "name" => DiscoursePoll::DEFAULT_SURVEY_NAME }

          # attributes
          p.attributes.values.each do |attribute|
            if attribute.name.start_with?(DATA_PREFIX)
              poll[attribute.name[DATA_PREFIX.length..-1]] = CGI.escapeHTML(attribute.value || "")
            end
          end

          # options
          p.css("li[#{DATA_PREFIX}option-id]").each do |o|
            option_id = o.attributes[DATA_PREFIX + "option-id"].value.to_s
            poll["options"] << { "id" => option_id, "html" => o.inner_html.strip }
          end

          poll
        end
      end

    end
  end
end
