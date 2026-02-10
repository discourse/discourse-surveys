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

  describe ".submit_response" do
    fab!(:user)
    fab!(:post)

    def create_survey_from_raw(raw, target_post: post)
      surveys = DiscourseSurveys::Helper.extract(raw, target_post.topic_id, target_post.user_id)
      surveys.each { |survey| DiscourseSurveys::Helper.create!(target_post.id, survey) }
      Survey.find_by(post_id: target_post.id)
    end

    describe "required field validation" do
      it "rejects submission when a required field is omitted" do
        survey = create_survey_from_raw(<<~MD)
          [survey name="test"]
          [radio question="Required radio:"]
          - A
          - B
          [/radio]
          [textarea question="Required text:"]
          [/textarea]
          [/survey]
        MD

        radio_field = survey.survey_fields.find { |f| f.question == "Required radio:" }
        radio_option = radio_field.survey_field_options.first

        # submit only the radio field, omitting the required textarea
        response = { radio_field.digest => radio_option.digest }

        expect {
          DiscourseSurveys::Helper.submit_response(post.id, "test", response, user)
        }.to raise_error(StandardError, /Required text:/)

        expect(SurveyResponse.count).to eq(0)
      end

      it "rejects submission when a required text field has a blank value" do
        survey = create_survey_from_raw(<<~MD)
          [survey name="test"]
          [textarea question="Required text:"]
          [/textarea]
          [/survey]
        MD

        textarea_field = survey.survey_fields.first
        response = { textarea_field.digest => "" }

        expect {
          DiscourseSurveys::Helper.submit_response(post.id, "test", response, user)
        }.to raise_error(StandardError, /Required text:/)

        expect(SurveyResponse.count).to eq(0)
      end

      it "allows omitting a non-required field" do
        survey = create_survey_from_raw(<<~MD)
          [survey name="test"]
          [radio question="Required radio:"]
          - A
          - B
          [/radio]
          [textarea question="Optional text:" required="false"]
          [/textarea]
          [/survey]
        MD

        radio_field = survey.survey_fields.find { |f| f.question == "Required radio:" }
        radio_option = radio_field.survey_field_options.first

        response = { radio_field.digest => radio_option.digest }

        expect {
          DiscourseSurveys::Helper.submit_response(post.id, "test", response, user)
        }.not_to raise_error

        expect(SurveyResponse.count).to eq(1)
      end
    end

    describe "invalid option validation" do
      it "rejects submission with a bogus option digest" do
        survey = create_survey_from_raw(<<~MD)
          [survey name="test"]
          [radio question="Pick one:"]
          - A
          - B
          [/radio]
          [/survey]
        MD

        radio_field = survey.survey_fields.first
        response = { radio_field.digest => "nonexistent-digest" }

        expect {
          DiscourseSurveys::Helper.submit_response(post.id, "test", response, user)
        }.to raise_error(StandardError, /Pick one:/)

        expect(SurveyResponse.count).to eq(0)
      end
    end

    describe "valid submission" do
      it "persists responses for all fields" do
        survey = create_survey_from_raw(<<~MD)
          [survey name="test"]
          [radio question="Pick one:"]
          - A
          - B
          [/radio]
          [textarea question="Your thoughts:"]
          [/textarea]
          [/survey]
        MD

        radio_field = survey.survey_fields.find { |f| f.question == "Pick one:" }
        textarea_field = survey.survey_fields.find { |f| f.question == "Your thoughts:" }
        radio_option = radio_field.survey_field_options.first

        response = {
          radio_field.digest => radio_option.digest,
          textarea_field.digest => "Great survey!",
        }

        expect {
          DiscourseSurveys::Helper.submit_response(post.id, "test", response, user)
        }.not_to raise_error

        expect(SurveyResponse.count).to eq(2)
      end
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
