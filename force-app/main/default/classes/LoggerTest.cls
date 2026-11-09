@IsTest
private class LoggerTest {

    @IsTest
    static void flushPublishesBufferedEntryAndTriggerPersistsIt() {
        Test.startTest();
        Logger.info('OpportunityService', 'Processamento iniciado');
        System.assertEquals(1, Logger.pendingCount(), 'A entrada deve ficar no buffer até o flush');
        Logger.flush();
        System.assertEquals(0, Logger.pendingCount(), 'O flush deve esvaziar o buffer');
        Test.stopTest(); // entrega os Log_Event__e e dispara LogEventTrigger

        List<Log__c> logs = [SELECT Level__c, Source__c, Source_Type__c, Message__c, User__c FROM Log__c];
        System.assertEquals(1, logs.size(), 'A trigger deve persistir exatamente um log');
        System.assertEquals('INFO', logs[0].Level__c);
        System.assertEquals('OpportunityService', logs[0].Source__c);
        System.assertEquals('Apex', logs[0].Source_Type__c);
        System.assertEquals('Processamento iniciado', logs[0].Message__c);
        System.assertEquals(UserInfo.getUserId(), logs[0].User__c, 'O usuário de origem deve ser preservado');
    }

    /**
     * Cenário de rollback: DML de negócio é revertido por savepoint, mas o log, registrado
     * depois da reversão, é persistido e ainda aponta para o Id que foi revertido.
     */
    @IsTest
    static void logRegisteredAfterBusinessRollbackSurvivesAndKeepsRecordReference() {
        Test.startTest();
        Savepoint sp = Database.setSavepoint();
        Account acc = new Account(Name = 'Conta Rollback Teste');
        insert acc;

        Database.rollback(sp);
        Logger.error('AccountFlow', 'Falha após DML de negócio revertido', acc.Id);
        Logger.flush();
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Account WHERE Name = 'Conta Rollback Teste'],
            'O DML de negócio deve ter sido revertido'
        );
        List<Log__c> logs = [SELECT Level__c, Related_Record_Id__c FROM Log__c];
        System.assertEquals(1, logs.size(), 'O log registrado após o rollback deve ser persistido');
        System.assertEquals('ERROR', logs[0].Level__c);
        System.assertEquals(String.valueOf(acc.Id), logs[0].Related_Record_Id__c, 'O log deve referenciar o Id revertido');
    }

    /**
     * Garantia que o desenho depende: evento publicado com Publish Immediately sobrevive ao rollback
     * da transação que o publicou. Se este teste falhar em uma org real, a premissa de
     * docs/logger-arquitetura.md (seção 2) está errada e a arquitetura precisa ser revista.
     */
    @IsTest
    static void logFlushedBeforeBusinessRollbackStillPersists() {
        Test.startTest();
        Savepoint sp = Database.setSavepoint();
        Account acc = new Account(Name = 'Conta Publicada Antes Rollback');
        insert acc;
        Logger.error('PublishedBeforeRollback', 'Publicado antes do rollback', acc.Id);
        Logger.flush();
        Database.rollback(sp);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Account WHERE Name = 'Conta Publicada Antes Rollback'],
            'O DML de negócio deve ter sido revertido'
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Log__c WHERE Source__c = 'PublishedBeforeRollback'],
            'Com Publish Immediately, o log publicado antes do rollback deve persistir'
        );
    }

    @IsTest
    static void dispatchGuardPreventsLogsFromBeingQueuedWhileHandlerRuns() {
        Test.startTest();
        Logger.setDispatchGuard(true);
        Logger.error('Loop', 'Não deve ser enfileirado');
        Logger.setDispatchGuard(false);
        System.assertEquals(0, Logger.pendingCount(), 'Com a guarda ativa, nenhuma entrada deve ser enfileirada');

        Logger.info('Loop', 'Depois da guarda');
        System.assertEquals(1, Logger.pendingCount(), 'Desativada a guarda, o logger volta a enfileirar');
        Logger.flush();
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Log__c WHERE Source__c = 'Loop'], 'Só a entrada fora da guarda deve persistir');
    }

    @IsTest
    static void minimumLevelDiscardsEntriesBelowThreshold() {
        LogSettings.minimumLevelOverride = LogLevel.WARN;
        try {
            Test.startTest();
            Logger.info('Threshold', 'Abaixo do mínimo');
            System.assertEquals(0, Logger.pendingCount(), 'INFO deve ser descartado quando o mínimo é WARN');

            Logger.warn('Threshold', 'No mínimo');
            System.assertEquals(1, Logger.pendingCount(), 'WARN deve ser aceito');
            Logger.flush();
            Test.stopTest();
        } finally {
            LogSettings.minimumLevelOverride = null;
        }

        List<Log__c> logs = [SELECT Level__c FROM Log__c WHERE Source__c = 'Threshold'];
        System.assertEquals(1, logs.size());
        System.assertEquals('WARN', logs[0].Level__c);
    }

    /** Mais entradas que FLUSH_CHUNK_SIZE: o buffer deve publicar em lotes e nenhuma entrada se perde. */
    @IsTest
    static void largeVolumeIsPublishedInChunksWithoutLoss() {
        Integer volume = Logger.FLUSH_CHUNK_SIZE + 50;
        Test.startTest();
        for (Integer i = 0; i < volume; i++) {
            Logger.info('Volume', 'Entrada ' + i);
        }
        Logger.flush();
        Test.stopTest();

        System.assertEquals(volume, [SELECT COUNT() FROM Log__c WHERE Source__c = 'Volume'], 'Nenhuma entrada deve se perder no lote');
    }

    @IsTest
    static void exceptionOverloadCapturesMessageAndStackTrace() {
        Test.startTest();
        try {
            throw new IllegalArgumentException('Valor inválido para teste');
        } catch (Exception e) {
            Logger.error('ExceptionSource', e, null);
        }
        Logger.flush();
        Test.stopTest();

        List<Log__c> logs = [SELECT Message__c, Stack_Trace__c, Level__c FROM Log__c WHERE Source__c = 'ExceptionSource'];
        System.assertEquals(1, logs.size());
        System.assertEquals('Valor inválido para teste', logs[0].Message__c);
        System.assertEquals('ERROR', logs[0].Level__c);
        System.assertNotEquals(null, logs[0].Stack_Trace__c, 'O stack trace deve ser capturado');
    }
}
