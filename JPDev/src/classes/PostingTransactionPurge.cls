global class PostingTransactionPurge implements Database.Batchable<sobject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator([Select Id, Transaction_Count__c, Transactions_Exceeding_Limit__c, Number_of_Saved_Transactions__c from Automated_Posting__c]);
    }
     
    global void execute(Database.BatchableContext BC, List<Automated_Posting__c> scope){
        List<Automated_Posting__c> jobbots = new List<Automated_Posting__c>();
        for (sobject s :scope){
           jobbots.add((Automated_Posting__c) s);
        }
           
        List<Posting_Transaction__c> transList = new List<Posting_Transaction__c>();
        List<Posting_Transaction__c> transListtoDel = new List<Posting_Transaction__c>();
        Map<String, Double> bot_IDlimit_Map = new Map<String, Double>();
        Map<String, Integer> bot_incr_Map = new Map<String, Integer>();
        Set<Id> botIDSet = new Set<Id>();
        Double incr = 0;
        Double total = 0;
        
        for (Automated_Posting__c bots : jobbots) {
            if (!bot_IDlimit_Map.containsKey(bots.Id)) {
                bot_IDlimit_Map.put(bots.Id, bots.Number_of_Saved_Transactions__c);
                bot_incr_Map.put(bots.Id, 0);
                botIDSet.add(bots.Id);
            }
        }
        
        transList = [Select Id, Automated_Posting__c, Date_Time__c FROM Posting_Transaction__c where Automated_Posting__c IN :botIDSet ORDER BY Date_Time__c DESC];
        
        for (Posting_Transaction__c trans : transList) {
            total = bot_IDlimit_Map.get(trans.Automated_Posting__c);
            Integer curIncr = bot_incr_Map.get(trans.Automated_Posting__c);
            curIncr++;
            bot_incr_Map.put(trans.Automated_Posting__c, curIncr);
            if (bot_incr_Map.get(trans.Automated_Posting__c) > total) transListtoDel.add(trans);
        }
        
        if (!transListtoDel.isEmpty()) {
          delete transListtoDel;
        }
        
        
    }
    
    global void finish(Database.BatchableContext BC){
    }
}