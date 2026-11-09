/** Apaga snapshots mais antigos que a janela de retenção. */
public with sharing class LimitSnapshotRetentionBatch implements Database.Batchable<SObject> {

    public static final Integer RETENTION_DAYS = 90;

    public Database.QueryLocator start(Database.BatchableContext context) {
        Date cutoff = Date.today().addDays(-RETENTION_DAYS);
        return Database.getQueryLocator([
            SELECT Id
            FROM Limit_Snapshot__c
            WHERE Snapshot_Date__c < :cutoff
        ]);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext context) {
    }
}
