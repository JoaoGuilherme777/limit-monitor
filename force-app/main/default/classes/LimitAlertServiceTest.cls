@IsTest
private class LimitAlertServiceTest {

    /** Usa snapshots em memória: o Flow só roda em insert, então isso isola a regra. */
    private static Limit_Snapshot__c snapshot(String limitName, Long used, Long maximum) {
        return new Limit_Snapshot__c(
            Limit_Name__c = limitName,
            Used__c = used,
            Maximum__c = maximum,
            Captured_At__c = DateTime.now(),
            Snapshot_Date__c = Date.today()
        );
    }

    @IsTest
    static void alertsOnceWhenOverThreshold() {
        List<Limit_Snapshot__c> snapshots = new List<Limit_Snapshot__c>{
            snapshot('DailyApiRequests', 85, 100)
        };

        Test.startTest();
        Integer first = LimitAlertService.evaluate(snapshots);
        Integer second = LimitAlertService.evaluate(snapshots);
        Test.stopTest();

        System.assertEquals(1, first, 'Deveria criar um alerta acima do threshold de 80%');
        System.assertEquals(0, second, 'Não pode repetir o alerta no mesmo dia');

        // WITH SYSTEM_MODE: o teste confere a regra, não o FLS do campo novo.
        Integer stored = [
            SELECT COUNT()
            FROM Limit_Alert__c
            WHERE Alert_Key__c = :LimitAlertService.keyFor('DailyApiRequests', Date.today())
            WITH SYSTEM_MODE
        ];
        System.assertEquals(1, stored, 'Deveria existir exatamente um registro de alerta');
    }

    @IsTest
    static void belowThresholdDoesNotAlert() {
        Integer created = LimitAlertService.evaluate(new List<Limit_Snapshot__c>{
            snapshot('DailyApiRequests', 50, 100)
        });
        System.assertEquals(0, created, 'Uso abaixo do threshold não gera alerta');
    }

    @IsTest
    static void limitWithoutActiveThresholdDoesNotAlert() {
        Integer created = LimitAlertService.evaluate(new List<Limit_Snapshot__c>{
            snapshot('DataStorageMB', 99, 100)
        });
        System.assertEquals(0, created, 'Limite sem threshold configurado não gera alerta');
    }

    @IsTest
    static void invocableIgnoresSnapshotBelowThreshold() {
        Limit_Snapshot__c low = snapshot('DailyApiRequests', 10, 100);
        insert low;

        LimitAlertInvocable.AlertRequest request = new LimitAlertInvocable.AlertRequest();
        request.snapshotId = low.Id;

        Test.startTest();
        LimitAlertInvocable.evaluate(new List<LimitAlertInvocable.AlertRequest>{ request });
        Test.stopTest();

        Integer alerts = [SELECT COUNT() FROM Limit_Alert__c WHERE Limit_Name__c = 'DailyApiRequests'];
        System.assertEquals(0, alerts, 'Snapshot abaixo do threshold não deve gerar alerta');
    }
}
