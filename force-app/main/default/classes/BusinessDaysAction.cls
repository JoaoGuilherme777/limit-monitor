/**
 * Ação de Flow: conta dias úteis entre duas datas, descontando feriados cadastrados.
 *
 * Bulkificação: os feriados são buscados UMA vez para o intervalo que cobre todo o lote
 * (menor a maior data), independentemente de quantas linhas o Flow envie.
 * Se os feriados não puderem ser lidos, nenhuma linha recebe um número: todas recebem erro.
 */
public inherited sharing class BusinessDaysAction {

    @TestVisible
    private static IHolidayProvider holidayProvider = new CustomMetadataHolidayProvider();

    @InvocableMethod(
        label='Calcular dias úteis'
        description='Conta dias úteis entre duas datas (segunda a sexta, sem feriados cadastrados). A data inicial não entra na contagem; a final entra.'
        category='Utilidades'
    )
    public static List<Response> calculate(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Set<Date> holidays = loadHolidays(requests);

        for (Request request : requests) {
            responses.add(holidays == null ? holidayErrorResponse() : buildResponse(request, holidays));
        }
        return responses;
    }

    /** Retorna null se os feriados não puderem ser lidos: um cálculo sem feriados daria resultado errado. */
    private static Set<Date> loadHolidays(List<Request> requests) {
        Date minDate = null;
        Date maxDate = null;
        for (Request request : requests) {
            if (request == null || request.startDate == null || request.endDate == null) {
                continue;
            }
            Date low = request.startDate < request.endDate ? request.startDate : request.endDate;
            Date high = request.startDate < request.endDate ? request.endDate : request.startDate;
            minDate = (minDate == null || low < minDate) ? low : minDate;
            maxDate = (maxDate == null || high > maxDate) ? high : maxDate;
        }

        if (minDate == null) {
            return new Set<Date>();
        }
        try {
            return holidayProvider.getHolidays(minDate, maxDate);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'BusinessDaysAction (feriados): ' + e.getMessage());
            return null;
        }
    }

    private static Response holidayErrorResponse() {
        Response response = new Response();
        response.isSuccess = false;
        response.message = 'Não foi possível carregar a lista de feriados. Tente novamente.';
        return response;
    }

    private static Response buildResponse(Request request, Set<Date> holidays) {
        Response response = new Response();
        if (request == null || request.startDate == null || request.endDate == null) {
            response.isSuccess = false;
            response.message = 'Informe a data inicial e a data final.';
            return response;
        }

        try {
            response.businessDays = BusinessDaysCalculator.countBetween(request.startDate, request.endDate, holidays);
            response.isSuccess = true;
            response.message = 'Cálculo concluído.';
        } catch (IllegalArgumentException e) {
            // Mensagens de IllegalArgumentException são escritas por nós e seguras para o usuário.
            response.isSuccess = false;
            response.message = e.getMessage();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'BusinessDaysAction: ' + e.getMessage());
            response.isSuccess = false;
            response.message = ActionMessages.GENERIC_ERROR;
        }
        return response;
    }

    public class Request {
        @InvocableVariable(label='Data inicial' description='Esta data não entra na contagem.' required=true)
        public Date startDate;

        @InvocableVariable(label='Data final' description='Esta data entra na contagem.' required=true)
        public Date endDate;
    }

    public class Response {
        @InvocableVariable(label='Sucesso?')
        public Boolean isSuccess;

        @InvocableVariable(label='Dias úteis')
        public Integer businessDays;

        @InvocableVariable(label='Mensagem')
        public String message;
    }
}
