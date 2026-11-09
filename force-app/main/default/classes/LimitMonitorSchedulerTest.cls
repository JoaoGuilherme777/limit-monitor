@IsTest
private class LimitMonitorSchedulerTest {

    @IsTest
    static void scheduleSnapshotKeepsOnlyOneJob() {
        LimitMonitorScheduler.scheduleSnapshot();
        LimitMonitorScheduler.scheduleSnapshot();

        Integer active = [
            SELECT COUNT()
            FROM CronTrigger
            WHERE CronJobDetail.Name = :LimitMonitorScheduler.SNAPSHOT_JOB
        ];
        System.assertEquals(1, active, 'Agendar de novo não pode duplicar o job');
    }

    @IsTest
    static void snapshotJobCapturesSnapshots() {
        Test.startTest();
        new LimitSnapshotJob().execute(null);
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Limit_Snapshot__c WITH SYSTEM_MODE];
        System.assert(count > 0, 'O job deveria gravar snapshots');
    }
}
