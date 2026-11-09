/**
 * Mensagens padronizadas devolvidas aos Flows.
 * Centralizadas para manter o texto consistente e para que detalhes técnicos
 * (stack trace, SOQL, nomes de classe) nunca cheguem ao usuário final.
 */
public inherited sharing class ActionMessages {
    public static final String GENERIC_ERROR = 'Não foi possível concluir a operação. Verifique os dados informados.';
    public static final String NULL_ENTRY = 'Nenhuma entrada foi informada para esta linha.';

    /** Registra o erro técnico no log e devolve a mensagem segura para o usuário. */
    public static String logUnexpectedError(String source, Exception e) {
        System.debug(LoggingLevel.ERROR, source + ': ' + e.getMessage());
        return GENERIC_ERROR;
    }
}
