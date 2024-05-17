# frozen_string_literal: true

module DiscourseSurveys
  module UserExtension
    extend ActiveSupport::Concern

    prepended { has_many :survey_response, dependent: :delete_all }
  end
end
