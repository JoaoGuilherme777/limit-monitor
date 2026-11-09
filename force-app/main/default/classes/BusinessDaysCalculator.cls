/**
 * Conta dias úteis (segunda a sexta, exceto feriados) entre duas datas.
 *
 * Convenção: a data inicial NÃO entra na contagem; a data final ENTRA.
 * Ex.: de segunda 06/07 até sexta 10/07 (sem feriados) = 4 dias úteis.
 * Se a data final for anterior à inicial, o resultado é negativo.
 *
 * Lógica pura: os feriados são recebidos por parâmetro, sem SOQL aqui dentro.
 */
public inherited sharing class BusinessDaysCalculator {
    /** Limite de intervalo (~10 anos) para proteger a CPU contra entradas absurdas. */
    public static final Integer MAX_SPAN_DAYS = 3660;

    /** 01/01/2024 foi uma segunda-feira; usada como referência para descobrir o dia da semana. */
    private static final Date REFERENCE_MONDAY = Date.newInstance(2024, 1, 1);
    private static final Integer FIRST_WEEKEND_DAY_INDEX = 5;

    public static Integer countBetween(Date startDate, Date endDate, Set<Date> holidays) {
        if (startDate == null || endDate == null) {
            throw new IllegalArgumentException('Informe as duas datas.');
        }
        if (startDate == endDate) {
            return 0;
        }
        if (endDate < startDate) {
            return -countBetween(endDate, startDate, holidays);
        }

        Integer span = startDate.daysBetween(endDate);
        if (span > MAX_SPAN_DAYS) {
            throw new IllegalArgumentException('O intervalo máximo é de ' + MAX_SPAN_DAYS + ' dias.');
        }

        Integer businessDays = 0;
        Date cursor = startDate;
        for (Integer i = 0; i < span; i++) {
            cursor = cursor.addDays(1);
            if (isBusinessDay(cursor, holidays)) {
                businessDays++;
            }
        }
        return businessDays;
    }

    public static Boolean isBusinessDay(Date someDate, Set<Date> holidays) {
        Boolean isHoliday = holidays != null && holidays.contains(someDate);
        return !isWeekend(someDate) && !isHoliday;
    }

    public static Boolean isWeekend(Date someDate) {
        // Math.mod pode devolver negativo para datas anteriores à referência; o ajuste garante 0..6.
        Integer dayIndex = Math.mod(Math.mod(REFERENCE_MONDAY.daysBetween(someDate), 7) + 7, 7);
        return dayIndex >= FIRST_WEEKEND_DAY_INDEX;
    }
}
