import { click, fillIn, select, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import topicFixtures from "discourse/tests/fixtures/topic";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

const topicUrl = "/t/internationalization-localization/280";
const modal = ".survey-invitation";
const next = `${modal} .survey-invitation__next`;
const back = `${modal} .survey-invitation__back`;
const start = ".survey-invitation-banner__start";
const field = (selector) => `${modal} .survey-field ${selector}`;

acceptance("Member survey invitation", function (needs) {
  needs.user();
  needs.settings({ surveys_enabled: true });
  let claims, dismissals, submission, post, topic;
  needs.hooks.beforeEach(() => {
    const fields = [0, 1, 2, 3, 4, 5, 6, 3].map((type, i) => ({
      question: `Question ${i + 1}`,
      digest: `f${i}`,
      response_type: type,
      response_required: i !== 2 && i !== 7,
      is_multiple_choice: type === 1,
      options: [
        { digest: "a", html: "Choice A" },
        { digest: "b", html: "Choice B" },
      ],
    }));
    topic = cloneJSON(topicFixtures["/t/280/1.json"]);
    post = topic.post_stream.posts[0];
    post.cooked = '<div class="survey" data-survey-name="feedback"></div>';
    post.surveys = [{ id: 15, name: "feedback", title: "Feedback", fields }];
    claims = [];
    dismissals = 0;
    submission = null;
  });
  needs.pretender((server, helper) => {
    server.get("/t/280.json", () => helper.response(topic));
    server.get("/t/130.json", () =>
      helper.response({
        ...topicFixtures["/t/130.json"],
        category_id: topic.category_id,
      })
    );
    server.post("/surveys/invitation/claim.json", (request) => {
      claims.push(helper.parsePostData(request.requestBody));
      return helper.response({
        invitation: { survey: post.surveys[0], post_id: post.id },
      });
    });
    server.post("/surveys/invitations/15/dismiss.json", () => {
      dismissals++;
      return helper.response(204);
    });
    server.put("/surveys/submit-response", (request) => {
      submission = new URLSearchParams(request.requestBody);
      return helper.response({ success: "OK" });
    });
  });

  test("the invitation is optional and claims are scoped to the browsing category", async function (assert) {
    await visit(topicUrl);
    assert.dom(start).exists("the invitation is offered outside a modal");
    assert.dom(modal).doesNotExist("claiming does not open the modal");
    await click(".survey-invitation-banner__dismiss");
    assert.strictEqual(dismissals, 1, "No thanks dismisses once");
    await visit("/t/topic/130");
    assert.deepEqual(
      claims,
      [{ category_id: String(topic.category_id) }],
      "another topic in the same category does not claim again"
    );
    assert.dom(start).doesNotExist("dismissed invitation stays hidden");
  });

  test("all seven controls restore edits on back and finishing updates the inline survey", async function (assert) {
    await visit(topicUrl);
    await click(start);
    assert
      .dom(modal)
      .includesText(
        i18n("discourse_surveys.invitation.disclosure"),
        "identified export is disclosed"
      );
    assert.dom(next).isDisabled("a required answer blocks Next");
    const option = field(".survey-field-option");
    const number = field(".survey-field-number");
    const text = field("textarea");
    const star = field('.star-rating-input[value="3"]');
    const thumb = field('.thumbs-rating-input[value="+1"]');
    const dropdown = field("select");
    const steps = [
      [
        () => click(option),
        () =>
          assert
            .dom(option)
            .hasAttribute("aria-pressed", "true", "radio restored"),
      ],
      [
        () => click(option),
        () =>
          assert
            .dom(option)
            .hasAttribute("aria-pressed", "true", "checkbox restored"),
      ],
      [
        () => click(number),
        () =>
          assert
            .dom(number)
            .hasAttribute("aria-pressed", "true", "number restored"),
      ],
      [
        () => fillIn(text, "Member answer"),
        () => assert.dom(text).hasValue("Member answer", "text restored"),
      ],
      [
        () => click(field('.star-rating-label[for$="-3"]')),
        () => assert.dom(star).isChecked("star restored"),
      ],
      [
        () => click(field(".thumbs-up")),
        () => assert.dom(thumb).isChecked("thumb restored"),
      ],
      [
        () => select(dropdown, "b"),
        () => assert.dom(dropdown).hasValue("b", "dropdown restored"),
      ],
    ];
    for (const [edit, verify] of steps) {
      await edit();
      await click(next);
      await click(back);
      verify();
      if (edit === steps[2][0]) {
        await click(`${modal} .survey-invitation__skip`);
      } else {
        await click(next);
      }
    }
    await click(`${modal} .survey-invitation__finish`);
    assert.dom(modal).doesNotExist("the wizard closes on success");
    assert
      .dom("#post_1 .survey-submitted")
      .exists("the inline form updates without navigation");
    assert.dom(start).doesNotExist("no invitation remains");
    assert.strictEqual(
      submission.get("via_invitation"),
      "true",
      "uses invitation eligibility"
    );
    assert.strictEqual(
      submission.get("post_id"),
      String(post.id),
      "targets the survey post"
    );
    assert.strictEqual(
      submission.get("survey_name"),
      "feedback",
      "targets the named survey"
    );
    assert.strictEqual(
      submission.get("response[f3]"),
      "Member answer",
      "sends the edited answer"
    );
    assert.false(submission.has("response[f2]"), "skipped edit is omitted");
  });
});
