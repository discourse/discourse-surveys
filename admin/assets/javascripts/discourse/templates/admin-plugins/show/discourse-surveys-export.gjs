import AdminSurveyList from "discourse/plugins/discourse-surveys/admin/components/admin-survey-list";

<template>
  <div class="discourse-surveys-admin admin-detail">
    <AdminSurveyList @surveys={{@controller.model.surveys}} />
  </div>
</template>
