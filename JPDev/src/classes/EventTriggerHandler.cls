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

public with sharing class EventTriggerHandler {

    private boolean m_isExecuting = false;  
    private integer BatchSize = 0;
  
    //Constructor
    public EventTriggerHandler(boolean isExecuting, integer size) {

        if (!PreventRecursiveExecution.dummyEmailCreateInProgress) {
            m_isExecuting = isExecuting;
            BatchSize = size;
        }
    }  

    //On Before insert trigger method
    public void OnBeforeInsert(List<Event> newList) {   

        populateFields (newList);
    
    }

    // On Before update trigger method
    public void OnBeforeUpdate (Map<Id, Event> oldMap, Map<Id, Event> newMap) {
   
        populateFields (newMap.values());

    }  


    //On After insert trigger method
    public void OnAfterInsert(List<Event> newList) {         
        //Nothing currently...
    }

  
    //On After update trigger method
    public void OnAfterUpdate (Map<Id, Event> oldMap, Map<Id, Event> newMap) {                                     
        //Nothing currently...
    }
    

    private void populateFields (List<Event> newList) {
    
        //This method doesn't really populate fields - instead it helps collect and organize the data so that the method at the end
        //can correctly populate the account brand picklist.

        Set<Id> accountIDs = new Set<Id>(); //this is the master accountID set to be used in the Event selection for statement.  The tricky part is populating this set because Event.AccountId can't be trusted at this point in time.
        Set<Id> contactIDs = new Set<Id>();
        Set<Id> leadIDs = new Set<Id>();        

        List<Id> WhatIds = new List<Id>();       
        Set<Id> accountWhatIDs = new Set<Id>();

        Set<Id> AccountBrandIDs     = new Set<Id>();
        Set<Id> CaseIDs             = new Set<Id>();
        Set<Id> OpportunityIDs      = new Set<Id>();
        Set<Id> ProductUserIDs      = new Set<Id>();
        Set<Id> UserGroupIDs        = new Set<Id>();
        Set<Id> WebstoreOrderIDs    = new Set<Id>();
        Set<Id> OwnerIds            = new Set<Id>();

        Map<Id, Id> WhatIdtoAccountId = new Map<Id, Id>();
        Map<Id, List<Id>> whatIDsToProcess = new Map<Id, List<Id>>();

        for (Event e : newList) {

            if (e.WhatId != null) {
                if (String.valueOf(e.WhatId).startsWith('001')) { 
                    accountIDs.add(e.WhatId);
                    if (!WhatIdtoAccountId.containsKey(e.WhatId)) WhatIdtoAccountId.put(e.WhatId, e.WhatId);
                }
                else WhatIds.add(e.WhatId);
            }
            
            if (e.WhoId != null ) {
                if (String.valueOf(e.WhoId).startsWith('003')) contactIDs.add(e.WhoId);     //contacts always begin with '003'
                if (String.valueOf(e.WhoId).startsWith('00Q')) leadIDs.add(e.WhoId);        //leads always begin with '00Q'
            }      
            
            if (e.OwnerId <> null) OwnerIds.Add(e.OwnerId);
                 
        }

        if (WhatIds.size() > 0) {
            whatIDsToProcess = TaskTriggerHandler.OrganizeLeftoverWhatIDs(WhatIds);

            Schema.Sobjecttype token;

            for (List<Id> thisList : whatIDsToProcess.values()) {
                
                token = thisList.get(0).getSObjectType();
                Schema.DescribeSObjectResult dr = token.getDescribe();
                
                if (dr.getName() == 'Opportunity') OpportunityIDs.addAll(thisList);        
                else if (dr.getName() == 'Account_Brand__c') AccountBrandIDs.addAll(thisList);
                else if (dr.getName() == 'Case') CaseIDs.addAll(thisList);
                else if (dr.getName() == 'Product_User__c') ProductUserIDs.addAll(thisList);
                else if (dr.getName() == 'User_Group__c') UserGroupIDs.addAll(thisList);
                else if (dr.getName() == 'Webstore_Order__c') WebstoreOrderIDs.addAll(thisList);
            }
            
            //We now have the IDs properly split up and ready to query to get the actual AccountId related...
            
            if (OpportunityIDs.size() > 0) {
                for (Opportunity o : [SELECT AccountId, Id FROM Opportunity WHERE Id IN : OpportunityIDs]) {
                    if (o.AccountId != null && (!WhatIdtoAccountId.containsKey(o.Id))) WhatIdtoAccountId.put(o.Id, o.AccountId);
                }
            }
            
            if (AccountBrandIDs.size() > 0) {
                for (Account_Brand__c ab : [SELECT Account__c, Id FROM Account_Brand__c WHERE Id IN : AccountBrandIDs]) {
                    if (ab.Account__c != null && (!WhatIdtoAccountId.containsKey(ab.Id))) WhatIdtoAccountId.put(ab.Id, ab.Account__c);
                }   
            }
            
            if (CaseIDs.size() > 0) {
                for (Case c : [SELECT AccountId, Id FROM Case WHERE Id IN : CaseIDs]) {
                    if (c.AccountId != null && (!WhatIdtoAccountId.containsKey(c.Id))) WhatIdtoAccountId.put(c.Id, c.AccountId);
                }
            }
            
            if (ProductUserIDs.size() > 0) {
                for (Product_User__c pu : [SELECT Account__c, Id FROM Product_User__c WHERE Id IN : ProductUserIDs]) {
                    if (pu.Account__c != null && (!WhatIdtoAccountId.containsKey(pu.Id))) WhatIdtoAccountId.put(pu.Id, pu.Account__c);
                }
            }
            
            if (UserGroupIDs.size() > 0) {
                for (User_Group__c ug : [SELECT Account__c, Id FROM User_Group__c WHERE Id IN : UserGroupIDs]) {
                    if (ug.Account__c != null && (!WhatIdtoAccountId.containsKey(ug.Id))) WhatIdtoAccountId.put(ug.Id, ug.Account__c);
                }
            }
            
            if (WebstoreOrderIDs.size() > 0) {
                for (Webstore_Order__c wo : [SELECT Account__c, Id FROM Webstore_Order__c WHERE Id IN : WebstoreOrderIDs]) {
                    if (wo.Account__c != null && (!WhatIdtoAccountId.containsKey(wo.Id))) WhatIdtoAccountId.put(wo.Id, wo.Account__c);
                }
            }
        }

        //Now we set the Account Brand lookup based on the Brand picklist value IF and only IF the Account Brand lookup is null.
        //(We never want to override a value that the user may have deliberately selected.)

        SetAccountBrandLookupBasedOnBrandPicklist(newList, WhatIdtoAccountId);
    }  

    private void SetAccountBrandLookupBasedOnBrandPicklist(List<Event> newList, Map<Id, Id> relatedObjectIdtoAccountId) {

        //relatedObjectIdtoAccountId contains the whatId and then the AccountId as the value.
        //First we need to append to this map in case if whatId is blank but whoId has a value.
        //We need to get all the AccountBrand records for said accountIds and then fill in the AccountBrand lookup

        //First we'll ensure that this actually needs to run.
        Boolean bContinue = false;
        for (Event e : newList) {
            if (e.Account_Brand__c == null && e.Brand__c != null) {
                bContinue = true;  
                break;
            } 
        }

        if (!bContinue) return;     //exit if this logic isn't necessary...

        Set<Id> accountIds = new Set<Id>(); //all accountIds in play.  Sourced from crawling e.WhatId up the chain to the account.  (Already done, passed in as 'relatedObjectIdtoAccountId')
        Set<Id> contactIds = new Set<Id>();

        for (Event e : newList) {
            if (e.WhatId == null && e.WhoId != null && String.valueOf(e.WhoId).startsWithIgnoreCase('003')) contactIds.add(e.WhoId);
        }

        if (!contactIds.isEmpty()) {
            for (Contact c : [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds]) {
                relatedObjectIdtoAccountId.put(c.Id, c.AccountId);
            }
        }

        //key = accountId + '~' + brandname, value = account brand Id
        Map<String, Account_Brand__c> accountBrandMap = new Map<String, Account_Brand__c>();

        for (Account_Brand__c ab : [SELECT Id, Name, Brand_Picklist__c, Account__c FROM Account_Brand__c WHERE Account__c IN :relatedObjectIdtoAccountId.values()]) {
            accountBrandMap.put(ab.Account__c + '~' + ab.Brand_Picklist__c, ab);
        }

        //We now have all the data we need collected - time to set the Account_Brand__c lookup field...

        for (Event e : newList) {

            //Since we could be finding the correct account brand lookup via either whatId or whoId (if whatId is blank) we set and use this variable for searching the map.
            Id idToUse = null;
            if (e.WhatId != null) idToUse = e.WhatId;
            else if (e.whoId != null) idToUse = e.WhoId;

            if (e.Account_Brand__c == null && e.Brand__c != null && relatedObjectIdtoAccountId.containsKey(idToUse) && accountBrandMap.containsKey(relatedObjectIdtoAccountId.get(idToUse) + '~' + e.Brand__c)) {
                e.Account_Brand__c = accountBrandMap.get(relatedObjectIdtoAccountId.get(idToUse) + '~' + e.Brand__c).Id;
            }
        }
    }   //end SetAccountBrandLookupBasedOnBrandPicklist
}