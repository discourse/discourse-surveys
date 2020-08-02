# frozen_string_literal: true

require 'migration/column_dropper'

class RemoveFieldNumberFromSurveyFields < ActiveRecord::Migration[6.0]
  DROPPED_COLUMNS ||= {
    survey_fields: %i{field_number}
  }

  def up
    DROPPED_COLUMNS.each do |table, columns|
      Migration::ColumnDropper.execute_drop(table, columns)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
