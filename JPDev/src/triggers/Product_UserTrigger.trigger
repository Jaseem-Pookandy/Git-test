/******************************************************************************
// (c) 2013 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to Product_UserTriggerHandler. 
//
// 14 June 2013 : Karun Gangwnani (Appirio Off)
//
******************************************************************************/
trigger Product_UserTrigger on Product_User__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if(Trigger.isInsert && Trigger.isBefore){     
      //Handler for before insert
      //Product_UserTriggerHandler.OnBeforeInsert(Trigger.new);     
    } else if(Trigger.isInsert && Trigger.isAfter){
      //Handler for after insert
      Product_UserTriggerHandler.OnAfterInsert(Trigger.new);       
    } else if(Trigger.isUpdate && Trigger.isAfter){  
      //Handler for after update trigger
      Product_UserTriggerHandler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);    
    } else if(Trigger.isDelete && Trigger.isAfter){   
      //Handler for after Delete trigger
      Product_UserTriggerHandler.OnAfterDelete(Trigger.oldMap);    
    } else if(Trigger.isUpdate && Trigger.isBefore){    
      //Handler for before update trigger
      //Product_UserTriggerHandler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);       
    } else if (Trigger.isDelete && Trigger.isBefore) {     
      //Handler for before Delete trigger
      //Product_UserTriggerHandler.OnBeforeDelete(Trigger.oldMap);    
    } else if(Trigger.isUnDelete && Trigger.isAfter) {     
      //Handler for after Undelete trigger
      Product_UserTriggerHandler.OnAfterUnDelete(Trigger.NewMap);    
    } 

}