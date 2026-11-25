import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { extractError } from "discourse/lib/ajax-error";
import { not, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import dAutoFocus from "discourse/ui-kit/modifiers/d-auto-focus";
import { i18n } from "discourse-i18n";
import SurveyField from "./field";

export default class Invitation extends Component {
  @service a11y;
  @service surveyResponses;

  @tracked index = 0;
  @tracked error;

  get survey() {
    return this.args.model.survey;
  }

  get draft() {
    return this.surveyResponses.forSurvey(this.args.model.post_id, this.survey);
  }

  get field() {
    return this.survey.fields[this.index];
  }

  get currentStep() {
    return this.field ? [this.field] : [];
  }

  get progress() {
    return i18n("discourse_surveys.invitation.progress", {
      current: this.index + 1,
      total: this.survey.fields.length,
    });
  }

  get canAdvance() {
    return !this.field.response_required || this.draft.answered(this.field);
  }

  get canFinish() {
    return this.draft.canSubmit(this.survey.fields);
  }

  get last() {
    return this.index === this.survey.fields.length - 1;
  }

  @action
  back() {
    this.error = null;
    this.index--;
  }

  @action
  next() {
    this.index++;
  }

  @action
  skip() {
    this.draft.toggleValue({ fieldId: this.field.digest, value: null });
    this.next();
  }

  @action
  async finish() {
    this.error = null;
    try {
      if (await this.draft.submit(this.survey.fields, true)) {
        this.a11y.announce(i18n("discourse_surveys.survey_submitted"));
        this.args.closeModal();
      }
    } catch (e) {
      this.error = extractError(e);
    }
  }

  <template>
    <DModal
      class="survey-invitation"
      @title={{or
        this.survey.title
        (i18n "discourse_surveys.invitation.title")
      }}
      @closeModal={{@closeModal}}
      @dismissable={{not this.draft.loading}}
      @submitOnEnter={{false}}
      @flash={{this.error}}
      @flashType="error"
    >
      <:body>
        <p>{{i18n "discourse_surveys.invitation.disclosure"}}</p>
        {{#each this.currentStep as |field|}}
          <h2
            class="survey-invitation__progress"
            tabindex="-1"
            {{dAutoFocus}}
          >{{this.progress}}</h2>
          <SurveyField
            @field={{field}}
            @postId="invitation-{{@model.post_id}}"
            @response={{this.draft.answers}}
            @toggleOption={{this.draft.toggleOption}}
            @toggleValue={{this.draft.toggleValue}}
          />
        {{/each}}
      </:body>
      <:footer>
        {{#if this.index}}
          <DButton
            class="btn-default survey-invitation__back"
            @action={{this.back}}
            @disabled={{this.draft.loading}}
            @label="discourse_surveys.invitation.back"
          />
        {{/if}}
        {{#if this.last}}
          <DButton
            class="btn-primary survey-invitation__finish"
            @action={{this.finish}}
            @disabled={{or this.draft.loading (not this.canFinish)}}
            @label="discourse_surveys.invitation.finish"
          />
        {{else}}
          {{#unless this.field.response_required}}
            <DButton
              class="btn-default survey-invitation__skip"
              @action={{this.skip}}
              @disabled={{this.draft.loading}}
              @label="discourse_surveys.invitation.skip"
            />
          {{/unless}}
          <DButton
            class="btn-primary survey-invitation__next"
            @action={{this.next}}
            @disabled={{or this.draft.loading (not this.canAdvance)}}
            @label="discourse_surveys.invitation.next"
          />
        {{/if}}
      </:footer>
    </DModal>
  </template>
}
