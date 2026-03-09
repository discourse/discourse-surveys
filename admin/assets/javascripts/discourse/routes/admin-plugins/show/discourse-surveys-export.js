import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class DiscourseSurveysExport extends DiscourseRoute {
  model() {
    return ajax("/admin/plugins/discourse-surveys/surveys");
  }
}
