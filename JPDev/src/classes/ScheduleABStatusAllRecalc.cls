global class ScheduleABStatusAllRecalc implements Schedulable {
  
  global void execute(SchedulableContext ctx) {
    
    ScheduleABStatusAllRecalcBatch abm = new ScheduleABStatusAllRecalcBatch();
    ID thisBatchJob = database.executebatch(abm); 
  }
}