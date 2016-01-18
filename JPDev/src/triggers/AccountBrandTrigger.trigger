/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to AccountBrandTriggerHandler. 
//
// Dec 12, 2012    Naresh Ojha (Appirio Off)    
//
********************************************************************/
trigger AccountBrandTrigger on Account_Brand__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    
    AccountBrandTriggerHandler handler = new AccountBrandTriggerHandler
                                           (Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isBefore){     
      //Handler for before insert
      handler.OnBeforeInsert(Trigger.new);     
    } else if(Trigger.isInsert && Trigger.isAfter){
      //Handler for after insert
      handler.OnAfterInsert(Trigger.new);       
    } else if(Trigger.isUpdate && Trigger.isAfter){   
      //Handler for after update trigger
      handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);    
    } else if(Trigger.isDelete && Trigger.isAfter){   
      //Handler for after Delete trigger
      handler.OnAfterDelete(Trigger.oldMap);    
    } else if(Trigger.isUpdate && Trigger.isBefore){    
      //Handler for before update trigger
      handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);       
    } else if (Trigger.isDelete && Trigger.isBefore) {     
      //Handler for before Delete trigger
      handler.OnBeforeDelete(Trigger.oldMap);    
    }
  
/*------------Handling the after update logic------------------*/  
  if(Trigger.isUpdate && Trigger.isAfter){
      String ownerId = UserInfo.getUserId();
      AccountBrandTriggerHandler.updateOnwerAssigned('AccountBrands', trigger.newmap.keyset());
  }
}