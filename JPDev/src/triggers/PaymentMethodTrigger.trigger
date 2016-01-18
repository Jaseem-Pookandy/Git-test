/***
*Class 			---- PaymentMethodTrigger
*Author 		---- Tim Byrnes
*Story 			---- CCBOB-92
*Created Date 	---- 2015.11.10
*Description 	---- Trigger for Zuora's Payment Method object
----------------------------- Modifications & Updates -----------------------------
*Modified By 	---- 
*Story 			---- 
*Modified Date 	---- 
*Description 	---- 
***/

trigger PaymentMethodTrigger on Zuora__PaymentMethod__c (before insert, before update, before delete, after insert, after update, after delete) {
	PaymentMethodTriggerHandler handler = new PaymentMethodTriggerHandler (Trigger.isExecuting, Trigger.size);
 
    if (Trigger.isInsert && Trigger.isBefore) {
        //Handler for before insert
      	handler.OnBeforeInsert(Trigger.new);     
    } 

    else if (Trigger.isUpdate && Trigger.isBefore) {    
      	//Handler for before update trigger
      	handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);  
    }

    else if (Trigger.isDelete && Trigger.isBefore) {     
    	//Handler for before delete trigger
      	handler.OnBeforeDelete(Trigger.oldMap);    
    }

    else if (Trigger.isInsert && Trigger.isAfter) {
      	//Handler for after insert
      	handler.OnAfterInsert(Trigger.newMap);            
    } 

    else if (Trigger.isUpdate && Trigger.isAfter) {   
      	//Handler for after update trigger
      	handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);    
    } 

    else if (Trigger.isDelete && Trigger.isAfter) {     
      	//Handler for After delete trigger
      	handler.OnAfterDelete(Trigger.oldMap);    
    }
}