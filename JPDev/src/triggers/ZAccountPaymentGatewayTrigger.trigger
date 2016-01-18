trigger ZAccountPaymentGatewayTrigger on Zuora__CustomerAccount__c (after insert, after update) {
    ZAccountPaymentGatewayTriggerHandler handler = new ZAccountPaymentGatewayTriggerHandler(Trigger.isExecuting, Trigger.size);
    handler.OnAfterInsertUpdate(Trigger.oldMap, Trigger.newMap);   
}