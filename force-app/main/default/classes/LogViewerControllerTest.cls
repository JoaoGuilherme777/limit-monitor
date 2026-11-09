@IsTest
private class LogViewerControllerTest {

    @TestSetup
    static void makeData() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 3; i++) {
            logs.add(newLog('ERROR', 'Faturamento', 'Erro ' + i, Datetime.now().addMinutes(-i)));
        }
        for (Integer i = 0; i < 2; i++) {
            logs.add(newLog('INFO', 'Cadastro', 'Info ' + i, Datetime.now().addDays(-10)));
        }
        insert logs;
    }

    private static Log__c newLog(String level, String source, String message, Datetime loggedAt) {
        return new Log__c(
            Level__c = level,
            Source__c = source,
            Source_Type__c = 'Apex',
            Message__c = message,
            Logged_At__c = loggedAt
        );
    }

    /**
     * Cria um usuário Standard User. Com withViewerAccess = true, recebe a permission set Logger Viewer,
     * igual a um usuário de produção. A consulta usa USER_MODE, então o teste precisa rodar como esse usuário.
     */
    private static User createUser(Boolean withViewerAccess) {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            ProfileId = standardProfile.Id,
            LastName = 'Logger Teste',
            Email = 'logger.teste@example.com',
            Username = 'logger.teste.' + Datetime.now().getTime() + '@example.com',
            Alias = 'lgtest',
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR'
        );
        insert u;

        if (withViewerAccess) {
            PermissionSet viewer = [SELECT Id FROM PermissionSet WHERE Name = 'Logger_Viewer' LIMIT 1];
            insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = viewer.Id);
        }
        return u;
    }

    @IsTest
    static void filterByLevelReturnsOnlyMatchingRowsAndPaginatesOnServer() {
        User viewer = createUser(true);
        LogViewerController.LogFilter filter = new LogViewerController.LogFilter();
        filter.level = 'ERROR';

        LogViewerController.LogPage firstPage;
        LogViewerController.LogPage secondPage;
        System.runAs(viewer) {
            Test.startTest();
            firstPage = LogViewerController.search(filter, 2, 1);
            secondPage = LogViewerController.search(filter, 2, 2);
            Test.stopTest();
        }

        System.assertEquals(3, firstPage.totalCount, 'Total deve refletir todos os ERROR, não só a página');
        System.assertEquals(2, firstPage.rows.size());
        System.assertEquals(1, secondPage.rows.size(), 'Segunda página deve trazer o restante');
        for (LogViewerController.LogRow row : firstPage.rows) {
            System.assertEquals('ERROR', row.level);
        }
    }

    @IsTest
    static void sourceAndStartDateFiltersAreCombined() {
        User viewer = createUser(true);
        LogViewerController.LogFilter filter = new LogViewerController.LogFilter();
        filter.source = 'Cadastro';
        filter.startDate = Date.today().addDays(-5);

        LogViewerController.LogPage page;
        System.runAs(viewer) {
            Test.startTest();
            page = LogViewerController.search(filter, 20, 1);
            Test.stopTest();
        }

        System.assertEquals(0, page.totalCount, 'Logs de Cadastro têm 10 dias e estão fora da janela de 5 dias');
    }

    @IsTest
    static void endDateFilterIncludesOldLogsOnly() {
        User viewer = createUser(true);
        LogViewerController.LogFilter filter = new LogViewerController.LogFilter();
        filter.endDate = Date.today().addDays(-5);

        LogViewerController.LogPage page;
        System.runAs(viewer) {
            Test.startTest();
            page = LogViewerController.search(filter, 20, 1);
            Test.stopTest();
        }

        System.assertEquals(2, page.totalCount, 'Somente os logs antigos (Cadastro) devem aparecer');
        for (LogViewerController.LogRow row : page.rows) {
            System.assertEquals('Cadastro', row.source);
        }
    }

    @IsTest
    static void sourceFilterTreatsWildcardCharactersAsLiterals() {
        User viewer = createUser(true);
        LogViewerController.LogFilter filter = new LogViewerController.LogFilter();
        filter.source = '%';

        LogViewerController.LogPage page;
        System.runAs(viewer) {
            Test.startTest();
            page = LogViewerController.search(filter, 20, 1);
            Test.stopTest();
        }

        System.assertEquals(0, page.totalCount, 'O caractere % digitado não pode funcionar como coringa');
    }

    @IsTest
    static void invalidLevelIsRejected() {
        User viewer = createUser(true);
        LogViewerController.LogFilter filter = new LogViewerController.LogFilter();
        filter.level = 'XPTO';

        Boolean rejected = false;
        System.runAs(viewer) {
            Test.startTest();
            try {
                LogViewerController.search(filter, 20, 1);
            } catch (AuraHandledException e) {
                rejected = true;
            }
            Test.stopTest();
        }

        System.assert(rejected, 'Nível fora do enum deve ser recusado');
    }

    @IsTest
    static void pagesBeyondOffsetLimitRequirePeriodFilter() {
        User viewer = createUser(true);

        Boolean rejected = false;
        System.runAs(viewer) {
            Test.startTest();
            try {
                LogViewerController.search(null, 100, 50);
            } catch (AuraHandledException e) {
                rejected = true;
            }
            Test.stopTest();
        }

        System.assert(rejected, 'Offset acima de 2000 deve ser recusado');
    }

    /** Segurança: usuário sem a permission set Logger Viewer não consegue consultar (USER_MODE). */
    @IsTest
    static void userWithoutLoggerViewerCannotSearch() {
        User restricted = createUser(false);

        Boolean rejected = false;
        System.runAs(restricted) {
            Test.startTest();
            try {
                LogViewerController.search(null, 20, 1);
            } catch (AuraHandledException e) {
                rejected = true;
            }
            Test.stopTest();
        }

        System.assert(rejected, 'Sem permission set Logger Viewer, a consulta deve ser negada (USER_MODE)');
    }
}
