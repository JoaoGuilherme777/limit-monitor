@IsTest
private class BusinessDaysActionTest {

    @IsTest
    static void bulkUsesHolidaysOnlyOnceForTwoHundredRows() {
        StubHolidayProvider provider = new StubHolidayProvider();
        provider.holidays.add(Date.newInstance(2026, 7, 8));
        BusinessDaysAction.holidayProvider = provider;

        List<BusinessDaysAction.Request> requests = new List<BusinessDaysAction.Request>();
        for (Integer i = 0; i < 200; i++) {
            BusinessDaysAction.Request request = new BusinessDaysAction.Request();
            request.startDate = Date.newInstance(2026, 7, 6);
            request.endDate = Date.newInstance(2026, 7, 10);
            requests.add(request);
        }

        List<BusinessDaysAction.Response> responses = BusinessDaysAction.calculate(requests);

        Assert.areEqual(1, provider.callCount, 'Feriados devem ser lidos uma vez para o lote inteiro.');
        Assert.areEqual(200, responses.size());
        for (BusinessDaysAction.Response response : responses) {
            Assert.isTrue(response.isSuccess);
            Assert.areEqual(3, response.businessDays, 'Seg-sex com quarta feriada = 3 dias úteis.');
        }
    }

    @IsTest
    static void mixedRangesInOneBatchEachGetTheirOwnCount() {
        BusinessDaysAction.holidayProvider = new StubHolidayProvider();

        BusinessDaysAction.Request weekRange = new BusinessDaysAction.Request();
        weekRange.startDate = Date.newInstance(2026, 7, 6);
        weekRange.endDate = Date.newInstance(2026, 7, 10);

        BusinessDaysAction.Request reversed = new BusinessDaysAction.Request();
        reversed.startDate = Date.newInstance(2026, 7, 13);
        reversed.endDate = Date.newInstance(2026, 7, 10);

        List<BusinessDaysAction.Response> responses = BusinessDaysAction.calculate(
            new List<BusinessDaysAction.Request>{ weekRange, reversed }
        );

        Assert.areEqual(4, responses[0].businessDays);
        Assert.areEqual(-1, responses[1].businessDays, 'Sexta a segunda reversa: -1 (segunda conta).');
    }

    @IsTest
    static void incompleteAndNullRowsReturnErrorsWithoutBreakingBatch() {
        BusinessDaysAction.holidayProvider = new StubHolidayProvider();

        BusinessDaysAction.Request missingEnd = new BusinessDaysAction.Request();
        missingEnd.startDate = Date.newInstance(2026, 7, 6);

        BusinessDaysAction.Request valid = new BusinessDaysAction.Request();
        valid.startDate = Date.newInstance(2026, 7, 6);
        valid.endDate = Date.newInstance(2026, 7, 7);

        List<BusinessDaysAction.Response> responses = BusinessDaysAction.calculate(
            new List<BusinessDaysAction.Request>{ missingEnd, null, valid }
        );

        Assert.isFalse(responses[0].isSuccess);
        Assert.isFalse(responses[1].isSuccess);
        Assert.isTrue(responses[2].isSuccess);
        Assert.areEqual(1, responses[2].businessDays);
    }

    @IsTest
    static void oversizedRangeReturnsFriendlyMessage() {
        BusinessDaysAction.holidayProvider = new StubHolidayProvider();
        BusinessDaysAction.Request request = new BusinessDaysAction.Request();
        request.startDate = Date.newInstance(2000, 1, 1);
        request.endDate = Date.newInstance(2026, 1, 1);

        BusinessDaysAction.Response response = BusinessDaysAction.calculate(
            new List<BusinessDaysAction.Request>{ request }
        )[0];

        Assert.isFalse(response.isSuccess);
        Assert.isTrue(response.message.contains('máximo'), 'Mensagem de intervalo deve ser amigável.');
    }

    @IsTest
    static void holidayReadFailureMarksEveryRowAsErrorInsteadOfGuessing() {
        StubHolidayProvider provider = new StubHolidayProvider();
        provider.shouldFail = true;
        BusinessDaysAction.holidayProvider = provider;

        BusinessDaysAction.Request request = new BusinessDaysAction.Request();
        request.startDate = Date.newInstance(2026, 7, 6);
        request.endDate = Date.newInstance(2026, 7, 10);

        BusinessDaysAction.Response response = BusinessDaysAction.calculate(
            new List<BusinessDaysAction.Request>{ request }
        )[0];

        Assert.isFalse(response.isSuccess, 'Sem feriados confiáveis não se deve devolver um número.');
        Assert.isNull(response.businessDays);
    }
}
