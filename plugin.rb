# frozen_string_literal: true

# name: discourse-surveys
# about: Discourse plugin to create surveys.
# version: 0.1
# authors: Arpit Jalan
# url: https://github.com/discourse-org/discourse-surveys

enabled_site_setting :surveys_enabled

PLUGIN_NAME ||= 'discourse-surveys'.freeze

load File.expand_path('lib/discourse-surveys/engine.rb', __dir__)

after_initialize do
  %w{
    ../app/models/survey.rb
    ../app/models/survey_field.rb
    ../app/models/survey_field_option.rb
    ../app/models/survey_response.rb
  }.each do |path|
    load File.expand_path(path, __FILE__)
  end
end
