import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import ModalContainer from "discourse/components/modal-container";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import { NO_VALUE_OPTION } from "discourse/ui-kit/d-native-select";
import { i18n } from "discourse-i18n";
import AdminSurveyList from "discourse/plugins/discourse-surveys/admin/components/admin-survey-list";

const first = "tbody tr:first-child .surveys-admin-table__invitation";
const second = "tbody tr:last-child .surveys-admin-table__invitation";

module("Integration | Component | AdminSurveyList", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(async function () {
    const surveys = [
      {
        id: 42,
        name: "First",
        response_count: 0,
        invitation_config: {
          enabled: false,
          group_id: null,
          category_id: null,
        },
      },
      {
        id: 43,
        name: "Second",
        invitation_config: { enabled: true, group_id: 50, category_id: 3 },
      },
    ];
    this.saves = [];
    pretender.put(
      "/admin/plugins/discourse-surveys/surveys/:id/invitation.json",
      (request) => {
        this.saves.push([request.params.id, JSON.parse(request.requestBody)]);
        return [204, {}, ""];
      }
    );
    await render(
      <template>
        <AdminSurveyList @surveys={{surveys}} /><ModalContainer />
      </template>
    );
  });

  test("enables filtered invitations on a survey without responses", async function (assert) {
    await click(first);
    const form = formKit(".d-modal form");
    await form.field("enabled").toggle();
    await form.field("group_id").select("50");
    const category = selectKit(".category-chooser");
    await category.expand();
    await category.selectRowByValue(3);
    await form.submit();
    assert.deepEqual(
      this.saves,
      [["42", { enabled: true, group_id: 50, category_id: 3 }]],
      "saves typed filters for the selected survey"
    );
    assert
      .dom(first)
      .hasText(
        i18n("discourse_surveys.admin.invitation.on"),
        "the list reflects the saved setting"
      );
  });

  test("closing the editor discards unsaved changes", async function (assert) {
    await click(first);
    await formKit(".d-modal form").field("enabled").toggle();
    await click(".d-modal .modal-close");
    await click(first);
    assert
      .dom('[name="enabled"]')
      .isNotChecked("the saved setting is unchanged");
    assert.deepEqual(this.saves, [], "closing did not issue a PUT");
  });

  test("loads existing filters and can clear both", async function (assert) {
    await click(second);
    const form = formKit(".d-modal form");
    assert.dom('[name="enabled"]').isChecked("invitations are enabled");
    assert
      .dom('select[name="group_id"]')
      .hasValue("50", "the configured group is selected");
    assert
      .dom(".category-chooser .select-kit-header")
      .hasAttribute("data-value", "3", "the configured category is selected");
    await form.field("enabled").toggle();
    await form.field("group_id").select(NO_VALUE_OPTION);
    await click(".category-chooser .btn-clear");
    await form.submit();
    assert.deepEqual(
      this.saves,
      [["43", { enabled: false, group_id: null, category_id: null }]],
      "sends explicit nulls to remove both restrictions"
    );
  });
});
