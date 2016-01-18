// Byrnes
// 2015.04.17

public with sharing class PaymentLinkTriggerHandler {
	private boolean m_isExecuting = false;
	private Integer batchSize = 0;

	//Constructor
	public PaymentLinkTriggerHandler(Boolean isExecuting, Integer size) {
		m_isExecuting = isExecuting;
		batchSize = size;
	}

	//On before insert trigger method
	public void OnBeforeInsert(List<Payment_Link__c> newList) { 
	

	}  

	// On before update trigger method
	public void OnBeforeUpdate (Map<Id, Payment_Link__c> oldMap, Map<Id, Payment_Link__c> newMap) {

	}

	//On After insert trigger method
	public void OnAfterInsert(List<Payment_Link__c> newList) { 

		InsertInitialHistoryRecord(newList);
		SetTheToken(newList);

		RollupToOpportunity(newList);

	}

	// On After update trigger method
	public void OnAfterUpdate (Map<Id, Payment_Link__c> oldMap, Map<Id, Payment_Link__c> newMap) {

		RollupToOpportunity(newMap.values());

	}

	// On after before trigger method
	public void OnBeforeDelete (Map<Id, Payment_Link__c> oldMap) {

	}

	// On after delete trigger method
	public void OnAfterDelete (Map<Id, Payment_Link__c> oldMap) {		

	}

	////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////

	private void SetTheToken(List<Payment_Link__c> newList) {

		List<Payment_Link__c> linksToUpdate = new List<Payment_Link__c>();
		PaymentLinkCryptoKey__c thisKey = PaymentLinkCryptoKey__c.getInstance(CCCaptureUtilities.CC_PRIVATE_KEY);

		if (thisKey == null) return;  	//If we didn't find the specific key we're looking for, quit.

		for (Payment_Link__c pl : newList) {
			if (pl.Token__c != null) continue;		//never change an existing token once populated.  Also crucial as without this it would loop infinitely.
			else {
				Payment_Link__c thisPL = new Payment_Link__c(Id = pl.Id);		//Can't update the record directly as, well, trigger is after.  Can't use before trigger as the Id isn't populated yet.
				thisPL.Token__c = CCCaptureUtilities.EncryptText(thisKey.Key__c, pl.Id);
				linksToUpdate.add(thisPL);
			}
		}

		if (!linksToUpdate.isEmpty()) update linksToUpdate;
	}

	private void InsertInitialHistoryRecord(List<Payment_Link__c> newList) {

		List<Payment_Link_History__c> historyToInsert = new List<Payment_Link_History__c>();

		for (Payment_Link__c pl : newList) {

			Payment_Link_History__c plh = ReturnNewLinkHistoryRecord(pl.Id, 'Created', 'Salesforce.com');
			historyToInsert.add(plh);
		}

		if (!historyToInsert.isEmpty()) insert historyToInsert;
	}

	public static Payment_Link_History__c ReturnNewLinkHistoryRecord(Id paymentLinkId, String action, String source) {

		Payment_Link_History__c plh = new Payment_Link_History__c();
		plh.Payment_Link__c = paymentLinkId;
		plh.Action__c = action;
		plh.Source_IP__c = source;

		return plh;
	}

	private void RollupToOpportunity(List<Payment_Link__c> newList) {

		Set<Id> oppIds = new Set<Id>();
		List<Opportunity> oppListToUpdate = new List<Opportunity>();
		Map<Id, List<Payment_Link__c>> oppPLMap = new Map<Id, List<Payment_Link__c>>();		
		Map<String, PaymentLinkStatusHierarchy__c> hierMap = new Map<String, PaymentLinkStatusHierarchy__c>();			//String (key) here is the name

		for (Payment_Link__c pl : newList) {
			oppIds.add(pl.Opportunity__c);

			if (!oppPLMap.containsKey(pl.Opportunity__c)) oppPLMap.put(pl.Opportunity__c, new List<Payment_Link__c>());
			oppPLMap.get(pl.Opportunity__c).add(pl);
		}

		//We now have a map of all opportunities and the newly inserted/updated link.
		//Now it's time we go get the rest for inclusion and processing...

		for (Payment_Link__c pl : [SELECT IsExcluded__c, Opportunity__c, Status_Workflow__c, Status__c, Name, CreatedDate FROM Payment_Link__c WHERE IsExcluded__c = FALSE AND Opportunity__c IN :oppIds]) {

			if (!oppPLMap.containsKey(pl.Opportunity__c)) oppPLMap.put(pl.Opportunity__c, new List<Payment_Link__c>());
			oppPLMap.get(pl.Opportunity__c).add(pl);

		}

		Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Payment_Status__c, Payment_Link_Cutoff__c FROM Opportunity WHERE Id IN :oppIds]);

		//Now get the hierarchy of values...
		for (PaymentLinkStatusHierarchy__c plsh : [SELECT Id, Name, Sort_Order__c FROM PaymentLinkStatusHierarchy__c ORDER BY Sort_Order__c]) {
			hierMap.put(plsh.Name, plsh);
		}

		//We now have all that we need to set the Opportunity's Payment Status field
		Boolean bOppChanged = false;

		for (Opportunity o : oppMap.values()) {

			bOppChanged = false;

			if (oppPLMap.containsKey(o.Id)) {

				Integer iOrigValue = 1;
				Integer iPotentialNewValue = 1;

				//Get the numerical values of the old and (potential) new value to see if one trumps the other...
				//if (o.Payment_Status__c != null && hierMap.containsKey(o.Payment_Status__c)) iOrigValue = Integer.valueOf(hierMap.get(o.Payment_Status__c).Sort_Order__c);				

				for (Payment_Link__c pl : oppPLMap.get(o.Id)) {
					if (o.Payment_Status__c != pl.Status__c) {
						
						if (hierMap.containsKey(pl.Status__c)) iPotentialNewValue = Integer.valueOf(hierMap.get(pl.Status__c).Sort_Order__c);

						//If the new value trumps the old value OR if the new value is created AFTER the cutoff on the opportunity if not null
						if ((iPotentialNewValue > iOrigValue) || (o.Payment_Link_Cutoff__c != null && (pl.CreatedDate > o.Payment_Link_Cutoff__c) || (pl.Id == null))) {
							bOppChanged = true;
							iOrigValue = iPotentialNewValue;
							o.Payment_Status__c = pl.Status__c;

							//If it's complete, then record the date/time on the opp so we know where the cutoff lies
							if (pl.Status__c == 'Complete') o.Payment_Link_Cutoff__c = Datetime.now();
						}						
					}
				}
			}
			if (bOppChanged) oppListToUpdate.add(o);			
		}

		if (!oppListToUpdate.isEmpty()) update oppListToUpdate;
	}
}