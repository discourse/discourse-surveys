# frozen_string_literal: true

DiscourseSurveys::Engine.routes.draw do
  put "surveys/submit-response" => "survey#submit_response"
  post "surveys/invitation/claim" => "survey#claim"
  post "surveys/invitations/:survey_id/dismiss" => "survey#dismiss"
end

Discourse::Application.routes.draw do
  namespace :admin, constraints: StaffConstraint.new do
    get "plugins/discourse-surveys/export" => "plugins#show",
        :defaults => {
          plugin_id: "discourse-surveys",
        }
  end

  scope "/admin/plugins/discourse-surveys", constraints: StaffConstraint.new do
    get "/surveys" => "discourse_surveys/admin_surveys#index"
    put "/surveys/:id/invitation" => "discourse_surveys/admin_surveys#update_invitation"
    get "/surveys/:id/export-csv" => "discourse_surveys/admin_surveys#export_csv"
  end
end
