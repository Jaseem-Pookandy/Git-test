global class batchMaskLeadEmail implements Database.Batchable<sObject>{
    
    public String appendText{get; set;}
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query;
        if(!Test.isRunningTest()) query = 'SELECT Id,Name,Email FROM Lead WHERE Email != null';
        else query = 'SELECT Id,Name,Email FROM Lead WHERE Email != null LIMIT 5';
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Lead> scope)
    {
         for(Lead c : scope)
         {
             c.Email = c.Email + appendText;            
         }
         update scope;
    }   
    global void finish(Database.BatchableContext BC)
    {
    }

}