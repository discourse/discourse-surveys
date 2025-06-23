# frozen_string_literal: true

describe PrettyText do
  context "with surveys enabled" do
    before { SiteSetting.surveys_enabled = true }

    it "correctly cooks surveys" do
      md = <<~MD
        [survey name="awesome-survey"]
        [radio question="Choose any one option:"]
        - 🐈 cat
        - 🐕 dog
        [/radio]

        [checkbox question="Choose multiple options:"]
        - red
        - blue
        - green
        [/checkbox]

        [dropdown question="Gender:"]
        - Male
        - Female
        [/dropdown]

        [number question="Rate this survey from 1 to 10:"]
        [/number]

        [textarea question="What is your feedback about xyz?"]
        [/textarea]

        [star question="How would you rate overall experience?"]
        [/star]

        [thumbs question="Were you satisfied with our services?"]
        [/thumbs]
        [/survey]
      MD

      cooked = PrettyText.cook(md)

      expected = <<~MD
        <div data-survey-wrapper="true">
        <div class="survey" data-survey-name="awesome-survey">
        <div class="survey-radio" data-survey-type="radio" data-survey-field-id="45de436cbdb15bbd9a11cb0301733189" data-survey-question="Choose any one option:">
        <ul>
        <li data-survey-option-id="0081803fadf8c67971a671882640b3be"><img src="/images/emoji/twitter/cat.png?v=14" title=":cat:" class="emoji" alt=":cat:" loading="lazy" width="20" height="20"> cat</li>
        <li data-survey-option-id="469b4f3d4617f34a816751fd918135d9"><img src="/images/emoji/twitter/dog.png?v=14" title=":dog:" class="emoji" alt=":dog:" loading="lazy" width="20" height="20"> dog</li>
        </ul>
        </div>
        <div class="survey-checkbox" data-survey-type="checkbox" data-survey-field-id="481e5197af6b16a4d1e12e12a3addc6e" data-survey-question="Choose multiple options:">
        <ul>
        <li data-survey-option-id="01c62ab8d8878ce22b4298b740e70bf7">red</li>
        <li data-survey-option-id="83254d47ebf2ee10688bf9303fcfa7f6">blue</li>
        <li data-survey-option-id="b6073234fc601007b541885dd70491f1">green</li>
        </ul>
        </div>
        <div class="survey-dropdown" data-survey-type="dropdown" data-survey-field-id="b83f40c51163cb9a12a114ac54254422" data-survey-question="Gender:">
        <ul>
        <li data-survey-option-id="747ff0ee2cb255e0b28f3b71dd7f6768">Male</li>
        <li data-survey-option-id="914b29f3a73e40df4690feecc4f76bf1">Female</li>
        </ul>
        </div>
        <div class="survey-number" data-survey-type="number" data-survey-field-id="e640c1203c008b7c9b99fac817589833" data-survey-question="Rate this survey from 1 to 10:"></div>
        <div class="survey-textarea" data-survey-type="textarea" data-survey-field-id="686b736392ac9422acbe59bd0531493e" data-survey-question="What is your feedback about xyz?"></div>
        <div class="survey-star" data-survey-type="star" data-survey-field-id="bef56ba188d28c5c17b848de4bf8cc8d" data-survey-question="How would you rate overall experience?"></div>
        <div class="survey-thumbs" data-survey-type="thumbs" data-survey-field-id="ed252319cfaf2124c23bc0e2b9c7c5fe" data-survey-question="Were you satisfied with our services?"></div>
        </div>
        </div>
      MD

      expect(cooked.strip).to eq(expected.strip)
    end
  end
end
