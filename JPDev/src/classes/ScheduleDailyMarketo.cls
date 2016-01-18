global class ScheduleDailyMarketo implements Schedulable{
  global void execute(SchedulableContext sc) {
    ScheduleDailyMarketoBatch mkt = new ScheduleDailyMarketoBatch();
    ID thisBatchJob = database.executebatch(mkt); 
  
  }

}