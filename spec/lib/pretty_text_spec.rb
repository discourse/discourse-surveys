# frozen_string_literal: true

require 'rails_helper'

describe PrettyText do

  def n(html)
    html.strip
  end

  context 'markdown it' do
    before do
      SiteSetting.surveys_enabled = true
    end

    it 'can correctly cook surveys' do
      md = <<~MD
        [survey]
        [radio]
        - one
        - two
        [/radio]

        [radio]
        - three
        - four
        [/radio]
        [/survey]
      MD

      cooked = PrettyText.cook md

      expected = <<~MD
        <div class="survey" data-survey-name="survey">
        <div class="survey-radio">
        <ul>
        <li data-survey-option-id="d8166958d0c9b9f5917456ef69a404c2">one</li>
        <li data-survey-option-id="6eaceb40c21dfe95cc8e17f801152174">two</li>
        </ul>
        </div>
        <div class="survey-radio">
        <ul>
        <li data-survey-option-id="b92738ba6c1dbbc9bffabd806f87fc96">three</li>
        <li data-survey-option-id="99a2e706846a4911473612864820a8f9">four</li>
        </ul>
        </div>
        </div>
      MD

      puts cooked
      expect(n cooked).to eq(n expected)

    end
  end
end
