/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to SubscriptionProductChargeTriggerHandler. 
//
// Feb 08, 2012    Naresh Ojha (Appirio Off)    
********************************************************************/
trigger SubscriptionProductChargeTrigger on Zuora__SubscriptionProductCharge__c (
                                                                                                        before insert, before update, 
                                                                                                        after insert, after update,
                                                                                                        before delete, after delete) {
    //Handler
    SubscriptionProductChargeTriggerHandler handler = 
            new SubscriptionProductChargeTriggerHandler (Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isBefore){
    //Handler for after insert
    handler.OnBeforeInsert(Trigger.new);        
  } else if(Trigger.isUpdate && Trigger.isBefore){   
    //Handler for after update trigger
    handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);     
  } else if(Trigger.isInsert && Trigger.isAfter){ 
    //Handler for after insert
    handler.OnAfterInsert(Trigger.new);        
  } else if(Trigger.isUpdate && Trigger.isAfter){   
    //Handler for after update trigger
    handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);     
  } else if(Trigger.isDelete && Trigger.isBefore){   
    //Handler for after update trigger
    handler.OnBeforeDelete(Trigger.oldMap);     
  }

}