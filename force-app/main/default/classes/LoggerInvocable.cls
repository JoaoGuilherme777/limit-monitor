/**
 * Invocable Action para Flow gravar logs. Um único flush por invocação, para não gerar
 * um lote de publicações por registro do Flow.
 */
public with sharing class LoggerInvocable {

    public class Request {
        @InvocableVariable(label='Nível' required=true description='DEBUG, INFO, WARN ou ERROR. Valor inválido vira INFO.')
        public String level;

        @InvocableVariable(label='Origem' required=true description='Nome do Flow ou elemento de origem.')
        public String source;

        @InvocableVariable(label='Mensagem' required=true)
        public String message;

        @InvocableVariable(label='ID do registro relacionado')
        public Id recordId;
    }

    @InvocableMethod(label='Registrar log' description='Grava uma entrada no Logger, persistida de forma assíncrona e independente da transação do Flow.' category='Logger')
    public static void log(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }
        try {
            for (Request req : requests) {
                Logger.write(
                    LogSettings.parseLevel(req.level, LogLevel.INFO),
                    'Flow',
                    req.source,
                    req.message,
                    req.recordId,
                    null
                );
            }
        } finally {
            Logger.flush();
        }
    }
}
