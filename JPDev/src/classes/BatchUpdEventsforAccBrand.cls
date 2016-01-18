/***
*Class          ---- BatchUpdEventsforAccBrand
*Author         ---- Jaseem Pookandy
*Story          ---- CCBOB-195
*Created Date   ---- 2015.12.17
*Description    ---- This is the batch that is called from UpdsObjforAccBrand.page to update Events for account brand
----------------------------- Modifications & Updates -----------------------------
*Modified By    ----
*Story          ----
*Modified Date  ---- 
*Description    ---- 
***/
global class BatchUpdEventsforAccBrand implements Database.batchable<SObject>{
    public string totalbatchsize{get;set;} //input from the page UpdsObjforAccBrand
    public boolean isrecurrence{get;set;}
     global Database.querylocator Start(Database.batchablecontext bc){  
        String query;
        if(totalbatchsize == null && !Test.isRunningTest()){
            query = 'Select id from Event where (whatid!=null or whoid!=null) and brand__c !=null and account_brand__c =null and isrecurrence = '+isrecurrence+' LIMIT 100';
        }else if(totalbatchsize !=null && !Test.isRunningTest()){
            query = 'Select id from Event where (whatid!=null or whoid!=null) and brand__c !=null and account_brand__c =null and isrecurrence = '+isrecurrence+' LIMIT '+totalbatchsize+' ALL ROWS';
        }else query = 'Select id from Event where (whatid!=null or whoid!=null) and brand__c !=null LIMIT 10';     
       system.debug('############ query Events '+query);
        return Database.getquerylocator(query);
    }
    
    global void Execute(Database.BatchableContext bc,list<Event> Scope){
       
        List<Error__c>Errorlist = new list<Error__c>();
        List<Database.SaveResult> results = Database.update(Scope, false); //Just update the scope because the trigger handler has the logic to populate account brand
        for(integer i=0;i<Scope.size();i++){
            Database.SaveResult s = results[i];
            Event e = Scope[i];
            if(!s.isSuccess()){ // if update is not successful
                for(Database.Error Err : s.getErrors()){
                    Error__c error = new Error__c(Record_ID__c=string.valueof(e.id),Exception_Status_Code__c = string.valueof(Err.getstatuscode()),Exception_Message__c=string.valueof(Err.getmessage()),Object__c = 'Event',Error_fields__c = string.valueof(Err.getfields()),Exception_Source__c = 'BatchUpdEventsforAccBrand'+'-'+string.valueof(Date.today()));
                    Errorlist.add(error); //new error record is inserted with record id, fields, error message captured
                }
            }
        }
        
        insert Errorlist;
        
    }
    
    
    global void Finish(Database.BatchableContext bc){
        
    }
}