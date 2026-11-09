@IsTest
private class LimitMonitorSchedulerTest {

    @IsTest
    static void scheduleAllCreatesTwoJobsWithoutDuplicating() {
        Test.startTest();
        List<Id> first = LimitMonitorScheduler.scheduleAll();
        List<Id> second = LimitMonitorScheduler.scheduleAll();
        Test.stopTest();

        System.assertEquals(2, first.size(), 'Deveria agendar 2 jobs');
        System.assertEquals(2, second.size(), 'Reagendar deveria devolver 2 jobs');

        Integer active = [
            SELECT COUNT()
            FROM CronTrigger
            WHERE CronJobDetail.Name IN :new List<String>{
                LimitMonitorScheduler.SNAPSHOT_JOB,
                LimitMonitorScheduler.RETENTION_JOB
            }
        ];
        System.assertEquals(2, active, 'Reagendar não pode duplicar jobs');
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
