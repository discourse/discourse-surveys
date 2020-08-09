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
  tagName: "div",

  buildAttributes(attrs) {
    return { "data-survey-field-id": attrs.field.digest };
  },

  html(attrs) {
    const field = attrs.field;
    const contents = [];
    contents.push(fieldHtml(field));

    let isMultiple = false
    if (field.response_type == 1) {
      isMultiple = true
    }

    contents.push(
      h("div",
        field.options.map(option => {
          return this.attach("discourse-survey-field-option", {
            option,
            fieldId: attrs.field.digest,
            isMultiple
          })
        })
      )
    );

    return contents;
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
    const contents = [];

    if (attrs.isMultiple) {
      contents.push(iconNode("far-square"));
    } else {
      contents.push(iconNode("far-circle"));
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
    return { loading: false };
  },

  html(attrs, state) {
    const contents = [];

    contents.push(
      h("div",
        attrs.survey.fields.map(field => {
          return this.attach("discourse-survey-field", { field })
        })
      )
    );

    return contents;
  },

  hasVoted() {
    const { vote } = this.attrs;
    return vote && vote.length > 0;
  },

  canCastVotes() {
    const { state, attrs } = this;

    if (state.loading) {
      return false;
    }

    const selectedOptionCount = attrs.vote.length;

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
        if(response[optionInfo.fieldId].indexOf(optionInfo.option.digest) === -1) {
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

  castVotes() {
    if (!this.canCastVotes()) return;
    if (!this.currentUser) return this.showLogin();

    const { attrs, state } = this;

    state.loading = true;

    return ajax("/surveys/vote", {
      type: "PUT",
      data: {
        post_id: attrs.post.id,
        survey_name: attrs.survey.get("name"),
        options: attrs.vote
      }
    })
      .then(({ survey }) => {
        attrs.survey.setProperties(survey);
        if (attrs.survey.get("results") !== "on_close") {
          state.showResults = true;
        }
        if (attrs.survey.results === "staff_only") {
          if (this.currentUser && this.currentUser.get("staff")) {
            state.showResults = true;
          } else {
            state.showResults = false;
          }
        }
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
