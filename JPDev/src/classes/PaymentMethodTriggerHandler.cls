/***
*Class 			---- PaymentMethodTriggerHandler
*Author 		---- Tim Byrnes
*Story 			---- CCBOB-92
*Created Date 	---- 2015.11.10
*Description 	---- Initial creation for logic to populate the 'Provided By' field based on data in the remittance link.
----------------------------- Modifications & Updates -----------------------------
*Modified By 	---- 
*Story 			---- 
*Modified Date 	---- 
*Description 	---- 
***/

public with sharing class PaymentMethodTriggerHandler {

    private boolean m_isExecuting = false;  
  	private integer BatchSize = 0;
 
	//Constructor
	public PaymentMethodTriggerHandler(boolean isExecuting, integer size) {
		m_isExecuting = isExecuting;
		BatchSize = size;
	}  

	//On Before insert trigger method
	public void OnBeforeInsert(List<Zuora__PaymentMethod__c> newList) {   
	
		PopulateProvidedBy(newList);

	}

	// On Before update trigger method
	public void OnBeforeUpdate(Map<Id, Zuora__PaymentMethod__c> oldMap, Map<Id, Zuora__PaymentMethod__c> newMap) {    
	
	}

	// On Before update trigger method
	public void OnBeforeDelete(Map<Id, Zuora__PaymentMethod__c> oldMap) {    
	
	}	

	//On after insert trigger method
	public void OnAfterInsert(Map<Id, Zuora__PaymentMethod__c> newMap) {   
	
	}  

	// On after update trigger method
	public void OnAfterUpdate(Map<Id, Zuora__PaymentMethod__c> oldMap, Map<Id, Zuora__PaymentMethod__c> newMap) {    
	
	}

	// On after update trigger method
	public void OnAfterDelete(Map<Id, Zuora__PaymentMethod__c> oldMap) {    
	
	}  

	private void PopulateProvidedBy(List<Zuora__PaymentMethod__c> newList) {

		Set<String> paymentMethodZuoraIdSet = new Set<String>();
		Map<String, Payment_Link__c> paymentLinkMap = new Map<String, Payment_Link__c>();

		for (Zuora__PaymentMethod__c zpm : newList) {
			if (zpm.Zuora__External_Id__c != null) paymentMethodZuoraIdSet.add(zpm.Zuora__External_Id__c);
		}

		for (Payment_Link__c pl : [SELECT 
										Id, 
										Link_Created_For__c, 
										Zuora_Payment_Method_Id__c 
									FROM Payment_Link__c 
									WHERE Zuora_Payment_Method_Id__c IN : paymentMethodZuoraIdSet AND
										Link_Created_For__c != null]) {

			paymentLinkMap.put(pl.Zuora_Payment_Method_Id__c, pl);

		}

		for (Zuora__PaymentMethod__c zpm : newList) {
			if (zpm.Zuora__External_Id__c != null && paymentLinkMap.containsKey(zpm.Zuora__External_Id__c) && paymentLinkMap.get(zpm.Zuora__External_Id__c).Link_Created_For__c != null) {

				zpm.Provided_By__c = paymentLinkMap.get(zpm.Zuora__External_Id__c).Link_Created_For__c;
				//This is called from 'on before insert' so no DML is needed here...

			}
		}
	}	// End of PopulateProvidedBy method

} // End of PaymentMethodTriggerHandler class