import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import CategoryChooser from "discourse/select-kit/components/category-chooser";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class SurveyInvitationModal extends Component {
  @service site;

  @tracked saving = false;

  get dismissable() {
    return !this.saving;
  }

  get formData() {
    const config = this.args.model.survey.invitation_config;
    return { ...config, placement: config?.placement ?? "banner" };
  }

  @action
  async save({ enabled, group_id, category_id, placement }) {
    const config = {
      enabled: enabled ?? false,
      group_id: group_id == null ? null : Number(group_id),
      category_id: category_id ?? null,
      placement,
    };
    this.saving = true;
    try {
      await ajax(
        `/admin/plugins/discourse-surveys/surveys/${this.args.model.survey.id}/invitation.json`,
        {
          type: "PUT",
          contentType: "application/json",
          data: JSON.stringify(config),
        }
      );
      this.args.model.onSave(config);
      this.args.closeModal();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <DModal
      @closeModal={{@closeModal}}
      @dismissable={{this.dismissable}}
      @title={{i18n
        "discourse_surveys.admin.invitation.edit"
        survey=(if @model.survey.title @model.survey.title @model.survey.name)
      }}
    >
      <:body>
        <Form
          @data={{this.formData}}
          @commitOnSubmit={{false}}
          @onSubmit={{this.save}}
          as |form|
        >
          <form.Field
            @name="enabled"
            @title={{i18n "discourse_surveys.admin.invitation.enabled"}}
            @type="checkbox"
            as |field|
          >
            <field.Control />
          </form.Field>
          <form.Field
            @name="group_id"
            @title={{i18n "discourse_surveys.admin.invitation.group"}}
            @type="select"
            as |field|
          >
            <field.Control
              @nonePlaceholder={{i18n
                "discourse_surveys.admin.invitation.any_group"
              }}
              as |select|
            >
              {{#each this.site.groups as |group|}}
                <select.Option
                  @value={{group.id}}
                >{{group.name}}</select.Option>
              {{/each}}
            </field.Control>
          </form.Field>
          <form.Field
            @name="category_id"
            @description={{i18n
              "discourse_surveys.admin.invitation.category_help"
            }}
            @title={{i18n "discourse_surveys.admin.invitation.category"}}
            @type="custom"
            as |field|
          >
            <field.Control>
              <CategoryChooser
                @onChange={{field.set}}
                @options={{hash
                  allowUncategorized=true
                  clearable=true
                  permissionType=null
                  headerAriaLabel=(i18n
                    "discourse_surveys.admin.invitation.category"
                  )
                  none="discourse_surveys.admin.invitation.any_category"
                }}
                @value={{field.value}}
              />
            </field.Control>
          </form.Field>
          <form.Field
            @name="placement"
            @title={{i18n "discourse_surveys.admin.invitation.placement"}}
            @type="select"
            as |field|
          >
            <field.Control @includeNone={{false}} as |select|>
              <select.Option @value="banner">{{i18n
                  "discourse_surveys.admin.invitation.banner"
                }}</select.Option>
              <select.Option @value="bottom_right">{{i18n
                  "discourse_surveys.admin.invitation.bottom_right"
                }}</select.Option>
            </field.Control>
          </form.Field>
          <form.Submit @label="save" />
        </Form>
      </:body>
    </DModal>
  </template>
}
