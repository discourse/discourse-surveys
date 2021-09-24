# frozen_string_literal: true
# rubocop:disable Discourse/NoAddReferenceOrAliasesActiveRecordMigration

class CreateSurveyFields < ActiveRecord::Migration[6.0]
  def change
    create_table :survey_fields do |t|
      t.references :survey, index: true, foreign_key: true
      t.integer :field_number, null: false, default: 1
      t.text :question, null: false
      t.integer :response_type, null: false, default: 0

      t.timestamps
    end

    add_index :survey_fields, [:survey_id, :field_number], unique: true
  end
end
