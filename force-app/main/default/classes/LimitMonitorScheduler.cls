/** Agenda (ou reagenda) os jobs do Limit Monitor. Idempotente: não duplica agendamentos. */
public with sharing class LimitMonitorScheduler {

    public static final String SNAPSHOT_JOB = 'Limit Monitor - Snapshot diario';
    public static final String RETENTION_JOB = 'Limit Monitor - Retencao semanal';
    public static final String SNAPSHOT_CRON = '0 0 7 * * ?';
    public static final String RETENTION_CRON = '0 0 3 ? * SUN';

    public static List<Id> scheduleAll() {
        abortExisting(new List<String>{ SNAPSHOT_JOB, RETENTION_JOB });
        return new List<Id>{
            System.schedule(SNAPSHOT_JOB, SNAPSHOT_CRON, new LimitSnapshotJob()),
            System.schedule(RETENTION_JOB, RETENTION_CRON, new LimitSnapshotRetentionJob())
        };
    }

    private static void abortExisting(List<String> jobNames) {
        for (CronTrigger job : [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name IN :jobNames
        ]) {
            System.abortJob(job.Id);
        }
    }
}
