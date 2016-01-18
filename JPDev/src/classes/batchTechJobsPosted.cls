/*******************************************************************
// 
// Class to process Number of Tech Jobs Posted and reset  if more than 90 days since updated
//
// Created: 8/29/2014    Mike Bergman     
********************************************************************/
global class batchTechJobsPosted implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,Tech_Jobs_Posted__c,Tech_Jobs_Posted_Updated__c FROM Account WHERE Tech_Jobs_Posted_Updated__c < LAST_90_DAYS';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        for(Account a : scope) {
            a.Tech_Jobs_Posted__c = Null;
        }
        update scope;
    }
    
    global void finish(Database.BatchableContext BC) {
    }    
}