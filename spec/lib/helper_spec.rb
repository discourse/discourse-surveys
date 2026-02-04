# frozen_string_literal: true

describe DiscourseSurveys::Helper do
  before { SiteSetting.surveys_enabled = true }

  describe ".cook_question" do
    it "returns empty string for blank input" do
      expect(DiscourseSurveys::Helper.cook_question("")).to eq("")
      expect(DiscourseSurveys::Helper.cook_question(nil)).to eq("")
    end

    it "processes markdown formatting" do
      result = DiscourseSurveys::Helper.cook_question("Which **language** do you prefer?")
      expect(result).to include("<strong>")
    end

    it "unwraps single paragraph content" do
      result = DiscourseSurveys::Helper.cook_question("Simple question")
      expect(result).not_to match(%r{\A<p>.*</p>\z})
    end

    it "removes unsafe HTML" do
      result = DiscourseSurveys::Helper.cook_question('Test <script>alert("xss")</script>')
      expect(result).not_to include("<script>")
    end
  end

  describe ".extract_attribute_value" do
    it "cooks question attributes" do
      result = DiscourseSurveys::Helper.extract_attribute_value("question", "**bold**")
      expect(result).to include("<strong>")
    end

    it "escapes non-question attributes" do
      result = DiscourseSurveys::Helper.extract_attribute_value("name", "<test>")
      expect(result).to eq("&lt;test&gt;")
    end
  end

  describe ".extract" do
    it "extracts survey fields with cooked questions" do
      raw = <<~MD
        [survey name="test"]
        [radio question="Which **option**?"]
        - A
        - B
        [/radio]
        [/survey]
      MD

      surveys = DiscourseSurveys::Helper.extract(raw, nil, nil)
      field = surveys.first["fields"].first

      expect(field["question"]).to include("<strong>")
    end

    it "only extracts valid field types" do
      raw = <<~MD
        [survey name="test"]
        [radio question="Valid"]
        - A
        [/radio]
        [/survey]
      MD

      surveys = DiscourseSurveys::Helper.extract(raw, nil, nil)
      types = surveys.first["fields"].map { |f| f["type"] }

      expect(types).to all(be_in(DiscourseSurveys::Helper::VALID_FIELD_TYPES))
    end

    it "extracts options for radio/checkbox/dropdown fields" do
      raw = <<~MD
        [survey name="test"]
        [radio question="Q1"]
        - A
        - B
        [/radio]
        [textarea question="Q2"]
        [/textarea]
        [/survey]
      MD

      surveys = DiscourseSurveys::Helper.extract(raw, nil, nil)
      fields = surveys.first["fields"].to_a

      radio = fields.find { |f| f["type"] == "radio" }
      textarea = fields.find { |f| f["type"] == "textarea" }

      expect(radio["options"]).to be_an(Array)
      expect(textarea["options"]).to be_nil
    end
  end
end
