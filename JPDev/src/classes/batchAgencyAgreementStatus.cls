/*******************************************************************
// 
// Class to process Agency Agreements and mark expired agreements as 'Inactive'.
//
// Created: 8/15/2014    Mike Bergman     
********************************************************************/
global class batchAgencyAgreementStatus implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,Status__c,Start_Date__c,End_Date__c FROM Agency_Agreement__c';
        return Database.getQueryLocator(query);
    }
	
    global void execute(Database.BatchableContext BC, List<Agency_Agreement__c> scope) {
         
         for(Agency_Agreement__c a : scope)
         {
             //
             if (a.Status__c == 'Active') {
                 if (a.Start_Date__c > System.today() || a.End_Date__c < System.today()) {
                     a.Status__c = 'Inactive';
                 }
             }    
             else {
                 if (a.Start_Date__c <= System.today() && a.End_Date__c >= System.today()) {
                     a.Status__c = 'Active';
                 }  
             }               
         }
         update scope;
    }   
    
    global void finish(Database.BatchableContext BC) {
    }
}