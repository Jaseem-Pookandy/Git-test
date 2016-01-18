global class ScheduleTechJobsUpdate implements Schedulable {
  global void execute(SchedulableContext ctx) {
    
    batchTechJobsPosted tjp = new batchTechJobsPosted();
    ID thisBatchJob = database.executebatch(tjp); 
  }
}