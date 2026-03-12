import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action, set } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class DiscourseSurveysExportController extends Controller {
  @tracked loading = false;

  get canLoadMore() {
    return !!this.model.load_more_surveys;
  }

  @action
  async loadMore() {
    if (this.loading || !this.model.load_more_surveys) {
      return;
    }

    this.loading = true;

    try {
      const result = await ajax(this.model.load_more_surveys);
      set(this, "model", {
        surveys: [...this.model.surveys, ...result.surveys],
        total_rows_surveys: result.total_rows_surveys,
        load_more_surveys: result.load_more_surveys,
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }
}
