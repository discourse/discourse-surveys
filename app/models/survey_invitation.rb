# frozen_string_literal: true

class SurveyInvitation < ActiveRecord::Base
  belongs_to :survey
  belongs_to :user
end

# == Schema Information
#
# Table name: survey_invitations
#
#  id                   :bigint           not null, primary key
#  dismissed_at         :datetime
#  last_claimed_at      :datetime         not null
#  browsing_category_id :bigint
#  survey_id            :bigint           not null
#  user_id              :bigint           not null
#
# Indexes
#
#  index_survey_invitations_on_survey_id_and_user_id        (survey_id,user_id) UNIQUE
#  index_survey_invitations_on_user_id_and_last_claimed_at  (user_id,last_claimed_at)
#
