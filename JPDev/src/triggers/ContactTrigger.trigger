/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to ContactTriggerHandler. 
//
// Jan 09, 2013    Naresh Ojha (Appirio Off)    
//
********************************************************************/
trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
  //Handler class 
  ContactTriggerHandler handler = new ContactTriggerHandler 
                                           (Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isBefore){     
    //Handler for before insert 
    handler.OnBeforeInsert(Trigger.new);
  } else if(Trigger.isUpdate && Trigger.isBefore){   
    //Handler for before update trigger
    handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);    
  } else if(Trigger.isInsert && Trigger.isAfter) {
    //Handler for after insert trigger
    handler.OnAfterInsert(Trigger.newMap);
  } else if(Trigger.isUpdate && Trigger.isAfter) {
    //Handler for before update trigger
    handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);    
  }
}