@IsTest
private class LimitMonitorControllerTest {

    @IsTest
    static void buildCardsKeepsOnlyMonitoredLimits() {
        List<LimitReading> readings = new List<LimitReading>{
            new LimitReading('DailyApiRequests', 10L, 100L),
            new LimitReading('LimiteNaoMonitorado', 1L, 10L)
        };

        List<LimitMonitorController.LimitCard> cards = LimitMonitorController.buildCards(readings);

        System.assertEquals(1, cards.size(), 'Só limites da lista monitorada devem virar card');
        System.assertEquals('DailyApiRequests', cards[0].name);
    }

    @IsTest
    static void statusFollowsThresholds() {
        System.assertEquals('ok', LimitMonitorController.statusFor(69.9));
        System.assertEquals('warning', LimitMonitorController.statusFor(70));
        System.assertEquals('warning', LimitMonitorController.statusFor(90));
        System.assertEquals('critical', LimitMonitorController.statusFor(90.1));
    }

    @IsTest
    static void percentIsRoundedToOneDecimal() {
        LimitMonitorController.LimitCard card = new LimitMonitorController.LimitCard('DataStorageMB', 1L, 3L);
        System.assertEquals(33.3, card.percent, 'Percentual deveria ter uma casa decimal');
        System.assertEquals('ok', card.status);
    }

    @IsTest
    static void zeroMaximumGivesZeroPercentWithoutError() {
        LimitMonitorController.LimitCard card = new LimitMonitorController.LimitCard('FileStorageMB', 5L, 0L);
        System.assertEquals(0, card.percent.intValue(), 'Máximo zero não pode causar divisão por zero');
        System.assertEquals('ok', card.status);
    }

    @IsTest
    static void buildHistoryKeepsLastSnapshotOfEachDay() {
        Date today = Date.today();
        Date yesterday = today.addDays(-1);
        List<Limit_Snapshot__c> snapshots = new List<Limit_Snapshot__c>{
            new Limit_Snapshot__c(Snapshot_Date__c = yesterday, Used__c = 50, Maximum__c = 100),
            new Limit_Snapshot__c(Snapshot_Date__c = today, Used__c = 10, Maximum__c = 100),
            new Limit_Snapshot__c(Snapshot_Date__c = today, Used__c = 80, Maximum__c = 100)
        };

        List<LimitMonitorController.HistoryPoint> points = LimitMonitorController.buildHistory(snapshots);

        System.assertEquals(2, points.size(), 'Um ponto por dia');
        System.assertEquals(yesterday, points[0].snapshotDate);
        System.assertEquals(50, points[0].percent.intValue());
        System.assertEquals(today, points[1].snapshotDate);
        System.assertEquals(80, points[1].percent.intValue(), 'Vale o último snapshot do dia');
    }

    @IsTest
    static void getHistoryRejectsUnmonitoredLimit() {
        Boolean thrown = false;
        try {
            LimitMonitorController.getHistory('LimiteNaoMonitorado', 7);
        } catch (AuraHandledException e) {
            // Em testes, getMessage() de AuraHandledException nem sempre traz o texto original.
            thrown = true;
        }
        System.assert(thrown, 'Limite fora da lista monitorada deve ser rejeitado');
    }

    @IsTest
    static void getHistoryClampsWindowAndReturnsSnapshots() {
        insert new Limit_Snapshot__c(
            Limit_Name__c = 'DailyApiRequests', Used__c = 30, Maximum__c = 100,
            Captured_At__c = DateTime.now(), Snapshot_Date__c = Date.today().addDays(-2)
        );

        List<LimitMonitorController.HistoryPoint> points =
            LimitMonitorController.getHistory('DailyApiRequests', 9999);

        System.assertEquals(1, points.size(), 'Janela máxima deve incluir o snapshot de 2 dias atrás');
        System.assertEquals(30, points[0].percent.intValue());
    }

    @IsTest
    static void getCurrentLimitsReturnsLiveCards() {
        List<LimitMonitorController.LimitCard> cards = LimitMonitorController.getCurrentLimits();
        System.assert(!cards.isEmpty(), 'A org deveria expor ao menos um limite monitorado');
        for (LimitMonitorController.LimitCard card : cards) {
            System.assert(card.percent >= 0, 'Percentual não pode ser negativo');
        }
    }
}
