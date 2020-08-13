import I18n from "I18n";
import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import { iconNode } from "discourse-common/lib/icon-library";
import RawHtml from "discourse/widgets/raw-html";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

function fieldHtml(field) {
  const $node = $(`<span>${field.question}</span>`);
  return new RawHtml({ html: `<span class="field-question">${$node.html()}</span>` });
}

createWidget("discourse-survey-field", {
  tagName: "div.survey-field",

  buildAttributes(attrs) {
    return { "data-survey-field-id": attrs.field.digest };
  },

  html(attrs) {
    const field = attrs.field;
    const hasOptions = field.has_options;
    const isMultiple = field.is_multiple_choice;

    const contents = [];
    contents.push(fieldHtml(field));

    if (hasOptions) {
      contents.push(
        h("div",
          field.options.map(option => {
            return this.attach("discourse-survey-field-option", {
              option,
              fieldId: attrs.field.digest,
              isMultiple,
              response: attrs.response[attrs.field.digest]
            })
          })
        )
      )
    } else {
      contents.push(
        h("div.field-textarea",
          this.attach("discourse-survey-field-textarea", {
            fieldId: attrs.field.digest
          })
        )
      )
    }

    return contents;
  }
});

function textareaHtml() {
  return new RawHtml({ html: `<textarea></textarea>` });
}

createWidget("discourse-survey-field-textarea", {
  tagName: "span",

  html(attrs) {
    const contents = [];
    contents.push(textareaHtml());
    return contents;
  },

  keyUp(e) {
    // remove zero-width chars
    const value = e.target.value.replace(/[\u200B-\u200D\uFEFF]/, "");
    this.sendWidgetAction("textChanged", {value: value, fieldId: this.attrs.fieldId});
  }
});

function optionHtml(option) {
  const $node = $(`<span>${option.html}</span>`);

  $node.find(".discourse-local-date").each((_index, elem) => {
    $(elem).applyLocalDates();
  });

  return new RawHtml({ html: `<span>${$node.html()}</span>` });
}

createWidget("discourse-survey-field-option", {
  tagName: "li",

  buildAttributes(attrs) {
    return { "data-survey-option-id": attrs.option.digest };
  },

  html(attrs) {
    const { option, response } = attrs;
    const contents = [];
    let chosen = false;

    if (response) {
      chosen = response.includes(option.digest);
    }

    if (attrs.isMultiple) {
      contents.push(iconNode(chosen ? "far-check-square" : "far-square"));
    } else {
      contents.push(iconNode(chosen ? "circle" : "far-circle"));
    }

    contents.push(" ");
    contents.push(optionHtml(attrs.option));

    return contents;
  },

  click(e) {
    if ($(e.target).closest("a").length === 0) {
      this.sendWidgetAction("toggleOption", this.attrs);
    }
  }
});

createWidget("discourse-survey-buttons", {
  tagName: "div.survey-buttons",

  html(attrs) {
    const contents = [];
    const { survey, post } = attrs;

    // const submitDisabled = !attrs.canSubmitResponse;
    const submitDisabled = false;

    contents.push(
      this.attach("button", {
        className: `submit-response ${
          submitDisabled ? "btn-default" : "btn-primary"
        }`,
        label: "discourse_surveys.submit-response.label",
        title: "discourse_surveys.submit-response.title",
        disabled: submitDisabled,
        action: "submitResponse"
      })
    );

    return contents;
  }
});

function submittedHtml() {
  const $node = $(`<span>${I18n.t("discourse_surveys.survey-submitted")}</span>`);
  return new RawHtml({ html: `<span class="survey-submitted">${$node.html()}</span>` });
}

export default createWidget("discourse-survey", {
  tagName: "div",
  buildKey: attrs => `survey-${attrs.id}`,

  buildAttributes(attrs) {
    let cssClasses = "survey";
    return {
      class: cssClasses,
      "data-survey-name": attrs.survey.get("name"),
      "data-survey-type": attrs.survey.get("type")
    };
  },

  defaultState(attrs) {
    const { post, survey } = attrs;
    return { loading: false, submitted: false };
  },

  html(attrs, state) {
    const contents = [];

    // todo: check if response is already submitted and do not show survey if so.
    if (state.submitted || attrs.survey.user_responded) {
      contents.push(submittedHtml());
    } else {
      contents.push(
        h("div.survey-fields-container",
          attrs.survey.fields.map(field => {
            return this.attach("discourse-survey-field", { field, response: attrs.response })
          })
        )
      );
      contents.push(this.attach("discourse-survey-buttons", attrs));
    }

    return contents;
  },

  hasVoted() {
    const { vote } = this.attrs;
    return vote && vote.length > 0;
  },

  canSubmitResponse() {
    const { state, attrs } = this;

    if (state.loading) {
      return false;
    }

    const selectedOptionCount = attrs.response.length;

    if (this.isMultiple()) {
      return (
        selectedOptionCount >= this.min() && selectedOptionCount <= this.max()
      );
    }

    return selectedOptionCount > 0;
  },

  showLogin() {
    this.register.lookup("route:application").send("showLogin");
  },

  _toggleOption(optionInfo) {
    const { response } = this.attrs;

    if (typeof response[optionInfo.fieldId] != 'undefined' && response[optionInfo.fieldId] instanceof Array ) {
      if (optionInfo.isMultiple) {
        const chosenIdx = response[optionInfo.fieldId].indexOf(optionInfo.option.digest);
        if (chosenIdx !== -1) {
          response[optionInfo.fieldId].splice(chosenIdx, 1);
        } else {
          response[optionInfo.fieldId].push(optionInfo.option.digest);
        }
      } else {
        response[optionInfo.fieldId] = [optionInfo.option.digest];
      }
    } else {
      response[optionInfo.fieldId] = [optionInfo.option.digest];
    }
  },

  toggleOption(optionInfo) {
    if (!this.currentUser) return this.showLogin();
    this._toggleOption(optionInfo);
  },

  textChanged(fieldInfo) {
    if (!this.currentUser) return this.showLogin();
    const { response } = this.attrs;
    response[fieldInfo.fieldId] = fieldInfo.value;
  },

  submitResponse() {
    // if (!this.canSubmitResponse()) return;
    if (!this.currentUser) return this.showLogin();

    const { attrs, state } = this;

    state.loading = true;

    return ajax("/surveys/submit-response", {
      type: "PUT",
      data: {
        post_id: attrs.post.id,
        survey_name: attrs.survey.get("name"),
        response: attrs.response
      }
    })
      .then(() => {
        state.submitted = true;
      })
      .catch(error => {
        if (error) {
          popupAjaxError(error);
        } else {
          bootbox.alert(I18n.t("survey.error_while_casting_votes"));
        }
      })
      .finally(() => {
        state.loading = false;
      });
  }
});
