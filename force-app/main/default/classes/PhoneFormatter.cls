/**
 * Normaliza telefones brasileiros para E.164 (+5511912345678) e máscara ((11) 91234-5678).
 * Aceita fixo (10 dígitos) ou celular (11 dígitos), com ou sem DDI 55 e máscara.
 * Lógica pura, sem SOQL nem DML.
 */
public inherited sharing class PhoneFormatter {
    public static final String TYPE_LANDLINE = 'FIXO';
    public static final String TYPE_MOBILE = 'CELULAR';

    private static final String COUNTRY_CODE = '55';
    private static final Integer LANDLINE_LENGTH = 10;
    private static final Integer MOBILE_LENGTH = 11;
    private static final Integer MIN_DDD = 11;

    public class Result {
        public Boolean isValid { get; private set; }
        public String e164 { get; private set; }
        public String formatted { get; private set; }
        public String phoneType { get; private set; }
        public String message { get; private set; }

        private Result(Boolean isValid, String e164, String formatted, String phoneType, String message) {
            this.isValid = isValid;
            this.e164 = e164;
            this.formatted = formatted;
            this.phoneType = phoneType;
            this.message = message;
        }
    }

    public static Result format(String phone) {
        if (String.isBlank(phone)) {
            return invalid('Informe um telefone.');
        }

        String national = stripCountryCode(phone.replaceAll('\\D', ''));

        if (national.length() != LANDLINE_LENGTH && national.length() != MOBILE_LENGTH) {
            return invalid('Telefone deve ter 10 dígitos (fixo) ou 11 dígitos (celular), com DDD.');
        }

        String ddd = national.substring(0, 2);
        if (Integer.valueOf(ddd) < MIN_DDD) {
            return invalid('DDD inválido.');
        }

        String subscriber = national.substring(2);
        if (national.length() == MOBILE_LENGTH) {
            if (!subscriber.startsWith('9')) {
                return invalid('Celular deve começar com 9 após o DDD.');
            }
            return new Result(
                true,
                '+' + COUNTRY_CODE + national,
                '(' + ddd + ') ' + subscriber.substring(0, 5) + '-' + subscriber.substring(5),
                TYPE_MOBILE,
                'Telefone celular válido.'
            );
        }

        return new Result(
            true,
            '+' + COUNTRY_CODE + national,
            '(' + ddd + ') ' + subscriber.substring(0, 4) + '-' + subscriber.substring(4),
            TYPE_LANDLINE,
            'Telefone fixo válido.'
        );
    }

    /** Remove o DDI 55 apenas quando o tamanho indica que ele está presente (12 ou 13 dígitos). */
    private static String stripCountryCode(String digits) {
        Boolean hasCountryCode = (digits.length() == 12 || digits.length() == 13) && digits.startsWith(COUNTRY_CODE);
        return hasCountryCode ? digits.substring(COUNTRY_CODE.length()) : digits;
    }

    private static Result invalid(String message) {
        return new Result(false, null, null, null, message);
    }
}
