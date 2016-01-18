/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to AccountTriggerHandler. 
//
// Dec 11, 2012    Naresh Ojha (Appirio Off)    
//
********************************************************************/
trigger AccountTrigger on Account (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    
    AccountTriggerHandler handler = new AccountTriggerHandler
                                           (Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isInsert && Trigger.isBefore){     
      //Handler for before insert
      handler.OnBeforeInsert(Trigger.new);     
    } else if(Trigger.isInsert && Trigger.isAfter){
      //Handler for after insert
      handler.OnAfterInsert(Trigger.newMap);       
    } else if(Trigger.isUpdate && Trigger.isBefore){    
      //Handler for before update trigger
      handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);       
    } else if(Trigger.isUpdate && Trigger.isAfter){   
      //Handler for after update trigger
      handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);    
    } else if (Trigger.isDelete && Trigger.isBefore) {     
      //Handler for before Delete trigger
      //handler.OnBeforeDelete(Trigger.oldMap);    
    } else if (Trigger.isDelete && Trigger.isAfter) {     
      //Handler for After Delete trigger
      //not yet - still dev'ing
      handler.OnAfterDelete(Trigger.oldMap);    
    }
}