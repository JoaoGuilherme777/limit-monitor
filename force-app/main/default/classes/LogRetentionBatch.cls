/**
 * Apaga logs mais antigos que LogSettings.getRetentionDays() (Logged_At__c, não CreatedDate,
 * porque CreatedDate não pode ser definido em testes e o momento do evento é o que importa).
 */
public with sharing class LogRetentionBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        Datetime cutoff = Datetime.now().addDays(-LogSettings.getRetentionDays());
        return Database.getQueryLocator([
            SELECT Id
            FROM Log__c
            WHERE Logged_At__c < :cutoff
            WITH USER_MODE
        ]);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Database.DeleteResult> results = Database.delete(scope, false, AccessLevel.USER_MODE);
        for (Database.DeleteResult result : results) {
            if (!result.isSuccess()) {
                System.debug(LoggingLevel.ERROR, '[LogRetentionBatch] Falha ao apagar log: ' + result.getErrors());
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug(LoggingLevel.INFO, '[LogRetentionBatch] Limpeza de logs concluída. Job: ' + context.getJobId());
    }
}
