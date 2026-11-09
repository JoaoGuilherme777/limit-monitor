/** Consome Log_Event__e (after insert) e delega a persistência ao handler. Sem lógica aqui. */
trigger LogEventTrigger on Log_Event__e (after insert) {
    LogEventHandler.handle(Trigger.new);
}
