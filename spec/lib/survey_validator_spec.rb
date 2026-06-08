# frozen_string_literal: true

describe DiscourseSurveys::SurveyValidator do
  before { SiteSetting.surveys_enabled = true }

  fab!(:user)
  fab!(:topic)
  fab!(:post) { Fabricate(:post, topic: topic, user: user) }

  def validate(raw)
    post.raw = raw
    described_class.new(post).validate_surveys
  end

  describe "number field range validation" do
    it "accepts a sensible explicit range" do
      result = validate(<<~MD)
        [survey name="test"]
        [number question="Pick a number:" min="1" max="10"]
        [/number]
        [/survey]
      MD

      expect(result).to be_truthy
      expect(post.errors[:base]).to be_empty
    end

    it "accepts a number field with no min/max (defaults to 1-10)" do
      result = validate(<<~MD)
        [survey name="test"]
        [number question="Pick a number:"]
        [/number]
        [/survey]
      MD

      expect(result).to be_truthy
    end

    it "rejects an extreme range that would render millions of elements" do
      result = validate(<<~MD)
        [survey name="test"]
        [number question="Pick a number:" min="1" max="2147483647"]
        [/number]
        [/survey]
      MD

      expect(result).to eq(false)
      expect(post.errors[:base]).to include(I18n.t("survey.number_field_invalid_range", count: 100))
    end

    it "rejects an extreme range driven only by max (min defaults to 1)" do
      result = validate(<<~MD)
        [survey name="test"]
        [number question="Pick a number:" max="1000000"]
        [/number]
        [/survey]
      MD

      expect(result).to eq(false)
    end

    it "rejects min greater than max" do
      result = validate(<<~MD)
        [survey name="test"]
        [number question="Pick a number:" min="20" max="5"]
        [/number]
        [/survey]
      MD

      expect(result).to eq(false)
    end

    it "rejects non-integer min/max values" do
      result = validate(<<~MD)
        [survey name="test"]
        [number question="Pick a number:" min="1" max="abc"]
        [/number]
        [/survey]
      MD

      expect(result).to eq(false)
    end

    it "ignores min/max on non-number fields" do
      result = validate(<<~MD)
        [survey name="test"]
        [textarea question="Your thoughts:" min="1" max="2147483647"]
        [/textarea]
        [/survey]
      MD

      expect(result).to be_truthy
    end
  end
end
