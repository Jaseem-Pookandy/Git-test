global class ScheduleDailyPreMarketo implements Schedulable{
  global void execute(SchedulableContext sc) {
    ScheduleDailyPreMarketoBatch mkt = new ScheduleDailyPreMarketoBatch();
    ID thisBatchJob = database.executebatch(mkt); 
  
  }

}