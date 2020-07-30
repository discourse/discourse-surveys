# frozen_string_literal: true

require 'migration/column_dropper'

class RemoveUserIdFromSurvey < ActiveRecord::Migration[6.0]
  DROPPED_COLUMNS ||= {
    surveys: %i{user_id}
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
