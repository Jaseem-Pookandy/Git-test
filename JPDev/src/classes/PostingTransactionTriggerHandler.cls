public with sharing class PostingTransactionTriggerHandler{
 
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
    
  //Constructor
  public PostingTransactionTriggerHandler(boolean isExecuting, integer size){
      m_isExecuting = isExecuting;
      BatchSize = size;
  }
      
  //On after insert trigger method
  public void OnAfterInsert(List<Posting_Transaction__c> newList) {  
      updateLastTransaction(newList);
  }
    
  //Set the last transaction detail 
  //on the JobBot detail record
    private void updateLastTransaction(List<Posting_Transaction__c> newList){
        
        Set<ID> BotIDset = new Set<ID>();
        List<Automated_Posting__c> BOTupdate = new List<Automated_Posting__c>();
        Map<Id, Automated_Posting__c> botUpdateMap = new Map<Id, Automated_Posting__c>();
        
        for (Posting_Transaction__c trans : newList) {
            BotIDset.add(trans.Automated_Posting__c);
        }
        
        for (Automated_Posting__c BOT : [SELECT ID, Latest_Transaction__c, Latest_Transaction_Date_Time__c
                              FROM Automated_Posting__c
                              WHERE ID IN : BotIDset]) {
                                  for (Posting_Transaction__c tran : newList){
                                      if ((tran.Automated_Posting__c == BOT.ID)&&(tran.Date_Time__c > BOT.Latest_Transaction_Date_Time__c || BOT.Latest_Transaction_Date_Time__c == null)) {

                                          BOT.Latest_Transaction__c = tran.ID;
                                          if (!botUpdateMap.containsKey(BOT.Id)) botUpdateMap.put(BOT.Id, BOT);
                                          else if (botUpdateMap.get(BOT.Id).Latest_Transaction_Date_Time__c < tran.Date_Time__c) botUpdateMap.put(BOT.Id, BOT);

                                      }                                        
                                    }
                                  }
                              
        if (botUpdateMap.values().size() > 0) update botUpdateMap.values();
            //update BOTupdate;
        
    }
}