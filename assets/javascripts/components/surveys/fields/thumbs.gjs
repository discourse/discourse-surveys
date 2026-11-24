import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import icon from "discourse/helpers/d-icon";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class SurveyThumbs extends Component {
  get value() {
    return this.args.response[this.args.field.digest];
  }

  @action
  changed(event) {
    const value = event.currentTarget.querySelector(`input:checked`)?.value;
    this.args.toggleValue({
      value,
      fieldId: this.args.field.digest,
    });
  }

  <template>
    <div class="survey-field-thumbs" {{on "input" this.changed}}>
      <input
        id="thumbs-rating-up-{{@postId}}-{{@field.digest}}"
        name="thumbs-rating-{{@postId}}-{{@field.digest}}"
        class="thumbs-rating-input"
        aria-label={{i18n "discourse_surveys.invitation.thumbs_up"}}
        checked={{eq this.value "+1"}}
        value="+1"
        type="radio"
      />
      <label
        class="thumbs-rating-label thumbs-up"
        for="thumbs-rating-up-{{@postId}}-{{@field.digest}}"
      >
        {{icon "thumbs-up" class="thumbs-icon"}}
      </label>

      <input
        id="thumbs-rating-down-{{@postId}}-{{@field.digest}}"
        name="thumbs-rating-{{@postId}}-{{@field.digest}}"
        class="thumbs-rating-input"
        aria-label={{i18n "discourse_surveys.invitation.thumbs_down"}}
        checked={{eq this.value "-1"}}
        value="-1"
        type="radio"
      />
      <label
        class="thumbs-rating-label thumbs-down"
        for="thumbs-rating-down-{{@postId}}-{{@field.digest}}"
      >
        {{icon "thumbs-down" class="thumbs-icon"}}
      </label>
    </div>
  </template>
}
