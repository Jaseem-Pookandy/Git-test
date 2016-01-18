/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to TaskTriggerHandler. 
//
// March 03rd, 2013    Naresh Ojha (Appirio Off)    
********************************************************************/
trigger TaskTrigger on Task (before insert, before update, after insert, after update) { 
    TaskTriggerHandler handler = new TaskTriggerHandler (Trigger.isExecuting, Trigger.size);
    

    if (Trigger.isInsert && Trigger.isBefore)       handler.OnBeforeInsert  (Trigger.new);     
    else if (Trigger.isUpdate && Trigger.isBefore)  handler.OnBeforeUpdate  (Trigger.oldMap, Trigger.newMap);       
    else if (Trigger.isInsert && Trigger.isAfter)   handler.OnAfterInsert   (Trigger.new);
    else if (Trigger.isUpdate && Trigger.isAfter)   handler.OnAfterUpdate   (Trigger.oldMap, Trigger.newMap);

}