global class SchedulePaymentLinksExpirationBatch implements Database.Batchable<sObject> {
    
    global String soql;
    
    global SchedulePaymentLinksExpirationBatch() {
        
        soql = 'SELECT Id, Processed_by_Batch__c, Status__c FROM Payment_Link__c WHERE Status__c = \'Expired\' AND Processed_by_Batch__c = null';

    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(soql);
    }
    
    //execute
    global void execute(Database.BatchableContext BC, List<Payment_Link__c> scope) {

    	CCCaptureUtilities.ProcessExpiredPaymentLinks(scope);

    }

    //finish
    global void finish(Database.BatchableContext BC) {
    	//nothing here... yet... possibly email admin upon failure?
    }
}