import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { not, or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import SurveyField from "./field";

export default class Survey extends Component {
  @service currentUser;

  @service surveyResponses;

  get survey() {
    return this.args.post.surveys?.find((s) => s.name === this.args.surveyName);
  }

  get draft() {
    return this.surveyResponses.forSurvey(this.args.post.id, this.survey);
  }

  get canSubmitResponse() {
    return this.draft.canSubmit(this.survey.fields);
  }

  @action
  toggleOption(info) {
    return this.currentUser
      ? this.draft.toggleOption(info)
      : this.args.showLogin();
  }

  @action
  toggleValue(info) {
    return this.currentUser
      ? this.draft.toggleValue(info)
      : this.args.showLogin();
  }

  @action
  submitResponse() {
    if (!this.currentUser) {
      return this.args.showLogin();
    }
    return this.draft.submit(this.survey.fields).catch(popupAjaxError);
  }

  <template>
    {{#if (not this.survey)}}
      Error: Survey not found
    {{else if (or this.draft.submitted this.survey.user_responded)}}
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
            @response={{this.draft.answers}}
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
