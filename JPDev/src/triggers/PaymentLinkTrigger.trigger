// Byrnes
// 2015.04.17

trigger PaymentLinkTrigger on Payment_Link__c(before insert, after insert, before update, after update, before delete, after delete) {

	PaymentLinkTriggerHandler handler = new PaymentLinkTriggerHandler(Trigger.isExecuting, Trigger.size);

	if (Trigger.isInsert && Trigger.isBefore) {
    	//Handler for before insert
      	handler.OnBeforeInsert(Trigger.new);
    } 
    else if (Trigger.isInsert && Trigger.isAfter) {
    	//Handler for after insert
      	handler.OnAfterInsert(Trigger.new);       
    }
    else if (Trigger.isUpdate && Trigger.isBefore) {
      	//Handler for before update trigger
      	handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);       
    } 
    else if (Trigger.isUpdate && Trigger.isAfter) {
      	//Handler for after update trigger
      	handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
    else if (Trigger.isDelete && Trigger.isBefore) {
      	//Handler for before Delete trigger
      	handler.OnBeforeDelete(Trigger.oldMap);    
    } 
    else if (Trigger.isDelete && Trigger.isAfter) {
      	//Handler for after Delete trigger
      	handler.OnAfterDelete(Trigger.oldMap); 
    }
}