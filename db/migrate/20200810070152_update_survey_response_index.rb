# frozen_string_literal: true

class UpdateSurveyResponseIndex < ActiveRecord::Migration[6.0]
  def change
    remove_index :survey_responses, %i[survey_field_id user_id]
    add_index :survey_responses, %i[user_id survey_field_option_id], unique: true
    add_index :survey_field_options, %i[survey_field_id digest], unique: true
  end
end
