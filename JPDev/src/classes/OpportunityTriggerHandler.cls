/***************************************************************************
// (c) 2013 Appirio, Inc. 
//
// Description    : Class that contains all of the functionality called by the 
//                  OpportunityTrigger. All contexts should be in this class.
//                  
// Jan 23rd, 2013  :  Naresh Ojha (Appirio Offshore)
// Aug 31st, 2013  :  Karun Gangwani added for I-66298 
// Oct 15th, 2013  :  Byrnes - CC-590
//***************************************************************************
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Jaseem Pookandy
*Story          ---- CCBOB - 95 & CCBOB - 189 
*Modified Date  ---- 2016.10.04
*Description    ---- Added new logic to fire OnBeforeInsert and onAfterupdate
***/
public with sharing class OpportunityTriggerHandler {
    private boolean m_isExecuting = false;  
    private integer BatchSize = 0;
  
      //Constructor
      public OpportunityTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
      }
      
    //---------------------------------------------------------------------------
    // OnBeforeInsert
    //---------------------------------------------------------------------------
    public void OnBeforeInsert(List<Opportunity> newList) { 

        //Byrnes, 2014.04.29 - CC-2355
        //As Webstore opps are inserted closed, this sub needs to be called upon insertion, not just update.
        CampaignSelectionForOppty (newList, null);
        
        //CC-865
        SetAccountBrandFields(newList, null);
        
        DefaultAgencyPercent (newList, null);        
        
    }
      
      //---------------------------------------------------------------------------
      // OnAfterInsert
      //---------------------------------------------------------------------------
      public void OnAfterInsert(List<Opportunity> newList) { 
       
        updateContactRole (newList, new Map<ID, Opportunity>());      
        populateRenewalOpportunity (newList);

      }  

      //---------------------------------------------------------------------------
      // OnAfterUpdate
      //---------------------------------------------------------------------------
      public void OnAfterUpdate (List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        handler_qlick.isOpportunityNotExecuted = false;
        updateContactRole (newList, oldMap);  
        Set<String> optyIDsForTeam = new Set<String>();
        Set<Id> sourceOppsToSyncRenewalOwner = new Set<Id>();
        
        
        
        
        //SravyaMogili, 2015.12.12** CCBOB-95 Start**//
         Map<string,Boolean> MapCountry = new Map<string,Boolean>(); // map that distinguish countries that are eurozone (VAT only suggested) vs non eurozone but VAT required
        list<Account> UpdAccountlist = new list<Account>();//update account for Eurozone without VAT checkbox when its checked
        Set<Id>AccountIds = new Set<ID>();
        Set<Id> OpportunityIDSet = new Set<Id>();
        Set<Id> OpportunityIDFeedItem = new Set<Id>();
        set<string> Eurozonecountryset = new set<string>();
        for(pw_ccpro__CountryObject__c country : [select Name,Part_of_Eurozone__c,Require_GST_VAT_Tax__c from pw_ccpro__CountryObject__c WHERE 
                                                  Part_of_Eurozone__c =true or Require_GST_VAT_Tax__c = true
                                                ]) {
            EurozoneCountrySet.add(country.Name);
            //Maps ......
            if(country.Require_GST_VAT_Tax__c == true)
                MapCountry.put(country.name,country.Require_GST_VAT_Tax__c);
            else if(country.Part_of_Eurozone__c == true)
                MapCountry.put(country.name,country.Require_GST_VAT_Tax__c);
            
        }
        system.debug('bbbb'+EurozoneCountrySet);

        //set<String> EurozoneCountrySet = new Set<String>{'Austria','Belgium','Bulgaria','Croatia','Republic of Cyprus','Czech Republic','Denmark','Estonia','Finland','France','Germany','Greece','Hungary','Ireland','Italy','Latvia','Lithuania','Luxembourg','Malta','Netherlands','Poland','Portugal','Romania','Slovak Republic','Slovenia','Spain','Sweden','Australia','United Kingdom'};
        List<zqu__Quote__c> QuotesList = new List<zqu__Quote__c>();
        List<zqu__Quote__c> UpdQuotesList = new List<zqu__Quote__c>();
        Map<ID,Boolean>MapOpps = new Map<ID,Boolean>();//Map to distinguish opp beween those which require VAT# and those which do not
        
        
        for(Opportunity o : newList){ 
          if((o.IsWon == True) && (o.IsClosed == true) && (oldMap.get(o.Id).IsWon == false) && (oldMap.get(o.Id).IsClosed == false) && (o.GST_VAT_Tax__c == null)){
            OpportunityIDSet.add(o.Id);
          }
          
        }
        
        
        system.debug('aaaa'+OpportunityIDSet);
        
        if(!OpportunityIDSet.IsEmpty()){
            Map<String, BrandTag_VAT__c> countries = BrandTag_VAT__c.getAll();
            Set<String> brandNames = new Set<String>();
            brandNames.addAll(countries.keySet());          
            QuotesList = [select IsSyncing__c,zqu__Opportunity__c,
              zqu__SoldToContact__c,zqu__SoldToContact__r.MailingCountry from zqu__Quote__c where zqu__Opportunity__c 
              in: OpportunityIDSet and IsSyncing__c=true and BrandTag__c IN :brandNames];
        }
        
        if(!QuotesList.IsEmpty()){
          for(zqu__Quote__c QuoteObj: QuotesList){      
             if(QuoteObj.zqu__SoldToContact__c!=null){
               if(QuoteObj.zqu__SoldToContact__r.MailingCountry !=null){
               // if(EurozoneCountrySet.contains(QuoteObj.zqu__SoldToContact__r.MailingCountry)){
                //   OpportunityIDFeedItem.add(QuoteObj.zqu__Opportunity__c);
               // }
                   if(MapCountry.containsKey(QuoteObj.zqu__SoldToContact__r.MailingCountry)){                       
                        MapOpps.put(QuoteObj.zqu__Opportunity__c,MapCountry.get(QuoteObj.zqu__SoldToContact__r.MailingCountry));
                        QuoteObj.Require_VAT__c = MapCountry.get(QuoteObj.zqu__SoldToContact__r.MailingCountry) == true? 'YES' : 'NO';
                        UpdQuotesList.add(QuoteObj);
                   }
               
               }
             
            }
          }
        }
        
        if(!MapOpps.IsEmpty()){
         
         OpportunityMethods.createFeedCommentOnOpportunity(MapOpps);
        }
        
        update UpdQuotesList;
        
        /****************** CCBOB-95 End********************/
        
        for(Opportunity op : newList) {
            if (op.IsClosed == true && op.IsWon == true && op.isTeam_Added__c == false && op.Provisioning_Status__c <> null && op.Provisioning_Status__c == Constants.STATUS_COMPLETE && op.IsMigrated__c == false) optyIDsForTeam.add(op.ID);
        }
        
        if (optyIDsForTeam.size() > 0) populateOppTeamForCloseWonOpps(optyIDsForTeam);

        //CC-2125, Scenario 1
        SyncQuoteLineSalesRepsWithNewOppOwner(newList, oldMap);

        //CC-2125, Scenario 2
        SyncRenewalOwnerWithRPCLI(newList, oldMap);

        //CC-1698 / 2844
        List<Opportunity> oppsForRenewal = new List<Opportunity>();
        for (Opportunity o : newList) {
          //if it is just now closed won where it wasn't before AND there is not renewal opp
          if ((o.IsWon == true) && (o.IsClosed == true) && (oldMap.get(o.Id).IsWon == false) && (oldMap.get(o.Id).IsClosed == false) && (o.Renewal_Opportunity__c == null)) {
            oppsForRenewal.add(o);
          }
        }

        if (!oppsForRenewal.isEmpty()) BeginAutoRenewalOppLogic(oppsForRenewal);
        //CC-1698 / 2844


        //CC-1698, Scenario 2b - If the renewal owner is initially populate or edited, the owner of the renewal opp (if already created & not closed) should be updated to match.
        Map<Id, Id> newOwnerMap = new Map<Id, Id>();    //key is the opp ID, value is the new Renewal Owner ID
        for(Opportunity op : newList) {
            if (op.Renewal_Owner_Assigned__c != null && op.Renewal_Owner_Assigned__c != oldMap.get(op.Id).Renewal_Owner_Assigned__c && op.Renewal_Opportunity__c != null) {
              if (!newOwnerMap.containsKey(op.Id)) newOwnerMap.put(op.Id, op.Renewal_Owner_Assigned__c);
              //sourceOppsToSyncRenewalOwner.add(op.ID);
            }
        }
        
        if (newOwnerMap.size() > 0) SyncRenewalOwnerWithRenewalOpp(newOwnerMap);
        //End of CC-1698, Scenario 2b 

        //CC-3366 start
        List<Opportunity> oppListwithNewAccounts = new List<Opportunity>();

        for (Opportunity o : newList) {
          if (oldMap.containsKey(o.Id) && o.AccountId != oldMap.get(o.Id).AccountId) {
            //Then the opportunity was moved to a different account, we need to fix Zuora's crappy data structure because they obviously aren't.
            oppListwithNewAccounts.add(o);
          }
        }
        if (!oppListwithNewAccounts.isEmpty()) UpdateApplicableQuotes(oppListwithNewAccounts);
        //CC-3366 end
        
        //If this is now Closed/Won and the approval source is Electronic (DocuSign) then we should send paymentlinks/remittance links      
        List<Opportunity> oppsForPaymentLink = new List<Opportunity>();

        for (Opportunity o : newList) {

          //if it is just now closed won where it wasn't before AND there is not renewal opp AND it isn't a webstore opportunity (onePost approval source is email so that's automatically weeded out.)
          //Due to the order of Docusign processing things, I'm now just checking the old value of Approval Source instead of prior value of Closed & Won.
          if ((o.IsWon == true) && (o.IsClosed == true) && (o.Approval_Source__c == 'Electronic') && (oldMap.get(o.Id).Approval_Source__c != 'Electronic') && (o.Credit_Card_Flag__c == true) && (o.Webstore_Order__c == null)) {
            oppsForPaymentLink.add(o);
          }
        }

        if (!oppsForPaymentLink.isEmpty()) ProcessPaymentLinkLogic(oppsForPaymentLink);
      }

      //---------------------------------------------------------------------------
      // OnBeforeUpdate
      //---------------------------------------------------------------------------
    public void OnBeforeUpdate (List<Opportunity> newList, Map<Id, Opportunity> oldMap) {

      //CC-3366 (workflow skip) start
      for (Opportunity o : newList) {
        if (oldMap.containsKey(o.Id) && o.AccountId != oldMap.get(o.Id).AccountId) o.Bypass_State_Model_Workflows__c = true;
      }
      //CC-3366 (workflow skip) end

      //Now the the brand fields are read-only for (most) users, keep them in sync with the owner in case if that changes...
      SyncOppBrandFieldsWithOwner(newList, oldMap);

      //CC-865
      SetAccountBrandFields(newList, oldMap);
  
      //CC-2626
      DefaultAgencyPercent (newList, oldMap);      
     
         
      Set<Id> oppIdListToConsiderTasks = new Set<Id>();       //cc-590
      Set<Id> oppIdListToConsiderCases = new Set<Id>();       //cc-590
  
      for (Opportunity op : newList) {
        if ((op.IsClosed == true) && (op.IsWon == true) && ((op.Provisioning_Status__c == Constants.STATUS_COMPLETE) || (op.Provisioning_Status__c == Constants.STATUS_PROVISIONED))) {

            if (op.TrainingTasksCreated__c == false) {
                oppIdListToConsiderTasks.add(op.Id);
                op.TrainingTasksCreated__c = true;    
            }

            if (op.CSCaseConsidered__c == false) {
                oppIdListToConsiderCases.add(op.Id);
                op.CSCaseConsidered__c = true;                
            }        
        }
      }    

      if (oppIdListToConsiderTasks.size() > 0) Utils_OpportunityProvision.OpptyCreateTasks(oppIdListToConsiderTasks);
      if (oppIdListToConsiderCases.size() > 0) Utils_OpportunityProvision.OpptyCreateCases(oppIdListToConsiderCases);

    } 

    private void UpdateApplicableQuotes(List<Opportunity> newList) {

      //If we are here then the Opportunity has been 'reparented' and now belongs to a different Account.
      //For each quote in each opportunity we need to correct the value of field zqu__Quote__c.zqu__Account__c
      //to prevent Zuora from throwing up all over.  (Despite this being their field in the first place!)

      List<zqu__Quote__c> quotestoUpdate = new List<zqu__Quote__c>();
      Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

      for (Opportunity opp : newList) {
        newMap.put(opp.Id, opp);
      }

      if (!newMap.isEmpty()) {
        for (zqu__Quote__c q : [SELECT Id, zqu__Account__c, zqu__ZuoraAccountID__c, Billing_Account_Selection_Response__c, zqu__Opportunity__c FROM zqu__Quote__c WHERE zqu__Opportunity__c IN :newMap.keySet()]) {

          q.zqu__Account__c = newMap.get(q.zqu__Opportunity__c).AccountId;
          q.zqu__ZuoraAccountID__c = null;
          q.Billing_Account_Selection_Response__c = 'The Zuora (Billing) Account Id field was cleared as this Quote\'s Opportunity was moved to a different Salesforce Account.';
          quotestoUpdate.add(q);
        }

        if (!quotestoUpdate.isEmpty()) update quotestoUpdate;
      }
    }

    private void SyncOppBrandFieldsWithOwner(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {

      List<Opportunity> oppsToUpdate = new List<Opportunity>();
      Set<Id> newOwnerIDs = new Set<Id>();
      Boolean bContinue = false;

      //before we run the SOQL statement, let's make sure the owner actually changed...
      for (Opportunity o : newList) {
        if ((oldMap.containsKey(o.Id)) && (o.OwnerId != oldMap.get(o.Id).OwnerId)) bContinue = true;
      }

      if (bContinue) {
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, DefaultBrand__c, Default_BrandTag__c FROM User WHERE IsActive = true]);

        for (Opportunity o : newList) {
          if (o.OwnerId != oldMap.get(o.Id).OwnerId) { 

            //Then the owner changed, update the opp brand fields to be accurate to the new owner...
            if (userMap.containsKey(o.OwnerId)) {
              //CC-3003 - Oppty Owner Change Do Not Update Primary Brand
              //o.Primary_Brand__c = userMap.get(o.OwnerId).DefaultBrand__c;
              o.BrandTag__c = userMap.get(o.OwnerId).Default_BrandTag__c;        
            }
          }
        }
      }
    }

    //Called from OnAfterUpdate, CC-1698, Scenario 2b
    private void SyncRenewalOwnerWithRenewalOpp(Map<Id, Id> newOwnerMap) {

      List<Opportunity> updatedOpps = new List<Opportunity>();

      //Get the opps, and make sure that the renewals are NOT closed.  (If they are closed we're not changing them...)
      for (Opportunity opp : [SELECT  Id, 
                                      IsClosed, 
                                      Renewal_Opportunity__c, 
                                      Renewal_Owner_Assigned__c, 
                                      RenewalOppCreatedAutomatically__c,
                                      Renewal_Opportunity__r.Id,
                                      Renewal_Opportunity__r.IsClosed,
                                      Renewal_Opportunity__r.OwnerId
                                    FROM Opportunity
                                    WHERE Id IN :newOwnerMap.keySet() AND Renewal_Opportunity__r.IsClosed = false]) {
        if (newOwnerMap.containsKey(opp.Id)) {
          Opportunity o = new Opportunity(Id = opp.Renewal_Opportunity__c);  
          o.OwnerId = newOwnerMap.get(opp.Id);
          updatedOpps.add(o);
        }
      }

      if (updatedOpps.size() > 0) update updatedOpps;
    }

    private void SyncRenewalOwnerWithRPCLI(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        //CC-2125, Scenario 2
        //in full detail this scenario is:
        //  When an opportunity that is closed-won & its quote IS 'Sent to Z-Billing'
        //  and the opporutnity renewal owner field is either changed OR initially populated, change the Sales Rep field in Zuora on the Rate Plan Charge Line Item
        //  for the zContract that is tied to this Opportunity WHERE the previous value equals the existing RPCLI sales rep.
        //  Previous value will either be the old Renewal Owner (if it had a value before) or the Opportunity Owner (if Renewal Owner did not have a previous value.)

        //Create new map to find the new values...          
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
        for (Opportunity o : newList) {
            if (!newMap.containsKey(o.Id)) newMap.put(o.Id, o);
        }       

        Set<String> ParametersForZuoraFutureJob = new Set<String>();            

        Set<Id> optyIDs = new Set<Id>();

        for(Opportunity op : newList) {
            if (op.IsClosed == true && op.IsWon == true && op.Renewal_Owner_Assigned__c != null && op.ZuoraSubscription__c != null 
                    && op.Renewal_Owner_Assigned__c != oldMap.get(op.Id).Renewal_Owner_Assigned__c && op.Renewal_Owner_Assigned__c != null) {
                optyIds.add(op.Id);
            }
        }

        if (optyIDs.size() > 0) {

            //User name map...
            Map<Id, String> userMap = new Map<Id, String>();

            //Populate the user map
            for (User u : [SELECT Id, Name FROM User]) {
                userMap.put(u.Id, u.Name);
            }

            for (Opportunity op : [SELECT Id, ZuoraSubscription__c, ZuoraSubscription__r.Zuora__Zuora_Id__c FROM Opportunity WHERE ZuoraSubscription__c != null AND Id IN : optyIDs]) {
              if (oldMap.get(op.Id).Renewal_Owner_Assigned__c == null) ParametersForZuoraFutureJob.add(op.ZuoraSubscription__r.Zuora__Zuora_Id__c + '_' + userMap.get(oldMap.get(op.Id).OwnerId) + '_' + userMap.get(newMap.get(op.Id).Renewal_Owner_Assigned__c));  
              else ParametersForZuoraFutureJob.add(op.ZuoraSubscription__r.Zuora__Zuora_Id__c + '_' + userMap.get(oldMap.get(op.Id).Renewal_Owner_Assigned__c) + '_' + userMap.get(newMap.get(op.Id).Renewal_Owner_Assigned__c));
            }

            //Call the future job to push it to Zuora.
            if (ParametersForZuoraFutureJob.size() > 0) SyncLineItemsToZuora(ParametersForZuoraFutureJob);
        }
    }

    private void SyncQuoteLineSalesRepsWithNewOppOwner(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        //CC-2125, Scenario 1
        //in full detail this scenario is:
        //  When an opportunity that is closed-won & its quote is NOT yet sent to Z-Billing
        //  and the opportunity.owner is changed, find all quote line items that have the same sales rep as the prior owner for ALL quotes tied to this opp
        //  and update them to the new opp owner.

        //User name map...
        Map<Id, String> userMap = new Map<Id, String>();

        //Create new map to find the new values...
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
        for (Opportunity o : newList) {
            if (!newMap.containsKey(o.Id)) newMap.put(o.Id, o);
        }

        Set<String> optyIDs = new Set<String>();
        List<zqu__Quote__c> quotesInPlay = new List<zqu__Quote__c>();
        List<zqu__QuoteCharge__c> chargesToUpdate = new List<zqu__QuoteCharge__c>();

        for(Opportunity op : newList) {
            if (op.IsClosed == true && op.IsWon == true && op.OwnerId != oldMap.get(op.Id).OwnerId) optyIDs.add(op.ID);
        }

        //get every quote related to this opportunity that had the owner changed...
        for (zqu__Quote__c q : [SELECT zqu__Opportunity__c, zqu__Status__c, Id, IsSyncing__c, (SELECT Sales_Representative__c, Id FROM zqu__QuoteCharge__r) FROM zqu__Quote__c WHERE zqu__Opportunity__c IN : optyIDs]) {
            //check the status - if it's sent to Z-billing, then that opp is no longer in play...
            //unfortunate, but this is necessary as there can be many quotes against an opp and only one would be sent to Z-billing.
            if (q.zqu__Status__c == 'Sent to Z-Billing') optyIds.remove(q.zqu__Opportunity__c);
        }

        if (optyIds.size() > 0) {
            
            //Populate the user map
            for (User u : [SELECT Id, Name FROM User]) {
                userMap.put(u.Id, u.Name);
            }

            //repeat the search, this time we know for certain that the Oppty ID set is absolutely correct. 
            for (zqu__Quote__c q : [SELECT zqu__Opportunity__c, zqu__Status__c, Id, IsSyncing__c, (SELECT Sales_Representative__c, Id, zqu__Quote__c FROM zqu__QuoteCharge__r) FROM zqu__Quote__c WHERE zqu__Opportunity__c IN : optyIDs]) {
            
                for (zqu__QuoteCharge__c qc : q.zqu__QuoteCharge__r) {

                    if ((userMap.containsKey(oldMap.get(q.zqu__Opportunity__c).OwnerId) && (userMap.get(oldMap.get(q.zqu__Opportunity__c).OwnerId) == qc.Sales_Representative__c)) || (test.isRunningTest())) {
                        //If the quote charge sales rep matches the OLD value of the opportunity owner...
                        qc.Sales_Representative__c = userMap.get(newMap.get(q.zqu__Opportunity__c).OwnerId);
                        chargesToUpdate.add(qc);
                    }
                }
            }

            if (chargesToUpdate.size() > 0) update chargesToUpdate;
        }
    }

@future (callout=true)
  public static void SyncLineItemsToZuora(Set<String> PipeSeparatedParameters) {   
    //Create two maps for updates
    //Map 1 :  ZuoraSubID --> Old Sales Rep Name
    //Map 2 :  ZuoraSubID --> New Sales Rep Name
    Map<String, String> oldMap = new Map<String, String>();
    Map<String, String> newMap = new Map<String, String>();

    //To be populated with Zuora data once it's retrieved...
    Map<String, String> ratePlanIDSubIDMap = new Map<String, String>();
    Map<String, String> ratePlanChargeIDRatePlanIDMap = new Map<String, String>();

    Map<String, String> ratePlanChargeIDSubIDMap = new Map<String, String>();
    Map<String, String> ratePlanChargeIDZuoraValues = new Map<String, String>();  //ratePlanChargeID --> Sales Rep (stored in Zuora)

    for (String s : PipeSeparatedParameters) {

      List<String> parts = s.split('_');

      if (parts.size() == 3) {
        if (!oldMap.containsKey(parts[0])) oldMap.put(parts[0], parts[1]);
        if (!newMap.containsKey(parts[0])) newMap.put(parts[0], parts[2]);
      }
    }

    Zuora.zApi zApiInstance = new Zuora.zApi();

    try {
      if (!Test.isRunningTest()) zApiInstance.zlogin();
    }
    catch (Exception ex) { ex.getMessage(); }

    try {

      List<Zuora.zObject> selectList = new List<Zuora.zObject>();
      List<Zuora.zObject> updateList = new List<Zuora.zObject>();
      List<Zuora.zApi.SaveResult> results;

      //Build the where clause...
      String ratePlanWhereClause = '';
      String ratePlanChargeWhereClause = '';
      String ratePlanChargeZoql;

      for (String zuoraSubID : oldMap.keySet()) {
        if (ratePlanWhereClause.length() > 1) ratePlanWhereClause += ' OR ';
        ratePlanWhereClause += 'SubscriptionId = \'' + zuoraSubID + '\'';
      }
        
      String ratePlanZoql = 'select Id, SubscriptionId from RatePlan where ' + ratePlanWhereClause;

      if (!Test.isRunningTest()) selectList = zApiInstance.zquery(ratePlanZoql);      

      for (Zuora.zObject o : selectList) {
        if (!ratePlanIDSubIDMap.containsKey((String)o.getValue('Id'))) ratePlanIDSubIDMap.put((String)o.getValue('Id'), (String)o.getValue('SubscriptionId'));
        if (ratePlanChargeWhereClause.length() > 1) ratePlanChargeWhereClause += ' OR ';
        ratePlanChargeWhereClause += 'RatePlanId = \'' + (String)o.getValue('Id') + '\'';
      }
      //We just finished bulding a map of Zuora Subscription IDs --> Zuora Rate Plan IDs
      //Now we effectively repeat the process only we go from Rate Plan --> Rate Plan Charge

      if (!Test.isRunningTest() && (ratePlanChargeWhereClause.length() < 1)) return;  //nothing returned, nothing to do, quit.

      if (!Test.isRunningTest()) ratePlanChargeZoql = 'select Id, RatePlanId, Sales_Representative__c from RatePlanCharge where ' + ratePlanChargeWhereClause;
      else ratePlanChargeZoql = 'select Id, RatePlanId, Sales_Representative__c from RatePlanCharge';

      if (!Test.isRunningTest()) selectList = zApiInstance.zquery(ratePlanChargeZoql);

      if ((!Test.isRunningTest()) && (selectList.size() < 1)) return;    //nothing returned - nothing to do, quit.

      for (Zuora.zObject o : selectList) {
        if (!ratePlanChargeIDRatePlanIDMap.containsKey((String)o.getValue('Id'))) ratePlanChargeIDRatePlanIDMap.put((String)o.getValue('Id'), (String)o.getValue('RatePlanId'));
        if (!ratePlanChargeIDZuoraValues.containsKey((String)o.getValue('Id'))) ratePlanChargeIDZuoraValues.put((String)o.getValue('Id'), (String)o.getValue('Sales_Representative__c'));
      }
      //We just finished bulding a map of Zuora Rate Plan IDs --> Zuora Rate Plan Charge IDs

      for (String s : ratePlanChargeIDRatePlanIDMap.keySet()) {
        if (!ratePlanChargeIDSubIDMap.containsKey(s)) ratePlanChargeIDSubIDMap.put(s, ratePlanIDSubIDMap.get(ratePlanChargeIDRatePlanIDMap.get(s)));        
      }
      //we now have a direct map of ratePlanChargeIDs --> SubscriptionID.

      //Now for everything in the ratePlanChargeChargeIDSubIDMap we compare values against oldMap.  If it matches, update it to the value in newMap
      for (String s : ratePlanChargeIDSubIDMap.keySet()) {

        if (oldMap.containsKey(ratePlanChargeIDSubIDMap.get(s)) && (oldMap.get(ratePlanChargeIDSubIDMap.get(s)) == ratePlanChargeIDZuoraValues.get(s))) {
          //then the sub is in the old map, the values match and we need to update
          Zuora.zObject subLineItem = new Zuora.zObject('RatePlanCharge');
          subLineItem.setValue('Id', s);    
          subLineItem.setValue('Sales_Representative__c', newMap.get(ratePlanChargeIDSubIDMap.get(s)));
          updateList.add(subLineItem);        
        }
      }
   
      if(!Test.isRunningTest()) results = zApiInstance.zupdate(updateList);
      else {
          results = new List<Zuora.zApi.SaveResult>();
          Zuora.zApi.SaveResult result = new Zuora.zApi.SaveResult();
          result.Success = false;
          results.add(result);
      }
    }
    catch (Zuora.zRemoteException ex) {
      if ('INVALID_FIELD' == ex.code) system.debug('&&&&&&&&&&&&&&&& - ERROR 1: ' + ex.getMessage());
      else system.debug('&&&&&&&&&&&&&&&& - ERROR 2: ' + ex.getMessage());
    } 
    catch (Zuora.zAPIException ex) {  system.debug('&&&&&&&&&&&&&&&& - ERROR 3: ' + ex.getMessage());   }
    catch (Zuora.zForceException ex) {  system.debug('&&&&&&&&&&&&&&&& - ERROR 4: ' + ex.getMessage());  }
  }

    //@future (callout=false)
    public static void CreateRenewalOpps(Set<Id> opportunityIDs) {

        //Get the standard record type ID:
        Id standardOppRecordType;
        List<RecordType> recordTypes = [SELECT Id FROM RecordType where sobjecttype = 'Opportunity' and isActive = true and developername = 'Standard' LIMIT 1];
        
        if (recordTypes.size() == 1) standardOppRecordType = recordTypes[0].Id;
        else return;

        //the key (id) is the SOURCE opportunity ID - the value (opportunity) is the new renewal opp to create
        Map<Id, Opportunity> oppsToInsert = new Map<Id, Opportunity>(); 

        List<Opportunity> oppsToUpdate = new List<Opportunity>();       

        //Map<Id, List<OpportunityLineItem>> oppLineItemsToInsert = new Map<Id, List<OpportunityLineItem>>();
        Map<Id, Opportunity> sourceOpps = new Map<Id, Opportunity>();

        Set<Id> abIDs = new Set<Id>();

        //the key (id) is the account brand id.
        Map<Id, Account_Brand__c> abMap = new Map<Id, Account_Brand__c>();

        Map<Id, User> possibleOwners = new Map<Id, User>();

        List<Training_Backup_User__c> fallBackList = Training_Backup_User__c.getall().values();     
        String fallBackOwnerID;
        if (fallBackList.size() > 0) fallBackOwnerID = fallBackList[0].UserID__c;
        else fallBackOwnerID = UserInfo.getUserId();

        for (Opportunity o : [SELECT 
                                Source_Opportunity__c, 
                                AccountId, 
                                Name, 
                                Contact__c, 
                                OwnerId,
                                CloseDate,
                                BrandTag__c,
                                CurrencyIsoCode, 
                                Primary_Brand__c, 
                                Account_Brand__c, 
                                Sold_By_Partner__c, 
                                Renewal_Opportunity__c, 
                                Renewal_Owner_Assigned__c,
                                RenewalOppCreatedAutomatically__c, 
                                SyncedQuote__r.Service_End_Date__c,
                                //ZuoraSubscription__c, 
                                //ZuoraSubscription__r.Id, 
                                //ZuoraSubscription__r.ServiceEndDate__c,
                                (SELECT 
                                    Brand__c,
                                    BrandTag__c,
                                    Product_Group__c,
                                    Sub_Category__c,
                                    Sale_Type__c,
                                    UnitPrice,
                                    Quantity,
                                    Country__c,
                                    CurrencyIsoCode,
                                    ListPrice,
                                    PricebookEntryId,
                                    TotalPrice,
                                    SortOrder,
                                    Description,
                                    OpportunityId,
                                    Id 
                                FROM OpportunityLineItems
                                ) 
                              FROM Opportunity 
                              WHERE Id IN : opportunityIDs]) {

            if (!sourceOpps.containsKey(o.Id)) sourceOpps.put(o.Id, o);
            abIDs.add(o.Account_Brand__c);
        }

        for (Account_Brand__c ab : [SELECT Primary_Owner__c, Id FROM Account_Brand__c WHERE Id IN : abIDs]) {
            if (!abMap.containsKey(ab.Id)) abMap.put(ab.Id, ab);
        }       

        //Populate the owner map now with only ACTIVE users.  This is needed in case if owners are inactive - we must know before otherwise a save where the owner is inactive will blow up...
        for (User u : [SELECT Id, Name, IsActive FROM User WHERE IsActive = TRUE]) {
            if (!possibleOwners.containsKey(u.Id)) possibleOwners.put(u.Id, u);
        }

        for (Opportunity o : sourceOpps.Values()) {

            Opportunity newOpp = new Opportunity();
            newOpp.Source_Opportunity__c = o.Id;
            newOpp.BrandTag__c = o.BrandTag__c;
            newOpp.Renewal_Feedback__c = 'Not Submitted';
            newOpp.Sold_By_Partner__c = o.Sold_By_Partner__c;
            newOpp.StageName = 'Auto Renew';
            newOpp.CurrencyIsoCode = o.CurrencyIsoCode;
            newOpp.Primary_Brand__c = o.Primary_Brand__c;
            newOpp.Account_Brand__c = o.Account_Brand__c;
            newOpp.Contact__c = o.Contact__c;
            newOpp.AccountId = o.AccountId;
            newOpp.RecordTypeId = standardOppRecordType;

            //Setting the owner now
            //first it's the source opp's renewal owner (if populated & active)
            //second is the source opp's owner (if active)
            //third is the source opp's account brand primary owner (if populated & active)
            //fourth is the failsafe
            //fifth is the current user - as we know that must be active.

            //FIRST
            if (o.Renewal_Owner_Assigned__c != null && possibleOwners.containsKey(o.Renewal_Owner_Assigned__c)) newOpp.OwnerId = o.Renewal_Owner_Assigned__c;

            //SECOND
            else if (possibleOwners.containsKey(o.OwnerId)) newOpp.OwnerId = o.OwnerId;            

            //THIRD
            else if (abMap.containsKey(newOpp.Account_Brand__c) && abMap.get(newOpp.Account_Brand__c).Primary_Owner__c != null && possibleOwners.containsKey(abMap.get(newOpp.Account_Brand__c).Primary_Owner__c)) newOpp.OwnerId = abMap.get(newOpp.Account_Brand__c).Primary_Owner__c;

            //FOURTH
            else if (possibleOwners.containsKey(fallBackOwnerID)) newOpp.OwnerId = fallBackOwnerID;

            //LAST
            else newOpp.OwnerId = UserInfo.getUserId();
            //DONE WITH THE OWNER

            //Now that the timing has changed and this is created immediately upon closed/won, the close date is no longer the subscription service end date but instead the syncedQuote's service end date.
            //if (o.ZuoraSubscription__c != null && o.ZuoraSubscription__r.ServiceEndDate__c != null) {

            if (o.SyncedQuote__c != null && o.SyncedQuote__r.Service_End_Date__c != null) {
              newOpp.CloseDate = o.SyncedQuote__r.Service_End_Date__c;
              String oldName = o.Name.replace('Auto Renewal:', '').trim();
              newOpp.Name = 'Auto Renewal: ' + oldName.replace('Renewal:', '').trim();

              if (newOpp.Name.length() > 120) newOpp.Name = newOpp.Name.substring(0, 119);

              oppsToInsert.put(o.Id, newOpp);
            }
            //}
            //As the else only effects EVERGREEN opportunities, skip them entirely.
            //EVERGREENs are ALWAYS ommitted.
        }       

        if (oppsToInsert.values().size() > 0) {
          insert oppsToInsert.values();
          //all base renewal opps are now created - next is their respective line items....

          List<OpportunityLineItem> olisToInsert = new List<OpportunityLineItem>();

          for (Opportunity o : sourceOpps.Values()) {

            if (oppsToInsert.containsKey(o.Id)) {
              for (OpportunityLineItem oli : o.OpportunityLineItems) {

                  OpportunityLineItem newOLI = new OpportunityLineItem();

                  newOLI.Quantity = oli.Quantity;
                  newOLI.UnitPrice = oli.UnitPrice;
                  newOLI.OpportunityId = oppsToInsert.get(o.Id).Id;
                  newOLI.Country__c = oli.Country__c;
                  newOLI.PricebookEntryId = oli.PricebookEntryId;
                  newOLI.BrandTag__c = oli.BrandTag__c;
                  newOLI.Product_Group__c = oli.Product_Group__c;
                  newOLI.Sub_Category__c = oli.Sub_Category__c;
                  newOLI.Sale_Type__c = oli.Sale_Type__c;

                  olisToInsert.add(newOLI);
              }           
            }
          }       

          if (olisToInsert.size() > 0) insert olisToInsert;
        }

        //now that we're saved - update the renewal feedback & renewal opp values on the source opp...

        for (Id thisID : oppsToInsert.keySet()) {
            Opportunity updatedOpp = new Opportunity(Id = thisID);
            updatedOpp.Renewal_Opportunity__c = oppsToInsert.get(thisID).Id;
            updatedOpp.Renewal_Feedback__c = 'Opportunity Created';
            updatedOpp.RenewalOppCreatedAutomatically__c = true;

            oppsToUpdate.add(updatedOpp);
        }

        if (oppsToUpdate.size() > 0) update oppsToUpdate;
    }

    //CC-1698
    //oppsQuote includes all zqu__QuoteCharge__c records as well as that is what is compared against the exclusion list.
    public static Boolean RenewalOppShouldBeCreated(Opportunity sourceOpp, Zqu__Quote__c oppsQuote, Map<String, List<Excluded_Products__c>> excludedProductMap) {
 
        //Note that this is only considering the excluded products listing per opp/quote - it doesn't factor in EVERGREENs.
        //Those are excluded in the following sub, 'CreateRenewalOpportunities'

        Integer numValid = 0;
        //Integer numInvalid = 0;
        //Integer numProductsOnQuote = 0;

        if (sourceOpp.Renewal_Opportunity__c != null) return false;

        if (oppsQuote!= null && oppsQuote.zqu__QuoteCharge__r != null) {

            //numProductsOnQuote = oppsQuote.zqu__QuoteCharge__r.size();

            for (zqu__QuoteCharge__c thisQC : oppsQuote.zqu__QuoteCharge__r) {
                
                if (thisQC.zqu__ProductRatePlanCharge__r != null 
                     && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r != null 
                     && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r != null 
                     && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.BuildOppty__c != null) {

                     if (thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.BuildOppty__c.tolowercase() == 'y' ) {
                        numValid++;
                     }

                    /*
                    List<Excluded_Products__c> thisList = excludedProductMap.get(thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c);
                    //we now have the list of excluded product groups & categories that match the same brand as the quote charge we're looking at...  now compare...

                    String thisQCGroup = thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c;
                    String thisQCSubCat = thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c;

                    Boolean matchFound = false;
                    Integer i = 0;

                    if (thisList.size() > 0) {
                        do {
                            Excluded_Products__c ep = thisList.get(i);

                            //if all product groups are excluded
                            if (ep.Product_Group__c == '*') matchFound = true;

                            //if the product group matches and all subcategories are excluded
                            if (ep.Product_Group__c == thisQCGroup && ep.Product_SubCategory__c == '*') matchFound = true;

                            //if the product group matches and the subcategory also matches
                            if (ep.Product_Group__c == thisQCGroup && ep.Product_SubCategory__c == thisQCSubCat) matchFound = true;

                            i++;
                        } while (matchFound == false && i < thisList.size());

                        if (!matchFound) numValid++;
                    }
                    else numValid++;
                    */
                }
                //else numValid++;
            }
        }

        if (numValid > 0) return true;
        else return false;
    }


       //CC-865
      private void SetAccountBrandFields(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
         Set<Id> accountIDs = new Set<Id>();
         Map<String, Account_Brand__c> brandMapToPopulateLookup = new Map<String, Account_Brand__c>();
         Map<String, Account_Brand__c> brandMapToPopulatePicklist = new Map<String, Account_Brand__c>();
         
         if (oldMap == null) {
           //Then we're inserting...
           for (Opportunity o : newList) {
              accountIDs.add(o.AccountId);
           }
         }
         else {
           //Else we're updating...
            for (Opportunity o : newList) {
              if ((oldMap.containsKey(o.Id)) && ((oldMap.get(o.Id).Account_Brand__c != o.Account_Brand__c) || (oldMap.get(o.Id).Primary_Brand__c != o.Primary_Brand__c))) accountIDs.add(o.AccountId);
            }
         }

         if (!accountIds.isEmpty()) {
           
           for (Account_Brand__c ab : [SELECT Id, Account__c, Brand_Picklist__c, Name FROM Account_Brand__c WHERE Account__c IN :accountIDs]) {
              if (!brandMapToPopulateLookup.containsKey(ab.Account__c + '~~' + ab.Brand_Picklist__c)) brandMapToPopulateLookup.put(ab.Account__c + '~~' + ab.Brand_Picklist__c, ab);
              if (!brandMapToPopulatePicklist.containsKey(ab.Id)) brandMapToPopulatePicklist.put(ab.Id, ab);
           }
           
           for (Opportunity o : newList) {
              if (o.Account_Brand__c != null || o.Primary_Brand__c != null) {
                //In case if we have an empty Account Brand lookup but a valid picklist value...
                if ((o.Account_Brand__c == null) && (o.Primary_Brand__c != null) && brandMapToPopulateLookup.containsKey(o.AccountId + '~~' + o.Primary_Brand__c)) {
                    o.Account_Brand__c = brandMapToPopulateLookup.get(o.AccountId + '~~' + o.Primary_Brand__c).Id;
                    continue;
                }
                
                //In case if we have an empty picklist value but a valid Account Brand
                if ((o.Account_Brand__c != null) && (o.Primary_Brand__c == null) && brandMapToPopulatePicklist.containsKey(o.Account_Brand__c)) {
                    o.Primary_Brand__c = brandMapToPopulatePicklist.get(o.Account_Brand__c).Brand_Picklist__c;
                    continue;
                }   
                
                //in case if brand picklist is changed, update the lookup control.
                if ((o.Primary_Brand__c != null) && (oldMap != null) && oldMap.containsKey(o.Id) && (oldMap.get(o.Id).Primary_Brand__c != o.Primary_Brand__c) && (oldMap.get(o.Id).Account_Brand__c == o.Account_Brand__c) && brandMapToPopulateLookup.containsKey(o.AccountId + '~~' + o.Primary_Brand__c)) {
                    o.Account_Brand__c = brandMapToPopulateLookup.get(o.AccountId + '~~' + o.Primary_Brand__c).Id;
                    continue;
                }
                
                //in case if brand lookup is changed, update the picklist.
                if ((o.Account_Brand__c != null) && (oldMap != null) && oldMap.containsKey(o.Id) && (oldMap.get(o.Id).Account_Brand__c != o.Account_Brand__c) && (oldMap.get(o.Id).Primary_Brand__c == o.Primary_Brand__c) && brandMapToPopulatePicklist.containsKey(o.Account_Brand__c)) {
                    o.Primary_Brand__c = brandMapToPopulatePicklist.get(o.Account_Brand__c).Brand_Picklist__c;
                    continue;
                }
              }
           }
        }
      }

      //T-125620
      private void CampaignSelectionForOppty (List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
      
        //CC-2985 - removing the Close filters so that the Campaign influence is determed when an Oppoty is created, not Closed.
        //CC-2985 - moving the campaign influece cut-off date from the Campaign to the Campaign member to allow for rolling campaign influence
          
        Set<String> contactIDs = new Set<String>();     
        Map<String, List<CampaignMember>> ContactID_ListOfCampMemberMap = new Map<String, List<CampaignMember>>();
        for(Opportunity op : newList) {
            if ((oldMap == null && op.CampaignId == null) && op.Primary_Brand__c <> null && !op.Name.startsWith('Auto Renewal')) {                       
              contactIDs.add(op.Contact__c);
            }
        }
        
        if(contactIDs.size() > 0) {
            for (CampaignMember cm : [SELECT Campaign.Brand__c, Campaign.Id, Campaign.Name, 
                                    Campaign.EndDate, Campaign.StartDate,                       //byrnes - added these two field 2013.12.03 for CC-1290
                                    ContactId, ID, CreatedDate,
                                    Influential_Cutoff_Date__c, Campaign.Influential__c          //bergman - added   Influential_Cutoff_Date__c and Campaign.Infuential__c
                                    FROM CampaignMember 
                                    WHERE ContactID IN : contactIDs  
                                    AND Influential_Cutoff_Date__c >= TODAY
                                    AND Campaign.Influential__c = true
                                    ORDER BY CreatedDate DESC]) {  // Switched from ASC on 9/17/2013
                                        
              if (!ContactID_ListOfCampMemberMap.containsKey(cm.ContactId)) ContactID_ListOfCampMemberMap.put(cm.ContactId, new List<CampaignMember>());
              ContactID_ListOfCampMemberMap.get(cm.ContactId).add(cm);
            }
            
            for (Opportunity oppty : newList) {
              if ((oldMap == null && oppty.CampaignId == null) && oppty.Primary_Brand__c <> null && !oppty.Name.startsWith('Auto Renewal')) {
                //Adding brands from opportunity                    
                  if (ContactID_ListOfCampMemberMap.containsKey(oppty.Contact__c)) {
                    for (CampaignMember cm : ContactID_ListOfCampMemberMap.get(oppty.Contact__c)) {
                        if (cm.Campaign != null && cm.Campaign.Brand__c != null && (String.valueOf(cm.Campaign.Brand__c).contains(oppty.Primary_Brand__c)) && (cm.Campaign.StartDate <= system.today()) && (cm.Influential_Cutoff_Date__c >= system.today()) && (cm.Campaign.Influential__C == true)) {  //byrnes, cc-1290, all conditions except the first...
                            if(oppty.CampaignId == null) oppty.CampaignId = cm.CampaignID;
                        }
                    }
                  }
              }        
            }
        }                
      }
        
      //T-111714: Opportunity: Contact and Contact Role.
      private void updateContactRole (List<Opportunity> newList, Map<ID, Opportunity> oldMap) { 
        List<OpportunityContactRole> ocrListToUpsert = new List<OpportunityContactRole>();
        Map<String, List<OpportunityContactRole>> contID_listContRole_map = 
               new Map<String, List<OpportunityContactRole>>();
        OpportunityContactRole ocrObj;
        Set<String> optyIDset = new Set<String>();
        //populating set for query contact roles
        for (Opportunity opty : newList) {
            if (!oldMap.isEmpty()) {
                if (opty.Contact__c <> null 
                               && oldMap.get(opty.ID).Contact__c <> opty.Contact__c 
                               && !contID_listContRole_map.containsKey(opty.Contact__c)) {
              optyIDset.add(opty.ID);
                    contID_listContRole_map.put(opty.Contact__c, new List<OpportunityContactRole>());
                }
            } else {
            if (opty.Contact__c <> null && !contID_listContRole_map.containsKey(opty.Contact__c)) {
              optyIDset.add(opty.ID);
              contID_listContRole_map.put(opty.Contact__c, new List<OpportunityContactRole>());
            }
            }
        }
        
        if (!contID_listContRole_map.isEmpty()) {
            for (OpportunityContactRole ocr : [SELECT ContactID, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityID IN: optyIDset]) {
                if (contID_listContRole_map.containsKey(ocr.ContactID)) contID_listContRole_map.get(ocr.ContactID).add(ocr);
            }
        }
        
        //populating set for query contact roles
        for (Opportunity opty : newList) {
          if (!oldMap.isEmpty()) { //Updation of the opportunity
            
            if (opty.Contact__c <> null 
                            && oldMap.get(opty.ID).Contact__c <> opty.Contact__c 
                            && contID_listContRole_map.containsKey(opty.Contact__c)
                            &&  contID_listContRole_map.get(opty.Contact__c).size() > 0) {
                //Updation of existing Contact Roles
                for (OpportunityContactRole ocr : contID_listContRole_map.get(opty.Contact__c)) {
                 ocrObj = new OpportunityContactRole(ID = ocr.ID);
                 ocrObj.IsPrimary = true;
                 ocrObj.Role = Constants.DECISION_MAKER;
                 //ocrObj.OpportunityId = opty.ID;
                 ocrObj.ContactId = opty.Contact__c;
                 ocrListToUpsert.add(ocrObj);
                } 
                        
            }
            else if (opty.Contact__c <> null
                  && oldMap.get(opty.ID).Contact__c <> opty.Contact__c  
                  && (!contID_listContRole_map.containsKey(opty.Contact__c) ||
                      (contID_listContRole_map.containsKey(opty.Contact__c)
                            &&  contID_listContRole_map.get(opty.Contact__c).size() < 1))) {
               //Creation of new Contact Roles
               ocrObj = new OpportunityContactRole();
               ocrObj.IsPrimary = true;
               ocrObj.Role = Constants.DECISION_MAKER;
               ocrObj.OpportunityId = opty.ID;
               ocrObj.ContactId = opty.Contact__c;
               ocrListToUpsert.add(ocrObj);
            }
            
          } else { // New insertion of opportunity
            if (opty.Contact__c <> null 
                            && contID_listContRole_map.containsKey(opty.Contact__c)
                            &&  contID_listContRole_map.get(opty.Contact__c).size() > 0) {
              //Updation of existing Contact Roles
              for (OpportunityContactRole ocr : contID_listContRole_map.get(opty.Contact__c)) {
               ocrObj = new OpportunityContactRole(ID = ocr.ID);
               ocrObj.IsPrimary = true;
               ocrObj.Role = Constants.DECISION_MAKER;
               //ocrObj.OpportunityId = opty.ID;
               ocrObj.ContactId = opty.Contact__c;
               ocrListToUpsert.add(ocrObj);
              } 
            }
            else if (opty.Contact__c <> null
                  && (!contID_listContRole_map.containsKey(opty.Contact__c) ||
                      (contID_listContRole_map.containsKey(opty.Contact__c)
                            &&  contID_listContRole_map.get(opty.Contact__c).size() < 1))) {
               //Creation of new Contact Roles
               ocrObj = new OpportunityContactRole();
               ocrObj.IsPrimary = true;
               ocrObj.Role = Constants.DECISION_MAKER;
               ocrObj.OpportunityId = opty.ID;
               ocrObj.ContactId = opty.Contact__c;
               ocrListToUpsert.add(ocrObj);
            }
           } //--End of IF insertion oppty  
        }
        if (!ocrListToUpsert.isEmpty()) {
            upsert ocrListToUpsert;
        }
      }
 
       //CC-2626 Default the Agency Discount Percentage
      private void DefaultAgencyPercent (List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        Map<String, Agency_Agreement__c> ABAgreementMap = new Map<String, Agency_Agreement__c>();
        
        for (Agency_Agreement__c aa : [Select ID, Account_Brand__c, Discount_Percent__c, Start_Date__c, 
                                                End_Date__c, Status__c, Account__c, Brand_Name__c 
                                            FROM Agency_Agreement__c
                                            WHERE Start_Date__c <= TODAY and (End_Date__c >= TODAY or End_Date__c = null)
                                            ORDER BY Start_Date__c DESC]) {                                 
            if (!ABAgreementMap.containskey(aa.Account__c + '-' + aa.Brand_Name__c)) ABAgreementMap.put(aa.Account__c + '-' + aa.Brand_Name__c, aa);                                                
        }
        
        for (Opportunity opp : newList) {
            if (ABAgreementMap.containskey(opp.Sold_By_Partner__c + '-' + opp.Primary_Brand__c) && opp.Sold_By_Partner__c <> null && opp.Primary_Brand__c <> null) {            
                //Only set the default the first time, do not override if already set
                if (oldMap == null || oldMap.get(opp.Id).Sold_By_Partner__c <> opp.Sold_By_Partner__c) {            
                     if (opp.Sold_By_Partner__c <> null) {
                         opp.Agency_Discount__c = ABAgreementMap.get(opp.Sold_By_Partner__c + '-' + opp.Primary_Brand__c).Discount_Percent__c;
                         opp.Agency_Agreement__c = ABAgreementMap.get(opp.Sold_By_Partner__c + '-' + opp.Primary_Brand__c).ID;
                     }
                     else {
                         opp.Agency_Discount__c = null;
                         opp.Agency_Agreement__c = null;    
                     }  
                }
            }
            // if the sold by partner is null 
            else if (opp.Sold_By_Partner__c == null) { 
                    opp.Agency_Discount__c = null;
                    opp.Agency_Agreement__c = null;
            }
            //or is being changed to a new sold by partner that does not have an active agency agreement
            else if (oldMap != null) {
                if (oldMap.get(opp.Id).Sold_By_Partner__c <> opp.Sold_By_Partner__c) {
                    opp.Agency_Discount__c = null;
                    opp.Agency_Agreement__c = null;                
                }
            }

        } 
      }  
 
  
      //T-122535: Update Renewal Opportunities
      private void populateRenewalOpportunity (List<Opportunity> newList) {
        Set<String> srcOptyIDs = new Set<String>();
        List<Opportunity> oppUpdateList = new List<Opportunity>();
        Map<String, Opportunity> sourceOpptyMap = new Map<String, Opportunity>();
        for (Opportunity opp : newList) { 
            if (opp.Source_Opportunity__c <> null) srcOptyIDs.add(opp.Source_Opportunity__c); 
        }
        
        for (Opportunity oppty : [SELECT ID, Renewal_Opportunity__c 
                                      FROM Opportunity WHERE ID IN : srcOptyIDs]) {
            if (!sourceOpptyMap.containsKey(oppty.ID)) sourceOpptyMap.put(oppty.ID, oppty);
        }
        
        for (Opportunity oppty : newList) {
            if (oppty.Source_Opportunity__c <> null && sourceOpptyMap.containsKey(oppty.Source_Opportunity__c) && sourceOpptyMap.get(oppty.Source_Opportunity__c).Renewal_Opportunity__c == null) oppUpdateList.add(new Opportunity(ID = oppty.Source_Opportunity__c, Renewal_Opportunity__c = oppty.ID, Validation_Rule_Override__c = System.now()));           
        }
        
        if (!oppUpdateList.isEmpty()) update oppUpdateList;
      }
     
      //T-123902:Populate Opportunity Team for Closed Won Opportunities
      public static void populateOppTeamForCloseWonOpps (Set<String> oppIDset) {
        //Delete All Opportunity Team Members for the given Opportunities that meet the above Criteria
        List<OpportunityTeamMember> delTeamMembersList = new List<OpportunityTeamMember>();
        for (OpportunityTeamMember member : [SELECT ID FROM OpportunityTeamMember
                                               WHERE OpportunityID IN :oppIDset]) {
           delTeamMembersList.add(member);
        } 
        if (!delTeamMembersList.isEmpty()) delete delTeamMembersList;
        
        //populating sets to query on account brands.
        Set<String> accIDset = new Set<String>();
        Set<String> brandsSet = new Set<String>();
        List<Opportunity> newList = new List<Opportunity>();
        
        for (Opportunity opty : [SELECT ID, Brands__c, AccountID FROM Opportunity WHERE ID IN : oppIDset]) {
            if (opty.AccountID <> null) accIDset.add(opty.AccountID);
            if (opty.Brands__c <> null) brandsSet.addAll(String.valueOf(opty.Brands__c).split(';'));
            opty.isTeam_Added__c = true; 
            newList.add(opty);
        }
        
        //Get account brand for Opportunity.Brands__c (splited values)
        Map<String, Account_Brand__c> accIDbrand_abMap = new Map<String, Account_Brand__c>();
        for (Account_Brand__c ab : [SELECT Primary_Owner__c, Id, Country__c, CS__c, Support_Owner_Inactive__c, Primary_Owner_Inactive__c,
                                        Brand__c, Brand_Picklist__c, Brand_Name__c, 
                                        Account__c FROM Account_Brand__c 
                                        WHERE Account__c IN : accIDset
                                          AND Brand_Picklist__c IN : brandsSet]) {
            if (!accIDbrand_abMap.containsKey(ab.Account__c + '-' + ab.Brand_Picklist__c)) accIDbrand_abMap.put(ab.Account__c + '-' + ab.Brand_Picklist__c, ab);
        }
        
        //Get Account Team Member__c for Opportunity.Account
        Map<String, Account_Team_Member__c> accIDbrand_atmMap = new Map<String, Account_Team_Member__c>();
        System.debug('--accIDset->'+accIDset+'========'+brandsSet);
        for (Account_Team_Member__c atm : [SELECT User__c, Role__c, Id, Country__c, User_Inactive__c,
                                                  Brand_Name__c, Account__c, 
                                                  Account_Brand__c 
                                            FROM Account_Team_Member__c 
                                            WHERE Account__c IN : accIDset
                                            AND Brand_Name__c IN : brandsSet]) {
          if (!accIDbrand_atmMap.containsKey(atm.Account__c + '-' + atm.Brand_Name__c)) accIDbrand_atmMap.put(atm.Account__c + '-' + atm.Brand_Name__c, atm);
        }
        
        //List to insert users on team 
        Map<String, OpportunityTeamMember> key_OptyTeamMemberMap = new Map<String, OpportunityTeamMember>();
        Set<String> currentBrands = new Set<String>();
        OpportunityTeamMember teamMember;

        for (Opportunity op : newList) {
            if (op.Brands__c <> null) {
                currentBrands = new Set<String>();
                currentBrands.addAll(String.valueOf(op.Brands__c).split(';'));

                for (String brand : currentBrands) {
                    
                    if (accIDbrand_abMap.containsKey(op.AccountID + '-' + brand) && 
                           accIDbrand_abMap.get(op.AccountID + '-' + brand).CS__c <> null && 
                           accIDbrand_abMap.get(op.AccountID + '-' + brand).Support_Owner_Inactive__c == false) {                    
                        teamMember = new OpportunityTeamMember();
                        teamMember.UserId = accIDbrand_abMap.get(op.AccountID + '-' + brand).CS__c;
                        teamMember.TeamMemberRole = 'Support Owner';
                        teamMember.OpportunityId = op.ID;
                teamMember.Account_Brand__c =  accIDbrand_abMap.get(op.AccountID + '-' + brand).ID;
                
                        if (!key_OptyTeamMemberMap.containsKey(op.ID + '-' + accIDbrand_abMap.get(op.AccountID + '-' + brand).CS__c)) key_OptyTeamMemberMap.put(op.ID + '-' + accIDbrand_abMap.get(op.AccountID + '-' + brand).CS__c, teamMember);
                    }

              if (accIDbrand_abMap.containsKey(op.AccountID + '-' + brand) && 
                     accIDbrand_abMap.get(op.AccountID + '-' + brand).Primary_Owner__c <> null && 
                     accIDbrand_abMap.get(op.AccountID + '-' + brand).Primary_Owner_Inactive__c == false) {
                
                teamMember = new OpportunityTeamMember();
                teamMember.UserId = accIDbrand_abMap.get(op.AccountID + '-' + brand).Primary_Owner__c;
                teamMember.TeamMemberRole = 'Primary Owner';
                teamMember.OpportunityId = op.ID;
                teamMember.Account_Brand__c =  accIDbrand_abMap.get(op.AccountID + '-' + brand).ID;
                
                if (!key_OptyTeamMemberMap.containsKey(op.ID + '-' + accIDbrand_abMap.get(op.AccountID + '-' + brand).Primary_Owner__c)) key_OptyTeamMemberMap.put(op.ID + '-' + accIDbrand_abMap.get(op.AccountID + '-' + brand).Primary_Owner__c, teamMember);
              }
              
              if (accIDbrand_atmMap.containsKey(op.AccountID + '-' + brand) && 
                     accIDbrand_atmMap.get(op.AccountID + '-' + brand).User__c <> null && 
                     accIDbrand_atmMap.get(op.AccountID + '-' + brand).User_Inactive__c == false) {
                
                teamMember = new OpportunityTeamMember();
                teamMember.UserId = accIDbrand_atmMap.get(op.AccountID + '-' + brand).User__c;
                teamMember.TeamMemberRole = accIDbrand_atmMap.get(op.AccountID + '-' + brand).Role__c;
                teamMember.OpportunityId = op.ID;
                teamMember.Account_Brand__c =  accIDbrand_atmMap.get(op.AccountID + '-' + brand).Account_Brand__c;
                teamMember.Country__c = accIDbrand_atmMap.get(op.AccountID + '-' + brand).Country__c;
                
                if (!key_OptyTeamMemberMap.containsKey(op.ID + '-' + accIDbrand_atmMap.get(op.AccountID + '-' + brand).User__c)) key_OptyTeamMemberMap.put(op.ID + '-' + accIDbrand_atmMap.get(op.AccountID + '-' + brand).User__c, teamMember);
              }          
                }
            }
        }
        
        if (key_OptyTeamMemberMap.size() > 0 && key_OptyTeamMemberMap.values().size() > 0) {
            insert key_OptyTeamMemberMap.values();
            update newList;
        } 
      }

      //cc-1698
      private void BeginAutoRenewalOppLogic(List<Opportunity> newList) {
 
        Set<Id> oppIDs = new Set<Id>();
        Set<Id> oppsToCreateRenewalsFrom = new Set<Id>();
        List<Opportunity> oppList = new List<Opportunity>();

        for (Opportunity o : newList) {
          oppIDs.add(o.Id);
          oppList.add(o);
        }

        Map<Id, zqu__Quote__c> oppQuoteMap = new Map<Id, zqu__Quote__c>();  //id in this case is the Opp.Id - not the Quote Id.
        for (zqu__Quote__c q : [SELECT 
                    zqu__ZuoraSubscriptionID__c,
                    zqu__Opportunity__c,
                    Id,
                    BrandTag__c, 
                    zqu__ZuoraAccountID__c, 
                    (SELECT Id, 
                      zqu__ProductRatePlanCharge__r.Id, 
                      zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id, 
                      zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c,
                      zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c, 
                      zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c,
                      zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.BuildOppty__c
                    FROM zqu__QuoteCharge__r) 
                    FROM zqu__Quote__c 
                    WHERE IsSyncing__c = true AND zqu__Opportunity__c IN : oppIDs]) {

          if (!oppQuoteMap.containsKey(q.zqu__Opportunity__c)) oppQuoteMap.put(q.zqu__Opportunity__c, q);
        }

        Map<String, List<Excluded_Products__c>> excludedProductMap = new Map<String, List<Excluded_Products__c>>(); 
        for (Brand__c b : [SELECT Name, Id, (SELECT Product_Group__c,Product_SubCategory__c,Id FROM Excluded_Product_Groupings__r) FROM Brand__c])  {
          //todo - populate the map here.  the key is the brand text name...  
          if (!excludedProductMap.containsKey(b.Name)) excludedProductMap.put(b.Name, new List<Excluded_Products__c>());
          for (Excluded_Products__c ep : b.Excluded_Product_Groupings__r) {
            excludedProductMap.get(b.Name).add(ep);
          }
        }   

        for (Opportunity op : oppList) {
          if (oppQuoteMap.containsKey(op.Id) && (OpportunityTriggerHandler.RenewalOppShouldBeCreated(op, oppQuoteMap.get(op.Id), excludedProductMap))) oppsToCreateRenewalsFrom.add(op.Id);
        }

        if (oppsToCreateRenewalsFrom.size() > 0) OpportunityTriggerHandler.CreateRenewalOpps(oppsToCreateRenewalsFrom);
      }
      
    private void ProcessPaymentLinkLogic(List<Opportunity> oppList) {

      if (PreventRecursiveExecution.paymentLinksProcessed == false) {

        PreventRecursiveExecution.paymentLinksProcessed = true;

        List<Payment_Link__c> newLinkList = ReturnPaymentLinks(oppList);

        if (!newLinkList.isEmpty()) insert newLinkList;

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SendEmailResult> listEmailResult = new List<Messaging.SendEmailResult>();    //list of results of sending said emails
        List<Payment_Link_History__c> historyRecordsToInsert = new List<Payment_Link_History__c>(); //for logging the 'emailed' history action

        //Map for the opp owner's information:        
        Map<Id, Opportunity> oppOwnerMap = new Map<Id, Opportunity>();    //id = opportunity id, user = opportunity owner
        Set<Id> oppIds = new Set<Id>();

        for (Opportunity o : oppList) {
          oppIds.add(o.Id);
        }

        for (Opportunity o : [SELECT Owner.Name, Owner.Email, Owner.Id, Id, Contact__r.Email FROM Opportunity WHERE Id IN :oppIds]) {
          if (!oppOwnerMap.containsKey(o.Id)) oppOwnerMap.put(o.Id, o);
        }

        //Get the correct template Id now:
        EmailTemplate et = null;
        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName =:Label.Payment_Link_Email_Template_Automatic];

        if (templateList != null && !templateList.isEmpty()) et = templateList[0];

        if (!newLinkList.isEmpty()) {
          List<OrgWideEmailAddress> oweaList = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'donotreply@dhigroupinc.com'];
          for (Payment_Link__c pl : newLinkList) {

              Messaging.SingleEmailMessage thisEmail = CCCaptureUtilities.CreatePaymentEmail(pl.Id, pl.Contact__c, et.Id);
              
              //adjust the 'FROM' display name and email address now

              if (!oweaList.isEmpty()) thisEmail.setOrgWideEmailAddressId(oweaList[0].Id);

              //thisEmail.setReplyTo(oppOwnerMap.get(pl.Opportunity__c).Owner.Email);   //this only will work if it's an org-wide email address.  Specific ones will not function.
              //thisEmail.setSenderDisplayName(oppOwnerMap.get(pl.Opportunity__c).Owner.Name);

              emailsToSend.add(thisEmail);

              Payment_Link_History__c plh = PaymentLinkTriggerHandler.ReturnNewLinkHistoryRecord(pl.Id, 'Emailed to ' + oppOwnerMap.get(pl.Opportunity__c).Contact__r.Email , 'Salesforce.com');
              historyRecordsToInsert.add(plh);
          }
        }

        if (emailsToSend.size() > 0) listEmailResult = Messaging.sendEmail(emailsToSend);

        if (!historyRecordsToInsert.isEmpty()) insert historyRecordsToInsert;          
      }        
    }   

    //Called only from the previous method, 'ProcessPaymentLinkLogic'
    //This is the 'bulkified' version.  The singular version (for use on the visualforce page) is in the WebServices class
    private List<Payment_Link__c> ReturnPaymentLinks(List<Opportunity> oppList) {

        List<Payment_Link__c> newLinkList = new List<Payment_Link__c>();

        for (Opportunity o : oppList) {

            Payment_Link__c newLink = new Payment_Link__c();
            newLink.Opportunity__c = o.Id;
            newLink.Contact__c = o.Contact__c;
            newLink.Reason__c = 'Docusign Quote';
            
            if (o.Sold_By_Partner__c == null) newLink.Link_Created_For__c = 'Customer';
            else newLink.Link_Created_For__c = 'Sold By Partner';

            newLinkList.add(newLink);
        }

        return newLinkList;
    }
    
}