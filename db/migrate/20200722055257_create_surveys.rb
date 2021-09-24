# frozen_string_literal: true
# rubocop:disable Discourse/NoAddReferenceOrAliasesActiveRecordMigration

class CreateSurveys < ActiveRecord::Migration[6.0]
  def change
    create_table :surveys do |t|
      t.references :post, index: true, foreign_key: true
      t.integer :survey_number, null: false, default: 1
      t.string :name, null: false, default: "survey"
      t.bigint :user_id, null: false
      t.boolean :active, null: false, default: true
      t.integer :visibility, null: false, default: 0

      t.timestamps
    end

    add_index :surveys, [:post_id, :name], unique: true
    add_index :surveys, [:post_id, :survey_number], unique: true
  end
end
