# frozen_string_literal: true

class SurveyFieldOption < ActiveRecord::Base
  belongs_to :survey_field
end

# == Schema Information
#
# Table name: survey_field_options
#
#  id              :bigint           not null, primary key
#  survey_field_id :bigint
#  digest          :string           not null
#  html            :text             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_survey_field_options_on_survey_field_id             (survey_field_id)
#  index_survey_field_options_on_survey_field_id_and_digest  (survey_field_id,digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (survey_field_id => survey_fields.id)
#
