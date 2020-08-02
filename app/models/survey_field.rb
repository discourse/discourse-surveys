# frozen_string_literal: true

class SurveyField < ActiveRecord::Base
  has_many :survey_field_options, -> { order(:id) }, dependent: :destroy

  def response_type
    @response_type ||= Enum.new(:radio, :checkbox, :number, :text, :star, :thumbs, start: 0)
  end
end

# == Schema Information
#
# Table name: survey_fields
#
#  id            :bigint           not null, primary key
#  survey_id     :bigint
#  question      :text             not null
#  response_type :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  digest        :string           not null
#
# Indexes
#
#  index_survey_fields_on_survey_id             (survey_id)
#  index_survey_fields_on_survey_id_and_digest  (survey_id,digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (survey_id => surveys.id)
#
