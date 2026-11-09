@IsTest
private class LogRetentionBatchTest {

    @IsTest
    static void batchDeletesOnlyLogsOlderThanRetentionWindow() {
        LogSettings.retentionDaysOverride = 30;
        try {
            List<Log__c> logs = new List<Log__c>{
                new Log__c(Level__c = 'INFO', Source__c = 'Antigo', Source_Type__c = 'Apex', Message__c = 'a', Logged_At__c = Datetime.now().addDays(-40)),
                new Log__c(Level__c = 'INFO', Source__c = 'Antigo', Source_Type__c = 'Apex', Message__c = 'b', Logged_At__c = Datetime.now().addDays(-31)),
                new Log__c(Level__c = 'ERROR', Source__c = 'Recente', Source_Type__c = 'Apex', Message__c = 'c', Logged_At__c = Datetime.now().addDays(-5)),
                new Log__c(Level__c = 'WARN', Source__c = 'Recente', Source_Type__c = 'Apex', Message__c = 'd', Logged_At__c = Datetime.now())
            };
            insert logs;

            Test.startTest();
            Database.executeBatch(new LogRetentionBatch());
            Test.stopTest();

            System.assertEquals(0, [SELECT COUNT() FROM Log__c WHERE Source__c = 'Antigo'], 'Logs além da janela devem ser apagados');
            System.assertEquals(2, [SELECT COUNT() FROM Log__c WHERE Source__c = 'Recente'], 'Logs dentro da janela devem ser preservados');
        } finally {
            LogSettings.retentionDaysOverride = null;
        }
    }

    @IsTest
    static void retentionFallsBackToDefaultWhenNotConfigured() {
        Test.startTest();
        Integer days = LogSettings.getRetentionDays();
        Test.stopTest();

        System.assert(days >= 1, 'Prazo nunca pode ser zero ou negativo');
    }

    @IsTest
    static void schedulerRegistersDailyJob() {
        Test.startTest();
        Id jobId = LogRetentionScheduler.schedule(null);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'O agendamento deve retornar o Id do job');
        List<CronTrigger> jobs = [
            SELECT CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, jobs.size());
        System.assertEquals(LogRetentionScheduler.DEFAULT_CRON, jobs[0].CronExpression);
    }
}
