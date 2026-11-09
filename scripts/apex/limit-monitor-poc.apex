// PoC: captura snapshots dos limites e lista os que passam do threshold configurado.
List<Limit_Snapshot__c> snaps = new LimitSnapshotService().captureSnapshots();
System.debug('Snapshots criados: ' + snaps.size());

Map<String, Limit_Threshold__mdt> thresholds = new Map<String, Limit_Threshold__mdt>();
for (Limit_Threshold__mdt t : [SELECT DeveloperName, Threshold_Percent__c, Is_Active__c FROM Limit_Threshold__mdt WHERE Is_Active__c = true]) {
    thresholds.put(t.DeveloperName, t);
}

for (Limit_Snapshot__c s : [SELECT Limit_Name__c, Used__c, Maximum__c, Percent_Used__c FROM Limit_Snapshot__c WHERE Snapshot_Date__c = TODAY AND Maximum__c > 0 ORDER BY Percent_Used__c DESC LIMIT 200]) {
    Limit_Threshold__mdt t = thresholds.get(s.Limit_Name__c);
    Decimal limitPct = (t != null) ? t.Threshold_Percent__c : null;
    String flag = (limitPct != null && s.Percent_Used__c >= limitPct) ? ' <-- ACIMA DO THRESHOLD (' + limitPct + '%)' : '';
    System.debug(s.Limit_Name__c + ': ' + s.Used__c + '/' + s.Maximum__c + ' = ' + s.Percent_Used__c + '%' + flag);
}
