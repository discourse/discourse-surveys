class AddPositionToSurveyFields < ActiveRecord::Migration[6.0]
  def change
    add_column :survey_fields, :position, :integer, default: 0
  end
end
