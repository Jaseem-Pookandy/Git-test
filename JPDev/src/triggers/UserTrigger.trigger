/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to UserTriggerHandler. 
//
// Jan 08, 2012    Naresh Ojha (Appirio Off)    
//
********************************************************************/
trigger UserTrigger on User (before insert, before update,after update) {
  //Handler class
  UserTriggerHandler handler = new UserTriggerHandler
                                           (Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isBefore){     
    //Handler for before insert
    handler.OnBeforeInsert(Trigger.new);     
  } else if(Trigger.isUpdate && Trigger.isBefore){   
    //Handler for before update trigger
    handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);    
  } else if(Trigger.isUpdate && Trigger.isAfter){
      handler.OnAfterUpdate(Trigger.oldMap,Trigger.newMap);
  }
}