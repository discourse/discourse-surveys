# frozen_string_literal: true

class AddDigestToSurveyFields < ActiveRecord::Migration[6.0]
  def change
    add_column :survey_fields, :digest, :string, null: false
    add_index :survey_fields, %i[survey_id digest], unique: true
  end
end
