public with sharing class OrgLimitsProvider implements ILimitProvider {
    public List<LimitReading> getReadings() {
        List<LimitReading> readings = new List<LimitReading>();
        for (System.OrgLimit orgLimit : System.OrgLimits.getAll()) {
            readings.add(new LimitReading(orgLimit.getName(), orgLimit.getValue(), orgLimit.getLimit()));
        }
        return readings;
    }
}
