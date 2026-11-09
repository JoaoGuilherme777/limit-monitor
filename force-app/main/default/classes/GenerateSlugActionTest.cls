@IsTest
private class GenerateSlugActionTest {

    @IsTest
    static void bulkGeneratesSlugsInOrder() {
        List<GenerateSlugAction.Request> requests = new List<GenerateSlugAction.Request>();
        for (Integer i = 0; i < 200; i++) {
            GenerateSlugAction.Request request = new GenerateSlugAction.Request();
            request.text = 'Título Número ' + i;
            requests.add(request);
        }

        List<GenerateSlugAction.Response> responses = GenerateSlugAction.generate(requests);

        Assert.areEqual(200, responses.size());
        for (Integer i = 0; i < 200; i++) {
            Assert.isTrue(responses[i].isSuccess, 'Linha ' + i);
            Assert.areEqual('titulo-numero-' + i, responses[i].slug, 'Linha ' + i);
        }
    }

    @IsTest
    static void symbolOnlyTextIsReportedAsFailure() {
        GenerateSlugAction.Request request = new GenerateSlugAction.Request();
        request.text = '@@@';

        GenerateSlugAction.Response response = GenerateSlugAction.generate(
            new List<GenerateSlugAction.Request>{ request }
        )[0];

        Assert.isFalse(response.isSuccess);
        Assert.areEqual('', response.slug);
    }

    @IsTest
    static void nullRowReturnsErrorWithoutBreakingOthers() {
        GenerateSlugAction.Request valid = new GenerateSlugAction.Request();
        valid.text = 'Olá Mundo';

        List<GenerateSlugAction.Response> responses = GenerateSlugAction.generate(
            new List<GenerateSlugAction.Request>{ null, valid }
        );

        Assert.isFalse(responses[0].isSuccess);
        Assert.isTrue(responses[1].isSuccess);
        Assert.areEqual('ola-mundo', responses[1].slug);
    }
}
