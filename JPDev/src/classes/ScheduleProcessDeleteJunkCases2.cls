//rubel
// Deletes cases there the case is assigned to the 'Email-SPAM/Junk' group


global class ScheduleProcessDeleteJunkCases2 implements Schedulable {

    global void execute(SchedulableContext ctx) {
        
        
        ScheduleProcessDeleteJunkCasesBatch2 sob = new ScheduleProcessDeleteJunkCasesBatch2();
        ID thisBatchJob = database.executebatch(sob); 
    }
}