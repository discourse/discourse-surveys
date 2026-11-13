# frozen_string_literal: true

class SurveyResponse < ActiveRecord::Base
  belongs_to :survey_field
  belongs_to :survey_field_option

  validate :respondent_present

  private

  def respondent_present
    if user_id.blank? && anon_token.blank?
      errors.add(:base, I18n.t("survey.response_requires_respondent"))
    end
  end
end

# == Schema Information
#
# Table name: survey_responses
#
#  id                     :bigint           not null, primary key
#  anon_token             :string(64)
#  value                  :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  survey_field_id        :bigint
#  survey_field_option_id :bigint
#  user_id                :bigint
#
# Indexes
#
#  index_survey_responses_on_anon_token_and_option_id            (anon_token,survey_field_option_id) UNIQUE WHERE (anon_token IS NOT NULL)
#  index_survey_responses_on_survey_field_id                     (survey_field_id)
#  index_survey_responses_on_user_id_and_survey_field_option_id  (user_id,survey_field_option_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (survey_field_id => survey_fields.id)
#
