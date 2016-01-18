/***
*Class          ---- BatchUpdCasesforAccBrand
*Author         ---- Jaseem Pookandy
*Story          ---- CCBOB-192
*Created Date   ---- 2015.12.11
*Description    ---- This is the batch that is called from UpdsObjforAccBrand.page to update Cases for account brand
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Pookandy
*Story          ---- CCBOB-192
*Modified Date  ---- 2015.12.15
*Description    ----  added code to cover error handling.
***/
global class BatchUpdCasesforAccBrand implements Database.batchable<SObject>{
    
    public string totalbatchsize{get;set;}//input coming from the page
   
    global Database.querylocator Start(Database.batchablecontext bc){  
        String query;
        if(totalbatchsize == null && !Test.isRunningTest()){
            query = 'Select id, accountid,contactid,brand__c,account.name,contact.account.name from Case where (accountid!=null or Contactid!=null) and brand__c !=null and account_brand__c =null LIMIT 100';
        }else if(totalbatchsize !=null && !Test.isRunningTest()){
            query = 'Select id,accountid,contactid,brand__c,account.name,contact.account.name from Case where (accountid!=null or Contactid!=null) and brand__c !=null and account_brand__c =null LIMIT '+totalbatchsize;
        }else query = 'Select id,accountid,contactid,brand__c,account.name,contact.account.name from Case where (accountid!=null or Contactid!=null) and brand__c !=null LIMIT 10';     
       
        return Database.getquerylocator(query);
    }
    
    global void Execute(Database.BatchableContext bc,list<Case> Scope){
       
        List<Error__c>Errorlist = new list<Error__c>();
        List<Database.SaveResult> results = Database.update(Scope, false); //Just update the scope because the trigger handler has the logic to populate account brand
        for(integer i=0;i<Scope.size();i++){
            Database.SaveResult s = results[i];
            Case c = Scope[i];
            if(!s.isSuccess()){ // if update is not successful
                for(Database.Error Err : s.getErrors()){
                   Error__c error = new Error__c(Record_ID__c=string.valueof(c.id),Exception_Status_Code__c = string.valueof(Err.getstatuscode()),Exception_Message__c=string.valueof(Err.getmessage()),Object__c = 'Case',Error_fields__c = string.valueof(Err.getfields()),Exception_Source__c = 'BatchCaseUpdateforAccBrand'+'-'+string.valueof(Date.today()));
                   Errorlist.add(error); //new error record is inserted with record id, fields, error message captured
                }
            }
        }
        
        insert Errorlist;
        
    }
    
    global void Finish(Database.BatchableContext bc){
        
    }
    
}