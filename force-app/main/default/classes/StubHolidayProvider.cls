/**
 * Stub de IHolidayProvider para testes. Devolve uma lista fixa e conta quantas vezes foi chamado,
 * o que permite provar que o lote consulta os feriados uma única vez.
 */
@IsTest
public class StubHolidayProvider implements IHolidayProvider {
    public Set<Date> holidays = new Set<Date>();
    public Integer callCount = 0;
    public Boolean shouldFail = false;

    public Set<Date> getHolidays(Date startDate, Date endDate) {
        callCount++;
        if (shouldFail) {
            throw new CalloutException('Falha simulada ao ler feriados.');
        }
        Set<Date> inRange = new Set<Date>();
        for (Date holiday : holidays) {
            if (holiday >= startDate && holiday <= endDate) {
                inRange.add(holiday);
            }
        }
        return inRange;
    }
}
