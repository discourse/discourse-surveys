import Component from "@glimmer/component";
import { concat, fn } from "@ember/helper";
import { action, set } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { popupAjaxError } from "discourse/lib/ajax-error";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import SurveyInvitationModal from "./survey-invitation-modal";

export default class AdminSurveyList extends Component {
  @service modal;

  @action
  editInvitation(survey) {
    this.modal.show(SurveyInvitationModal, {
      model: {
        survey,
        onSave: (config) => set(survey, "invitation_config", config),
      },
    });
  }

  @action
  exportCsv(surveyId) {
    try {
      window.open(
        getURL(
          `/admin/plugins/discourse-surveys/surveys/${surveyId}/export-csv`
        ),
        "_blank"
      );
    } catch (e) {
      popupAjaxError(e);
    }
  }

  <template>
    {{#if @surveys.length}}
      <table class="d-table surveys-admin-table">
        <thead class="d-table__header">
          <tr>
            <th class="d-table__header-cell --overview">{{i18n
                "discourse_surveys.admin.survey_name"
              }}</th>
            <th class="d-table__header-cell --detail --topic">{{i18n
                "discourse_surveys.admin.topic"
              }}</th>
            <th class="d-table__header-cell --detail">{{i18n
                "discourse_surveys.admin.fields"
              }}</th>
            <th class="d-table__header-cell --detail">{{i18n
                "discourse_surveys.admin.responses"
              }}</th>
            <th class="d-table__header-cell">{{i18n
                "discourse_surveys.admin.invitation.heading"
              }}</th>
            <th class="d-table__header-cell --controls"></th>
          </tr>
        </thead>
        <tbody>
          {{#each @surveys as |survey|}}
            <tr class="d-table__row">
              <td class="d-table__cell --overview">{{if
                  survey.title
                  survey.title
                  survey.name
                }}</td>
              <td class="d-table__cell --detail --topic">
                <div class="d-table__mobile-label">{{i18n
                    "discourse_surveys.admin.topic"
                  }}</div>
                <a href={{getURL (concat "/t/" survey.topic_id)}}>
                  {{survey.topic_title}}
                </a>
              </td>
              <td class="d-table__cell --detail">
                <div class="d-table__mobile-label">{{i18n
                    "discourse_surveys.admin.fields"
                  }}</div>
                {{survey.field_count}}
              </td>
              <td class="d-table__cell --detail">
                <div class="d-table__mobile-label">{{i18n
                    "discourse_surveys.admin.responses"
                  }}</div>
                {{survey.response_count}}
              </td>
              <td class="d-table__cell">
                <div class="d-table__mobile-label">{{i18n
                    "discourse_surveys.admin.invitation.heading"
                  }}</div>
                <DButton
                  class="btn-default btn-small surveys-admin-table__invitation"
                  @action={{fn this.editInvitation survey}}
                  @icon="pencil"
                  @label={{if
                    survey.invitation_config.enabled
                    "discourse_surveys.admin.invitation.on"
                    "discourse_surveys.admin.invitation.off"
                  }}
                  @translatedAriaLabel={{i18n
                    "discourse_surveys.admin.invitation.edit"
                    survey=(if survey.title survey.title survey.name)
                  }}
                />
              </td>
              <td class="d-table__cell --controls">
                {{#if survey.response_count}}
                  <div class="d-table__cell-actions">
                    <DButton
                      @action={{fn this.exportCsv survey.id}}
                      @icon="download"
                      @label="discourse_surveys.admin.export_csv"
                      class="btn-default btn-small"
                    />
                  </div>
                {{/if}}
              </td>
            </tr>
          {{/each}}
        </tbody>
      </table>
    {{else}}
      <div class="admin-plugin-config-area__empty-list">
        {{i18n "discourse_surveys.admin.no_surveys"}}
      </div>
    {{/if}}
  </template>
}
