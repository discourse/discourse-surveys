# frozen_string_literal: true

class SurveySerializer < ApplicationSerializer
  attributes :name,
             :title,
             :active,
             :visibility,
             :fields,
             :user_responded

  def fields
    object.survey_fields.map { |f| SurveyFieldSerializer.new(f, root: false).as_json }
  end

  def user_responded
    scope.authenticated? && object.has_responded?(scope.user)
  end

end
