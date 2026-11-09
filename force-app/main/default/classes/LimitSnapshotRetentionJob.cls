/** Job semanal: dispara o batch de retenção. */
public with sharing class LimitSnapshotRetentionJob implements Schedulable {
    public void execute(SchedulableContext context) {
        Database.executeBatch(new LimitSnapshotRetentionBatch(), 2000);
    }
}
