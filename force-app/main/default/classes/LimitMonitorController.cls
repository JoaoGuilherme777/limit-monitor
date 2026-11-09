/** Dados para os cards e para o gráfico de histórico do LWC. */
public with sharing class LimitMonitorController {

    public static final Decimal WARNING_PERCENT = 70;
    public static final Decimal CRITICAL_PERCENT = 90;
    public static final Integer DEFAULT_HISTORY_DAYS = 30;
    public static final Integer MAX_HISTORY_DAYS = 90;

    public static final Set<String> MONITORED_LIMITS = new Set<String>{
        'DailyApiRequests',
        'DataStorageMB',
        'FileStorageMB',
        'DailyAsyncApexExecutions',
        'DailyBulkV2QueryJobs',
        'SingleEmail'
    };

    @AuraEnabled
    public static List<LimitCard> getCurrentLimits() {
        return buildCards(new OrgLimitsProvider().getReadings());
    }

    @AuraEnabled(cacheable=true)
    public static List<HistoryPoint> getHistory(String limitName, Integer days) {
        if (!MONITORED_LIMITS.contains(limitName)) {
            throw new AuraHandledException('Limite não monitorado: ' + limitName);
        }
        Integer window = Math.min(Math.max(days == null ? DEFAULT_HISTORY_DAYS : days, 1), MAX_HISTORY_DAYS);
        Date fromDate = Date.today().addDays(-window);

        List<Limit_Snapshot__c> snapshots = [
            SELECT Snapshot_Date__c, Used__c, Maximum__c, Captured_At__c
            FROM Limit_Snapshot__c
            WHERE Limit_Name__c = :limitName
              AND Snapshot_Date__c >= :fromDate
            WITH USER_MODE
            ORDER BY Snapshot_Date__c ASC, Captured_At__c ASC
        ];
        return buildHistory(snapshots);
    }

    public static List<LimitCard> buildCards(List<LimitReading> readings) {
        List<LimitCard> cards = new List<LimitCard>();
        for (LimitReading reading : readings) {
            if (MONITORED_LIMITS.contains(reading.name)) {
                cards.add(new LimitCard(reading.name, reading.used, reading.maximum));
            }
        }
        return cards;
    }

    /** Um ponto por dia. Com mais de um snapshot no dia, vale o último (lista ordenada por Captured_At). */
    public static List<HistoryPoint> buildHistory(List<Limit_Snapshot__c> snapshots) {
        Map<Date, HistoryPoint> byDay = new Map<Date, HistoryPoint>();
        for (Limit_Snapshot__c snapshot : snapshots) {
            Long used = (snapshot.Used__c == null) ? null : snapshot.Used__c.longValue();
            Long maximum = (snapshot.Maximum__c == null) ? null : snapshot.Maximum__c.longValue();
            byDay.put(
                snapshot.Snapshot_Date__c,
                new HistoryPoint(snapshot.Snapshot_Date__c, calculatePercent(used, maximum))
            );
        }

        List<Date> days = new List<Date>(byDay.keySet());
        days.sort();
        List<HistoryPoint> points = new List<HistoryPoint>();
        for (Date day : days) {
            points.add(byDay.get(day));
        }
        return points;
    }

    public static Decimal calculatePercent(Long used, Long maximum) {
        if (used == null || maximum == null || maximum == 0) {
            return 0;
        }
        Decimal ratio = Decimal.valueOf(used) * 100 / Decimal.valueOf(maximum);
        return ratio.setScale(1, System.RoundingMode.HALF_UP);
    }

    public static String statusFor(Decimal percent) {
        if (percent > CRITICAL_PERCENT) {
            return 'critical';
        }
        if (percent >= WARNING_PERCENT) {
            return 'warning';
        }
        return 'ok';
    }

    public class LimitCard {
        @AuraEnabled public String name;
        @AuraEnabled public Long used;
        @AuraEnabled public Long maximum;
        @AuraEnabled public Decimal percent;
        @AuraEnabled public String status;

        public LimitCard(String name, Long used, Long maximum) {
            this.name = name;
            this.used = used;
            this.maximum = maximum;
            this.percent = calculatePercent(used, maximum);
            this.status = statusFor(this.percent);
        }
    }

    public class HistoryPoint {
        @AuraEnabled public Date snapshotDate;
        @AuraEnabled public Decimal percent;

        public HistoryPoint(Date snapshotDate, Decimal percent) {
            this.snapshotDate = snapshotDate;
            this.percent = percent;
        }
    }
}
