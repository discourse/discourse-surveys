# frozen_string_literal: true

class SurveyField < ActiveRecord::Base
end

# == Schema Information
#
# Table name: survey_fields
#
#  id            :bigint           not null, primary key
#  survey_id     :bigint
#  field_number  :integer          default(1), not null
#  question      :text             not null
#  response_type :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_survey_fields_on_survey_id                   (survey_id)
#  index_survey_fields_on_survey_id_and_field_number  (survey_id,field_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (survey_id => surveys.id)
#
