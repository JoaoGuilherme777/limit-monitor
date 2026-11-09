@IsTest
private class ValidateDocumentActionTest {

    @IsTest
    static void bulkValidatesTwoHundredRowsInOrder() {
        List<ValidateDocumentAction.Request> requests = new List<ValidateDocumentAction.Request>();
        for (Integer i = 0; i < 200; i++) {
            ValidateDocumentAction.Request request = new ValidateDocumentAction.Request();
            Integer kind = Math.mod(i, 4);
            if (kind == 0) {
                request.document = '52998224725';        // CPF válido
            } else if (kind == 1) {
                request.document = '52998224724';        // CPF com dígito errado
            } else if (kind == 2) {
                request.document = '11.444.777/0001-61'; // CNPJ válido
            } else {
                request.document = '123';                // tamanho inválido
            }
            requests.add(request);
        }

        List<ValidateDocumentAction.Response> responses = ValidateDocumentAction.validate(requests);

        Assert.areEqual(200, responses.size(), 'Deve haver uma resposta por linha.');
        for (Integer i = 0; i < 200; i++) {
            ValidateDocumentAction.Response response = responses[i];
            Integer kind = Math.mod(i, 4);
            if (kind == 0) {
                Assert.isTrue(response.isValid, 'Linha ' + i + ': CPF válido.');
                Assert.areEqual('CPF', response.documentType);
            } else if (kind == 1) {
                Assert.isFalse(response.isValid, 'Linha ' + i + ': CPF inválido.');
                Assert.areEqual('CPF', response.documentType);
            } else if (kind == 2) {
                Assert.isTrue(response.isValid, 'Linha ' + i + ': CNPJ válido.');
                Assert.areEqual('CNPJ', response.documentType);
            } else {
                Assert.isFalse(response.isValid, 'Linha ' + i + ': tamanho inválido.');
                Assert.isNull(response.documentType);
            }
        }
    }

    @IsTest
    static void nullRequestReturnsErrorWithoutFailingTheBatch() {
        ValidateDocumentAction.Request valid = new ValidateDocumentAction.Request();
        valid.document = '52998224725';

        List<ValidateDocumentAction.Response> responses = ValidateDocumentAction.validate(
            new List<ValidateDocumentAction.Request>{ null, valid }
        );

        Assert.areEqual(2, responses.size());
        Assert.isFalse(responses[0].isValid);
        Assert.areEqual(ActionMessages.NULL_ENTRY, responses[0].message);
        Assert.isTrue(responses[1].isValid, 'A linha válida não pode ser afetada pela linha nula.');
    }

    @IsTest
    static void nullListReturnsEmptyList() {
        Assert.isTrue(ValidateDocumentAction.validate(null).isEmpty());
    }

    @IsTest
    static void normalizedNumberIsReturnedForFlowReuse() {
        ValidateDocumentAction.Request request = new ValidateDocumentAction.Request();
        request.document = '529.982.247-25';

        ValidateDocumentAction.Response response = ValidateDocumentAction.validate(
            new List<ValidateDocumentAction.Request>{ request }
        )[0];

        Assert.areEqual('52998224725', response.normalizedNumber);
    }
}
