for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Limit Monitor%']) {
    System.abortJob(ct.Id);
}
System.debug('JOBS_ABORTADOS');