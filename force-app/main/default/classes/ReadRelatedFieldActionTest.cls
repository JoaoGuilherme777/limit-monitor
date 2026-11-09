@IsTest
private class ReadRelatedFieldActionTest {

    @IsTest
    static void bulkReadOfTwoHundredContactsUsesOneQuery() {
        Account account = TestDataFactory.createAccount('Acme', 'Finance');
        List<Contact> contacts = TestDataFactory.createContacts(account.Id, 200);

        List<ReadRelatedFieldAction.Request> requests = new List<ReadRelatedFieldAction.Request>();
        for (Contact contact : contacts) {
            ReadRelatedFieldAction.Request request = new ReadRelatedFieldAction.Request();
            request.recordId = contact.Id;
            request.fieldPath = 'Account.Industry';
            requests.add(request);
        }

        Integer queriesBefore = Limits.getQueries();
        List<ReadRelatedFieldAction.Response> responses = ReadRelatedFieldAction.read(requests);
        Integer queriesUsed = Limits.getQueries() - queriesBefore;

        Assert.areEqual(1, queriesUsed, 'Lote de 200 linhas do mesmo tipo e caminho deve gerar 1 SOQL.');
        Assert.areEqual(200, responses.size());
        for (ReadRelatedFieldAction.Response response : responses) {
            Assert.isTrue(response.isSuccess);
            Assert.isTrue(response.found);
            Assert.areEqual('Finance', response.value);
        }
    }

    @IsTest
    static void responsesKeepRequestOrderAcrossDifferentPaths() {
        Account account = TestDataFactory.createAccount('Globex', 'Retail');
        Contact contact = TestDataFactory.createContacts(account.Id, 1)[0];

        ReadRelatedFieldAction.Request industry = new ReadRelatedFieldAction.Request();
        industry.recordId = contact.Id;
        industry.fieldPath = 'Account.Industry';

        ReadRelatedFieldAction.Request accountName = new ReadRelatedFieldAction.Request();
        accountName.recordId = contact.Id;
        accountName.fieldPath = 'Account.Name';

        List<ReadRelatedFieldAction.Response> responses = ReadRelatedFieldAction.read(
            new List<ReadRelatedFieldAction.Request>{ accountName, null, industry }
        );

        Assert.areEqual('Globex', responses[0].value);
        Assert.isFalse(responses[1].isSuccess);
        Assert.areEqual('Retail', responses[2].value);
    }

    @IsTest
    static void invalidPathAndBlankPathAreErrorsNotExceptions() {
        Account account = TestDataFactory.createAccount('Initech', 'Software');

        ReadRelatedFieldAction.Request invalid = new ReadRelatedFieldAction.Request();
        invalid.recordId = account.Id;
        invalid.fieldPath = 'Campo_Inexistente__c';

        ReadRelatedFieldAction.Request blank = new ReadRelatedFieldAction.Request();
        blank.recordId = account.Id;
        blank.fieldPath = '';

        List<ReadRelatedFieldAction.Response> responses = ReadRelatedFieldAction.read(
            new List<ReadRelatedFieldAction.Request>{ invalid, blank }
        );

        Assert.isFalse(responses[0].isSuccess);
        Assert.isFalse(responses[1].isSuccess);
        Assert.isFalse(responses[0].found);
    }

    @IsTest
    static void mixedObjectTypesInOneBatchAreReadCorrectly() {
        Account account = TestDataFactory.createAccount('Umbrella', 'Health');
        Contact contact = TestDataFactory.createContacts(account.Id, 1)[0];

        ReadRelatedFieldAction.Request fromContact = new ReadRelatedFieldAction.Request();
        fromContact.recordId = contact.Id;
        fromContact.fieldPath = 'LastName';

        ReadRelatedFieldAction.Request fromAccount = new ReadRelatedFieldAction.Request();
        fromAccount.recordId = account.Id;
        fromAccount.fieldPath = 'Name';

        List<ReadRelatedFieldAction.Response> responses = ReadRelatedFieldAction.read(
            new List<ReadRelatedFieldAction.Request>{ fromContact, fromAccount }
        );

        Assert.areEqual('Contato 0', responses[0].value);
        Assert.areEqual('Umbrella', responses[1].value);
    }

    @IsTest
    static void nullListReturnsEmptyList() {
        Assert.isTrue(ReadRelatedFieldAction.read(null).isEmpty());
    }
}
