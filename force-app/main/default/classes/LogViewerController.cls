/**
 * Consulta paginada (no servidor) dos logs para o LWC logViewer.
 *
 * Segurança:
 *  - Todas as consultas usam AccessLevel.USER_MODE (equivalente a WITH USER_MODE em SOQL dinâmico):
 *    CRUD, FLS e sharing do usuário logado são aplicados.
 *  - Filtros entram como bind variables. Nenhum valor vindo do LWC é concatenado na query.
 *
 * Paginação:
 *  - OFFSET do SOQL é limitado a 2000. Páginas além disso exigem filtro de período.
 */
public with sharing class LogViewerController {

    public static final Integer MAX_PAGE_SIZE = 100;
    public static final Integer DEFAULT_PAGE_SIZE = 20;
    public static final Integer MAX_OFFSET = 2000;

    public class LogFilter {
        @AuraEnabled public String level;
        @AuraEnabled public String source;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public Id userId;
    }

    public class LogRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String level;
        @AuraEnabled public String source;
        @AuraEnabled public String sourceType;
        @AuraEnabled public String message;
        @AuraEnabled public Datetime loggedAt;
        @AuraEnabled public String userName;
        @AuraEnabled public String relatedRecordId;
    }

    public class LogPage {
        @AuraEnabled public List<LogRow> rows = new List<LogRow>();
        @AuraEnabled public Integer totalCount = 0;
        @AuraEnabled public Integer pageNumber = 1;
        @AuraEnabled public Integer pageSize = DEFAULT_PAGE_SIZE;
    }

    @AuraEnabled
    public static LogPage search(LogFilter filter, Integer pageSize, Integer pageNumber) {
        Integer size = pageSize == null ? DEFAULT_PAGE_SIZE : Math.min(Math.max(pageSize, 1), MAX_PAGE_SIZE);
        Integer page = Math.max(pageNumber == null ? 1 : pageNumber, 1);
        Integer offset = (page - 1) * size;
        if (offset > MAX_OFFSET) {
            throw new AuraHandledException('Use filtros de período para acessar registros mais antigos.');
        }

        LogFilter criteria = filter == null ? new LogFilter() : filter;
        Map<String, Object> binds = new Map<String, Object>();
        String whereClause = buildWhereClause(criteria, binds);

        try {
            Integer total = Database.countQueryWithBinds(
                'SELECT COUNT() FROM Log__c' + whereClause, binds, AccessLevel.USER_MODE
            );

            binds.put('pageLimit', size);
            binds.put('pageOffset', offset);
            List<Log__c> records = Database.queryWithBinds(
                'SELECT Id, Name, Level__c, Source__c, Source_Type__c, Message__c, Logged_At__c, ' +
                'Related_Record_Id__c, User__r.Name FROM Log__c' + whereClause +
                ' ORDER BY Logged_At__c DESC, Id DESC LIMIT :pageLimit OFFSET :pageOffset',
                binds,
                AccessLevel.USER_MODE
            );

            LogPage result = new LogPage();
            result.totalCount = total;
            result.pageNumber = page;
            result.pageSize = size;
            for (Log__c record : records) {
                result.rows.add(toRow(record));
            }
            return result;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '[LogViewerController] Falha na consulta: ' + e.getMessage());
            throw new AuraHandledException('Não foi possível carregar os logs. Tente novamente.');
        }
    }

    @TestVisible
    private static String buildWhereClause(LogFilter criteria, Map<String, Object> binds) {
        List<String> conditions = new List<String>();

        if (String.isNotBlank(criteria.level)) {
            LogLevel level = LogSettings.parseLevel(criteria.level, null);
            if (level == null) {
                throw new AuraHandledException('Nível inválido: ' + criteria.level);
            }
            binds.put('levelValue', level.name());
            conditions.add('Level__c = :levelValue');
        }
        if (String.isNotBlank(criteria.source)) {
            binds.put('sourcePattern', '%' + escapeLike(criteria.source.trim()) + '%');
            conditions.add('Source__c LIKE :sourcePattern');
        }
        if (criteria.startDate != null) {
            binds.put('startAt', Datetime.newInstance(criteria.startDate, Time.newInstance(0, 0, 0, 0)));
            conditions.add('Logged_At__c >= :startAt');
        }
        if (criteria.endDate != null) {
            // Limite exclusivo: inclui o dia inteiro de endDate.
            binds.put('endBefore', Datetime.newInstance(criteria.endDate.addDays(1), Time.newInstance(0, 0, 0, 0)));
            conditions.add('Logged_At__c < :endBefore');
        }
        if (criteria.userId != null) {
            binds.put('userValue', criteria.userId);
            conditions.add('User__c = :userValue');
        }

        return conditions.isEmpty() ? '' : ' WHERE ' + String.join(conditions, ' AND ');
    }

    private static String escapeLike(String value) {
        return value.replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_');
    }

    private static LogRow toRow(Log__c record) {
        LogRow row = new LogRow();
        row.id = record.Id;
        row.name = record.Name;
        row.level = record.Level__c;
        row.source = record.Source__c;
        row.sourceType = record.Source_Type__c;
        row.message = record.Message__c;
        row.loggedAt = record.Logged_At__c;
        row.userName = record.User__r == null ? null : record.User__r.Name;
        row.relatedRecordId = record.Related_Record_Id__c;
        return row;
    }
}
