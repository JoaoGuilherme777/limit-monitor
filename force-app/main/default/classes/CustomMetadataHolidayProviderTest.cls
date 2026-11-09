@IsTest
private class CustomMetadataHolidayProviderTest {

    @IsTest
    static void readsDeployedHolidaysFor2026() {
        Set<Date> holidays = new CustomMetadataHolidayProvider().getHolidays(
            Date.newInstance(2026, 1, 1),
            Date.newInstance(2026, 12, 31)
        );

        Assert.isTrue(holidays.contains(Date.newInstance(2026, 12, 25)), 'Natal deve estar cadastrado.');
        Assert.isTrue(holidays.contains(Date.newInstance(2026, 11, 20)), 'Consciência Negra deve estar cadastrado.');
        Assert.areEqual(9, holidays.size(), 'São 9 feriados cadastrados para 2026 no metadado.');
    }

    @IsTest
    static void returnsOnlyHolidaysInsideRequestedRange() {
        Set<Date> holidays = new CustomMetadataHolidayProvider().getHolidays(
            Date.newInstance(2026, 4, 1),
            Date.newInstance(2026, 4, 30)
        );

        Assert.areEqual(1, holidays.size());
        Assert.isTrue(holidays.contains(Date.newInstance(2026, 4, 21)), 'Tiradentes.');
    }

    @IsTest
    static void nullRangeReturnsEmptySet() {
        Assert.isTrue(new CustomMetadataHolidayProvider().getHolidays(null, null).isEmpty());
    }
}
