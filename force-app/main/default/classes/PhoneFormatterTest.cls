@IsTest
private class PhoneFormatterTest {

    @IsTest
    static void formatsMobileWithCountryCodeAndMask() {
        PhoneFormatter.Result result = PhoneFormatter.format('+55 (11) 91234-5678');
        Assert.isTrue(result.isValid);
        Assert.areEqual('+5511912345678', result.e164);
        Assert.areEqual('(11) 91234-5678', result.formatted);
        Assert.areEqual(PhoneFormatter.TYPE_MOBILE, result.phoneType);
    }

    @IsTest
    static void formatsMobileWithoutCountryCode() {
        PhoneFormatter.Result result = PhoneFormatter.format('11912345678');
        Assert.isTrue(result.isValid);
        Assert.areEqual('+5511912345678', result.e164);
    }

    @IsTest
    static void formatsLandlineWithTenDigits() {
        PhoneFormatter.Result result = PhoneFormatter.format('5532345678');
        Assert.isTrue(result.isValid, 'Fixo com DDD 55 (10 dígitos) é lido como nacional, não como DDI.');
        Assert.areEqual('+555532345678', result.e164, 'Sem DDI no texto, o número inteiro vira o nacional.');
        Assert.areEqual('(55) 3234-5678', result.formatted);
        Assert.areEqual(PhoneFormatter.TYPE_LANDLINE, result.phoneType);
    }

    @IsTest
    static void rejectsMobileWithoutNinthDigit() {
        PhoneFormatter.Result result = PhoneFormatter.format('11812345678');
        Assert.isFalse(result.isValid);
        Assert.isTrue(result.message.contains('começar com 9'));
    }

    @IsTest
    static void rejectsInvalidDddAndWrongLength() {
        Assert.isFalse(PhoneFormatter.format('0112345678').isValid, 'DDD 01 não existe.');
        PhoneFormatter.Result tooShort = PhoneFormatter.format('123456');
        Assert.isFalse(tooShort.isValid);
        Assert.isNull(tooShort.e164, 'Sem E.164 quando o número é inválido.');
    }

    @IsTest
    static void rejectsBlankInput() {
        Assert.isFalse(PhoneFormatter.format(null).isValid);
        Assert.isFalse(PhoneFormatter.format('  ').isValid);
    }
}
