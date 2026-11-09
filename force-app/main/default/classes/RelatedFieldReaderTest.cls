@IsTest
private class RelatedFieldReaderTest {

    @IsTest
    static void readsRelatedAccountFieldThroughContact() {
        Account account = TestDataFactory.createAccount('Acme', 'Technology');
        Contact contact = TestDataFactory.createContacts(account.Id, 1)[0];

        RelatedFieldReader.Result result = RelatedFieldReader.readAll(
            contactType(), 'Account.Industry', new List<Id>{ contact.Id }
        )[0];

        Assert.isTrue(result.isSuccess);
        Assert.isTrue(result.found);
        Assert.areEqual('Technology', result.value);
    }

    @IsTest
    static void contactWithoutAccountIsNotAnError() {
        Contact contact = TestDataFactory.createContacts(null, 1)[0];

        RelatedFieldReader.Result result = RelatedFieldReader.readAll(
            contactType(), 'Account.Industry', new List<Id>{ contact.Id }
        )[0];

        Assert.isTrue(result.isSuccess, 'Relacionamento vazio não é erro de execução.');
        Assert.isFalse(result.found);
        Assert.isNull(result.value);
    }

    @IsTest
    static void missingRecordReturnsNotFoundWithoutException() {
        Account account = TestDataFactory.createAccount('Temporária', 'Retail');
        Id deletedId = account.Id;
        delete account;

        RelatedFieldReader.Result result = RelatedFieldReader.readAll(
            accountType(), 'Name', new List<Id>{ deletedId }
        )[0];

        Assert.isTrue(result.isSuccess);
        Assert.isFalse(result.found);
        Assert.isTrue(result.message.contains('não encontrado'));
    }

    @IsTest
    static void invalidFieldIsReportedWithFriendlyMessage() {
        Account account = TestDataFactory.createAccount('Acme', 'Technology');

        RelatedFieldReader.Result result = RelatedFieldReader.readAll(
            accountType(), 'Nao_Existe__c', new List<Id>{ account.Id }
        )[0];

        Assert.isFalse(result.isSuccess);
        Assert.isFalse(result.found);
        Assert.isTrue(result.message.contains('Nao_Existe__c'), 'Mensagem deve citar o campo digitado.');
    }

    @IsTest
    static void invalidRelationshipAndPolymorphicLookupAreRejected() {
        Account account = TestDataFactory.createAccount('Acme', 'Technology');

        RelatedFieldReader.Result unknownRelationship = RelatedFieldReader.readAll(
            accountType(), 'Fantasia.Name', new List<Id>{ account.Id }
        )[0];
        Assert.isFalse(unknownRelationship.isSuccess);
        Assert.isTrue(unknownRelationship.message.contains('Relacionamento'));

        // Case.OwnerId aponta para User e Group: polimórfico, não suportado. (Account.OwnerId só aponta para User.)
        Case caseRecord = new Case(Subject = 'Teste polimórfico');
        insert caseRecord;
        RelatedFieldReader.Result polymorphic = RelatedFieldReader.readAll(
            caseType(), 'Owner.Name', new List<Id>{ caseRecord.Id }
        )[0];
        Assert.isFalse(polymorphic.isSuccess);
        Assert.isTrue(polymorphic.message.contains('polimórfico'));
    }

    @IsTest
    static void rejectsPathsThatAreTooDeepOrBlank() {
        Contact contact = TestDataFactory.createContacts(null, 1)[0];

        RelatedFieldReader.Result deep = RelatedFieldReader.readAll(
            contactType(), 'Account.Owner.Manager.Manager.Manager.Name', new List<Id>{ contact.Id }
        )[0];
        Assert.isFalse(deep.isSuccess);
        Assert.isTrue(deep.message.contains('máximo'));

        RelatedFieldReader.Result blank = RelatedFieldReader.readAll(
            contactType(), '  ', new List<Id>{ contact.Id }
        )[0];
        Assert.isFalse(blank.isSuccess);
        Assert.isTrue(blank.message.contains('caminho do campo'));
    }

    @IsTest
    static void bulkReadOfTwoHundredRowsUsesOneQuery() {
        Account account = TestDataFactory.createAccount('Acme', 'Energy');
        List<Contact> contacts = TestDataFactory.createContacts(account.Id, 200);
        List<Id> ids = new List<Id>();
        for (Contact contact : contacts) {
            ids.add(contact.Id);
        }

        Integer queriesBefore = Limits.getQueries();
        List<RelatedFieldReader.Result> results = RelatedFieldReader.readAll(contactType(), 'Account.Industry', ids);
        Integer queriesUsed = Limits.getQueries() - queriesBefore;

        Assert.areEqual(1, queriesUsed, 'Um único SOQL para o lote inteiro, não um por registro.');
        Assert.areEqual(200, results.size());
        for (RelatedFieldReader.Result result : results) {
            Assert.areEqual('Energy', result.value);
        }
    }

    @IsTest
    static void nullIdsKeepTheirPositionAsErrors() {
        Account account = TestDataFactory.createAccount('Acme', 'Energy');

        List<RelatedFieldReader.Result> results = RelatedFieldReader.readAll(
            accountType(), 'Name', new List<Id>{ null, account.Id }
        );

        Assert.isFalse(results[0].isSuccess);
        Assert.isTrue(results[1].found);
        Assert.areEqual('Acme', results[1].value);
    }
    private static Schema.SObjectType contactType() {
        return Schema.getGlobalDescribe().get('Contact');
    }

    private static Schema.SObjectType caseType() {
        return Schema.getGlobalDescribe().get('Case');
    }

    private static Schema.SObjectType accountType() {
        return Schema.getGlobalDescribe().get('Account');
    }
}
