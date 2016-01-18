/***
*Class          ---- BatchUpdCustFBforAccBrand
*Author         ---- Jaseem Pookandy
*Story          ---- CCBOB-193
*Created Date   ---- 2015.12.11
*Description    ---- This is the batch that is called from UpdsObjforAccBrand.page to update customer feedback for account brand
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Pookandy
*Story          ---- CCBOB-193
*Modified Date  ---- 2015.12.15
*Description    ----  added code to cover error handling.
***/
global class BatchUpdCustFBforAccBrand implements Database.batchable<SObject>{
    public string totalbatchsize{get;set;} //input coming from the page
    global Database.querylocator Start(Database.batchablecontext bc){  
        String query;
        if(totalbatchsize == null && !Test.isRunningTest()){
            query = 'Select id,Primary_Brand__c from Customer_Feedback__c where (account__c!=null or Contact__c!=null) and primary_brand__c !=null and account_brand__c =null LIMIT 100';
        }else if(totalbatchsize !=null && !Test.isRunningTest()){
            query = 'Select id,Primary_Brand__c from Customer_Feedback__c where (account__c!=null or Contact__c!=null) and primary_brand__c !=null and account_brand__c =null LIMIT '+totalbatchsize;
        }else query = 'Select id,Primary_Brand__c from Customer_Feedback__c where (account__c!=null or Contact__c!=null) and primary_brand__c !=null LIMIT 10';     
       
        return Database.getquerylocator(query);
    }
    
    global void Execute(Database.BatchableContext bc,list<Customer_Feedback__c> Scope){
       
         List<Error__c>Errorlist = new list<Error__c>();
        List<Database.SaveResult> results = Database.update(Scope, false);//Just update the scope because the trigger handler has the logic to populate account brand
        
         for(integer i=0;i<Scope.size();i++){
            Database.SaveResult s = results[i];
            Customer_feedback__c CF = Scope[i];
            if(!s.isSuccess()){ // if update is not successful
                for(Database.Error Err : s.getErrors()){
                    Error__c error = new Error__c(Record_ID__c=string.valueof(CF.id),Exception_Status_Code__c = string.valueof(Err.getstatuscode()),Exception_Message__c=string.valueof(Err.getmessage()),Object__c = 'Customer Feedback',Error_fields__c = string.valueof(Err.getfields()),Exception_Source__c = 'BatchUpdCustFBforAccBrand'+'-'+string.valueof(Date.today()));
                    Errorlist.add(error); //new error record is inserted with record id, fields, error message captured
                }
            }
        }
        
        insert Errorlist;
        
    }
    
    global void Finish(Database.BatchableContext bc){
        
    }
    
}