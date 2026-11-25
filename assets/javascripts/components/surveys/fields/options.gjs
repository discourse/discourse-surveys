import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
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

  @action
  handleKey(choice, event) {
    if (event.key === " " || event.key === "Enter") {
      event.preventDefault();
      this.toggle(choice);
    }
  }

  @bind
  isChosen(option) {
    return (
      this.args.response[this.args.field.digest]?.includes(option.digest) ??
      false
    );
  }

  @bind
  iconFor(option) {
    const isChosen = this.isChosen(option);
    if (this.args.field.is_multiple_choice) {
      return isChosen ? "far-square-check" : "far-square";
    } else {
      return isChosen ? "far-circle-check" : "far-circle";
    }
  }

  <template>
    <ul>
      {{#each @field.options as |option|}}
        <li
          role="button"
          tabindex="0"
          aria-pressed={{if (this.isChosen option) "true" "false"}}
          class="survey-field-option"
          {{on "click" (fn this.toggle option)}}
          {{on "keydown" (fn this.handleKey option)}}
        >
          {{icon (this.iconFor option)}}
          <span {{this.applyLocalDatesModifier}}>{{trustHTML
              option.html
            }}</span>
        </li>
      {{/each}}
    </ul>
  </template>
}
