import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { modifier } from "ember-modifier";
import icon from "discourse/helpers/d-icon";
import { bind } from "discourse/lib/decorators";
import { applyLocalDates } from "discourse/lib/local-dates";

export default class SurveyOptions extends Component {
  @service siteSettings;

  applyLocalDatesModifier = modifier((element) => {
    applyLocalDates(
      element.querySelectorAll(".discourse-local-date"),
      this.siteSettings
    );
  });

  @action
  toggle(option) {
    this.args.toggleOption({
      fieldId: this.args.field.digest,
      option,
      isMultiple: this.args.field.is_multiple_choice,
    });
  }

  @bind
  iconFor(option) {
    const isChosen = this.args.response[this.args.field.digest]?.includes(
      option.digest
    );

    if (this.args.field.is_multiple_choice) {
      return isChosen ? "far-square-check" : "far-square";
    } else {
      return isChosen ? "far-circle-check" : "far-circle";
    }
  }

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    {{#each @field.options as |option|}}
      <li class="survey-field-option" {{on "click" (fn this.toggle option)}}>
        {{icon (this.iconFor option)}}
        <span {{this.applyLocalDatesModifier}}>{{htmlSafe option.html}}</span>
      </li>
    {{/each}}
  </template>
}
