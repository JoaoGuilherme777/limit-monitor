/**
 * Ação de Flow: formata telefone brasileiro para E.164 e para máscara.
 * Contrato: uma linha de Request gera exatamente uma linha de Response, na mesma ordem.
 */
public inherited sharing class FormatPhoneAction {

    @InvocableMethod(
        label='Formatar telefone brasileiro'
        description='Converte para E.164 (+5511912345678) e para máscara ((11) 91234-5678). Aceita fixo e celular.'
        category='Utilidades'
    )
    public static List<Response> format(List<Request> requests) {
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
            PhoneFormatter.Result result = PhoneFormatter.format(request.phone);
            response.isValid = result.isValid;
            response.e164 = result.e164;
            response.formatted = result.formatted;
            response.phoneType = result.phoneType;
            response.message = result.message;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'FormatPhoneAction: ' + e.getMessage());
            response.isValid = false;
            response.message = ActionMessages.GENERIC_ERROR;
        }
        return response;
    }

    public class Request {
        @InvocableVariable(label='Telefone' description='Aceita com ou sem DDI 55, DDD e máscara.' required=true)
        public String phone;
    }

    public class Response {
        @InvocableVariable(label='É válido?')
        public Boolean isValid;

        @InvocableVariable(label='Telefone E.164 (+5511912345678)')
        public String e164;

        @InvocableVariable(label='Telefone com máscara ((11) 91234-5678)')
        public String formatted;

        @InvocableVariable(label='Tipo (FIXO ou CELULAR)')
        public String phoneType;

        @InvocableVariable(label='Mensagem')
        public String message;
    }
}
