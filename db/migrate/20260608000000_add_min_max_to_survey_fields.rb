# frozen_string_literal: true

class AddMinMaxToSurveyFields < ActiveRecord::Migration[7.2]
  def change
    add_column :survey_fields, :min, :integer, default: nil
    add_column :survey_fields, :max, :integer, default: nil
  end
end
