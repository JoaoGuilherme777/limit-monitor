/** Job diário: grava um snapshot por limite da org. */
public with sharing class LimitSnapshotJob implements Schedulable {
    public void execute(SchedulableContext context) {
        new LimitSnapshotService().captureSnapshots();
    }
}
