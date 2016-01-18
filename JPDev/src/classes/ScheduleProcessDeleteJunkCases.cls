//bergman

global class ScheduleProcessDeleteJunkCases implements Schedulable {

    global void execute(SchedulableContext ctx) {
        
        
        ScheduleProcessDeleteJunkCasesBatch sob = new ScheduleProcessDeleteJunkCasesBatch();
        ID thisBatchJob = database.executebatch(sob); 
    }
}