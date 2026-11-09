public with sharing class LimitSnapshotService {
    private final ILimitProvider provider;

    public LimitSnapshotService(ILimitProvider provider) {
        this.provider = provider;
    }

    public LimitSnapshotService() {
        this(new OrgLimitsProvider());
    }

    /** Grava um snapshot por limite e devolve os registros criados. */
    public List<Limit_Snapshot__c> captureSnapshots() {
        DateTime now = DateTime.now();
        Date today = Date.today();
        List<Limit_Snapshot__c> snapshots = new List<Limit_Snapshot__c>();

        for (LimitReading reading : provider.getReadings()) {
            snapshots.add(new Limit_Snapshot__c(
                Limit_Name__c = reading.name,
                Used__c = reading.used,
                Maximum__c = reading.maximum,
                Captured_At__c = now,
                Snapshot_Date__c = today
            ));
        }

        // Job interno: grava em modo de sistema. A leitura de usuários é protegida
        // por WITH USER_MODE/permission set, não pela gravação do job.
        Database.insert(snapshots, true, AccessLevel.SYSTEM_MODE);
        return snapshots;
    }
}
