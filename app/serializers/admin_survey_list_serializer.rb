# frozen_string_literal: true

class AdminSurveyListSerializer < ApplicationSerializer
  attributes :id,
             :name,
             :title,
             :active,
             :created_at,
             :post_id,
             :topic_title,
             :topic_id,
             :field_count,
             :response_count

  def topic_title
    object.post&.topic&.title
  end

  def topic_id
    object.post&.topic&.id
  end

  def field_count
    object.survey_fields.size
  end

  def response_count
    @options[:response_counts]&.[](object.id) || 0
  end
end
