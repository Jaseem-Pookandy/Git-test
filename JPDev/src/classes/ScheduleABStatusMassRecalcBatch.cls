global class ScheduleABStatusMassRecalcBatch implements Database.Batchable <sObject> {
	
	global String soql;
	
	//Constructor
	global ScheduleABStatusMassRecalcBatch() {
		//This will return the IDs whose last service end date is either today or yesterday.
		//We could change this to TODAY only if we're getting close to limits, but this has a little bit of redundancy which is nice as long as the limits aren't a problem (and they shouldn't be).
		//soql = 'SELECT Zuora__Account__c FROM Zuora__SubscriptionProductCharge__c WHERE Zuora__Subscription__r.ServiceEndDate__c = TODAY GROUP BY Zuora__Account__c';
		
		soql = 'SELECT Zuora__Account__c FROM Zuora__SubscriptionProductCharge__c WHERE Zuora__Subscription__r.ServiceEndDate__c = LAST_N_DAYS:1 OR Zuora__EffectiveStartDate__c = TOMORROW';
	}
	
	//'Start'
	global Database.QueryLocator start(Database.BatchableContext bcMain) {
		return Database.getQueryLocator(soql);
	}
	
	//'Execute'
	global void execute(Database.BatchableContext bcMain, List<Zuora__SubscriptionProductCharge__c> subsToProcess) {
		
		Set<String> accountIDSet = new Set<String>();
		
		for (Zuora__SubscriptionProductCharge__c sub : subsToProcess) {
			accountIDSet.add(sub.Zuora__Account__c);
		}
		
		CommonUtil.recallABstatus(accountIDSet, false);
	}
	
	//'Finish'
	global void finish(Database.BatchableContext bcMain) {
		//nothing here... yet... possibly email admin upon failure?
	}

}