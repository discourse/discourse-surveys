# frozen_string_literal: true

DiscourseSurveys::Engine.routes.draw { put "surveys/submit-response" => "survey#submit_response" }
