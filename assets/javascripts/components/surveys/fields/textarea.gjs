import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";

export default class SurveyTextarea extends Component {
  get value() {
    return this.args.response[this.args.field.digest];
  }

  @action
  changed(e) {
    const value = e.target.value.replace(/[\u200B-\u200D\uFEFF]/, "");
    this.args.toggleValue({
      value,
      fieldId: this.args.field.digest,
    });
  }

  <template>
    <span>
      <textarea
        aria-labelledby={{@questionId}}
        value={{this.value}}
        {{on "input" this.changed}}
      ></textarea>
    </span>
  </template>
}
