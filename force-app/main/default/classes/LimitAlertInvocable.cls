/** Ponte entre o Flow de alerta e a regra em LimitAlertService. */
public with sharing class LimitAlertInvocable {

    public class AlertRequest {
        @InvocableVariable(label='Id do snapshot' required=true)
        public Id snapshotId;
    }

    @InvocableMethod(label='Avaliar alerta de limite' description='Gera alerta e notificação quando o uso passa do threshold.')
    public static void evaluate(List<AlertRequest> requests) {
        Set<Id> snapshotIds = new Set<Id>();
        for (AlertRequest request : requests) {
            if (request.snapshotId != null) {
                snapshotIds.add(request.snapshotId);
            }
        }
        if (snapshotIds.isEmpty()) {
            return;
        }
        List<Limit_Snapshot__c> snapshots = [
            SELECT Limit_Name__c, Used__c, Maximum__c
            FROM Limit_Snapshot__c
            WHERE Id IN :snapshotIds
            WITH SYSTEM_MODE
        ];
        LimitAlertService.evaluate(snapshots);
    }
}
