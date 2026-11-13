# frozen_string_literal: true
class AddAnonymousSubmissionSupportToSurveyResponses < ActiveRecord::Migration[8.1]
  ANON_TOKEN_INDEX = "index_survey_responses_on_anon_token_and_option_id"

  def up
    change_column_null :survey_responses, :user_id, true
    add_column :survey_responses, :anon_token, :string, limit: 64

    # Partial so the existing (user_id, survey_field_option_id) unique index keeps covering
    # logged-in respondents, while anonymous rows dedupe on the browser-supplied token.
    add_index :survey_responses,
              %i[anon_token survey_field_option_id],
              unique: true,
              where: "anon_token IS NOT NULL",
              name: ANON_TOKEN_INDEX
  end

  def down
    remove_index :survey_responses, name: ANON_TOKEN_INDEX
    remove_column :survey_responses, :anon_token
    execute "DELETE FROM survey_responses WHERE user_id IS NULL"
    change_column_null :survey_responses, :user_id, false
  end
end
