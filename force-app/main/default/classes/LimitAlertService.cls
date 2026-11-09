/**
 * Regra de alerta: registra um Limit_Alert__c por limite e por dia quando o uso
 * passa do threshold configurado, e envia uma Custom Notification ao usuário.
 * A chave Alert_Key__c (única) impede alertas repetidos no mesmo dia.
 */
public with sharing class LimitAlertService {

    public static final String NOTIFICATION_TYPE = 'Limit_Monitor_Alert';

    private static Id notificationTypeId;

    /** Devolve quantos alertas novos foram criados. */
    public static Integer evaluate(List<Limit_Snapshot__c> snapshots) {
        Map<String, Decimal> thresholds = activeThresholds();
        Date today = Date.today();

        Map<String, Limit_Alert__c> candidates = new Map<String, Limit_Alert__c>();
        for (Limit_Snapshot__c snapshot : snapshots) {
            Decimal limitThreshold = thresholds.get(snapshot.Limit_Name__c);
            if (limitThreshold == null) {
                continue;
            }
            Decimal percent = LimitMonitorController.calculatePercent(
                longOf(snapshot.Used__c), longOf(snapshot.Maximum__c)
            );
            if (percent < limitThreshold) {
                continue;
            }
            String key = keyFor(snapshot.Limit_Name__c, today);
            Limit_Alert__c candidate = candidates.get(key);
            if (candidate == null || percent > candidate.Percent_Used__c) {
                candidates.put(key, new Limit_Alert__c(
                    Limit_Name__c = snapshot.Limit_Name__c,
                    Alert_Date__c = today,
                    Percent_Used__c = percent,
                    Threshold_Percent__c = limitThreshold,
                    Alert_Key__c = key
                ));
            }
        }
        if (candidates.isEmpty()) {
            return 0;
        }

        Set<String> alreadyAlerted = existingKeys(candidates.keySet());
        List<Limit_Alert__c> toCreate = new List<Limit_Alert__c>();
        for (String key : candidates.keySet()) {
            if (!alreadyAlerted.contains(key)) {
                toCreate.add(candidates.get(key));
            }
        }
        if (toCreate.isEmpty()) {
            return 0;
        }

        // Job/Flow interno: grava em modo de sistema (mesma decisão da Fase 3).
        Database.SaveResult[] results = Database.insert(toCreate, false, AccessLevel.SYSTEM_MODE);
        List<Limit_Alert__c> created = new List<Limit_Alert__c>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                created.add(toCreate[i]);
            }
        }
        notify(created);
        return created.size();
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

    private static Set<String> existingKeys(Set<String> keys) {
        Set<String> found = new Set<String>();
        for (Limit_Alert__c alert : [
            SELECT Alert_Key__c
            FROM Limit_Alert__c
            WHERE Alert_Key__c IN :keys
            WITH SYSTEM_MODE
        ]) {
            found.add(alert.Alert_Key__c);
        }
        return found;
    }

    private static void notify(List<Limit_Alert__c> alerts) {
        Id typeId = notificationTypeId();
        if (typeId == null || alerts.isEmpty()) {
            return;
        }
        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };
        for (Limit_Alert__c alert : alerts) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setNotificationTypeId(typeId);
            notification.setTitle('Limite em alerta: ' + alert.Limit_Name__c);
            notification.setBody(
                alert.Limit_Name__c + ' chegou a ' + alert.Percent_Used__c
                + '% (threshold de ' + alert.Threshold_Percent__c + '%).'
            );
            notification.setTargetId(alert.Id);
            notification.send(recipients);
        }
    }

    private static Id notificationTypeId() {
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

    private static Long longOf(Decimal value) {
        return (value == null) ? null : value.longValue();
    }
}
