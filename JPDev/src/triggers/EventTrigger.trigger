/***
*Class          ---- EventTriggerHandlerTest
*Author         ---- Sravya Mogili
*Story          ---- Account Restructure
*Created Date   ---- 2015.12.07
*Description    ---- Test class for the EventTrigger & EventTriggerHandler object
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- 
*Story          ---- 
*Modified Date  ---- 
*Description    ---- 
***/

trigger EventTrigger on Event(before insert, before update, after insert, after update) { 
    EventTriggerHandler handler = new EventTriggerHandler (Trigger.isExecuting, Trigger.size);
    

    if (Trigger.isInsert && Trigger.isBefore)       handler.OnBeforeInsert  (Trigger.new);     
    else if (Trigger.isUpdate && Trigger.isBefore)  handler.OnBeforeUpdate  (Trigger.oldMap, Trigger.newMap);       
    else if (Trigger.isInsert && Trigger.isAfter)   handler.OnAfterInsert   (Trigger.new);
    else if (Trigger.isUpdate && Trigger.isAfter)   handler.OnAfterUpdate   (Trigger.oldMap, Trigger.newMap);

}