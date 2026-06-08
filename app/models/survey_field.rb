# frozen_string_literal: true

class SurveyField < ActiveRecord::Base
  DEFAULT_NUMBER_MIN = 1
  DEFAULT_NUMBER_MAX = 10

  has_many :survey_field_options, -> { order(:id) }, dependent: :destroy
  has_many :survey_responses, dependent: :destroy
  belongs_to :survey

  default_scope { order("position ASC") }

  def self.response_type
    @response_type ||=
      Enum.new(:radio, :checkbox, :number, :textarea, :star, :thumbs, :dropdown, start: 0)
  end

  def has_options?
    response_type == SurveyField.response_type[:radio] ||
      response_type == SurveyField.response_type[:checkbox] ||
      response_type == SurveyField.response_type[:dropdown]
  end

  def is_multiple_choice?
    response_type == SurveyField.response_type[:checkbox]
  end

  def is_number?
    response_type == SurveyField.response_type[:number]
  end

  def number_min
    min || DEFAULT_NUMBER_MIN
  end

  def number_max
    max || DEFAULT_NUMBER_MAX
  end
end

# == Schema Information
#
# Table name: survey_fields
#
#  id                :bigint           not null, primary key
#  digest            :string           not null
#  field_class       :string(100)
#  position          :integer          default(0)
#  question          :text             not null
#  response_required :boolean          default(TRUE), not null
#  response_type     :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  survey_id         :bigint
#  min               :integer
#  max               :integer
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
