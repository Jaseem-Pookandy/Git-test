/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to EmailMessageTriggerHandler. 
//
// Feb 11, 2012    Naresh Ojha (Appirio Off)    
********************************************************************/
trigger EmailMessageTrigger on EmailMessage (after insert, before insert) {
  EmailMessageTriggerHandler handler = new EmailMessageTriggerHandler
                                           (Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isAfter){     
    //Handler for before insert
    handler.OnAfterInsert(Trigger.new);       
  } else if (Trigger.isInsert && Trigger.isBefore) {
    //Handler for before before
    handler.OnBeforeInsert(Trigger.new);  	
  }
}