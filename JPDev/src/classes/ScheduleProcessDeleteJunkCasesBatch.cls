global class ScheduleProcessDeleteJunkCasesBatch implements Database.Batchable<sObject>{

   global final String Query;
   
   global Database.QueryLocator start(Database.BatchableContext BC){

      List<Group> g = [SELECT Id FROM Group WHERE Name = 'Email-SPAM/JUNK' LIMIT 1];
      
      String gr = null;
      
      if (g.size() >0){
          gr = g[0].Id;
      }else {
          return null;
      }
      Date dCheckDate = Date.today().AddDays(-30);
      return Database.getQueryLocator([Select id from Case where (ClosedDate < LAST_N_DAYS:30 AND Status = 'Junk/Spam') OR OwnerId = :gr]);
     }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
     List<Case> lCase = new List<Case>();
     for(sobject s : scope){    
     lCase.add((Case) s); 
     }

     delete lCase;

    }

   global void finish(Database.BatchableContext BC){
   }
}