global class ScheduleProcessProvisionedOppBatch implements Database.Batchable <sObject> {
    
    global String soql;
    
    //Constructor
    global ScheduleProcessProvisionedOppBatch(Boolean allTime) {
        
        //if 'allTime' is either true or false.  If false, the WHERE clause differs slightly...
        
        if (allTime) soql = 'SELECT Id, Provisioning_Completed_Date__c, Credit_Card_Entry_Date__c, Cardholder_Name__c, Credit_Card_Number__c, SyncedQuote__r.Id, SyncedQuote__r.BrandTag__c, SyncedQuote__r.zqu__Currency__c, SyncedQuote__r.Payment_Gateway__c, SyncedQuote__r.Contract_End_Date_Apex__c FROM Opportunity WHERE SyncedQuote__c != null AND Provisioning_Completed_Date__c < LAST_N_DAYS:7 AND Credit_Card_Entry_Date__c < LAST_N_DAYS:7';
        else soql =         'SELECT Id, Provisioning_Completed_Date__c, Credit_Card_Entry_Date__c, Cardholder_Name__c, Credit_Card_Number__c, SyncedQuote__r.Id, SyncedQuote__r.BrandTag__c, SyncedQuote__r.zqu__Currency__c, SyncedQuote__r.Payment_Gateway__c, SyncedQuote__r.Contract_End_Date_Apex__c FROM Opportunity WHERE SyncedQuote__c != null AND Provisioning_Completed_Date__c < LAST_N_DAYS:7 AND Credit_Card_Entry_Date__c < LAST_N_DAYS:7';
        
    }
    
    //"Start"
    global Database.QueryLocator start(Database.BatchableContext bcMain) {
        return Database.getQueryLocator(soql);
    }
    
    //"Execute"
    global void execute(Database.BatchableContext bcMain, List<Opportunity> listRecords) {
        
        ScheduleProcessProvisionedOppLogic.ClearApplicableCreditCards(listRecords);

    }

    //Finish
    global void finish(Database.BatchableContext bcMain) {
        //email results, etc?
    }
}