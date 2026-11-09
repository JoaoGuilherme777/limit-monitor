/**
 * Lê um campo de um registro relacionado (ex.: Contact -> Account.Industry) de forma segura.
 *
 * Segurança:
 *  - O caminho do campo é validado contra o describe do Salesforce (objeto, relacionamento,
 *    campo existem e são acessíveis) antes de montar qualquer SOQL. Só identificadores
 *    canônicos do schema entram na query; o texto digitado pelo admin nunca é concatenado cru.
 *  - A consulta usa WITH USER_MODE, então respeita FLS e compartilhamento do usuário atual.
 *
 * Desempenho:
 *  - readAll faz UMA consulta por tipo de objeto para todos os IDs recebidos (WHERE Id IN :ids),
 *    nunca uma consulta por registro.
 *
 * Erros: nada aqui lança exceção para o Flow. Caminho inválido e registro ausente viram
 * Result com isSuccess = false ou found = false, com mensagem em português.
 */
@SuppressWarnings('PMD.ApexSOQLInjection')
public with sharing class RelatedFieldReader {

    public static final Integer MAX_PATH_DEPTH = 5;

    public class Result {
        public Boolean isSuccess { get; private set; }
        public Boolean found { get; private set; }
        public String value { get; private set; }
        public String message { get; private set; }

        private Result(Boolean isSuccess, Boolean found, String value, String message) {
            this.isSuccess = isSuccess;
            this.found = found;
            this.value = value;
            this.message = message;
        }

        public Result(Boolean isSuccess, String message) {
            this(isSuccess, false, null, message);
        }
    }

    /** Caminho validado e pronto para uso em SOQL. */
    private class ResolvedPath {
        Boolean isValid;
        String message;
        String rootObjectName;
        List<String> relationshipNames = new List<String>();
        String leafFieldName;

        String soqlField() {
            List<String> parts = new List<String>(relationshipNames);
            parts.add(leafFieldName);
            return String.join(parts, '.');
        }
    }

    /**
     * Retorna um Result para cada ID, na mesma ordem. IDs nulos viram erro de entrada.
     * Todos os IDs devem ser do mesmo tipo de objeto (o chamador agrupa por tipo).
     */
    public static List<Result> readAll(Schema.SObjectType rootType, String fieldPath, List<Id> recordIds) {
        List<Result> results = new List<Result>();
        if (recordIds == null || recordIds.isEmpty()) {
            return results;
        }

        ResolvedPath path = resolve(rootType, fieldPath);
        Map<Id, Result> resultById = new Map<Id, Result>();
        Set<Id> validIds = new Set<Id>();
        for (Id recordId : recordIds) {
            if (recordId != null) {
                validIds.add(recordId);
            }
        }

        if (!path.isValid) {
            for (Id recordId : validIds) {
                resultById.put(recordId, new Result(false, path.message));
            }
        } else if (!validIds.isEmpty()) {
            fillResults(path, validIds, resultById);
        }

        for (Id recordId : recordIds) {
            results.add(recordId == null ? new Result(false, 'Informe o registro de origem.') : resultById.get(recordId));
        }
        return results;
    }

    private static void fillResults(ResolvedPath path, Set<Id> ids, Map<Id, Result> resultById) {
        String soql = 'SELECT Id, ' + path.soqlField() + ' FROM ' + path.rootObjectName
            + ' WHERE Id IN :ids WITH USER_MODE';
        Map<Id, SObject> rowById = new Map<Id, SObject>(Database.query(soql));

        for (Id recordId : ids) {
            if (!rowById.containsKey(recordId)) {
                resultById.put(recordId, new Result(true, 'Registro não encontrado ou sem acesso.'));
                continue;
            }
            resultById.put(recordId, extractValue(rowById.get(recordId), path));
        }
    }

    private static Result extractValue(SObject row, ResolvedPath path) {
        SObject current = row;
        for (String relationshipName : path.relationshipNames) {
            current = current.getSObject(relationshipName);
            if (current == null) {
                return new Result(true, 'Registro relacionado vazio.');
            }
        }

        Object raw = current.get(path.leafFieldName);
        if (raw == null) {
            return new Result(true, 'Campo sem valor.');
        }
        return new Result(true, true, String.valueOf(raw), 'Valor encontrado.');
    }

    @TestVisible
    private static ResolvedPath resolve(Schema.SObjectType rootType, String fieldPath) {
        ResolvedPath resolved = new ResolvedPath();
        resolved.isValid = false;

        if (rootType == null) {
            resolved.message = 'Objeto de origem inválido.';
            return resolved;
        }
        String cleanPath = fieldPath == null ? '' : fieldPath.trim();
        if (String.isBlank(cleanPath)) {
            resolved.message = 'Informe o caminho do campo, por exemplo Account.Industry.';
            return resolved;
        }

        List<String> segments = cleanPath.split('\\.');
        if (segments.size() > MAX_PATH_DEPTH) {
            resolved.message = 'Caminho muito longo: o máximo são ' + MAX_PATH_DEPTH + ' níveis.';
            return resolved;
        }

        Schema.SObjectType currentType = rootType;
        for (Integer i = 0; i < segments.size() - 1; i++) {
            String segment = segments[i].trim();
            Schema.DescribeFieldResult relationship = findRelationship(currentType, segment);
            if (relationship == null || !relationship.isAccessible()) {
                resolved.message = 'Relacionamento "' + segment + '" não existe em '
                    + currentType.getDescribe().getName() + ' ou não está acessível.';
                return resolved;
            }
            List<Schema.SObjectType> targets = relationship.getReferenceTo();
            if (targets.size() != 1) {
                resolved.message = 'Relacionamento "' + segment + '" é polimórfico e não é suportado.';
                return resolved;
            }
            resolved.relationshipNames.add(relationship.getRelationshipName());
            currentType = targets[0];
        }

        String leafName = segments[segments.size() - 1].trim();
        Schema.SObjectField leaf = currentType.getDescribe().fields.getMap().get(leafName.toLowerCase());
        if (leaf == null || !leaf.getDescribe().isAccessible()) {
            resolved.message = 'Campo "' + leafName + '" não existe em ' + currentType.getDescribe().getName()
                + ' ou não está acessível.';
            return resolved;
        }

        resolved.isValid = true;
        resolved.rootObjectName = rootType.getDescribe().getName();
        resolved.leafFieldName = leaf.getDescribe().getName();
        return resolved;
    }

    private static Schema.DescribeFieldResult findRelationship(Schema.SObjectType objectType, String relationshipName) {
        for (Schema.SObjectField field : objectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult description = field.getDescribe();
            if (description.getType() == Schema.DisplayType.REFERENCE
                && String.isNotBlank(description.getRelationshipName())
                && description.getRelationshipName().equalsIgnoreCase(relationshipName)) {
                return description;
            }
        }
        return null;
    }
}
