import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { TrackedObject } from "@ember-compat/tracked-built-ins";
import { not } from "truth-helpers";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import SurveyField from "./field";

export default class Survey extends Component {
  @service currentUser;

  @tracked loading = false;
  @tracked submitted = false;

  response = new TrackedObject();

  get survey() {
    return this.args.post.surveys?.find((s) => s.name === this.args.surveyName);
  }

  get canSubmitResponse() {
    if (this.loading) {
      return false;
    }

    const requiredFields = [];
    this.survey.fields.map((field) => {
      if (field.response_required) {
        requiredFields.push(field.digest);
      }
    });

    const respondedFields = Object.keys(this.response);
    return requiredFields.every((i) => respondedFields.includes(i));
  }

  @action
  toggleOption(optionInfo) {
    if (!this.currentUser) {
      return this.args.showLogin();
    }

    const response = this.response;

    if (
      typeof response[optionInfo.fieldId] !== "undefined" &&
      response[optionInfo.fieldId] instanceof Array
    ) {
      if (optionInfo.isMultiple) {
        const chosenIdx = response[optionInfo.fieldId].indexOf(
          optionInfo.option.digest
        );
        if (chosenIdx !== -1) {
          const updated = [...response[optionInfo.fieldId]];
          updated.splice(chosenIdx, 1);
          response[optionInfo.fieldId] = updated;
        } else {
          response[optionInfo.fieldId] = [
            ...response[optionInfo.fieldId],
            optionInfo.option.digest,
          ];
        }
        // delete empty array
        if (response[optionInfo.fieldId].length === 0) {
          delete response[optionInfo.fieldId];
        }
      } else {
        response[optionInfo.fieldId] = [optionInfo.option.digest];
      }
    } else {
      response[optionInfo.fieldId] = [optionInfo.option.digest];
    }
  }

  @action
  toggleValue(fieldInfo) {
    if (!this.currentUser) {
      return this.args.showLogin();
    }

    const response = this.response;
    // delete empty string
    if (fieldInfo.value === "") {
      delete response[fieldInfo.fieldId];
    } else {
      response[fieldInfo.fieldId] = fieldInfo.value;
    }
  }

  @action
  submitResponse() {
    if (!this.canSubmitResponse) {
      return;
    }
    if (!this.currentUser) {
      return this.args.showLogin();
    }

    this.loading = true;

    return ajax("/surveys/submit-response", {
      type: "PUT",
      data: {
        post_id: this.args.post.id,
        survey_name: this.survey.name,
        response: this.response,
      },
    })
      .then(() => {
        this.submitted = true;
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.loading = false;
      });
  }

  <template>
    {{#if (not this.survey)}}
      Error: Survey not found
    {{else if this.submitted}}
      <span class="survey-submitted">
        {{icon "far-circle-check"}}
        <span>{{i18n "discourse_surveys.user_responded"}}</span>
      </span>
    {{else if this.survey.user_responded}}
      <span class="survey-submitted">
        {{icon "far-circle-check"}}
        <span>{{i18n "discourse_surveys.user_responded"}}</span>
      </span>
    {{else}}
      {{#if this.survey.title}}
        <div class="survey-title">
          <p>{{this.survey.title}}</p>
        </div>
      {{/if}}

      <div class="survey-fields-container">
        {{#each this.survey.fields as |field|}}
          <SurveyField
            @field={{field}}
            @response={{this.response}}
            @postId={{@post.id}}
            @toggleOption={{this.toggleOption}}
            @toggleValue={{this.toggleValue}}
          />
        {{/each}}
      </div>

      <div class="survey-buttons">
        <DButton
          class={{concatClass
            "submit-response"
            (if this.canSubmitResponse "btn-primary" "btn-default")
          }}
          @label="discourse_surveys.submit_response.label"
          @title="discourse_surveys.submit_response.title"
          disabled={{not this.canSubmitResponse}}
          @action={{this.submitResponse}}
        />
      </div>
    {{/if}}
  </template>
}
