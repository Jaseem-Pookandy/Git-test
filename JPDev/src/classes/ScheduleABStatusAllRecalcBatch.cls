global class ScheduleABStatusAllRecalcBatch implements Database.Batchable <sObject> {
  
  global String soql;
  
  //Constructor
  global ScheduleABStatusAllRecalcBatch() {
    
    soql = 'SELECT Zuora__Account__c FROM Zuora__SubscriptionProductCharge__c';
  }
  
  //'Start'
  global Database.QueryLocator start(Database.BatchableContext bcMain) {
    return Database.getQueryLocator(soql);
  }
  
  //'Execute'
  global void execute(Database.BatchableContext bcMain, List<Zuora__SubscriptionProductCharge__c> subsToProcess) {
    
    Set<String> accountIDSet = new Set<String>();
    
    for (Zuora__SubscriptionProductCharge__c sub : subsToProcess) {
      accountIDSet.add(sub.Zuora__Account__c);
    }
    
    CommonUtil.recallABstatus(accountIDSet, false);
  }
  
  //'Finish'
  global void finish(Database.BatchableContext bcMain) {
    //nothing here... yet... possibly email admin upon failure?
  }

}