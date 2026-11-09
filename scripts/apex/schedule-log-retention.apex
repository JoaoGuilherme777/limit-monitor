// Agenda a limpeza diária de logs (02:00). Executar como administrador do Logger.
// Para trocar o horário, passe outra expressão cron. Ex.: '0 30 3 * * ?' às 03:30.
// Uso: sf apex run --target-org <alias> --file scripts/apex/schedule-log-retention.apex

Id jobId = LogRetentionScheduler.schedule(null);
System.debug('Limpeza de logs agendada. CronTrigger Id: ' + jobId);
