/***
*Class          ---- BatchUpdTasksforAccBrand
*Author         ---- Jaseem Pookandy
*Story          ---- CCBOB-195
*Created Date   ---- 2015.12.17
*Description    ---- This is the batch that is called from UpdsObjforAccBrand.page to update Tasks for account brand
----------------------------- Modifications & Updates -----------------------------
*Modified By    ----
*Story          ----
*Modified Date  ---- 
*Description    ---- 
***/
global class BatchUpdTasksforAccBrand implements Database.Batchable<sObject>{
    public string totalbatchsize{get;set;}//input coming from the page
    public string query;
    global BatchUpdTasksforAccBrand(string status,string batchsize,boolean isrecurrence){
        totalbatchsize = batchsize; // batchsize passed from the page is assigned to the totalbatchsize
        if(status == 'Open'){ // called from open activity action method
            if(totalbatchsize!=null && !Test.isRunningTest())
                query = 'Select id from Task where account_brand__c =null and (whatid!=null or whoid!=null) and brand__c !=null and (status= \'Not Started\' OR status = \'In Progress\') and isrecurrence = '+isrecurrence+' LIMIT '+totalbatchsize+' ALL ROWS';
            else if(Test.isRunningTest())
                query = 'Select id from Task where (whatid!=null or whoid!=null) and brand__c !=null and (status= \'Not Started\' OR status = \'In Progress\') LIMIT 10';
        }else if(status == 'Closed'){ // called from the closed activity action method
            if(totalbatchsize!=null && !Test.isRunningTest())
                query = 'Select id from Task where account_brand__c =null and (whatid!=null or whoid!=null) and brand__c !=null and (status= \'Completed\' OR status = \'Cancelled\') and isrecurrence = '+isrecurrence+' LIMIT '+totalbatchsize+' ALL ROWS';
            else if(Test.isRunningTest())
                query = 'Select id from Task where (whatid!=null or whoid!=null) and brand__c !=null and (status= \'Completed\' OR status = \'Cancelled\') LIMIT 10';
        }
    }
    
    global Database.querylocator Start(Database.batchablecontext bc){  
             system.debug('########### query tasks'+query);  
        return Database.getquerylocator(query);
    }
    
      global void Execute(Database.BatchableContext bc,list<Task> Scope){
       
        List<Error__c>Errorlist = new list<Error__c>();
        List<Database.SaveResult> results = Database.update(Scope, false); //Just update the scope because the trigger handler has the logic to populate account brand
        for(integer i=0;i<Scope.size();i++){
            Database.SaveResult s = results[i];
            Task t = Scope[i];
            if(!s.isSuccess()){ // if update is not successful
                for(Database.Error Err : s.getErrors()){
                    Error__c error = new Error__c(Record_ID__c=string.valueof(t.id),Exception_Status_Code__c = string.valueof(Err.getstatuscode()),Exception_Message__c=string.valueof(Err.getmessage()),Object__c = 'Task',Error_fields__c = string.valueof(Err.getfields()),Exception_Source__c = 'BatchUpdTasksforAccBrand'+'-'+string.valueof(Date.today()));
                    Errorlist.add(error); //new error record is inserted with record id, fields, error message captured
                }
            }
        }
        
        insert Errorlist;
        
    }
    
    global void Finish(Database.BatchableContext bc){
        
    }
}