@IsTest
private class ActionMessagesTest {

    @IsTest
    static void unexpectedErrorReturnsSafeMessageWithoutTechnicalDetail() {
        String message = ActionMessages.logUnexpectedError('Teste', new CalloutException('detalhe técnico'));
        Assert.areEqual(ActionMessages.GENERIC_ERROR, message);
        Assert.isFalse(message.contains('detalhe técnico'), 'Detalhe técnico não pode vazar ao usuário.');
    }
}
