import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import icon from "discourse/helpers/d-icon";
import { bind } from "discourse/lib/decorators";

const DEFAULT_MIN = 1;
const DEFAULT_MAX = 10;

export default class SurveyNumber extends Component {
  get numbers() {
    const min = parseInt(this.args.field.min, 10);
    const max = parseInt(this.args.field.max, 10);
    const start = Number.isNaN(min) ? DEFAULT_MIN : min;
    const end = Number.isNaN(max) ? DEFAULT_MAX : max;

    const numbers = [];
    for (let value = start; value <= end; value++) {
      numbers.push(value);
    }
    return numbers;
  }

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
    {{#each this.numbers as |value|}}
      <li class="survey-field-number" {{on "click" (fn this.toggle value)}}>
        {{icon (this.iconFor value)}}
        <span>{{value}}</span>
      </li>
    {{/each}}
  </template>
}
