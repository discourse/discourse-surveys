class AddResponseRequiredToSurveyFields < ActiveRecord::Migration[6.0]
  def change
    add_column :survey_fields, :response_required, :boolean, null: false, default: true
  end
end
