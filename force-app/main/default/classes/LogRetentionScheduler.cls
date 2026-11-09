/** Agenda a limpeza diária de logs. Ex.: LogRetentionScheduler.schedule(null) agenda às 02:00. */
public with sharing class LogRetentionScheduler implements Schedulable {

    public static final String JOB_NAME = 'Logger - Retenção diária';
    public static final String DEFAULT_CRON = '0 0 2 * * ?';
    public static final Integer BATCH_SIZE = 2000;

    public void execute(SchedulableContext context) {
        Database.executeBatch(new LogRetentionBatch(), BATCH_SIZE);
    }

    public static Id schedule(String cronExpression) {
        String expression = String.isBlank(cronExpression) ? DEFAULT_CRON : cronExpression;
        return System.schedule(JOB_NAME, expression, new LogRetentionScheduler());
    }
}
