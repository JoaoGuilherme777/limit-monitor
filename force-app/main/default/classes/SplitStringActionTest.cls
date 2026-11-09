@IsTest
private class SplitStringActionTest {

    @IsTest
    static void bulkSplitsTwoHundredRowsInOrder() {
        List<SplitStringAction.Request> requests = new List<SplitStringAction.Request>();
        for (Integer i = 0; i < 200; i++) {
            SplitStringAction.Request request = new SplitStringAction.Request();
            request.text = 'item' + i + ', extra' + i + ',';
            requests.add(request);
        }

        List<SplitStringAction.Response> responses = SplitStringAction.split(requests);

        Assert.areEqual(200, responses.size());
        for (Integer i = 0; i < 200; i++) {
            Assert.isTrue(responses[i].isSuccess);
            Assert.areEqual(2, responses[i].itemCount, 'A vírgula final não gera item vazio por padrão.');
            Assert.areEqual(new List<String>{ 'item' + i, 'extra' + i }, responses[i].items, 'Linha ' + i);
        }
    }

    @IsTest
    static void defaultsAreCommaSeparatorRemoveEmptyAndTrim() {
        SplitStringAction.Request request = new SplitStringAction.Request();
        request.text = ' um , , dois ';

        SplitStringAction.Response response = SplitStringAction.split(new List<SplitStringAction.Request>{ request })[0];

        Assert.areEqual(new List<String>{ 'um', 'dois' }, response.items);
        Assert.areEqual(2, response.itemCount);
    }

    @IsTest
    static void explicitFlagsAreRespected() {
        SplitStringAction.Request request = new SplitStringAction.Request();
        request.text = 'a|  |b';
        request.separator = '|';
        request.removeEmpty = false;
        request.trimItems = false;

        SplitStringAction.Response response = SplitStringAction.split(new List<SplitStringAction.Request>{ request })[0];

        Assert.areEqual(new List<String>{ 'a', '  ', 'b' }, response.items);
        Assert.areEqual(3, response.itemCount);
    }

    @IsTest
    static void nullRowReturnsEmptyItemsAndError() {
        List<SplitStringAction.Response> responses = SplitStringAction.split(
            new List<SplitStringAction.Request>{ null }
        );

        Assert.isFalse(responses[0].isSuccess);
        Assert.isTrue(responses[0].items.isEmpty(), 'Lista de itens nunca deve ser nula para o Flow.');
        Assert.areEqual(0, responses[0].itemCount);
    }
}
