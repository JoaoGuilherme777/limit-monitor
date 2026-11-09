@IsTest
private class LoggerInvocableTest {

    @IsTest
    static void flowRequestsArePersistedWithFlowSourceTypeAndSafeLevelFallback() {
        Account acc = new Account(Name = 'Conta Flow Teste');
        insert acc;

        LoggerInvocable.Request errorRequest = new LoggerInvocable.Request();
        errorRequest.level = 'ERROR';
        errorRequest.source = 'Flow: Cobranca';
        errorRequest.message = 'Falha ao cobrar';
        errorRequest.recordId = acc.Id;

        LoggerInvocable.Request invalidLevelRequest = new LoggerInvocable.Request();
        invalidLevelRequest.level = 'NIVEL_INEXISTENTE';
        invalidLevelRequest.source = 'Flow: Cobranca';
        invalidLevelRequest.message = 'Nível inválido vira INFO';

        Test.startTest();
        LoggerInvocable.log(new List<LoggerInvocable.Request>{ errorRequest, invalidLevelRequest });
        Test.stopTest();

        List<Log__c> logs = [
            SELECT Level__c, Source_Type__c, Related_Record_Id__c, Message__c
            FROM Log__c
            WHERE Source__c = 'Flow: Cobranca'
        ];
        System.assertEquals(2, logs.size(), 'Cada request do Flow deve gerar um log');
        for (Log__c log : logs) {
            System.assertEquals('Flow', log.Source_Type__c, 'Origem do Flow deve ser marcada como Flow');
        }

        Map<String, Log__c> byMessage = new Map<String, Log__c>();
        for (Log__c log : logs) {
            byMessage.put(log.Message__c, log);
        }
        System.assertEquals('ERROR', byMessage.get('Falha ao cobrar').Level__c);
        System.assertEquals(String.valueOf(acc.Id), byMessage.get('Falha ao cobrar').Related_Record_Id__c);
        System.assertEquals('INFO', byMessage.get('Nível inválido vira INFO').Level__c);
    }

    @IsTest
    static void emptyRequestListIsNoOp() {
        Test.startTest();
        LoggerInvocable.log(new List<LoggerInvocable.Request>());
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Log__c], 'Lista vazia não deve gerar logs');
    }
}
