# frozen_string_literal: true

DiscourseSurveys::Engine.routes.draw do
  put "surveys/submit-response" => "survey#submit_response"
end
