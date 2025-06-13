import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import icon from "discourse/helpers/d-icon";
import { bind } from "discourse/lib/decorators";

const NUMBERS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

export default class SurveyNumber extends Component {
  @action
  toggle(value) {
    this.args.toggleValue({
      fieldId: this.args.field.digest,
      value,
    });
  }

  @bind
  iconFor(value) {
    const isChosen = this.args.response[this.args.field.digest] === value;

    return isChosen ? "far-circle-check" : "far-circle";
  }

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    {{#each NUMBERS as |value|}}
      <li class="survey-field-number" {{on "click" (fn this.toggle value)}}>
        {{icon (this.iconFor value)}}
        <span {{this.applyLocalDatesModifier}}>{{value}}</span>
      </li>
    {{/each}}
  </template>
}
