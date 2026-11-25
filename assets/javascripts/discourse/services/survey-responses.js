import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Service from "@ember/service";
import { ajax } from "discourse/lib/ajax";

class SurveyResponse {
  @tracked answers = {};
  @tracked loading = false;
  @tracked submitted = false;

  constructor(postId, name) {
    this.postId = postId;
    this.name = name;
  }

  answered(field) {
    return Object.hasOwn(this.answers, field.digest);
  }

  canSubmit(fields) {
    return (
      !this.loading &&
      !this.submitted &&
      fields.every((f) => !f.response_required || this.answered(f))
    );
  }

  @action
  toggleOption({ fieldId, option, isMultiple }) {
    const selected = this.answers[fieldId] || [];
    const value = !isMultiple
      ? [option.digest]
      : selected.includes(option.digest)
        ? selected.filter((id) => id !== option.digest)
        : [...selected, option.digest];
    this.toggleValue({ fieldId, value });
  }

  @action
  toggleValue({ fieldId, value }) {
    if (this.loading || this.submitted) {
      return;
    }
    const answers = { ...this.answers };
    if (
      value == null ||
      value.length === 0 ||
      (typeof value === "string" && !value.trim())
    ) {
      delete answers[fieldId];
    } else {
      answers[fieldId] = value;
    }
    this.answers = answers;
  }

  async submit(fields, viaInvitation = false) {
    if (!this.canSubmit(fields)) {
      return false;
    }
    this.loading = true;
    try {
      await ajax("/surveys/submit-response", {
        type: "PUT",
        data: {
          post_id: this.postId,
          survey_name: this.name,
          response: this.answers,
          ...(viaInvitation && { via_invitation: true }),
        },
      });
      this.submitted = true;
      this.answers = {};
      return true;
    } finally {
      this.loading = false;
    }
  }
}

export default class SurveyResponses extends Service {
  #responses = new Map();

  forSurvey(postId, survey) {
    const key = `${postId}:${survey.name}`;
    if (!this.#responses.has(key)) {
      this.#responses.set(key, new SurveyResponse(postId, survey.name));
    }
    return this.#responses.get(key);
  }
}
