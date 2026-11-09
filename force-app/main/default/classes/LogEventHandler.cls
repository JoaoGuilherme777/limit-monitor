/**
 * Persiste Log_Event__e em Log__c. Executado pelo LogEventTrigger, em transação própria.
 *
 * Decisões:
 *  - Nunca lança exceção: se lançar, a plataforma reenfileira o evento (até 9 vezes) e pode perder o lote.
 *    Falhas por registro são reportadas via System.debug e não derrubam o lote inteiro.
 *  - Gravação em SYSTEM_MODE: é persistência interna de uma entrada já autorizada na origem.
 *    A leitura pelo usuário é que passa por USER_MODE (ver LogViewerController).
 *  - Usa Database.insert e não o Logger: a guarda anti-loop impede que este handler gere novos eventos.
 */
public with sharing class LogEventHandler {

    public static void handle(List<Log_Event__e> events) {
        if (events == null || events.isEmpty()) {
            return;
        }

        Logger.setDispatchGuard(true);
        try {
            List<Log__c> logs = new List<Log__c>();
            for (Log_Event__e event : events) {
                logs.add(toLog(event));
            }

            List<Database.SaveResult> results = Database.insert(logs, false, AccessLevel.SYSTEM_MODE);
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    System.debug(LoggingLevel.ERROR, '[LogEventHandler] Falha ao gravar log: ' + result.getErrors());
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '[LogEventHandler] Erro inesperado: ' + e.getMessage());
        } finally {
            Logger.setDispatchGuard(false);
        }
    }

    @TestVisible
    private static Log__c toLog(Log_Event__e event) {
        return new Log__c(
            Level__c = LogSettings.parseLevel(event.Level__c, LogLevel.INFO).name(),
            Source__c = event.Source__c,
            Source_Type__c = 'Flow'.equalsIgnoreCase(event.Source_Type__c) ? 'Flow' : 'Apex',
            Message__c = event.Message__c,
            Stack_Trace__c = event.Stack_Trace__c,
            Related_Record_Id__c = event.Related_Record_Id__c,
            User__c = toUserId(event.User_Id__c),
            Transaction_Id__c = event.Transaction_Id__c,
            Logged_At__c = event.Logged_At__c != null ? event.Logged_At__c : Datetime.now()
        );
    }

    /** Converte o Id textual apenas se for de um User válido; caso contrário, retorna null. */
    @TestVisible
    private static Id toUserId(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        try {
            Id candidate = Id.valueOf(value);
            return candidate.getSObjectType() == User.SObjectType ? candidate : null;
        } catch (Exception e) {
            return null;
        }
    }
}
