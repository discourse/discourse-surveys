class AddTitleToSurvey < ActiveRecord::Migration[6.0]
  def change
    add_column :surveys, :title, :text
  end
end
