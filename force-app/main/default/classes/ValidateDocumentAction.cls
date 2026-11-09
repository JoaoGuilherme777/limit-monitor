/**
 * Ação de Flow: valida CPF ou CNPJ.
 * Contrato: uma linha de Request gera exatamente uma linha de Response, na mesma ordem.
 */
public inherited sharing class ValidateDocumentAction {

    @InvocableMethod(
        label='Validar CPF ou CNPJ'
        description='Verifica os dígitos verificadores e informa se o documento é CPF ou CNPJ.'
        category='Utilidades'
    )
    public static List<Response> validate(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null) {
            return responses;
        }

        for (Request request : requests) {
            responses.add(buildResponse(request));
        }
        return responses;
    }

    private static Response buildResponse(Request request) {
        Response response = new Response();
        if (request == null) {
            response.isValid = false;
            response.message = ActionMessages.NULL_ENTRY;
            return response;
        }

        try {
            CpfCnpjValidator.Result result = CpfCnpjValidator.validate(request.document);
            response.isValid = result.isValid;
            response.documentType = result.documentType;
            response.normalizedNumber = result.normalizedNumber;
            response.message = result.message;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ValidateDocumentAction: ' + e.getMessage());
            response.isValid = false;
            response.message = ActionMessages.GENERIC_ERROR;
        }
        return response;
    }

    public class Request {
        @InvocableVariable(label='CPF ou CNPJ' description='Documento com ou sem máscara.' required=true)
        public String document;
    }

    public class Response {
        @InvocableVariable(label='É válido?')
        public Boolean isValid;

        @InvocableVariable(label='Tipo (CPF ou CNPJ)')
        public String documentType;

        @InvocableVariable(label='Número normalizado (só dígitos)')
        public String normalizedNumber;

        @InvocableVariable(label='Mensagem')
        public String message;
    }
}
