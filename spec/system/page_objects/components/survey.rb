# frozen_string_literal: true

module PageObjects
  module Components
    class Survey < PageObjects::Components::Base
      def initialize(selector = ".survey", parent = nil)
        @selector = selector
        @parent = parent || page
      end

      def component
        @parent.find(@selector, wait: 10)
      end

      def has_title?(title)
        component.has_css?(".survey-title", text: title)
      end

      def has_no_title?
        component.has_no_css?(".survey-title")
      end

      def has_submitted_message?
        component.has_css?(".survey-submitted")
      end

      def has_no_submitted_message?
        component.has_no_css?(".survey-submitted")
      end

      def submit_button
        component.find("button.submit-response")
      end

      def submit_button_disabled?
        submit_button.disabled?
      end

      def submit_button_enabled?
        !submit_button.disabled?
      end

      def submit
        submit_button.click
        self
      end

      def field(question_text)
        SurveyField.new(question_text, component)
      end

      def has_field?(question_text)
        component.has_css?(".field-question", text: question_text)
      end
    end

    class SurveyField < PageObjects::Components::Base
      def initialize(question_text, parent)
        @question_text = question_text
        @parent = parent
      end

      def component
        @parent.find(".field-question", text: @question_text).ancestor(".survey-field")
      end

      def select_radio_option(option_text)
        component.find(".field-radio .survey-field-option", text: option_text, match: :first).click
        self
      end

      def select_checkbox_option(option_text)
        component.find(
          ".field-checkbox .survey-field-option",
          text: option_text,
          match: :first,
        ).click
        self
      end

      def select_dropdown_option(option_text)
        component.find(".field-dropdown select").select(option_text)
        self
      end

      def select_number(value)
        component.find(".field-number li", text: value.to_s).click
        self
      end

      def fill_textarea(text)
        component.find(".field-textarea textarea").fill_in(with: text)
        self
      end

      def select_star_rating(rating)
        component.find(".field-star label[for$='-#{rating}']").click
        self
      end

      def select_thumbs_up
        component.find(".field-thumbs label.thumbs-up").click
        self
      end

      def select_thumbs_down
        component.find(".field-thumbs label.thumbs-down").click
        self
      end

      def has_selected_option?(option_text)
        component.has_css?(".d-icon-far-circle-check, .d-icon-far-square-check", visible: true)
      end
    end
  end
end
