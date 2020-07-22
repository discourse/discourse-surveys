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
  #
end
