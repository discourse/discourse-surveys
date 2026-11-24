import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { trustHTML } from "@ember/template";
import { eq } from "discourse/truth-helpers";

export default class SurveyDropdown extends Component {
  get value() {
    return this.args.response[this.args.field.digest];
  }

  @action
  changed(event) {
    this.args.toggleValue({
      fieldId: this.args.field.digest,
      value: event.target.value,
    });
  }

  <template>
    <select
      aria-labelledby={{@questionId}}
      class="survey-field-dropdown"
      {{on "change" this.changed}}
    >
      <option label=" " value=""></option>
      {{#each @field.options as |optionInfo|}}
        <option
          selected={{eq this.value optionInfo.digest}}
          value={{optionInfo.digest}}
        >{{trustHTML optionInfo.html}}</option>
      {{/each}}
    </select>
  </template>
}
