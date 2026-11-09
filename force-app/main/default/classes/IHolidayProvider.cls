/**
 * Fonte de feriados para o cálculo de dias úteis.
 * A implementação padrão lê Custom Metadata; testes injetam um stub (ver StubHolidayProvider).
 */
public interface IHolidayProvider {
    /** Retorna os feriados com data entre startDate e endDate, inclusive. */
    Set<Date> getHolidays(Date startDate, Date endDate);
}
