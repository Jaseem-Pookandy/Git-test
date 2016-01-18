/*******************************************************************
// (c) 2013 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to zqu__QuoteTrigger.trigger 
//
// Jan 18, 2013    Naresh Ojha (Appirio Off)    
********************************************************************/
trigger zquQuoteTrigger on zqu__Quote__c (after insert, after update, before insert, before update) {
  //Handler class
  zquQuoteTriggerHandler handler = new zquQuoteTriggerHandler
                                           (Trigger.isExecuting, Trigger.size);
  
  if (Trigger.isInsert && Trigger.isAfter) {
    //Handler for After insert
    handler.OnAfterInsert (Trigger.newMap);     
  } else if(Trigger.isUpdate && Trigger.isAfter) {   
    //Handler for After update trigger
    handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
        
  } else if (Trigger.isInsert && Trigger.isBefore) {
    //Handler for before insert
    handler.OnBeforeInsert (Trigger.new);     
  } else if(Trigger.isUpdate && Trigger.isBefore) {   
    //Handler for before update trigger
    handler.OnBeforeUpdate(Trigger.oldMap, Trigger.new);
    	// Section for setting a Global Deal on Quote for Amendments, when the Trigger is Before Update
    	//Shawn Xuereb: This will be used in a future release for amendments. Please don't delete.
	    /*
	    for (zqu__Quote__c myQuote : Trigger.new){
	    	if(myQuote.zqu__SubscriptionType__c == 'Amend Subscription' || myQuote.zqu__SubscriptionType__c == 'Renew Subscription'){
	    	
	    		if(!myQuote.IsFutureContext__c){	                               
	        		myQuote.IsFutureContext__c = true;
	            	ClassForGlobalDealTriggerForQuote gdtfq = new ClassForGlobalDealTriggerForQuote(String.valueOf(myQuote.Id));
				}
			}
	    } // end of Global Deal section
	    */    
  }
}