# frozen_string_literal: true

class AddSurveyInvitations < ActiveRecord::Migration[8.1]
  def change
    add_column :surveys, :invitation_enabled, :boolean, default: false, null: false
    add_column :surveys, :invitation_group_id, :bigint
    add_column :surveys, :invitation_category_id, :bigint

    create_table :survey_invitations do |t|
      t.bigint :survey_id, null: false
      t.bigint :user_id, null: false
      t.bigint :browsing_category_id
      t.datetime :last_claimed_at, null: false
      t.datetime :dismissed_at
      t.index %i[survey_id user_id], unique: true
      t.index %i[user_id last_claimed_at]
    end
  end
end
