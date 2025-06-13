import SurveyDropdown from "./fields/dropdown";
import SurveyNumber from "./fields/number";
import SurveyOptions from "./fields/options";
import SurveyStar from "./fields/star";
import SurveyTextarea from "./fields/textarea";
import SurveyThumbs from "./fields/thumbs";

const FIELDS = {
  0: {
    name: "radio",
    component: SurveyOptions,
  },
  1: {
    name: "checkbox",
    component: SurveyOptions,
  },
  2: {
    name: "number",
    component: SurveyNumber,
  },
  3: {
    name: "textarea",
    component: SurveyTextarea,
  },
  4: {
    name: "star",
    component: SurveyStar,
  },
  5: {
    name: "thumbs",
    component: SurveyThumbs,
  },
  6: {
    name: "dropdown",
    component: SurveyDropdown,
  },
  unknown: {
    name: "unknown",
    component: <template>Unknown field type</template>,
  },
};

function configFor(field) {
  return FIELDS[field.response_type] || FIELDS["unknown"];
}

<template>
  <div class="survey-field" data-survey-field-id={{@field.digest}}>
    <span class="field-question">
      <span>{{@field.question}}</span>
    </span>

    {{#let (configFor @field) as |fieldConfig|}}
      <div class="field-{{fieldConfig.name}}">
        <fieldConfig.component
          @postId={{@postId}}
          @field={{@field}}
          @toggleValue={{@toggleValue}}
          @toggleOption={{@toggleOption}}
          @response={{@response}}
        />
      </div>
    {{/let}}
  </div>
</template>
