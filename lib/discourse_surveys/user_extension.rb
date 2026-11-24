# frozen_string_literal: true

module DiscourseSurveys
  module UserExtension
    extend ActiveSupport::Concern

    prepended do
      has_many :survey_response, dependent: :delete_all
      has_many :survey_invitations, dependent: :delete_all
    end
  end
end
