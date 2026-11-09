/**
 * Ação de Flow: divide um texto em uma coleção usando um separador configurável.
 * Opções: remover itens vazios (padrão: sim) e aparar espaços (padrão: sim).
 * Contrato: uma linha de Request gera exatamente uma linha de Response, na mesma ordem.
 */
public inherited sharing class SplitStringAction {

    public static final String DEFAULT_SEPARATOR = ',';

    @InvocableMethod(
        label='Dividir texto em lista'
        description='Divide um texto pelo separador (padrão: vírgula) e devolve uma coleção. Por padrão remove itens vazios e espaços nas pontas.'
        category='Utilidades'
    )
    public static List<Response> split(List<Request> requests) {
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
        response.items = new List<String>();
        response.itemCount = 0;

        if (request == null) {
            response.isSuccess = false;
            response.message = ActionMessages.NULL_ENTRY;
            return response;
        }

        try {
            String separator = request.separator == null ? DEFAULT_SEPARATOR : request.separator;
            Boolean removeEmpty = request.removeEmpty == null ? true : request.removeEmpty;
            Boolean trimItems = request.trimItems == null ? true : request.trimItems;

            response.items = StringSplitter.split(request.text, separator, removeEmpty, trimItems);
            response.itemCount = response.items.size();
            response.isSuccess = true;
            response.message = response.itemCount + ' item(ns) encontrado(s).';
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'SplitStringAction: ' + e.getMessage());
            response.isSuccess = false;
            response.message = ActionMessages.GENERIC_ERROR;
        }
        return response;
    }

    public class Request {
        @InvocableVariable(label='Texto' required=true)
        public String text;

        @InvocableVariable(label='Separador' description='Opcional. Padrão: vírgula (,). Tratado como texto literal, sem regex.')
        public String separator;

        @InvocableVariable(label='Remover itens vazios?' description='Opcional. Padrão: sim.')
        public Boolean removeEmpty;

        @InvocableVariable(label='Aparar espaços?' description='Opcional. Padrão: sim.')
        public Boolean trimItems;
    }

    public class Response {
        @InvocableVariable(label='Sucesso?')
        public Boolean isSuccess;

        @InvocableVariable(label='Itens')
        public List<String> items;

        @InvocableVariable(label='Quantidade de itens')
        public Integer itemCount;

        @InvocableVariable(label='Mensagem')
        public String message;
    }
}
