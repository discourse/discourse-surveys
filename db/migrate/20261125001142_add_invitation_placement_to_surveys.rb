# frozen_string_literal: true

class AddInvitationPlacementToSurveys < ActiveRecord::Migration[8.1]
  def change
    add_column :surveys, :invitation_placement, :string, default: "banner", null: false
  end
end
