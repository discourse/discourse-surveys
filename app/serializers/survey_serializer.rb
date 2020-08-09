# frozen_string_literal: true

class SurveySerializer < ApplicationSerializer
  attributes :name,
             :active,
             :visibility,
             :fields

  def fields
    object.survey_fields.map { |f| SurveyFieldSerializer.new(f, root: false).as_json }
  end

end
