/**
 * Cria um Limit_Alert__c quando o uso de um limite passa do threshold cadastrado,
 * e envia uma notificação para o usuário.
 */
public with sharing class LimitAlertService {

    public static final String NOTIFICATION_TYPE = 'Limit_Monitor_Alert';

    private static Id notificationTypeId;

    /**
     * Um alerta por limite e por dia. Alerta repetido no mesmo dia é rejeitado
     * pela chave única Alert_Key__c, então não gera nova notificação.
     * Devolve quantos alertas foram criados.
     */
    public static Integer evaluate(List<Limit_Snapshot__c> snapshots) {
        Map<String, Decimal> thresholds = activeThresholds();
        Date today = Date.today();
        List<Limit_Alert__c> alerts = new List<Limit_Alert__c>();

        for (Limit_Snapshot__c snapshot : snapshots) {
            Decimal threshold = thresholds.get(snapshot.Limit_Name__c);
            if (threshold == null) {
                continue;
            }
            Decimal percent = LimitMonitorController.calculatePercent(
                toLong(snapshot.Used__c),
                toLong(snapshot.Maximum__c)
            );
            if (percent < threshold) {
                continue;
            }
            alerts.add(new Limit_Alert__c(
                Limit_Name__c = snapshot.Limit_Name__c,
                Alert_Date__c = today,
                Percent_Used__c = percent,
                Threshold_Percent__c = threshold,
                Alert_Key__c = keyFor(snapshot.Limit_Name__c, today)
            ));
        }
        if (alerts.isEmpty()) {
            return 0;
        }

        // Gravação feita pelo sistema (job ou Flow), não pelo usuário final.
        Database.SaveResult[] results = Database.insert(alerts, false, AccessLevel.SYSTEM_MODE);
        Integer created = 0;
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                created++;
                notify(alerts[i]);
            }
        }
        return created;
    }

    public static String keyFor(String limitName, Date alertDate) {
        return limitName + '|' + String.valueOf(alertDate);
    }

    private static Map<String, Decimal> activeThresholds() {
        Map<String, Decimal> thresholds = new Map<String, Decimal>();
        for (Limit_Threshold__mdt threshold : [
            SELECT DeveloperName, Threshold_Percent__c
            FROM Limit_Threshold__mdt
            WHERE Is_Active__c = true
        ]) {
            thresholds.put(threshold.DeveloperName, threshold.Threshold_Percent__c);
        }
        return thresholds;
    }

    private static void notify(Limit_Alert__c alert) {
        Id typeId = getNotificationTypeId();
        if (typeId == null) {
            return;
        }
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(typeId);
        notification.setTitle('Limite em alerta: ' + alert.Limit_Name__c);
        notification.setBody(
            alert.Limit_Name__c + ' chegou a ' + alert.Percent_Used__c
            + '% (threshold de ' + alert.Threshold_Percent__c + '%).'
        );
        notification.setTargetId(alert.Id);
        notification.send(new Set<String>{ UserInfo.getUserId() });
    }

    private static Id getNotificationTypeId() {
        if (notificationTypeId == null) {
            List<CustomNotificationType> types = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = :NOTIFICATION_TYPE
                LIMIT 1
            ];
            if (!types.isEmpty()) {
                notificationTypeId = types[0].Id;
            }
        }
        return notificationTypeId;
    }

    private static Long toLong(Decimal value) {
        return (value == null) ? null : value.longValue();
    }
}
