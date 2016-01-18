global class ScheduleDailyMarketoUser implements Schedulable{
  global void execute(SchedulableContext sc) {
    ScheduleDailyMarketoUserBatch mkt = new ScheduleDailyMarketoUserBatch();
    ID thisBatchJob = database.executebatch(mkt); 
  
  }

}