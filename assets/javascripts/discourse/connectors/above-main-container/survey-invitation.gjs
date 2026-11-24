import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import Invitation from "../../../components/surveys/invitation";

export default class SurveyInvitation extends Component {
  static shouldRender(_args, { currentUser, siteSettings }) {
    return currentUser && siteSettings.surveys_enabled;
  }

  @service composer;
  @service discovery;
  @service modal;
  @service router;
  @service surveyResponses;

  @tracked claim;
  @tracked pending = false;
  #checked;
  #request = 0;

  get context() {
    if (this.composer.visible || this.modal.activeModal) {
      return;
    }
    if (this.discovery.onDiscoveryRoute) {
      return this.discovery.category?.id ?? 0;
    }
    if (this.router.currentRouteName?.startsWith("topic.")) {
      const topic = this.router.currentRoute?.find(
        (r) => r.name === "topic"
      )?.attributes;
      if (topic && !topic.isPrivateMessage) {
        return topic.category_id ?? 0;
      }
    }
  }

  get contexts() {
    return this.context === undefined ? [] : [this.context];
  }

  get invitation() {
    if (this.claim?.context !== this.context) {
      return;
    }
    const invitation = this.claim?.invitation;
    if (
      invitation &&
      !this.surveyResponses.forSurvey(invitation.post_id, invitation.survey)
        .submitted
    ) {
      return invitation;
    }
  }

  @action
  async check(context) {
    if (this.#checked === context) {
      return;
    }
    this.#checked = context;
    const request = ++this.#request;
    try {
      const { invitation } = await ajax("/surveys/invitation/claim.json", {
        type: "POST",
        data: context ? { category_id: context } : {},
      });
      if (!this.isDestroying && request === this.#request) {
        this.claim = { context, invitation };
      }
    } catch {
      // Delivery is optional; never interrupt navigation with a background error.
    }
  }

  @action
  open() {
    if (this.invitation) {
      this.modal.show(Invitation, { model: this.invitation });
    }
  }

  @action
  async dismiss() {
    const claim = this.claim;
    this.pending = true;
    try {
      await ajax(
        `/surveys/invitations/${claim.invitation.survey.id}/dismiss.json`,
        { type: "POST" }
      );
      if (this.claim === claim) {
        this.claim = null;
      }
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.pending = false;
    }
  }

  <template>
    {{#each this.contexts as |context|}}
      <span hidden {{didInsert (fn this.check context)}}></span>
      {{#if this.invitation}}
        <aside
          aria-label={{i18n "discourse_surveys.invitation.title"}}
          class="survey-invitation-banner"
          ...attributes
        >
          <strong>{{this.invitation.survey.title}}</strong>
          {{i18n "discourse_surveys.invitation.description"}}
          <DButton
            class="btn-default survey-invitation-banner__start"
            @action={{this.open}}
            @disabled={{this.pending}}
            @label="discourse_surveys.invitation.start"
          />
          <DButton
            class="btn-flat survey-invitation-banner__dismiss"
            @action={{this.dismiss}}
            @disabled={{this.pending}}
            @label="discourse_surveys.invitation.dismiss"
          />
        </aside>
      {{/if}}
    {{/each}}
  </template>
}
