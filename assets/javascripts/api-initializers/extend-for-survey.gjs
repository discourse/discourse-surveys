import routeAction from "discourse/helpers/route-action";
import { apiInitializer } from "discourse/lib/api";
import Survey from "../components/surveys/survey";

const SurveyShim = <template>
  <Survey
    @surveyName={{@data.surveyName}}
    @post={{@data.post}}
    @showLogin={{routeAction "showLogin"}}
  />
</template>;

export default apiInitializer((api) => {
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

  api.decorateCookedElement((element, helper) => {
    const post = helper.getModel();

    if (!post) {
      return;
    }

    element.querySelectorAll(".survey").forEach((surveyElement) => {
      const surveyName = surveyElement.dataset.surveyName;
      surveyElement.innerHTML = "";
      helper.renderGlimmer(surveyElement, SurveyShim, { surveyName, post });
    });
  });
});
