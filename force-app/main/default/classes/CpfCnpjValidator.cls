/**
 * Valida CPF (11 dígitos) e CNPJ (14 dígitos) com os dígitos verificadores.
 * Lógica pura, sem SOQL nem DML: é a única fonte de verdade para essa regra.
 */
public inherited sharing class CpfCnpjValidator {
    public static final String TYPE_CPF = 'CPF';
    public static final String TYPE_CNPJ = 'CNPJ';

    private static final Integer CPF_LENGTH = 11;
    private static final Integer CNPJ_LENGTH = 14;
    private static final List<Integer> CNPJ_WEIGHTS_1 = new List<Integer>{ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 };
    private static final List<Integer> CNPJ_WEIGHTS_2 = new List<Integer>{ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 };

    public class Result {
        public Boolean isValid { get; private set; }
        public String documentType { get; private set; }
        public String normalizedNumber { get; private set; }
        public String message { get; private set; }

        private Result(Boolean isValid, String documentType, String normalizedNumber, String message) {
            this.isValid = isValid;
            this.documentType = documentType;
            this.normalizedNumber = normalizedNumber;
            this.message = message;
        }
    }

    /**
     * Aceita o documento com ou sem máscara. Retorna sempre um Result; nunca lança exceção.
     */
    public static Result validate(String document) {
        if (String.isBlank(document)) {
            return new Result(false, null, null, 'Informe um CPF ou CNPJ.');
        }

        String digits = document.replaceAll('\\D', '');

        if (digits.length() == CPF_LENGTH) {
            return isValidCpf(digits)
                ? new Result(true, TYPE_CPF, digits, 'CPF válido.')
                : new Result(false, TYPE_CPF, digits, 'CPF inválido.');
        }

        if (digits.length() == CNPJ_LENGTH) {
            return isValidCnpj(digits)
                ? new Result(true, TYPE_CNPJ, digits, 'CNPJ válido.')
                : new Result(false, TYPE_CNPJ, digits, 'CNPJ inválido.');
        }

        return new Result(false, null, digits, 'Documento deve ter 11 dígitos (CPF) ou 14 dígitos (CNPJ).');
    }

    @TestVisible
    private static Boolean isValidCpf(String digits) {
        if (digits.length() != CPF_LENGTH || isRepeatedDigit(digits)) {
            return false;
        }
        return digitAt(digits, 9) == cpfCheckDigit(digits, 9)
            && digitAt(digits, 10) == cpfCheckDigit(digits, 10);
    }

    @TestVisible
    private static Boolean isValidCnpj(String digits) {
        if (digits.length() != CNPJ_LENGTH || isRepeatedDigit(digits)) {
            return false;
        }
        return digitAt(digits, 12) == cnpjCheckDigit(digits, CNPJ_WEIGHTS_1)
            && digitAt(digits, 13) == cnpjCheckDigit(digits, CNPJ_WEIGHTS_2);
    }

    /** CPF/CNPJ com todos os dígitos iguais (ex.: 000.000.000-00) passam no cálculo, mas são inválidos. */
    private static Boolean isRepeatedDigit(String digits) {
        return digits.left(1).repeat(digits.length()) == digits;
    }

    private static Integer cpfCheckDigit(String digits, Integer length) {
        Integer sum = 0;
        for (Integer i = 0; i < length; i++) {
            sum += digitAt(digits, i) * (length + 1 - i);
        }
        Integer remainder = Math.mod(sum * 10, 11);
        return remainder == 10 ? 0 : remainder;
    }

    private static Integer cnpjCheckDigit(String digits, List<Integer> weights) {
        Integer sum = 0;
        for (Integer i = 0; i < weights.size(); i++) {
            sum += digitAt(digits, i) * weights[i];
        }
        Integer remainder = Math.mod(sum, 11);
        return remainder < 2 ? 0 : 11 - remainder;
    }

    private static Integer digitAt(String digits, Integer index) {
        return Integer.valueOf(digits.substring(index, index + 1));
    }
}
