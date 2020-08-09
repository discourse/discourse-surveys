# frozen_string_literal: true

class SurveyFieldSerializer < ApplicationSerializer
  attributes :question,
             :response_type,
             :digest,
             :options

  def options
    object.survey_field_options.map { |o| SurveyFieldOptionSerializer.new(o, root: false).as_json }
  end

end
