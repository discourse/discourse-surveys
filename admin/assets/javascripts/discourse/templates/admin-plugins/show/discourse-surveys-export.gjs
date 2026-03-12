import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import LoadMore from "discourse/components/load-more";
import AdminSurveyList from "discourse/plugins/discourse-surveys/admin/components/admin-survey-list";

<template>
  <div class="discourse-surveys-admin admin-detail">
    <LoadMore
      @action={{@controller.loadMore}}
      @enabled={{@controller.canLoadMore}}
      @isLoading={{@controller.loading}}
    >
      <AdminSurveyList @surveys={{@controller.model.surveys}} />
    </LoadMore>
    <ConditionalLoadingSpinner @condition={{@controller.loading}} />
  </div>
</template>
