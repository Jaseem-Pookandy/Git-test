//byrnes

global class ScheduleProcessProvisionedOpp implements Schedulable {

	global void execute(SchedulableContext ctx) {
		
		//This schedulabe class will always call the batch with 'allTime = false'.
		//If all records need to be processed that will be done manually via the developer console.
		
		ScheduleProcessProvisionedOppBatch sob = new ScheduleProcessProvisionedOppBatch(false);
		ID thisBatchJob = database.executebatch(sob); 
	}
}