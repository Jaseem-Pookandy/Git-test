//byrnes
//2014.01.08

global class ScheduleABStatusMassRecalc implements Schedulable {
	
	global void execute(SchedulableContext ctx) {
		
		ScheduleABStatusMassRecalcBatch abm = new ScheduleABStatusMassRecalcBatch();
		ID thisBatchJob = database.executebatch(abm); 
	}
}