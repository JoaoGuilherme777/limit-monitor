@IsTest
private class CpfCnpjValidatorTest {

    @IsTest
    static void acceptsValidCpfWithAndWithoutMask() {
        CpfCnpjValidator.Result masked = CpfCnpjValidator.validate('529.982.247-25');
        Assert.isTrue(masked.isValid, 'CPF com máscara deveria ser válido.');
        Assert.areEqual(CpfCnpjValidator.TYPE_CPF, masked.documentType);
        Assert.areEqual('52998224725', masked.normalizedNumber, 'Número deve sair só com dígitos.');

        CpfCnpjValidator.Result plain = CpfCnpjValidator.validate('12345678909');
        Assert.isTrue(plain.isValid, 'CPF sem máscara deveria ser válido.');
    }

    @IsTest
    static void rejectsCpfWithWrongCheckDigit() {
        CpfCnpjValidator.Result result = CpfCnpjValidator.validate('52998224724');
        Assert.isFalse(result.isValid);
        Assert.areEqual(CpfCnpjValidator.TYPE_CPF, result.documentType, 'Tipo continua CPF mesmo inválido.');
        Assert.areEqual('CPF inválido.', result.message);
    }

    @IsTest
    static void rejectsRepeatedDigitCpfEvenIfCalculationPasses() {
        Assert.isFalse(CpfCnpjValidator.validate('11111111111').isValid);
        Assert.isFalse(CpfCnpjValidator.validate('00000000000').isValid);
    }

    @IsTest
    static void acceptsValidCnpjWithMask() {
        CpfCnpjValidator.Result result = CpfCnpjValidator.validate('11.444.777/0001-61');
        Assert.isTrue(result.isValid, 'CNPJ válido com máscara deveria passar.');
        Assert.areEqual(CpfCnpjValidator.TYPE_CNPJ, result.documentType);
        Assert.areEqual('11444777000161', result.normalizedNumber);
    }

    @IsTest
    static void rejectsCnpjWithWrongCheckDigit() {
        CpfCnpjValidator.Result result = CpfCnpjValidator.validate('11444777000162');
        Assert.isFalse(result.isValid);
        Assert.areEqual('CNPJ inválido.', result.message);
    }

    @IsTest
    static void rejectsUnsupportedLengthWithoutType() {
        CpfCnpjValidator.Result result = CpfCnpjValidator.validate('12345');
        Assert.isFalse(result.isValid);
        Assert.isNull(result.documentType, 'Sem tipo quando o tamanho não corresponde a CPF nem CNPJ.');
        Assert.isTrue(result.message.contains('11 dígitos'));
    }

    @IsTest
    static void rejectsBlankInput() {
        Assert.isFalse(CpfCnpjValidator.validate(null).isValid);
        Assert.isFalse(CpfCnpjValidator.validate('   ').isValid);
    }
}
