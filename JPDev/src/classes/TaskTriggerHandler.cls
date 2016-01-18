/***
*Class          ---- TaskTriggerHandler
*Author         ---- Naresh Ojha (Appirio Offshore)
*Story          ---- Initial implementation
*Created Date   ---- 2013.03.03
*Description    ---- Class that contains all of the functionality called by the TaskTrigger.
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Tim Byrnes
*Story          ---- CCBOB-153, Set new Account_Brand__c field
*Modified Date  ---- 2015.12.01
*Description    ---- Added new logic to fire OnBeforeInsert

*Modified By    ---- Jaseem Pookandy
*Story          ---- CCBOB-189, populate department and division of task owner
*Modified Date  ---- 2016.10.14
*Description    ---- Added new logic to fire OnBeforeInsert and onBeforeUpdate
***/

public with sharing class TaskTriggerHandler {

    private boolean m_isExecuting = false;  
    private integer BatchSize = 0;
  
    //Constructor
    public TaskTriggerHandler(boolean isExecuting, integer size) {

        if (!PreventRecursiveExecution.dummyEmailCreateInProgress) {
            m_isExecuting = isExecuting;
            BatchSize = size;
        }
    }  

    //On Before insert trigger method
    public void OnBeforeInsert(List<Task> newList) {   

        SetAccountBrandForOutboundEmail(newList);
        
        populateOwnerDepartmentDivision(newList,null);

        if (!PreventRecursiveExecution.dummyEmailCreateInProgress) populateFields (newList);

    }

    // On Before update trigger method
    public void OnBeforeUpdate (Map<Id, Task> oldMap, Map<Id, Task> newMap) {
        
        populateOwnerDepartmentDivision(newMap.values(),oldMap);
        if (!PreventRecursiveExecution.dummyEmailCreateInProgress) {
            //CC-597
            //split the map into two - one for tasks that WERE related to Leads and are NOW related to Contacts (conversion)
            //and another for all others...
            Map<Id, Task> oldMapConverted = new Map<Id, Task>();
            Map<Id, Task> newMapConverted = new Map<Id, Task>();
            Map<Id, Task> oldMapNotConverted = new Map<Id, Task>();
            Map<Id, Task> newMapNotConverted = new Map<Id, Task>();
            
            for (Task t : oldMap.values()) {
                if ((t.WhoId != null) && (newMap.get(t.Id).WhoId != null)) {
                    if ((String.valueOf(t.WhoId).StartsWith('00Q')) && (String.valueOf(newMap.get(t.Id).WhoId).StartsWith('003'))) {
                        //add it to the ConvertedMap...
                        oldMapConverted.put(t.Id, oldMap.get(t.Id));
                        newMapConverted.put(t.Id, newMap.get(t.Id));
                    }
                    else {
                        //add it to the NOTconverted map...
                        oldMapNotConverted.put(t.Id, oldMap.get(t.Id));
                        newMapNotConverted.put(t.Id, newMap.get(t.Id));
                    }
                }
                else {
                    //add it to the NOTconverted map...
                    oldMapNotConverted.put(t.Id, oldMap.get(t.Id));
                    newMapNotConverted.put(t.Id, newMap.get(t.Id));
                }
            }
        
            if (PreventRecursiveExecution.isFirstRun) {
                PreventRecursiveExecution.isFirstRun = false;
                populateFields (newMapNotConverted.values());
            }   
            
            if (newMapConverted.size() > 0) populateFields (newMapConverted.values());    
        }
    }  


    //On After insert trigger method
    public void OnAfterInsert(List<Task> newList) {         
        //Nothing currently... 
    }

  
    //On After update trigger method
    public void OnAfterUpdate (Map<Id, Task> oldMap, Map<Id, Task> newMap) {                                     
        //Nothing currently... 
    }

    private void SetAccountBrandForOutboundEmail(List<Task> newList) {
        //Called OnBeforeInsert only for when users click the 'Send Email' button from inside Salesforce.
        //This sets the 'Account_Brand__c' field to the existing 'WhatId' field, assuming it is an Account_Brand__c record.
        //It also then crawls the parent of the account brand record and finds the account it belongs to and assigns that to the WhatId.
        //All related to CCBOB-153.

        //First, find the key prefix for the Account_Brand__c object:
        String accountBrandKeyPrefix = Account_Brand__c.sObjectType.getDescribe().getKeyPrefix();       //should be something like 'a03'.
        Set<Id> accountBrandIdSet = new Set<Id>();

        for (Task t : newList) {
            //If the task is completed, the whatId starts with accountBrandKeyPrefix and the Account_Brand__c field is null
            if (t.Subject != null && t.Subject.startsWithIgnoreCase('email:') && t.Status.equalsIgnoreCase('Completed') && t.WhatId != null &&String.valueOf(t.WhatId).startsWith(accountBrandKeyPrefix) && t.Account_Brand__c == null) {
                //If we're here then we need to get the data for this WhatId as it's a contender.
                accountBrandIdSet.add(t.WhatId);
            }
        }

        //Now create/populate the accountBrandMap to finish our data collection
        Map<Id, Account_Brand__c> accountBrandMap = new Map<Id, Account_Brand__c> ([SELECT Id, Name, Account__c FROM Account_Brand__c WHERE Id IN :accountBrandIdSet]);


        //Data is collected, now we begin the actual processing / editing of the records where necessary:
        for (Task t : newList) {

            if (t.Subject != null && t.Subject.startsWithIgnoreCase('email:') && t.Status.equalsIgnoreCase('Completed') && t.WhatId != null && String.valueOf(t.WhatId).startsWith(accountBrandKeyPrefix) && t.Account_Brand__c == null && accountBrandMap.containsKey(t.WhatId)) {
                //If we're here then we have met all our criteria to set the values:
                t.Account_Brand__c = t.WhatId;
                t.WhatId = accountBrandMap.get(t.WhatId).Account__c;
            }
        }
    }

    //Only called  by populateFields IF tasks have WhatIds that are not Accounts.
    //Returns nested list.  the first ID is an example ID of the type in the matching collection.
    //i.e. 009adsfladsfda, List<Id> 009adsfladsfda, 009dsaflkdsaj, 009, adslfkjdsaf
    //This is so the metadata method getDescribe can be called efficiently, and also the matching SOQL statements used to retrieve the exact records.
    public static Map<Id, List<Id>> OrganizeLeftoverWhatIDs(List<Id> whatIDs) {
    
        whatIDs.sort();
        
        Id currentID;
        String currentFirst3;
        Id previousID;
        String previousFirst3;
        
        Map<Id, List<Id>> result = new Map<Id, List<Id>>();
        Set<Id> idSet = new Set<Id>();
        List<Id> idSetList = new List<Id>();
        
        for (Id thisId : whatIDs) {
        
            currentID = thisId;
            currentFirst3 = String.valueOf(thisId).substring(0, 3);
        
            if (previousFirst3 != currentFirst3) {
                //Then we need to reset the list, but first, add the id/set to the result
                if (idSet.size() > 0) {
                    idSetList.clear();
                    idSetList.addAll(idSet);
                    List<Id> finalList = idSetList.clone();
                    result.put(previousID, finalList);          
                }
                idSet.clear();
            }
            
            idSet.add(currentID);
        
        
            previousID = currentID;
            previousFirst3 = currentFirst3;
        }
        
        if (idSet.size() > 0) {
            idSetList.clear();
            idSetList.addAll(idSet);
            List<Id> finalList = idSetList.clone();
            result.put(previousID, finalList);                      
        }
        
        return result;
    }
  
    //T-120810: Copy Due Date in Custom Activity Field
    private void populateFields (List<Task> newList) {
    
        Set<Id> accountIDs = new Set<Id>(); //this is the master accountID set to be used in the task selection for statement.  The tricky part is populating this set because task.AccountId can't be trusted at this point in time.
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

        for (Task t : newList) {

            if (t.WhatId != null) {
                if (String.valueOf(t.WhatId).startsWith('001')) { 
                    accountIDs.add(t.WhatId);
                    if (!WhatIdtoAccountId.containsKey(t.WhatId)) WhatIdtoAccountId.put(t.WhatId, t.WhatId);
                }
                else WhatIds.add(t.WhatId);
            }
            
            if (t.WhoId != null ) {
                if (String.valueOf(t.WhoId).startsWith('003')) contactIDs.add(t.WhoId);     //contacts always begin with '003'
                if (String.valueOf(t.WhoId).startsWith('00Q')) leadIDs.add(t.WhoId);        //leads always begin with '00Q'
            }      
            
            if (t.OwnerId <> null) OwnerIds.Add(t.OwnerId);
                 
        }

        if (WhatIds.size() > 0) {
            whatIDsToProcess = OrganizeLeftoverWhatIDs(WhatIds);

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
                    if (o.AccountId != null) {
                        accountIDs.add(o.AccountId);
                        if (!WhatIdtoAccountId.containsKey(o.Id)) WhatIdtoAccountId.put(o.Id, o.AccountId);
                    }
                }
            }
            
            if (AccountBrandIDs.size() > 0) {
                for (Account_Brand__c ab : [SELECT Account__c, Id FROM Account_Brand__c WHERE Id IN : AccountBrandIDs]) {
                    if (ab.Account__c != null) {
                        accountIDs.add(ab.Account__c);
                        if (!WhatIdtoAccountId.containsKey(ab.Id)) WhatIdtoAccountId.put(ab.Id, ab.Account__c);
                    }
                }   
            }
            
            if (CaseIDs.size() > 0) {
                for (Case c : [SELECT AccountId, Id FROM Case WHERE Id IN : CaseIDs]) {
                    if (c.AccountId != null) {
                        accountIDs.add(c.AccountId);
                        if (!WhatIdtoAccountId.containsKey(c.Id)) WhatIdtoAccountId.put(c.Id, c.AccountId);
                    }
                }
            }
            
            if (ProductUserIDs.size() > 0) {
                for (Product_User__c pu : [SELECT Account__c, Id FROM Product_User__c WHERE Id IN : ProductUserIDs]) {
                    if (pu.Account__c != null) {
                        accountIDs.add(pu.Account__c);
                        if (!WhatIdtoAccountId.containsKey(pu.Id)) WhatIdtoAccountId.put(pu.Id, pu.Account__c);
                    }
                }
            }
            
            if (UserGroupIDs.size() > 0) {
                for (User_Group__c ug : [SELECT Account__c, Id FROM User_Group__c WHERE Id IN : UserGroupIDs]) {
                    if (ug.Account__c != null) {
                        accountIDs.add(ug.Account__c);
                        if (!WhatIdtoAccountId.containsKey(ug.Id)) WhatIdtoAccountId.put(ug.Id, ug.Account__c);
                    }
                }
            }
            
            if (WebstoreOrderIDs.size() > 0) {
                for (Webstore_Order__c wo : [SELECT Account__c, Id FROM Webstore_Order__c WHERE Id IN : WebstoreOrderIDs]) {
                    if (wo.Account__c != null) {
                        accountIDs.add(wo.Account__c);
                        if (!WhatIdtoAccountId.containsKey(wo.Id)) WhatIdtoAccountId.put(wo.Id, wo.Account__c);
                    }
                }
            }
        }

        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        Map<String, Account_Brand__c> accountBrandMap = new Map<String, Account_Brand__c>();
        Map<Id, User> UserMap = new Map<Id, User>();

        for (Account a : [SELECT Id, Name, BillingCountry, BillingState, (SELECT Rank__c, Name, Id, Brand_Picklist__c, Status__c FROM Account_Brands__r) FROM Account WHERE Id IN :accountIDs]) {
            if (!accountMap.containsKey(a.Id)) accountMap.put(a.Id, a);

            //Yes this contains a lot more records than necessary - but this will save on SOQL calls - we just need to weed out when used.
            for (Account_Brand__c ab : a.Account_Brands__r) {
                if (!accountBrandMap.containsKey(a.Id + '<>' + ab.Brand_Picklist__c)) accountBrandMap.put(a.Id + '<>' + ab.Brand_Picklist__c, ab);
            }       
        }

        for (Contact c : [SELECT Id, MailingCountry, MailingState FROM Contact WHERE Id IN :contactIDs]) {
            if (!contactMap.containsKey(c.Id)) contactMap.put(c.Id, c);
        }

        for (Lead l : [SELECT Id, Country, State, Rank__c FROM Lead WHERE Id IN :leadIDs]) {
            if (!leadMap.containsKey(l.Id)) leadMap.put(l.Id, l);
        }       
        //Byrnes CC-597 end  

        //CC-780 - Bergman - first build a map of users and default brands, so we don't have to query inside a for-loop
        for (User u : [Select Id, DefaultBrand__c FROM User where Id in :OwnerIds])  {
            if (!UserMap.containsKey(u.Id)) UserMap.put(u.Id, u);
        }
        // end bergman

        for (Task t : newList) {
            if (t.ActivityDate <> null) t.Due_Date__c = t.ActivityDate;

            if (t.Description <> null) {
                Integer length = t.Description.length() < 255 ? t.Description.length() : 255;
                t.Short_Description_Raw__c = String.valueOf(t.Description).substring(0, length);
            }

                    
            //CC-780 - Bergman
            
            /////////////////////////////////////////////////////////////////////////////////////////////
            // CC-2497 - wrubel -  The original code is below:
            //if ((t.Subject != null) && (t.Subject.startsWith('Email:') && t.Status == 'Completed')) {
            //
            // Outlook plugin changed to lowercase email
            ///////////////////////////////////////////////////////////////////////////////////////////////
            if ((t.Subject != null) && ((t.Subject.startsWith('Email:') || t.Subject.startsWith('email:')) )) {                
                if (t.Status == 'Completed') {    
                    //system.debug('&&&&&&&&&& Closed and Subject = ' + t.Subject);
                    if (t.Brand__c == null) {
                        if ((UserMap.containsKey(t.OwnerId)) && (UserMap.get(t.OwnerId).DefaultBrand__c != null)) t.Brand__c = UserMap.get(t.OwnerId).DefaultBrand__c;
                    }

                    //Since we cannot differentiate inbound vs outbound, we will use a default email type that is not part of the PickList
                    if (t.Type__c == null) t.Type__c = 'EMAIL';    
                }
            }
            //end bergman
                            
            //begin Byrnes, CC-597
            if ((t.Status != 'Completed') && (t.Status != 'Cancelled')) {
                //Account Brand Rank stuff...
                //make sure it's in the map first...
                Id thisAccountID;
                if (WhatIdtoAccountId.containsKey(t.WhatId)) {
                    thisAccountID = WhatIdtoAccountId.get(t.WhatId);
                    if (accountBrandMap.containsKey(thisAccountID + '<>' + t.Brand__c)) t.Account_Brand_Rank__c = accountBrandMap.get(thisAccountID + '<>' + t.Brand__c).Rank__c;
                    else t.Account_Brand_Rank__c = '';
                }
                else t.Account_Brand_Rank__c = '';
                           
                //set the account stuff...
                if (WhatIdtoAccountId.containsKey(t.WhatId)) {
                    Account matchingAccount = accountMap.get(WhatIdtoAccountId.get(t.WhatId));          
                    t.Country_Account__c = matchingAccount.BillingCountry;                
                    t.State_Account__c = matchingAccount.BillingState;
                    t.AccountLookup__c = matchingAccount.Id;       //CCBOB-83
                    t.AccountID__c = matchingAccount.Id;
                    t.Account_Name__c = matchingAccount.Name;
                }
                else {
                    t.Country_Account__c = '';
                    t.State_Account__c = '';
                    t.AccountLookup__c = null;     //CCBOB-83
                    t.AccountID__c = '';
                    t.Account_Name__c = '';
                }
                
                //If the who ID is a contact
                if (t.WhoId != null) {
                    if (String.valueOf(t.WhoId).startsWith('003')) {
                        //if the ID is in the map (it always should be, but just in case...
                        if (contactMap.containsKey(t.WhoId)) {
                            Contact matchingContact = contactMap.get(t.WhoId);
                            t.Country_Person__c = matchingContact.MailingCountry;
                            t.State_Person__c = matchingContact.MailingState;
                        }
                        else {
                            t.Country_Person__c = '';
                            t.State_Person__c = '';
                        }
                    }
                
                    //if the whoID is a Lead
                    else if (String.valueOf(t.WhoId).startsWith('00Q')) { 
                        //if the ID is in the map (it always should be, but just in case...
                        if (leadMap.containsKey(t.WhoId)) {
                            Lead matchingLead = leadMap.get(t.WhoId);
                            t.Country_Person__c = matchingLead.Country;
                            t.State_Person__c = matchingLead.State;
                            t.Account_Brand_Rank__c = matchingLead.Rank__c;
                        }
                        else {
                            t.Country_Person__c = '';
                            t.State_Person__c = '';
                        }           
                    }
                }
            }
            else {
                //clear the values out
                t.Country_Person__c = '';
                t.State_Person__c = '';
                t.Country_Account__c = '';
                t.State_Account__c = '';
                t.Account_Brand_Rank__c = '';
                t.AccountID__c = '';
                t.Account_Name__c = '';

                if (WhatIdtoAccountId.containsKey(t.WhatId)) {
                    Account matchingAccount = accountMap.get(WhatIdtoAccountId.get(t.WhatId));          
                    t.AccountLookup__c = matchingAccount.Id;       //CCBOB-83
                }
            }        
            //end Byrnes, CC-597
        }

        //The fields (Brand picklist, account lookup, etc) should now be correctly populated.
        //Now we set the Account Brand lookup based on the Brand picklist value IF and only IF the Account Brand lookup is null.
        //(We never want to override a value that the user may have deliberately selected.)

        SetAccountBrandLookupBasedOnBrandPicklist(newList, WhatIdtoAccountId);

    }  

    private void SetAccountBrandLookupBasedOnBrandPicklist(List<Task> newList, Map<Id, Id> relatedObjectIdtoAccountId) {

        //relatedObjectIdtoAccountId contains the whatId and then the AccountId as the value.
        //First we need to append to this map in case if whatId is blank but whoId has a value.
        //We need to get all the AccountBrand records for said accountIds and then fill in the AccountBrand lookup

        //First we'll ensure that this actually needs to run.  We're close on SOQLs for lead conversion so we'll loop through first:
        Boolean bContinue = false;
        for (Task t : newList) {
            if (t.Account_Brand__c == null && t.Brand__c != null) {
                bContinue = true;  
                break;
            } 
        }

        if (!bContinue) return;     //exit if this logic isn't necessary...

        Set<Id> accountIds = new Set<Id>(); //all accountIds in play.  Sourced from crawling t.WhatId up the chain to the account.  (Already done, passed in as 'relatedObjectIdtoAccountId')
        Set<Id> contactIds = new Set<Id>();

        for (Task t : newList) {
           if ((t.WhatId == null || (t.whatid!=null && !relatedObjectIdtoAccountId.containskey(t.whatid)))&& t.WhoId != null && String.valueOf(t.WhoId).startsWithIgnoreCase('003')) contactIds.add(t.WhoId);
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

        for (Task t : newList) {

            //Since we could be finding the correct account brand lookup via either whatId or whoId (if whatId is blank) we set and use this variable for searching the map.
            Id idToUse = null;
            if (t.WhatId != null && relatedObjectIdtoAccountId.containskey(t.whatId)) idToUse = t.WhatId;
            else if (t.whoId != null) idToUse = t.WhoId;

            if (t.Account_Brand__c == null && t.Brand__c != null && relatedObjectIdtoAccountId.containsKey(idToUse) && accountBrandMap.containsKey(relatedObjectIdtoAccountId.get(idToUse) + '~' + t.Brand__c)) {
                t.Account_Brand__c = accountBrandMap.get(relatedObjectIdtoAccountId.get(idToUse) + '~' + t.Brand__c).Id;
            }
        }
    }   //end SetAccountBrandLookupBasedOnBrandPicklist
    //method that populates department and division of task owner as long as it is open
      private void populateOwnerDepartmentDivision(list<Task> newList,map<id,Task> oldMap){
        Set<Id>OwnerIDSet = new Set<ID>();
        map<id,User> MapUser = new map<id,User>();        
        
           
            for(Task t:newList){
                //oldmap is null for insert, on an update check if it is an update to owner and status is open
                    if(oldMap==null || (oldMap.containskey(t.id) && oldMap.get(t.id).ownerid!=t.ownerid && (t.status == 'Not Started' || t.status == 'In Progress'))){
                        OwnerIdSet.add(t.ownerid);
                    }
            }
                
        if(!OwnerIdSet.isEmpty()){
           
            for(User owner: [select id,Department,Division from User where id in:OwnerIDSet]){
                MapUser.put(owner.id,owner);
            }
            for(Task t:newList){
                
                t.Activity_Department_fw__c = MapUser.get(t.ownerid).Department !=null ? MapUser.get(t.ownerid).Department:'';
                t.Activity_Division_fw__c = MapUser.get(t.ownerid).Division !=null? MapUser.get(t.ownerid).Division:'';
            }
        }
    }
}