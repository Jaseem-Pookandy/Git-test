/***
*Class          ---- BatchUpdzCLineItemforAccBrand
*Author         ---- Jaseem Pookandy
*Story          ---- CCBOB-194
*Created Date   ---- 2015.12.15
*Description    ---- This is the batch that is called from UpdsObjforAccBrand.page to update zContract Line Item for account brand
----------------------------- Modifications & Updates -----------------------------

***/
global class BatchUpdzCLineItemforAccBrand implements Database.Batchable<SObject>{
    public string totalbatchsize{get;set;} //input from the page
    global Database.querylocator Start(Database.batchablecontext bc){  
        String query;

        if (totalbatchsize == null && !Test.isRunningTest()) {
            query = 'Select id,Brand__c from Zuora__SubscriptionProductCharge__c where Zuora__Account__c!=null and brand__c !=null and Zuora__RatePlanName__c!=null and Zuora__ProductName__c!=null and account_brand__c =null LIMIT 100';
        }
        else if (totalbatchsize !=null && !Test.isRunningTest()) {
            query = 'Select id,Brand__c from Zuora__SubscriptionProductCharge__c where Zuora__Account__c!=null and brand__c !=null and Zuora__RatePlanName__c!=null and Zuora__ProductName__c!=null and account_brand__c =null LIMIT '+totalbatchsize;
        }
        else query = 'Select id,Brand__c from Zuora__SubscriptionProductCharge__c where Zuora__Account__c!=null and brand__c !=null and Zuora__RatePlanName__c!=null and Zuora__ProductName__c!=null LIMIT 10';     
       
        return Database.getquerylocator(query);
    }
    
    global void Execute(Database.BatchableContext bc,list<Zuora__SubscriptionProductCharge__c> Scope){
       
        List<Error__c>Errorlist = new list<Error__c>();
        List<Database.SaveResult> results = Database.update(Scope, false);
        for(integer i=0;i<Scope.size();i++){
            Database.SaveResult s = results[i];
            Zuora__SubscriptionProductCharge__c zlineitem = Scope[i];
            if(!s.isSuccess()){ // if update is not successful
                
                for(Database.Error Err : s.getErrors()){
                    Error__c error = new Error__c(Record_ID__c=string.valueof(zlineitem.id),Exception_Status_Code__c = string.valueof(Err.getstatuscode()),Exception_Message__c=string.valueof(Err.getmessage()),Object__c = 'zContract Line Item',Error_fields__c = string.valueof(Err.getfields()),Exception_Source__c = 'BatchUpdzCLineItemforAccBrand'+'-'+string.valueof(Date.today()));
                    
                    Errorlist.add(error); //new error record is inserted with record id, fields, error message captured
                }
            }
            
        }
        
        insert Errorlist;
        
    }
    
    global void Finish(Database.BatchableContext bc){
        
    }
}