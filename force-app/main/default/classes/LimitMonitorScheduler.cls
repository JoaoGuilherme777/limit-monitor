/**
 * Agenda o snapshot diário dos limites.
 * Se for chamado de novo, o agendamento anterior é cancelado antes.
 */
public with sharing class LimitMonitorScheduler {

    public static final String SNAPSHOT_JOB = 'Limit Monitor - Snapshot diario';
    public static final String SNAPSHOT_CRON = '0 0 7 * * ?';

    public static Id scheduleSnapshot() {
        abortExisting();
        return System.schedule(SNAPSHOT_JOB, SNAPSHOT_CRON, new LimitSnapshotJob());
    }

    private static void abortExisting() {
        for (CronTrigger job : [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = :SNAPSHOT_JOB
        ]) {
            System.abortJob(job.Id);
        }
    }
}
