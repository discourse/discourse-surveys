# frozen_string_literal: true

class SurveyResponse < ActiveRecord::Base
end

# == Schema Information
#
# Table name: survey_responses
#
#  id                     :bigint           not null, primary key
#  survey_field_id        :bigint
#  user_id                :bigint           not null
#  survey_field_option_id :bigint
#  value                  :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_survey_responses_on_survey_field_id              (survey_field_id)
#  index_survey_responses_on_survey_field_id_and_user_id  (survey_field_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (survey_field_id => survey_fields.id)
#
