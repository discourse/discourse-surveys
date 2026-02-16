# frozen_string_literal: true

class AddFieldClassToSurveyFields < ActiveRecord::Migration[7.0]
  def change
    add_column :survey_fields, :field_class, :string, default: nil
  end
end
