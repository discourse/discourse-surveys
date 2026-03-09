# frozen_string_literal: true

DiscourseSurveys::Engine.routes.draw { put "surveys/submit-response" => "survey#submit_response" }

Discourse::Application.routes.draw do
  namespace :admin, constraints: StaffConstraint.new do
    get "plugins/discourse-surveys/export" => "plugins#show",
        :defaults => {
          plugin_id: "discourse-surveys",
        }
  end

  scope "/admin/plugins/discourse-surveys", constraints: StaffConstraint.new do
    get "/surveys" => "discourse_surveys/admin_surveys#index"
    get "/surveys/:id/export-csv" => "discourse_surveys/admin_surveys#export_csv"
  end
end
