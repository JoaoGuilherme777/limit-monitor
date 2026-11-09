// Agenda o snapshot diário dos limites (substitui o agendamento anterior, se existir).
Id jobId = LimitMonitorScheduler.scheduleSnapshot();
System.debug('JOB_ID=' + jobId);
