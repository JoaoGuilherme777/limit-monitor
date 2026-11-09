@IsTest
private class LimitSnapshotServiceTest {

    /** Provider fixo: torna o teste independente dos limites reais da org. */
    private class StubProvider implements ILimitProvider {
        public List<LimitReading> getReadings() {
            return new List<LimitReading>{
                new LimitReading('DailyApiRequests', 80L, 100L),
                new LimitReading('DataStorageMB', 5L, 0L)
            };
        }
    }

    @IsTest
    static void capturesOneSnapshotPerLimit() {
        Test.startTest();
        List<Limit_Snapshot__c> created = new LimitSnapshotService(new StubProvider()).captureSnapshots();
        Test.stopTest();

        System.assertEquals(2, created.size(), 'Deveria criar um snapshot por limite retornado');

        // WITH SYSTEM_MODE: o teste verifica o cálculo, não a permissão.
        // A permissão é coberta pelo permission set Limit_Monitor_User.
        Limit_Snapshot__c api = [
            SELECT Percent_Used__c, Snapshot_Date__c
            FROM Limit_Snapshot__c
            WHERE Limit_Name__c = 'DailyApiRequests'
            WITH SYSTEM_MODE
        ];
        System.assertEquals(80, api.Percent_Used__c, 'Percentual deveria ser 80 de 100');
        System.assertEquals(Date.today(), api.Snapshot_Date__c, 'Snapshot deveria ser de hoje');
    }

    @IsTest
    static void zeroMaximumGivesZeroPercent() {
        new LimitSnapshotService(new StubProvider()).captureSnapshots();

        Limit_Snapshot__c storage = [
            SELECT Percent_Used__c
            FROM Limit_Snapshot__c
            WHERE Limit_Name__c = 'DataStorageMB'
            WITH SYSTEM_MODE
        ];
        System.assertEquals(0, storage.Percent_Used__c, 'Maximo zero nao pode gerar divisao por zero');
    }

    @IsTest
    static void orgLimitsProviderReturnsReadings() {
        List<LimitReading> readings = new OrgLimitsProvider().getReadings();
        System.assert(!readings.isEmpty(), 'OrgLimits deveria retornar ao menos um limite');
    }
}
