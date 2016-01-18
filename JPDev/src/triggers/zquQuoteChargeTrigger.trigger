/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to zqu__QuoteTrigger.trigger 
//
// Jan 22, 2012    Naresh Ojha (Appirio Off)    
********************************************************************/
trigger zquQuoteChargeTrigger on zqu__QuoteCharge__c (before insert, before update, 
                                                      after insert, after update, 
                                                      after delete, before delete) {
  //Handler class
  zquQuoteChargeTriggerHandler handler = new zquQuoteChargeTriggerHandler
                                           (Trigger.isExecuting, Trigger.size);
  
  if (Trigger.isInsert && Trigger.isAfter) {
    //Handler for After insert
    handler.OnAfterInsert (Trigger.newMap);     
  } else if(Trigger.isUpdate && Trigger.isAfter) {   
    //Handler for After update trigger
    handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);    
  } else if(Trigger.isDelete && Trigger.isBefore) {
    //Handler for After update trigger
    handler.OnAfterDelete(Trigger.oldMap);    
  } else if(Trigger.isInsert && Trigger.isBefore) {
    //Handler for before insert trigger
    handler.OnBeforeInsert(Trigger.new);    
  } else if(Trigger.isUpdate && Trigger.isBefore) {
    //Handler for before update trigger
    handler.OnBeforeUpdate(Trigger.oldMap, Trigger.new);    
  }
}