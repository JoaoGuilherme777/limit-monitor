@IsTest
private class FormatPhoneActionTest {

    @IsTest
    static void bulkFormatsTwoHundredRowsInOrder() {
        List<FormatPhoneAction.Request> requests = new List<FormatPhoneAction.Request>();
        for (Integer i = 0; i < 200; i++) {
            FormatPhoneAction.Request request = new FormatPhoneAction.Request();
            request.phone = Math.mod(i, 2) == 0 ? '(11) 91234-5678' : '1123456789';
            requests.add(request);
        }

        List<FormatPhoneAction.Response> responses = FormatPhoneAction.format(requests);

        Assert.areEqual(200, responses.size());
        for (Integer i = 0; i < 200; i++) {
            FormatPhoneAction.Response response = responses[i];
            Assert.isTrue(response.isValid, 'Linha ' + i + ' deveria ser válida.');
            if (Math.mod(i, 2) == 0) {
                Assert.areEqual('+5511912345678', response.e164, 'Linha ' + i);
                Assert.areEqual(PhoneFormatter.TYPE_MOBILE, response.phoneType);
            } else {
                Assert.areEqual('+551123456789', response.e164, 'Linha ' + i);
                Assert.areEqual(PhoneFormatter.TYPE_LANDLINE, response.phoneType);
            }
        }
    }

    @IsTest
    static void invalidRowDoesNotAffectOthers() {
        FormatPhoneAction.Request invalid = new FormatPhoneAction.Request();
        invalid.phone = 'abc';
        FormatPhoneAction.Request valid = new FormatPhoneAction.Request();
        valid.phone = '11912345678';

        List<FormatPhoneAction.Response> responses = FormatPhoneAction.format(
            new List<FormatPhoneAction.Request>{ invalid, null, valid }
        );

        Assert.isFalse(responses[0].isValid);
        Assert.isFalse(responses[1].isValid);
        Assert.areEqual(ActionMessages.NULL_ENTRY, responses[1].message);
        Assert.isTrue(responses[2].isValid);
    }
}
