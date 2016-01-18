//Byrnes

trigger ContactTypeTrigger on Contact_Type__c (after insert, after update, before insert, before update) 
{
  //Handler class 
  ContactTypeTriggerHandler handler = new ContactTypeTriggerHandler(Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isBefore){     
    //Handler for before insert
    //nothing here yet, just stubbed... 
    //handler.OnBeforeInsert(Trigger.new);     
  } else if(Trigger.isUpdate && Trigger.isBefore){   
    //Handler for before update trigger   
    handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
  } else if(Trigger.isInsert && Trigger.isAfter) {
    //Handler for after insert trigger
    handler.OnAfterInsert(Trigger.newMap);
  } else if(Trigger.isUpdate && Trigger.isAfter) {
    //Handler for before update trigger
    handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);  
  } else if (Trigger.isDelete && Trigger.isAfter) {     
      handler.OnAfterDelete(Trigger.oldMap);
  }
}