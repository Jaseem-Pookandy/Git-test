global class batchMaskAltEmail implements Database.Batchable<sObject>{
    
    public String appendText{get; set;}
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query;
        if(!Test.isRunningTest()) query = 'SELECT Id,Name,Alternate_Email__c FROM Contact WHERE Alternate_Email__c != null';
        else query = 'SELECT Id,Name,Alternate_Email__c FROM Contact WHERE Alternate_Email__c != null LIMIT 5';
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Contact> scope)
    {
         for(Contact c : scope)
         {
             c.Alternate_Email__c = c.Alternate_Email__c + appendText;            
         }
         update scope;
    }   
    global void finish(Database.BatchableContext BC)
    {
    }

}