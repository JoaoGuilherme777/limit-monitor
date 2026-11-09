@IsTest
private class BusinessDaysCalculatorTest {

    @IsTest
    static void countsMondayToFridayAsFourBusinessDays() {
        // 06/07/2026 é segunda; 10/07/2026 é sexta. Início não conta, fim conta: 07, 08, 09, 10.
        Integer days = BusinessDaysCalculator.countBetween(Date.newInstance(2026, 7, 6), Date.newInstance(2026, 7, 10), new Set<Date>());
        Assert.areEqual(4, days);
    }

    @IsTest
    static void fridayToMondayCountsOnlyMonday() {
        // 10/07 (sex) -> 13/07 (seg): sábado e domingo não contam.
        Integer days = BusinessDaysCalculator.countBetween(Date.newInstance(2026, 7, 10), Date.newInstance(2026, 7, 13), new Set<Date>());
        Assert.areEqual(1, days);
    }

    @IsTest
    static void holidayInsideRangeIsDiscounted() {
        Set<Date> holidays = new Set<Date>{ Date.newInstance(2026, 7, 8) };
        Integer days = BusinessDaysCalculator.countBetween(Date.newInstance(2026, 7, 6), Date.newInstance(2026, 7, 10), holidays);
        Assert.areEqual(3, days, 'Quarta feriada deve sair da contagem.');
    }

    @IsTest
    static void holidayOnFinalDateIsDiscounted() {
        Set<Date> holidays = new Set<Date>{ Date.newInstance(2026, 7, 10) };
        Integer days = BusinessDaysCalculator.countBetween(Date.newInstance(2026, 7, 6), Date.newInstance(2026, 7, 10), holidays);
        Assert.areEqual(3, days);
    }

    @IsTest
    static void weekendOnlyRangeHasNoBusinessDays() {
        // 04/07 é sábado e 05/07 é domingo.
        Assert.areEqual(0, BusinessDaysCalculator.countBetween(Date.newInstance(2026, 7, 4), Date.newInstance(2026, 7, 5), new Set<Date>()));
    }

    @IsTest
    static void sameDateReturnsZero() {
        Assert.areEqual(0, BusinessDaysCalculator.countBetween(Date.newInstance(2026, 7, 6), Date.newInstance(2026, 7, 6), new Set<Date>()));
    }

    @IsTest
    static void reversedRangeReturnsNegativeCount() {
        Integer days = BusinessDaysCalculator.countBetween(Date.newInstance(2026, 7, 10), Date.newInstance(2026, 7, 6), new Set<Date>());
        Assert.areEqual(-4, days, 'Data final anterior à inicial deve dar resultado negativo.');
    }

    @IsTest
    static void weekendDetectionIsCorrectBeforeAndAfterReferenceDate() {
        Assert.isTrue(BusinessDaysCalculator.isWeekend(Date.newInstance(2023, 12, 31)), '31/12/2023 é domingo.');
        Assert.isFalse(BusinessDaysCalculator.isWeekend(Date.newInstance(2024, 1, 1)), '01/01/2024 é segunda.');
        Assert.isTrue(BusinessDaysCalculator.isWeekend(Date.newInstance(2026, 7, 11)), '11/07/2026 é sábado.');
        Assert.isFalse(BusinessDaysCalculator.isBusinessDay(Date.newInstance(2026, 7, 8), new Set<Date>{ Date.newInstance(2026, 7, 8) }));
    }

    @IsTest
    static void rejectsNullDatesAndOversizedSpan() {
        try {
            BusinessDaysCalculator.countBetween(null, Date.newInstance(2026, 7, 6), new Set<Date>());
            Assert.fail('Data nula deveria lançar IllegalArgumentException.');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('Informe as duas datas'));
        }

        try {
            BusinessDaysCalculator.countBetween(Date.newInstance(2000, 1, 1), Date.newInstance(2026, 1, 1), new Set<Date>());
            Assert.fail('Intervalo acima do limite deveria lançar exceção.');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('máximo'));
        }
    }
}
