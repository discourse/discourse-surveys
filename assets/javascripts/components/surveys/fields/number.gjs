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

  @action
  handleKey(choice, event) {
    if (event.key === " " || event.key === "Enter") {
      event.preventDefault();
      this.toggle(choice);
    }
  }

  @bind
  isChosen(value) {
    return this.args.response[this.args.field.digest] === value;
  }

  @bind
  iconFor(value) {
    const isChosen = this.isChosen(value);
    return isChosen ? "far-circle-check" : "far-circle";
  }

  <template>
    <ul>
      {{#each this.numbers as |value|}}
        <li
          role="button"
          tabindex="0"
          aria-pressed={{if (this.isChosen value) "true" "false"}}
          class="survey-field-number"
          {{on "click" (fn this.toggle value)}}
          {{on "keydown" (fn this.handleKey value)}}
        >
          {{icon (this.iconFor value)}}
          <span>{{value}}</span>
        </li>
      {{/each}}
    </ul>
  </template>
}
