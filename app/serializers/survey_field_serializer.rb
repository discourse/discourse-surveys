# frozen_string_literal: true

class SurveyFieldSerializer < ApplicationSerializer
  attributes :question,
             :response_type,
             :digest,
             :position,
             :options,
             :has_options,
             :is_multiple_choice

  def options
    object.survey_field_options.map { |o| SurveyFieldOptionSerializer.new(o, root: false).as_json }
  end

  def has_options
    object.has_options?
  end

  def is_multiple_choice
    object.is_multiple_choice?
  end

end
