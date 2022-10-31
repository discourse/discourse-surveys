import EmberObject from "@ember/object";
import { withPluginApi } from "discourse/lib/plugin-api";
import { observes } from "discourse-common/utils/decorators";
import { getRegister } from "discourse-common/lib/get-owner";
import WidgetGlue from "discourse/widgets/glue";

function initializeSurveys(api) {
  const register = getRegister(api);

  api.modifyClass("controller:topic", {
    pluginId: "discourse-surveys",
    subscribe() {
      this._super(...arguments);
      this.messageBus.subscribe("/surveys/" + this.get("model.id"), (msg) => {
        const post = this.get("model.postStream").findLoadedPost(msg.post_id);
        if (post) {
          post.set("surveys", msg.surveys);
        }
      });
    },
    unsubscribe() {
      this.messageBus.unsubscribe("/surveys/*");
      this._super(...arguments);
    },
  });

  let _glued = [];
  let _interval = null;

  function rerender() {
    _glued.forEach((g) => g.queueRerender());
  }

  api.modifyClass("model:post", {
    pluginId: "discourse-surveys",
    _surveys: null,
    surveysObject: null,

    // we need a proper ember object so it is bindable
    @observes("surveys")
    surveysChanged() {
      const surveys = this.surveys;
      if (surveys) {
        this._surveys = this._surveys || {};
        surveys.forEach((p) => {
          const existing = this._surveys[p.name];
          if (existing) {
            this._surveys[p.name].setProperties(p);
          } else {
            this._surveys[p.name] = EmberObject.create(p);
          }
        });
        this.set("surveysObject", this._surveys);
        rerender();
      }
    },
  });

  function attachSurveys($elem, helper) {
    const $surveys = $(".survey", $elem);
    if (!$surveys.length || !helper) {
      return;
    }

    let post = helper.getModel();
    api.preventCloak(post.id);
    post.surveysChanged();

    const surveys = post.surveysObject || {};

    _interval = _interval || setInterval(rerender, 30000);

    $surveys.each((idx, surveyElem) => {
      const $survey = $(surveyElem);
      const surveyName = $survey.data("survey-name");
      let survey = surveys[surveyName];

      if (survey) {
        const attrs = {
          id: `${surveyName}-${post.id}`,
          post,
          survey,
          response: {},
        };
        const glue = new WidgetGlue("discourse-survey", register, attrs);
        glue.appendTo(surveyElem);
        _glued.push(glue);
      }
    });
  }

  function cleanUpSurveys() {
    if (_interval) {
      clearInterval(_interval);
      _interval = null;
    }

    _glued.forEach((g) => g.cleanUp());
    _glued = [];
  }

  api.decorateCooked(attachSurveys, {
    onlyStream: true,
    id: "discourse-survey",
  });
  api.cleanupStream(cleanUpSurveys);
}

export default {
  name: "extend-for-survey",

  initialize() {
    withPluginApi("0.8.7", initializeSurveys);
  },
};
