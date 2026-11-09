@IsTest
private class LogEventHandlerTest {

    /** Testa o mapeamento direto, sem depender da entrega do evento. */
    @IsTest
    static void mapsEventFieldsAndSanitizesInvalidValues() {
        Log_Event__e event = new Log_Event__e(
            Level__c = 'NIVEL_INVALIDO',
            Source__c = 'Fatura',
            Source_Type__c = 'Flow',
            Message__c = 'Mensagem',
            User_Id__c = 'isto-nao-e-um-id',
            Logged_At__c = Datetime.now().addHours(-1)
        );

        Test.startTest();
        Log__c log = LogEventHandler.toLog(event);
        Test.stopTest();

        System.assertEquals('INFO', log.Level__c, 'Nível inválido deve cair em INFO');
        System.assertEquals('Flow', log.Source_Type__c);
        System.assertEquals(null, log.User__c, 'Id textual inválido não deve virar lookup');
        System.assertEquals(event.Logged_At__c, log.Logged_At__c, 'Logged_At__c deve preservar o momento da origem');
    }

    @IsTest
    static void userIdIsAcceptedOnlyWhenItBelongsToUser() {
        Account acc = new Account(Name = 'Conta Para Id Test');
        insert acc;

        Test.startTest();
        Id validUser = LogEventHandler.toUserId(String.valueOf(UserInfo.getUserId()));
        Id accountIdAsUser = LogEventHandler.toUserId(String.valueOf(acc.Id));
        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(), validUser, 'Id de User válido deve ser aceito');
        System.assertEquals(null, accountIdAsUser, 'Id de outro objeto (Account) deve ser rejeitado');
    }

    @IsTest
    static void handlerPersistsBatchAndReleasesDispatchGuard() {
        List<Log_Event__e> events = new List<Log_Event__e>();
        for (Integer i = 0; i < 3; i++) {
            events.add(new Log_Event__e(
                Level__c = 'WARN',
                Source__c = 'Lote',
                Source_Type__c = 'Apex',
                Message__c = 'Item ' + i,
                Logged_At__c = Datetime.now()
            ));
        }

        Test.startTest();
        LogEventHandler.handle(events);
        Logger.info('AfterHandler', 'Guarda deve estar liberada');
        System.assertEquals(1, Logger.pendingCount(), 'A guarda anti-loop deve ser liberada ao final do handler');
        Logger.flush();
        Test.stopTest();

        System.assertEquals(3, [SELECT COUNT() FROM Log__c WHERE Source__c = 'Lote'], 'O handler deve gravar o lote inteiro');
    }

    @IsTest
    static void emptyBatchIsIgnored() {
        Test.startTest();
        LogEventHandler.handle(new List<Log_Event__e>());
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Log__c], 'Lote vazio não deve gravar nada');
    }
}
