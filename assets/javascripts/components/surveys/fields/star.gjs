import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { gt } from "truth-helpers";
import icon from "discourse/helpers/d-icon";

const RATINGS = [0, 1, 2, 3, 4, 5];

export default class SurveyStar extends Component {
  @action
  changed(event) {
    const value = event.currentTarget.querySelector(`input:checked`)?.value;
    this.args.toggleValue({
      value,
      fieldId: this.args.field.digest,
    });
  }

  <template>
    <div class="survey-field-star" {{on "input" this.changed}}>
      {{#each RATINGS as |value|}}
        {{#if (gt value 0)}}
          <label
            class="star-rating-label"
            for="star-rating-{{@postId}}-{{value}}"
          >
            {{icon "star"}}
          </label>
          <input
            id="star-rating-{{@postId}}-{{value}}"
            name="star-rating-{{@postId}}"
            class="star-rating-input"
            value={{value}}
            type="radio"
          />
        {{else}}
          <input
            id="star-rating-{{@postId}}-0"
            name="star-rating-{{@postId}}"
            disabled
            checked
            class="star-rating-input"
            value="0"
            type="radio"
          />
        {{/if}}
      {{/each}}
    </div>
  </template>
}
