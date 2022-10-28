import I18n from "I18n";
import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import { iconHTML, iconNode } from "discourse-common/lib/icon-library";
import RawHtml from "discourse/widgets/raw-html";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { applyLocalDates } from "discourse/lib/local-dates";

createWidget("discourse-survey-title", {
  tagName: "div.survey-title",

  html(attrs) {
    return new RawHtml({ html: `<p>${attrs.title}</p>` });
  },
});

function fieldHtml(field) {
  const $node = $(`<span>${field.question}</span>`);
  return new RawHtml({
    html: `<span class="field-question">${$node.html()}</span>`,
  });
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

    if (field.response_type === 6) {
      // dropdown field
      contents.push(
        h(
          "div.field-dropdown",
          this.attach("discourse-survey-field-dropdown", {
            options: field.options,
            fieldId: attrs.field.digest,
          })
        )
      );
    } else if (hasOptions) {
      // radio & checkbox field
      contents.push(
        h(
          "div",
          field.options.map((option) => {
            return this.attach("discourse-survey-field-option", {
              option,
              fieldId: attrs.field.digest,
              isMultiple,
              response: attrs.response[attrs.field.digest],
            });
          })
        )
      );
    } else if (field.response_type === 2) {
      // number field
      const values = Array.from(Array(10), (_, i) => i + 1);

      contents.push(
        h(
          "div.field-number",
          values.map((value) => {
            return this.attach("discourse-survey-field-number", {
              fieldId: attrs.field.digest,
              value: value,
              response: attrs.response[attrs.field.digest],
            });
          })
        )
      );
    } else if (field.response_type === 3) {
      // textarea field
      contents.push(
        h(
          "div.field-textarea",
          this.attach("discourse-survey-field-textarea", {
            fieldId: attrs.field.digest,
          })
        )
      );
    } else if (field.response_type === 4) {
      // star rating field
      const values = Array.from(Array(6).keys());

      contents.push(
        h(
          "div.field-star",
          this.attach("discourse-survey-field-star", {
            fieldId: attrs.field.digest,
            postId: attrs.postId,
            values,
          })
        )
      );
    } else if (field.response_type === 5) {
      // thumbs up/down field

      contents.push(
        h(
          "div.field-thumbs",
          this.attach("discourse-survey-field-thumbs", {
            fieldId: attrs.field.digest,
            postId: attrs.postId,
          })
        )
      );
    }

    return contents;
  },
});

function listHtml(option, siteSettings) {
  const el = document.createElement("span");
  el.innerHTML = option.html;
  applyLocalDates(el.querySelectorAll(".discourse-local-date"), siteSettings);
  return new RawHtml({ html: el.outerHTML });
}

createWidget("discourse-survey-field-option", {
  tagName: "li.survey-field-option",

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
      contents.push(iconNode(chosen ? "far-check-circle" : "far-circle"));
    }

    contents.push(" ");
    contents.push(listHtml(attrs.option, this.siteSettings));

    return contents;
  },

  click(e) {
    if ($(e.target).closest("a").length === 0) {
      this.sendWidgetAction("toggleOption", this.attrs);
    }
  },
});

createWidget("discourse-survey-field-textarea", {
  tagName: "span",

  html() {
    const contents = [];
    contents.push(new RawHtml({ html: `<textarea></textarea>` }));
    return contents;
  },

  keyUp(e) {
    // remove zero-width chars
    const value = e.target.value.replace(/[\u200B-\u200D\uFEFF]/, "");
    this.sendWidgetAction("toggleValue", {
      value: value,
      fieldId: this.attrs.fieldId,
    });
  },
});

createWidget("discourse-survey-field-number", {
  tagName: "li.survey-field-number",

  html(attrs) {
    const { value, response } = attrs;
    const contents = [];
    let chosen = false;

    if (response) {
      chosen = value === response;
    }

    contents.push(iconNode(chosen ? "circle" : "far-circle"));
    contents.push(" ");
    contents.push(new RawHtml({ html: `<span>${value}</span>` }));

    return contents;
  },

  click(e) {
    if ($(e.target).closest("a").length === 0) {
      this.sendWidgetAction("toggleValue", {
        value: this.attrs.value,
        fieldId: this.attrs.fieldId,
      });
    }
  },
});

createWidget("discourse-survey-field-dropdown", {
  tagName: "select.survey-field-dropdown",

  html(attrs) {
    const contents = [];

    contents.push(new RawHtml({ html: `<option label=" "></option>` }));
    attrs.options.map((option) => {
      contents.push(
        new RawHtml({
          html: `<option value="${option.digest}">${option.html}</option>`,
        })
      );
    });

    return contents;
  },

  change(e) {
    this.sendWidgetAction("toggleValue", {
      value: e.target.value,
      fieldId: this.attrs.fieldId,
    });
  },
});

createWidget("discourse-survey-field-star", {
  tagName: "div.survey-field-star",

  html(attrs) {
    const contents = [];
    const postId = attrs.postId;

    attrs.values.forEach((value) => {
      if (value > 0) {
        contents.push(
          new RawHtml({
            html: `<label class="star-rating-label" for="star-rating-${postId}-${value}">${iconHTML(
              "star"
            )}</label>`,
          })
        );
        contents.push(
          new RawHtml({
            html: `<input id="star-rating-${postId}-${value}" name="star-rating-${postId}" class="star-rating-input" value="${value}" type="radio">`,
          })
        );
      } else {
        contents.push(
          new RawHtml({
            html: `<input id="star-rating-${postId}-0" name="star-rating-${postId}" disabled checked class="star-rating-input" value="0" type="radio">`,
          })
        );
      }
    });

    return contents;
  },

  click(e) {
    if ($(e.target).closest("a").length === 0) {
      this.sendWidgetAction("toggleValue", {
        value: $(
          `input[name*='star-rating-${this.attrs.postId}']:checked`
        ).val(),
        fieldId: this.attrs.fieldId,
      });
    }
  },
});

createWidget("discourse-survey-field-thumbs", {
  tagName: "div.survey-field-thumbs",

  html(attrs) {
    const contents = [];
    const postId = attrs.postId;

    // thumbs up
    contents.push(
      new RawHtml({
        html: `<input id="thumbs-rating-up-${postId}" name="thumbs-rating-${postId}" class="thumbs-rating-input" value="+1" type="radio">`,
      })
    );
    contents.push(
      new RawHtml({
        html: `<label class="thumbs-rating-label thumbs-up" for="thumbs-rating-up-${postId}">${iconHTML(
          "thumbs-up",
          { class: "thumbs-icon" }
        )}</label>`,
      })
    );

    // thumbs down
    contents.push(
      new RawHtml({
        html: `<input id="thumbs-rating-down-${postId}" name="thumbs-rating-${postId}" class="thumbs-rating-input" value="-1" type="radio">`,
      })
    );
    contents.push(
      new RawHtml({
        html: `<label class="thumbs-rating-label thumbs-down" for="thumbs-rating-down-${postId}">${iconHTML(
          "thumbs-down",
          { class: "thumbs-icon" }
        )}</label>`,
      })
    );

    return contents;
  },

  click(e) {
    if ($(e.target).closest("a").length === 0) {
      this.sendWidgetAction("toggleValue", {
        value: $(
          `input[name*='thumbs-rating-${this.attrs.postId}']:checked`
        ).val(),
        fieldId: this.attrs.fieldId,
      });
    }
  },
});

createWidget("discourse-survey-buttons", {
  tagName: "div.survey-buttons",

  html(attrs) {
    const contents = [];

    const submitDisabled = !attrs.canSubmitResponse;

    contents.push(
      this.attach("button", {
        className: `submit-response ${
          submitDisabled ? "btn-default" : "btn-primary"
        }`,
        label: "discourse_surveys.submit_response.label",
        title: "discourse_surveys.submit_response.title",
        disabled: submitDisabled,
        action: "submitResponse",
      })
    );

    return contents;
  },
});

export default createWidget("discourse-survey", {
  tagName: "div",
  buildKey: (attrs) => `survey-${attrs.id}`,

  buildAttributes(attrs) {
    let cssClasses = "survey";
    return {
      class: cssClasses,
      "data-survey-name": attrs.survey.get("name"),
    };
  },

  defaultState() {
    return { loading: false, submitted: false };
  },

  html(attrs, state) {
    const contents = [];
    const submittedIcon = iconHTML("far-check-circle");

    // todo: check if response is already submitted and do not show survey if so.
    if (state.submitted) {
      const $node = $(
        `<span>${I18n.t("discourse_surveys.survey_submitted")}</span>`
      );

      contents.push(
        new RawHtml({
          html: `<span class="survey-submitted">${submittedIcon}${$node.html()}</span>`,
        })
      );
    } else if (attrs.survey.user_responded) {
      const $node = $(
        `<span>${I18n.t("discourse_surveys.user_responded")}</span>`
      );

      contents.push(
        new RawHtml({
          html: `<span class="survey-submitted">${submittedIcon}${$node.html()}</span>`,
        })
      );
    } else {
      if (attrs.survey.title) {
        contents.push(
          this.attach("discourse-survey-title", {
            title: attrs.survey.title,
          })
        );
      }
      contents.push(
        h(
          "div.survey-fields-container",
          attrs.survey.fields.map((field) => {
            return this.attach("discourse-survey-field", {
              field,
              response: attrs.response,
              postId: attrs.post.id,
            });
          })
        )
      );
      contents.push(
        this.attach("discourse-survey-buttons", {
          canSubmitResponse: this.canSubmitResponse(),
        })
      );
    }

    return contents;
  },

  canSubmitResponse() {
    const { state, attrs } = this;

    if (state.loading) {
      return false;
    }

    const requiredFields = [];
    attrs.survey.fields.map((field) => {
      if (field.response_required) {
        requiredFields.push(field.digest);
      }
    });

    const respondedFields = Object.keys(attrs.response);
    return requiredFields.every((i) => respondedFields.includes(i));
  },

  showLogin() {
    this.register.lookup("route:application").send("showLogin");
  },

  _toggleOption(optionInfo) {
    const { response } = this.attrs;

    if (
      typeof response[optionInfo.fieldId] !== "undefined" &&
      response[optionInfo.fieldId] instanceof Array
    ) {
      if (optionInfo.isMultiple) {
        const chosenIdx = response[optionInfo.fieldId].indexOf(
          optionInfo.option.digest
        );
        if (chosenIdx !== -1) {
          response[optionInfo.fieldId].splice(chosenIdx, 1);
        } else {
          response[optionInfo.fieldId].push(optionInfo.option.digest);
        }
        // delete empty array
        if (response[optionInfo.fieldId].length === 0) {
          delete response[optionInfo.fieldId];
        }
      } else {
        response[optionInfo.fieldId] = [optionInfo.option.digest];
      }
    } else {
      response[optionInfo.fieldId] = [optionInfo.option.digest];
    }
  },

  toggleOption(optionInfo) {
    if (!this.currentUser) {
      return this.showLogin();
    }
    this._toggleOption(optionInfo);
  },

  toggleValue(fieldInfo) {
    if (!this.currentUser) {
      return this.showLogin();
    }
    const { response } = this.attrs;
    // delete empty string
    if (fieldInfo.value === "") {
      delete response[fieldInfo.fieldId];
    } else {
      response[fieldInfo.fieldId] = fieldInfo.value;
    }
  },

  submitResponse() {
    if (!this.canSubmitResponse()) {
      return;
    }
    if (!this.currentUser) {
      return this.showLogin();
    }

    const { attrs, state } = this;

    state.loading = true;

    return ajax("/surveys/submit-response", {
      type: "PUT",
      data: {
        post_id: attrs.post.id,
        survey_name: attrs.survey.get("name"),
        response: attrs.response,
      },
    })
      .then(() => {
        state.submitted = true;
      })
      .catch(popupAjaxError)
      .finally(() => {
        state.loading = false;
      });
  },
});
