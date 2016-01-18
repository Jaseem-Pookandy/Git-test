// (c) 2012 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  SubscriptionTrigger. 
//                                  All contexts should be in this class.
//                  
// Feb 08th, 2012  :  Naresh Ojha
//***************************************************************************/
public class SubscriptionTriggerHandler {

  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  
  //Constructor
  public SubscriptionTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

  // On before delete trigger method
  public void OnBeforeDelete (Map<Id, Zuora__Subscription__c> oldMap) {
    Set<String> acIDset = new Set<String>();
    for (Zuora__Subscription__c spc : oldMap.values()) {
        if (spc.Zuora__Account__c <> null) acIDset.add(spc.Zuora__Account__c);
    } 
    if (!acIDset.isEmpty()) CommonUtil.recallABstatus(acIDset, true);
  }
    
    //On after insert trigger method
  public void OnAfterInsert(List<Zuora__Subscription__c> newList) { 
    Set<String> acIDset = new Set<String>();
    for (Zuora__Subscription__c spc : newList) {
        if (spc.Zuora__Account__c <> null) {
            acIDset.add(spc.Zuora__Account__c);
        }
    } 
    if (!acIDset.isEmpty()) {
        CommonUtil.recallABstatus(acIDset, true);
    }
    populateZuoraSubscriptionOnOpp (newList);
  }  
  
  // On after update trigger method
  public void OnAfterUpdate (Map<Id, Zuora__Subscription__c> oldMap, Map<Id, Zuora__Subscription__c> newMap) {

    Set<String> acIDset = new Set<String>();
    Set<Id> zSubIDs = new Set<Id>();

    Map<Id, Zuora__Subscription__c> zSubIDsForRenewalOpps = new Map<Id, Zuora__Subscription__c>();    //cc-1698

    for (Zuora__Subscription__c spc : newMap.values()) {
        if (spc.Zuora__Account__c <> null) acIDset.add(spc.Zuora__Account__c);
        
        //If the service end date is populated & it changed (to earlier only), then queue it to recalc the opp. Renewal date.
        if (spc.ServiceEndDate__c != null && oldMap.get(spc.Id).ServiceEndDate__c != null && spc.ServiceEndDate__c < oldMap.get(spc.Id).ServiceEndDate__c)  zSubIDs.add(spc.Id);    //byrnes

        if (spc.ServiceEndDate__c != null && oldMap.get(spc.Id).ServiceEndDate__c != null && spc.ServiceEndDate__c != oldMap.get(spc.Id).ServiceEndDate__c) {
          if (!zSubIDsForRenewalOpps.containsKey(spc.Id)) zSubIDsForRenewalOpps.put(spc.Id, spc);
        } 
    }

    if (!acIDset.isEmpty()) CommonUtil.recallABstatus(acIDset, true);
    
    populateZuoraSubscriptionOnOpp (newMap.values());

    if (!zSubIDs.isEmpty()) UpdateOpportunityRenewalDate(zSubIDs);      //byrnes

    if (!zSubIDsForRenewalOpps.Values().isEmpty()) UpdateRenewalOppsCloseDate(zSubIDsForRenewalOpps); //cc-1698, scenario 2
  }

  
  //CC-1698 - Byrnes, scenario 2
  private void UpdateRenewalOppsCloseDate(Map<Id, Zuora__Subscription__c> zSubMap) {

    List<Opportunity> oppsToUpdate = new List<Opportunity>();
    List<Zuora__Subscription__c> oppsToCreate = new List<Zuora__Subscription__c>();

    //first ID is the zcontract - the second ID is the renewal opp
    Map<Id, Id> zsubToRenewalOppMap = new Map<Id, Id>();

    Set<Id> renewalOppIDs = new Set<Id>();

    for (Opportunity thisOpp : [SELECT Id, Renewal_Opportunity__c, Renewal_Feedback__c, Renewal_Opportunity__r.Id, Renewal_Opportunity__r.CloseDate, Renewal_Opportunity__r.IsClosed, ZuoraSubscription__c FROM Opportunity WHERE ZuoraSubscription__c IN :zSubMap.keySet()]) {

      //If the opp's renewal opp exists, update the close date for it as long as it isn't itself already closed.
      if (thisOpp.Renewal_Opportunity__c != null && thisOpp.Renewal_Opportunity__r.IsClosed == false) {
        Opportunity updatedOpp = new Opportunity(Id = thisOpp.Renewal_Opportunity__r.Id);
        updatedOpp.CloseDate = zSubMap.get(thisOpp.ZuoraSubscription__c).ServiceEndDate__c;
        oppsToUpdate.add(updatedOpp);
      }
      //If the opp's renewal opp does NOT exist, create it. (This is effectively here for the data loader and processing historical records to create those opps only.  Shouldn't be executed on a consistent basis...)
      else if (thisOpp.Renewal_Opportunity__c == null && thisOpp.Renewal_Feedback__c == 'Not Submitted' && zSubMap.containsKey(thisOpp.ZuoraSubscription__c)) oppsToCreate.add(zSubMap.get(thisOpp.ZuoraSubscription__c));
    }

    if (oppsToUpdate.size() > 0) update oppsToUpdate;
    //if (oppsToCreate.size() > 0) BeginAutoRenewalOppLogic(oppsToCreate);  //triggering scenario 1 if necessary
  }
  
  //CC-526 - Byrnes - This updates the necessary field(s) so that the opportunity's renewal date is correct if/when the Contract's service end date is changed to earlier.
  private void UpdateOpportunityRenewalDate(Set<Id> zSubIDs) {
    
    //We're updating the Contract's Subscription End Date as that is referenced in the Opportunity.Renewal Date formula.
    List<Zuora__Subscription__c> subsToUpdate = new List<Zuora__Subscription__c>();
    
    for (Zuora__Subscription__c sub : [SELECT Id, Zuora__SubscriptionEndDate__c, ServiceEndDate__c FROM Zuora__Subscription__c WHERE Id IN :zSubIDs]) {
        sub.Zuora__SubscriptionEndDate__c = sub.ServiceEndDate__c.addDays(1);
    }
  }
  
  //I-57840 Refactored to Use Subscription.Name
  //eFC-Webstore - Godfrey - Added Opportunity Type Webstore to include eFC Webstore when updating Subscription Id
  private void populateZuoraSubscriptionOnOpp (List<Zuora__Subscription__c> newList) {
    Set<String> zSubsIDs = new Set<String>();
    Map<String, Zuora__Subscription__c> zSubMap = new Map<String, Zuora__Subscription__c>();
    List<Opportunity> opptyListToUpdate = new List<Opportunity>();
    
    for (Zuora__Subscription__c zSubs : newList) {
        zSubsIDs.add(zSubs.Zuora__Zuora_Id__c);
        if (!zSubMap.containsKey(zSubs.Zuora__Zuora_Id__c)) zSubMap.put(zSubs.Zuora__Zuora_Id__c, zSubs);

        zSubsIDs.add(zSubs.Name);
        if (!zSubMap.containsKey(zSubs.Name)) zSubMap.put(zSubs.Name, zSubs);
    }
    
    //Populating fields on opportunity
    for (Opportunity oppty : [SELECT ID, ZuoraSubscription__c, Webstore_Order__c,
                               Validation_Rule_Override__c, SyncedQuote__c,
                               Webstore_Order__r.Zuora_Subscription_ID__c,
                               SyncedQuote__r.zqu__ZuoraSubscriptionID__c, 
                               SyncedQuote__r.Zuora_Subscription_Name__c,
                               Name
                               FROM Opportunity 
                               WHERE ZuoraSubscription__c = Null 
                               AND (Webstore_Order__r.Zuora_Subscription_ID__c IN : zSubsIDs 
                                     OR SyncedQuote__r.Zuora_Subscription_Name__c IN : zSubsIDs
                                     OR Name IN : zSubsIDs)]) {

    if (oppty.Webstore_Order__c <> null && oppty.Webstore_Order__r.Zuora_Subscription_ID__c <> null &&
              zSubMap.containsKey(oppty.Webstore_Order__r.Zuora_Subscription_ID__c)) {
        
        oppty.Validation_Rule_Override__c = System.now();
        oppty.ZuoraSubscription__c = zSubMap.get(oppty.Webstore_Order__r.Zuora_Subscription_ID__c).ID;
        opptyListToUpdate.add(oppty);        
      } else if (oppty.SyncedQuote__c <> null && oppty.SyncedQuote__r.Zuora_Subscription_Name__c <> null &&
              zSubMap.containsKey(oppty.SyncedQuote__r.Zuora_Subscription_Name__c)) {
        oppty.Validation_Rule_Override__c = System.now();
        oppty.ZuoraSubscription__c = zSubMap.get(oppty.SyncedQuote__r.Zuora_Subscription_Name__c).ID;
        opptyListToUpdate.add(oppty);
      } else if(zSubMap.containsKey(oppty.Name)){
        oppty.Validation_Rule_Override__c = System.now();
        oppty.ZuoraSubscription__c = zSubMap.get(oppty.Name).ID;          
        opptyListToUpdate.add(oppty);
      }

    }

    //Updating list of opportunities.
    if (!opptyListToUpdate.isEmpty()) {
        update opptyListToUpdate;
    }
  }  
  
  /* //T-122888 populate Opportunity.ZuoraSubscription  -- REFACTORED
  private void populateZuoraSubscriptionOnOpp (List<Zuora__Subscription__c> newList) {
    Set<String> zSubsIDs = new Set<String>();
    Map<String, Zuora__Subscription__c> zSubMap = new Map<String, Zuora__Subscription__c>();
    List<Opportunity> opptyListToUpdate = new List<Opportunity>();
    
    for (Zuora__Subscription__c zSubs : newList) {
        zSubsIDs.add(zSubs.Zuora__Zuora_Id__c);
        if (!zSubMap.containsKey(zSubs.Zuora__Zuora_Id__c)) {
          zSubMap.put(zSubs.Zuora__Zuora_Id__c, zSubs);
        }
    }
    
    //Populating fields on opportunity
    for (Opportunity oppty : [SELECT ID, ZuoraSubscription__c, Webstore_Order__c,
                               Validation_Rule_Override__c, SyncedQuote__c,
                               Webstore_Order__r.Zuora_Subscription_ID__c,
                               SyncedQuote__r.zqu__ZuoraSubscriptionID__c 
                               FROM Opportunity 
                               WHERE ZuoraSubscription__c = Null 
                               AND (Webstore_Order__r.Zuora_Subscription_ID__c IN : zSubsIDs 
                                     OR SyncedQuote__r.zqu__ZuoraSubscriptionID__c IN : zSubsIDs)]) {

      if (oppty.Webstore_Order__c <> null && oppty.Webstore_Order__r.Zuora_Subscription_ID__c <> null &&
              zSubMap.containsKey(oppty.Webstore_Order__r.Zuora_Subscription_ID__c)) {
        
        oppty.Validation_Rule_Override__c = System.now();
        oppty.ZuoraSubscription__c = zSubMap.get(oppty.Webstore_Order__r.Zuora_Subscription_ID__c).ID;
        opptyListToUpdate.add(oppty);
      } else if (oppty.SyncedQuote__c <> null && oppty.SyncedQuote__r.zqu__ZuoraSubscriptionID__c <> null &&
              zSubMap.containsKey(oppty.SyncedQuote__r.zqu__ZuoraSubscriptionID__c)) {
        oppty.Validation_Rule_Override__c = System.now();
        oppty.ZuoraSubscription__c = zSubMap.get(oppty.SyncedQuote__r.zqu__ZuoraSubscriptionID__c).ID;
        opptyListToUpdate.add(oppty);
      }
    }

    //Updating list of opportunities.
    if (!opptyListToUpdate.isEmpty()) {
        update opptyListToUpdate;
    }
  }
  */
}