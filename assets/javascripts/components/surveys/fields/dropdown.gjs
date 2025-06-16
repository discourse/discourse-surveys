import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";

export default class SurveyDropdown extends Component {
  @action
  changed(event) {
    this.args.toggleValue({
      fieldId: this.args.field.digest,
      value: event.target.value,
    });
  }

  <template>
    <select class="survey-field-dropdown" {{on "change" this.changed}}>
      <option label=" "></option>
      {{#each @field.options as |optionInfo|}}
        <option value={{optionInfo.digest}}>{{htmlSafe
            optionInfo.html
          }}</option>
      {{/each}}
    </select>
  </template>
}
