/**
 * Ação de Flow: lê um campo de um registro relacionado, sem gerar erro se ele não existir.
 *
 * Bulkificação: as linhas são agrupadas por (tipo do registro + caminho do campo).
 * Cada grupo gera uma única consulta, então 200 linhas do mesmo tipo custam 1 SOQL.
 * A ordem das respostas é a mesma ordem das requisições.
 */
public inherited sharing class ReadRelatedFieldAction {

    @InvocableMethod(
        label='Ler campo de registro relacionado'
        description='Retorna o valor de um campo de um registro relacionado (ex.: Account.Industry a partir de um Contact). Se o registro ou o relacionamento não existir, retorna found = false sem erro.'
        category='Utilidades'
    )
    public static List<Response> read(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null) {
            return responses;
        }

        // Placeholder para manter a ordem; cada posição é preenchida abaixo.
        for (Integer i = 0; i < requests.size(); i++) {
            responses.add(nullEntryResponse());
        }

        Map<String, List<Integer>> indexesByGroup = new Map<String, List<Integer>>();
        Map<String, Schema.SObjectType> typeByGroup = new Map<String, Schema.SObjectType>();
        Map<String, String> pathByGroup = new Map<String, String>();

        for (Integer i = 0; i < requests.size(); i++) {
            Request request = requests[i];
            if (request == null || request.recordId == null) {
                continue;
            }
            Schema.SObjectType recordType = request.recordId.getSObjectType();
            String path = String.isBlank(request.fieldPath) ? '' : request.fieldPath.trim();
            String groupKey = recordType.getDescribe().getName() + '|' + path.toLowerCase();

            if (!indexesByGroup.containsKey(groupKey)) {
                indexesByGroup.put(groupKey, new List<Integer>());
                typeByGroup.put(groupKey, recordType);
                pathByGroup.put(groupKey, path);
            }
            indexesByGroup.get(groupKey).add(i);
        }

        for (String groupKey : indexesByGroup.keySet()) {
            List<Integer> indexes = indexesByGroup.get(groupKey);
            List<Id> recordIds = new List<Id>();
            for (Integer index : indexes) {
                recordIds.add(requests[index].recordId);
            }
            List<RelatedFieldReader.Result> results;
            try {
                results = RelatedFieldReader.readAll(typeByGroup.get(groupKey), pathByGroup.get(groupKey), recordIds);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'ReadRelatedFieldAction: ' + e.getMessage());
                results = errorResults(recordIds.size());
            }

            for (Integer j = 0; j < indexes.size(); j++) {
                responses[indexes[j]] = toResponse(results[j]);
            }
        }
        return responses;
    }

    private static Response toResponse(RelatedFieldReader.Result result) {
        Response response = new Response();
        response.isSuccess = result.isSuccess;
        response.found = result.found;
        response.value = result.value;
        response.message = result.message;
        return response;
    }

    private static Response nullEntryResponse() {
        Response response = new Response();
        response.isSuccess = false;
        response.found = false;
        response.message = ActionMessages.NULL_ENTRY;
        return response;
    }

    private static List<RelatedFieldReader.Result> errorResults(Integer size) {
        List<RelatedFieldReader.Result> results = new List<RelatedFieldReader.Result>();
        for (Integer i = 0; i < size; i++) {
            results.add(new RelatedFieldReader.Result(false, ActionMessages.GENERIC_ERROR));
        }
        return results;
    }

    public class Request {
        @InvocableVariable(label='Registro de origem' description='Ex.: o Contact cujo campo da Account será lido.' required=true)
        public Id recordId;

        @InvocableVariable(label='Caminho do campo' description='Ex.: Account.Industry. Até 5 níveis de relacionamento.' required=true)
        public String fieldPath;
    }

    public class Response {
        @InvocableVariable(label='Sucesso?')
        public Boolean isSuccess;

        @InvocableVariable(label='Valor encontrado?')
        public Boolean found;

        @InvocableVariable(label='Valor (texto)')
        public String value;

        @InvocableVariable(label='Mensagem')
        public String message;
    }
}
