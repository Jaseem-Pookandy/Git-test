/***
*Class          ---- CustomerFeedbackTrigger
*Author         ---- Tim Byrnes
*Story          ---- Account Restructure
*Created Date   ---- 2015.12.07
*Description    ---- Trigger for the Customer Feedback object
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- 
*Story          ---- 
*Modified Date  ---- 
*Description    ---- 
***/

trigger CustomerFeedbackTrigger on Customer_Feedback__c(before insert, before update, before delete, after insert, after update, after delete) {

	CustomerFeedbackTriggerHandler handler = new CustomerFeedbackTriggerHandler (Trigger.isExecuting, Trigger.size);
	 
    if (Trigger.isInsert && Trigger.isBefore) {     
		//Handler for before insert
		handler.OnBeforeInsert(Trigger.new);     
    } 
 
    else if (Trigger.isUpdate && Trigger.isBefore) {    
		//Handler for before update trigger
		handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);  
    } 
 
    else if (Trigger.isDelete && Trigger.isBefore) {     
		//Handler for before Delete trigger
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
		//Handler for After Delete trigger
		handler.OnAfterDelete(Trigger.oldMap);    
    }
}