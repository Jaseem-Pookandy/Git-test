/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to SubscriptionTriggerHandler. 
//
// Feb 08, 2012    Naresh Ojha (Appirio Off)    
********************************************************************/
trigger SubscriptionTrigger on Zuora__Subscription__c (after delete, after insert, after update, 
before delete) {
    //Handler
    SubscriptionTriggerHandler handler = 
            new SubscriptionTriggerHandler (Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isAfter){   
    //Handler for after update trigger
    handler.OnAfterInsert(Trigger.new);         
  } else if(Trigger.isUpdate && Trigger.isAfter){ 
    //Handler for after insert
    handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);        
  } else if(Trigger.isDelete && Trigger.isBefore){   
    //Handler for after update trigger
    handler.OnBeforeDelete(Trigger.oldMap);     
  }
}