global class ScheduleProcessDeleteJunkCasesBatch2 implements Database.Batchable<sObject>{

   global final String Query;
   
   
   // Gets invoked when the batch job starts. Returns the record 
   // set as a QueryLocator object that will be batched for execution.
   // BC is the jobid
   global Database.QueryLocator start(Database.BatchableContext BC){

      System.debug('Getting the query locator for cases with owner of email-spam/junk');
      
      List<Group> g = [SELECT Id FROM Group WHERE Name = 'Email-SPAM/JUNK' LIMIT 1];
      
      String gr = null;
      
      if (g.size() >0){
          gr = g[0].Id;
      }else {
          return null;
      }


      return Database.getQueryLocator([Select id from Case where OwnerId =: gr]);
     }

   // Gets invoked when the batch job executes and operates on one batch of records. Contains 
   // or calls the main execution logic for the batch job.
   // scope is the batch of records to process
   global void execute(Database.BatchableContext BC, List<sObject> scope){
   
     // List for holding the cases
     List<Case> lCase = new List<Case>();
     
     // For each of the objects in the query
     for(sobject s : scope){ 
         // Add the case to the list 
         // cast s as Case  
         lCase.add((Case) s); 
     }

    // Delete all the cases
     delete lCase;

    }
    // Gets invoked when the batch job finishes. Place any clean up code in this method.
   global void finish(Database.BatchableContext BC){
   }
}