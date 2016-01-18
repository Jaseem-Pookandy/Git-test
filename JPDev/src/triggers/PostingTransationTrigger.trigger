trigger PostingTransationTrigger on Posting_Transaction__c (after insert) {
   
    PostingTransactionTriggerHandler handler = new PostingTransactionTriggerHandler
                                           (Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isInsert && Trigger.isAfter){
      //Handler for after insert
      handler.OnAfterInsert(Trigger.new);  
    }
}