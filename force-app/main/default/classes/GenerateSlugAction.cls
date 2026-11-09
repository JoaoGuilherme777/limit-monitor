/**
 * Ação de Flow: gera slug a partir de um texto (remove acentos e caracteres especiais).
 * Contrato: uma linha de Request gera exatamente uma linha de Response, na mesma ordem.
 */
public inherited sharing class GenerateSlugAction {

    @InvocableMethod(
        label='Gerar slug'
        description='Remove acentos e caracteres especiais e une as palavras com o separador (padrão: hífen). Ex.: "Ação & Solução 2026" -> acao-solucao-2026.'
        category='Utilidades'
    )
    public static List<Response> generate(List<Request> requests) {
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
            response.isSuccess = false;
            response.slug = '';
            response.message = ActionMessages.NULL_ENTRY;
            return response;
        }

        try {
            response.slug = SlugGenerator.generate(request.text, request.separator);
            response.isSuccess = String.isNotBlank(response.slug);
            response.message = response.isSuccess ? 'Slug gerado.' : 'O texto não tem letras ou números para gerar o slug.';
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'GenerateSlugAction: ' + e.getMessage());
            response.isSuccess = false;
            response.slug = '';
            response.message = ActionMessages.GENERIC_ERROR;
        }
        return response;
    }

    public class Request {
        @InvocableVariable(label='Texto' required=true)
        public String text;

        @InvocableVariable(label='Separador' description='Opcional. Padrão: hífen (-). Use vazio para juntar sem separador.')
        public String separator;
    }

    public class Response {
        @InvocableVariable(label='Sucesso?')
        public Boolean isSuccess;

        @InvocableVariable(label='Slug')
        public String slug;

        @InvocableVariable(label='Mensagem')
        public String message;
    }
}
