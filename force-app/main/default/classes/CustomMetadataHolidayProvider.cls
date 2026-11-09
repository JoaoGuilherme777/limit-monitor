/**
 * Lê os feriados cadastrados em Custom Metadata (Feriado__mdt).
 * Uma única consulta por chamada; o chamador deve agrupar o intervalo do lote inteiro.
 */
public inherited sharing class CustomMetadataHolidayProvider implements IHolidayProvider {
    public Set<Date> getHolidays(Date startDate, Date endDate) {
        Set<Date> holidays = new Set<Date>();
        if (startDate == null || endDate == null) {
            return holidays;
        }

        for (Feriado__mdt holiday : [
            SELECT Data__c
            FROM Feriado__mdt
            WHERE Data__c >= :startDate AND Data__c <= :endDate
            WITH USER_MODE
        ]) {
            holidays.add(holiday.Data__c);
        }
        return holidays;
    }
}
