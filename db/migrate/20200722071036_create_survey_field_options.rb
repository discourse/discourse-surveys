# frozen_string_literal: true
# rubocop:disable Discourse/NoAddReferenceOrAliasesActiveRecordMigration

class CreateSurveyFieldOptions < ActiveRecord::Migration[6.0]
  def change
    create_table :survey_field_options do |t|
      t.references :survey_field, index: true, foreign_key: true
      t.string :digest, null: false
      t.text :html, null: false

      t.timestamps
    end
  end
end
