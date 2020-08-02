# frozen_string_literal: true

class Survey < ActiveRecord::Base
  belongs_to :post, -> { unscope(:where) }
  has_many :survey_fields, -> { order(:id) }, dependent: :destroy

  def self.visibility
    @visibility ||= Enum.new(:secret, :everyone, start: 0)
  end
end

# == Schema Information
#
# Table name: surveys
#
#  id            :bigint           not null, primary key
#  post_id       :bigint
#  survey_number :integer          default(1), not null
#  name          :string           default("survey"), not null
#  active        :boolean          default(TRUE), not null
#  visibility    :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_surveys_on_post_id                    (post_id)
#  index_surveys_on_post_id_and_name           (post_id,name) UNIQUE
#  index_surveys_on_post_id_and_survey_number  (post_id,survey_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (post_id => posts.id)
#
