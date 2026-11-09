@IsTest
private class LimitSnapshotRetentionBatchTest {

    @IsTest
    static void deletesOnlySnapshotsOutsideRetentionWindow() {
        Integer retention = LimitSnapshotRetentionBatch.RETENTION_DAYS;
        DateTime now = DateTime.now();

        insert new List<Limit_Snapshot__c>{
            new Limit_Snapshot__c(
                Limit_Name__c = 'OldLimit', Used__c = 1, Maximum__c = 10,
                Captured_At__c = now, Snapshot_Date__c = Date.today().addDays(-(retention + 10))
            ),
            new Limit_Snapshot__c(
                Limit_Name__c = 'RecentLimit', Used__c = 1, Maximum__c = 10,
                Captured_At__c = now, Snapshot_Date__c = Date.today()
            )
        };

        Test.startTest();
        Database.executeBatch(new LimitSnapshotRetentionBatch());
        Test.stopTest();

        List<Limit_Snapshot__c> remaining = [
            SELECT Limit_Name__c
            FROM Limit_Snapshot__c
            WHERE Limit_Name__c IN ('OldLimit', 'RecentLimit')
            WITH SYSTEM_MODE
        ];
        System.assertEquals(1, remaining.size(), 'Só o snapshot recente deveria sobrar');
        System.assertEquals('RecentLimit', remaining[0].Limit_Name__c);
    }
}
