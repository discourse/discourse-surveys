# frozen_string_literal: true

class CreateSurveyResponses < ActiveRecord::Migration[6.0]
  def change
    create_table :survey_responses do |t|
      t.references :survey_field, index: true, foreign_key: true
      t.bigint :user_id, null: false
      t.bigint :survey_field_option_id
      t.text :value

      t.timestamps
    end

    add_index :survey_responses, [:survey_field_id, :user_id], unique: true
  end
end
