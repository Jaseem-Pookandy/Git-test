/***
*Class          ---- AccountTriggerHandler
*Author         ---- Tim Byrnes
*Story          ---- Initial Implementation
*Created Date   ---- 2012.12.11
*Description    ---- Class that contains all of the functionality called by the AccountTrigger
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Byrnes
*Story          ---- CCBOB-220
*Modified Date  ---- 2015.12.10
*Description    ---- Added UltimateParent logic, rev 1.
***/

public with sharing class AccountTriggerHandler {
    
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  private static final String ADDRESS_SYNC_NAME = 'Sync Account Address Edits to Contacts';
  
  //Constructor
  public AccountTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }  

  //On Before insert trigger method
  public void OnBeforeInsert(List<Account> newList) {   
    accountOwnerShipToDice (newList);   
    SetUltimateParent(newList); 
  }

  // On Before update trigger method
  public void OnBeforeUpdate (Map<Id, Account> oldMap, Map<Id, Account> newMap) {    
    accountOwnerShipToDice (newMap.values());
    SetUltimateParent(newMap.values());
    //createChatterAlert (oldMap, newMap);  
  }

  //On after insert trigger method
  public void OnAfterInsert(Map<Id, Account> newMap) {   
    if(System.Userinfo.getLastName() != 'Migration') createAccountBrandRecords(newMap.values()) ;
    
    // SetUltimateParent(newMap.values());

    if (PreventRecursiveExecution.isFirstRun) {        
        PreventRecursiveExecution.isFirstRun = false;
        UpdateStateCountryOnOpenTasks(newMap);
    }              
  }  

  // On after update trigger method
  public void OnAfterUpdate (Map<Id, Account> oldMap, Map<Id, Account> newMap) {    
    //createChatterAlert (oldMap, newMap);
    
    //byrnes, 2013.09.05
    if (PreventRecursiveExecution.isFirstRun) {
      PreventRecursiveExecution.isFirstRun = false;
      UpdateStateCountryOnOpenTasks(oldMap, newMap);
    }       
    
    CascadeAddressChangesToContacts(oldMap, newMap);
           
    updateValidationRuleOverride (oldMap, newMap.values());    
  }
  
  // On after update trigger method
  public void OnAfterDelete (Map<Id, Account> oldMap) {    
    PreventRecursiveExecution.isFirstRun = false;
    UpdateOpenTasksFromDelete(oldMap);    
  }  

  
 private void SetUltimateParent(List<Account> newList) {

    //If this logic has already executed, bug out.  
    if (PreventRecursiveExecution.ultimateParentSet) return;

    //Set this to true so it can't execute multiple times.
    PreventRecursiveExecution.ultimateParentSet = true;

    //This is *not* a complete solution as it never recalculates other records.  This only updates the current record.
    //This is merely a replacement for the *current* ultimate parent implementation.  Recommended solution is for a talend job to process this
    //data in batch on a schedule.

    Set<Id> parentAccountIdSet = new Set<Id>();
    Map<Id, Id> accountIdToTopId = new Map<Id, Id>();
    List<Account> accountsToUpdate = new List<Account>();

    for (Account a : newList) {
      if (a.ParentId != null) parentAccountIdSet.add(a.ParentId);
      else a.UltimateParentId__c = null;  //If no parent is set, self is ultimate parent so indicate this by setting it to blank
    }

    for (Account a : [SELECT  Id, 
                              Name, 
                              ParentId,
                              Parent.Id,
                              Parent.ParentId,
                              Parent.Parent.Id, 
                              Parent.Parent.ParentId, 
                              Parent.Parent.Parent.Id,
                              Parent.Parent.Parent.ParentId,
                              Parent.Parent.Parent.Parent.Id,
                              Parent.Parent.Parent.Parent.ParentId,
                              Parent.Parent.Parent.Parent.Parent.Id,
                              Parent.Parent.Parent.Parent.Parent.ParentId
                      FROM Account WHERE Id IN :parentAccountIdSet]) {

      if (a != null && a.Parent != null) {
        //Then we know we have *at least* one parent
        if (a.Parent.Parent != null && a.Parent.Parent.Parent != null && a.Parent.Parent.Parent.Parent != null && a.Parent.Parent.Parent.Parent.Parent != null) {
          //if we're here, we have as many parents as we can crawl in SOQL (5)
          if (a.Parent.Parent.Parent.Parent.Parent.ParentId != null) accountIdToTopId.put(a.Id, a.Parent.Parent.Parent.Parent.Parent.ParentId);
          else accountIdToTopId.put(a.Id, a.Parent.Parent.Parent.Parent.Parent.Id);
        }
        else if (a.Parent.Parent != null && a.Parent.Parent.Parent != null && a.Parent.Parent.Parent.Parent != null && a.Parent.Parent.Parent.Parent.Parent == null) accountIdToTopId.put(a.Id, a.Parent.Parent.Parent.Parent.Id);
        else if (a.Parent.Parent != null && a.Parent.Parent.Parent != null && a.Parent.Parent.Parent.Parent == null) accountIdToTopId.put(a.Id, a.Parent.Parent.Parent.Id);
        else if (a.Parent.Parent != null && a.Parent.Parent.Parent == null) accountIdToTopId.put(a.Id, a.Parent.Parent.Id);
        else if (a.Parent.Parent == null) accountIdToTopId.put(a.Id, a.Parent.Id);
        else accountIdToTopId.put(a.Id, a.Id);    //This line should never execute.
      }
      //else we have *no* parents, time to self-reference as requested.
      else accountIdToTopId.put(a.Id, a.Id);
    }

    for (Account a : newList) {
      if (a.ParentId != null && accountIdToTopId.containsKey(a.ParentId)) a.UltimateParentId__c = accountIdToTopId.get(a.ParentId);
      else (a.UltimateParentId__c = null); //If no parent is set, self is ultimate parent so indicate this by setting it to blank
    }
  }
  

  //==========================================================================//
  // Create new Account_Brand__c records.
  //==========================================================================//
  private void createAccountBrandRecords(List<Account> newList) {
    // Account_Brand__c's Object 
    Account_Brand__c accBrandObj;
    // List of Account_Brand__c to be inserted
    List<Account_Brand__c> accBrandList = new List<Account_Brand__c>();
    // List of Brand__c
    List<Brand__c> brandList = new List<Brand__c>();    
    for(Brand__c br : [SELECT Name, External_Id__c, isMigrated__c, 
                              Migration_Source__c FROM Brand__c]) {
      brandList.add(br);
    }
    // Checking if there are some Records in the Brand__c List
    if(brandList.size() > 0) {
        // Now Iterating for Each Account
        for(Account acc : newList){
            // Creating One Account_Brand__c record for Each Brand
        for(Brand__c br : brandList) {
          accBrandObj = new Account_Brand__c();
          accBrandObj.Account__c = acc.Id;
          accBrandObj.Brand__c = br.Id;
          
          // If Migrated Record Use Migration_Id__c instead of Account Id
          if (acc.Migration_Id__c != null) accBrandObj.Migration_Id__c = acc.Migration_Id__c + '_' + br.External_Id__c;
          else accBrandObj.Migration_Id__c = acc.Id + '_' + br.External_Id__c;

          accBrandList.add(accBrandObj);
        }
      }
    }
    // Checking List size before inserting
    if(accBrandList.size() > 0) insert accBrandList;
  } // End of createAccountBrandRecords()

  //T-111620: Create a Trigger to Replace Account Ownership Workflow
  private void accountOwnerShipToDice (List<Account> newList) {
   //If this logic has already executed, bug out.  
    if (PreventRecursiveExecution.accountownershiptodiceset) return;

    //Set this to true so it can't execute multiple times.
    PreventRecursiveExecution.accountownershiptodiceset = true;
    
    User diceUser = [SELECT ID FROM User WHERE alias =: Label.Default_Account_Owner_User_Alias LIMIT 1];
    if (diceUser <> null && diceUser.ID <> null) {
            for (Account account : newList) {
          account.OwnerId = diceUser.ID;
            }
    }
  }
  
  //T-120617 : Create an after update Trigger on Account that when Account Name is 
  // updated then set the related Account_Brand.validationRuleOverride to Now()
  private void updateValidationRuleOverride (Map<ID, Account> oldMap, List<Account> newList) {
    Set<String> accIDset = new Set<String>();
    Map<String, List<Account_Brand__c>> accID_AccountBrandList_Map = new Map<String, List<Account_Brand__c>>();
    List<Account_Brand__c> accountBrandList = new List<Account_Brand__c>();
    
    for (Account a : newList) {
        if (a.Name <> oldMap.get(a.ID).Name) accIDset.add(a.ID);
    }
    for (Account_Brand__c ab : [SELECT ID, Validation_Rule_Override__c FROM Account_Brand__c WHERE Account__c IN : accIDset]) {
      ab.Validation_Rule_Override__c = Datetime.now();
      accountBrandList.add(ab);
    }
    
    if (!accountBrandList.isEmpty()) update accountBrandList;
  }
  
  //byrnes, new 2013.08.16
  private static boolean AddressEditsSynctoContactsIsEnabled()
  {
    List<GlobalFlags__c> flags = [SELECT Enabled__c FROM GlobalFlags__c WHERE Name = :ADDRESS_SYNC_NAME LIMIT 1];
    if (flags.size() < 1) return false; //if it doesn't exist, return false.
        
    //exception thrown around API Profile users for Zuora integration limits - 2013.12.13
    //had to oddly rearrange the code due to the data.com user execution and permissions to access their profile...
    Id profileID = userInfo.getProfileId();
    Profile currentUserProfile;
    List<Profile> currentUserProfileList = new List<Profile>();
    
    if (profileID != null) currentUserProfileList = [SELECT Id, Name FROM Profile WHERE Id=:profileID LIMIT 1];
    if (currentUserProfileList.size() < 1) return false;
    else currentUserProfile = currentUserProfileList[0];
    if ((currentUserProfile != null) && (currentUserProfile.Name == 'API Profile')) return false;       
    
    return flags.get(0).Enabled__c;        
  }

  //byrnes, new 2013.08.16
  private static boolean AccountHasAddressChange(Account oldAccount, Account newAccount)
  {
    if (oldAccount.BillingStreet != newAccount.BillingStreet) return true;
    if (oldAccount.BillingCity != newAccount.BillingCity) return true;
    if (oldAccount.BillingState != newAccount.BillingState) return true;
    if (oldAccount.BillingPostalCode != newAccount.BillingPostalCode) return true;
    if (oldAccount.BillingCountry != newAccount.BillingCountry) return true;
    if (oldAccount.pw_ccpro__BillingAddressStatus__c != newAccount.pw_ccpro__BillingAddressStatus__c) return true;
    if (oldAccount.pw_ccpro__BillingStateLookup__c != newAccount.pw_ccpro__BillingStateLookup__c) return true;
    if (oldAccount.pw_ccpro__BillingZipCodeLookup__c != newAccount.pw_ccpro__BillingZipCodeLookup__c) return true;
    if (oldAccount.pw_ccpro__BillingCountryLookup__c != newAccount.pw_ccpro__BillingCountryLookup__c) return true;
    
    return false;
  }
  
  //byrnes, new 2013.08.16
  //returns true if and only if all pieces of the address match.
  //considers only the raw text values, not the lookups or status
  private static boolean ContactAddressMatchesAccount(Account oldAccount, Contact contact)
  {
    if ( (oldAccount.BillingStreet      == contact.MailingStreet) &&
         (oldAccount.BillingCity        == contact.MailingCity) &&
         (oldAccount.BillingState       == contact.MailingState) &&
         (oldAccount.BillingPostalCode  == contact.MailingPostalCode) &&
         (oldAccount.BillingCountry     == contact.MailingCountry) ) return true;
         
    return false;
  }

  //byrnes, new 2013.09.05, CC-597
  private void UpdateStateCountryOnOpenTasks (Map<Id, Account> oldMap, Map<Id, Account> newMap)
  {
    List<Task> tasksToUpdate = new List<Task>();
    Map<String, List<Task>> mapTasks = new Map<String, List<Task>>();
    
    String currentID = '';
    List<Task> tasksForMap = new List<Task>();
    
    for (Task t : [SELECT Id, State_Account__c, Country_Account__c, AccountId FROM Task WHERE IsClosed = false AND AccountId IN : oldMap.Values()]) {
        if (currentID != String.valueOf(t.AccountId)) {
            
            if ((currentID != '') && (tasksForMap.size() > 0)) mapTasks.put(currentID, tasksForMap);
            tasksForMap.clear();
            currentID = t.AccountId;
        }
        
        tasksForMap.add(t);
    }
    //very last one to add...
    mapTasks.put(currentID, tasksForMap);
    
    for (Account a : oldMap.values()) {
        if ((a.BillingState != newMap.get(a.Id).BillingState) || (a.BillingCountry != newMap.get(a.Id).BillingCountry)) {
            
            //Then either the state or country changed.  In that case, update tasks...
            if (mapTasks.containsKey(a.Id)) {
                List<Task> affectedTasks = mapTasks.get(a.Id);
                if (affectedTasks.size() > 0) {
                    for (Task affectedTask : affectedTasks) {
                        affectedTask.State_Account__c = newMap.get(a.Id).BillingState;
                        affectedTask.Country_Account__c = newMap.get(a.Id).BillingCountry;
                        
                        tasksToUpdate.add(affectedTask);
                    }
                }
            }
        }
    }
    
    if (tasksToUpdate.size() > 0) update tasksToUpdate;
  }
  
  private void UpdateStateCountryOnOpenTasks (Map<Id, Account> newMap)
  {
    List<Task> tasksToUpdate = new List<Task>();
    Map<String, List<Task>> mapTasks = new Map<String, List<Task>>();
    
    String currentID = '';
    List<Task> tasksForMap = new List<Task>();
    
    for (Task t : [SELECT Id, State_Account__c, Country_Account__c, AccountId FROM Task WHERE IsClosed = false AND AccountId IN : newMap.Values()]) {
        if (currentID != String.valueOf(t.AccountId)) {
            
            if ((currentID != '') && (tasksForMap.size() > 0)) mapTasks.put(currentID, tasksForMap);
            tasksForMap.clear();
            currentID = t.AccountId;
        }
        
        tasksForMap.add(t);
    }
    //very last one to add...
    mapTasks.put(currentID, tasksForMap);
    
    for (Account a : newMap.values()) {
        //Then either the state or country changed.  In that case, update tasks...
        if (mapTasks.containsKey(a.Id)) {
            List<Task> affectedTasks = mapTasks.get(a.Id);
            if (affectedTasks.size() > 0) {
                for (Task affectedTask : affectedTasks) {
                    affectedTask.State_Account__c = newMap.get(a.Id).BillingState;
                    affectedTask.Country_Account__c = newMap.get(a.Id).BillingCountry;
                        
                    tasksToUpdate.add(affectedTask);
                }
            }
        }
    }
    
    if (tasksToUpdate.size() > 0) update tasksToUpdate;
  }  
  
private void UpdateOpenTasksFromDelete (Map<Id, Account> oldMap)  {
    
  Map<Id, Task> mapTasksToUpdate = new Map<Id, Task>();
  Map<Id, List<Task>> mergeMap = new Map<Id, List<Task>>();
    Id previousAccountID;
    Id currentAccountID;
    List<Task> tasks = new List<Task>();
    Map<Id, Account> masterAccountMap = new Map<Id, Account>();
    Set<Id> masterAccountIDs = new Set<Id>(); 
    Map<String, Account_Brand__c> accountBrandMap = new Map<String, Account_Brand__c>();
    List<Task> tasksToUpdate = new List<Task>();

    //Begin getting all 'Master' Account Ids
    for (Account a : oldMap.values()) {
        if (a.MasterRecordId != null) masterAccountIDs.add(a.MasterRecordId);
    }
    //End getting all 'Master' Account Ids

    //Begin getting, sorting, and organizing all TASKS that need to be updated....
    for (Task t : [SELECT Account_Brand_Rank__c, AccountId, Brand__c, WhoId, Id, Country_Account__c, Country_Person__c, WhatId, State_Account__c, State_Person__c FROM Task WHERE IsClosed = false AND AccountId IN :masterAccountIDs ORDER BY AccountId]) {    
        currentAccountID = t.AccountId;
        if ((previousAccountID != currentAccountID) && (previousAccountID != null)) {
            //then add to the map...
            if (tasks.size() > 0) mergeMap.put(previousAccountID, tasks.clone());
            tasks.clear();  
        }
        
        previousAccountID = t.AccountId;
        tasks.add(t);
    }
    
    if (tasks.size() > 0) mergeMap.put(previousAccountID, tasks.clone());
    //End getting, sorting and organizing all TASKS that need to be updated...
        
    //Begin getting all Account objects and accountBrand objects.
    for (Account a : [SELECT Id, Name, BillingCountry, BillingState, (SELECT Rank__c, Name, Id, Brand_Picklist__c FROM Account_Brands__r ORDER BY LastModifiedDate ASC) FROM Account WHERE Id IN :masterAccountIDs]) {
        if (!masterAccountMap.containsKey(a.Id)) masterAccountMap.put(a.Id, a);
    
        for (Account_Brand__c ab : a.Account_Brands__r) {
            //if (!accountBrandMap.containsKey(a.Id + '<>' + ab.Brand_Picklist__c)) accountBrandMap.put(a.Id + '<>' + ab.Brand_Picklist__c, ab);
            if (!accountBrandMap.containsKey(ab.Name)) accountBrandMap.put(ab.Name, ab);
        }       
    }   
    //End getting all Account objects and accountBrand objects.
    
    //Loop all accounts that are getting purged...
    for (Account a : oldMap.values()) {
        if (a.MasterRecordId != null) {
            //Then let's do the updates....
            
            if ((mergeMap.containsKey(a.MasterRecordId)) && (masterAccountMap.containsKey(a.MasterRecordId))) {
                List<Task> affectedTasks = mergeMap.get(a.MasterRecordId);
                Account masterAccount = masterAccountMap.get(a.MasterRecordId);
                if (affectedTasks.size() > 0) {
                    //update address values...
                    

                    for (Task t : affectedTasks) {
              if (!mapTasksToUpdate.containsKey(t.Id)) {
                t.State_Account__c = masterAccount.BillingState;
                t.Country_Account__c = masterAccount.BillingCountry;
                
                //now find the account brand...           
                if (accountBrandMap.containsKey(t.Brand__c + '@' + masterAccount.Name)) t.Account_Brand_Rank__c = accountBrandMap.get(t.Brand__c + '@' + masterAccount.Name).Rank__c;
                //tasksToUpdate.add(t);  
                mapTasksToUpdate.put(t.Id, t);
              }                     
                    }
                }
            }
        }
    }
    
    if (mapTasksToUpdate.size() > 0) update mapTasksToUpdate.values();
    
  }    

  //byrnes, new 2014.02.07
  //This will NOT uncheck a contact's no gift.
  //It will only check contacts gift if it was unchecked and the account's is checked.
  // private void CascadeNoGiftToContacts (Map<Id, Account> oldMap, Map<Id, Account> newMap) {

  //   //List of contacts that we're actually going to update...
  //   List<Contact> contactsUpdate = new List<Contact>();

  //   //get all contacts for the affected accounts that have No_Gift__c = false.  (If it's true we don't care...)
  //   List<Contact> allContacts = [SELECT 
  //                                 AccountId,
  //                                 Id,
  //                                 No_Gift__c
  //                                 FROM Contact 
  //                                 WHERE AccountId IN :oldMap.Values()
  //                                 AND No_Gift__c = false];

  //   for (Account a : oldMap.values()) {

  //     //make sure that this particular account has 'No Gift' checked - if it's unchecked we won't do anything
  //     //and this is only if it's changed.  
  //     if ((oldMap.get(a.Id).NO_GIFT__c == false) && (newMap.get(a.Id).NO_GIFT__c == true)) {

  //       for (Contact c : allContacts) {
  //         if (c.AccountId == a.Id) {
  //           c.No_Gift__c = true; 
  //           contactsUpdate.add(c);
  //         }
  //       }        
  //     }
  //   }

  //   if (contactsUpdate.size() > 0) update contactsUpdate;
  // }

  //byrnes, new 2013.08.16  
  private void CascadeAddressChangesToContacts (Map<Id, Account> oldMap, Map<Id, Account> newMap) {    
    //These are the fields/values that are pushed to Contacts from Accounts in this sub...
    //  Account.BillingStreet                       == Contact.MailingStreet
    //  Account.BillingCity                         == Contact.MailingCity
    //  Account.BillingState                        == Contact.MailingState
    //  Account.BillingPostalCode                   == Contact.MailingPostalCode
    //  Account.BillingCountry                      == Contact.MailingCountry
    //  Account.pw_ccpro__BillingAddressStatus__c   == Contact.pw_ccpro__MailingAddressStatus__c
    //  Account.pw_ccpro__BillingStateLookup__c     == Contact.pw_ccpro__MailingStateLookup__c
    //  Account.pw_ccpro__BillingZipCodeLookup__c   == Contact.pw_ccpro__MailingZipCodeLookup__c
    //  Account.pw_ccpro__BillingCountryLookup__c   == Contact.pw_ccpro__MailingCountryLookup__c
    
    if (!AddressEditsSynctoContactsIsEnabled()) return;     
       
  
    //ID is the AccountId in this contactMap variable.
    Map<Id, List<Contact>> contactMap = new Map<Id, List<Contact>>();
     
    //get all contacts for the affected accounts
    List<Contact> allContacts = [SELECT AccountId,
                                        MailingStreet,                                                                                                                                  
                                        MailingCity,
                                        MailingState,                                           
                                        MailingPostalCode,
                                        MailingCountry,
                                        pw_ccpro__MailingAddressStatus__c,
                                        pw_ccpro__MailingStateLookup__c,
                                        pw_ccpro__MailingZipCodeLookup__c, 
                                        pw_ccpro__MailingCountryLookup__c
                                        FROM Contact WHERE AccountId IN :oldMap.Values()];
   
   //populate the contactMap
   for (Account a : oldMap.values())
   {
     List<Contact> specificAccountContactList = new List<Contact>();
     
     //before we get too far into this, make sure that this particular account actually has an address change
     if (AccountHasAddressChange(a, newMap.get(a.Id)))
     {
        for (Contact c : allContacts)
        {
            if ((c.AccountId == a.Id) && (ContactAddressMatchesAccount(a, c))) specificAccountContactList.add(c);
        }   
     
        contactMap.put(a.Id, specificAccountContactList);
     }
   }
   
   List<Contact> contactsToUpdate = new List<Contact>();
   
   //functional loop that actually makes the changes now that the variables are set up and populated properly
   for (List<Contact> contacts : contactMap.values())
   {
    
    if (contacts.size() > 0)
    {
        //get the new and old values from the account first to compare
        Account preEditAccount = oldMap.get(contacts.get(0).AccountId);
        Account postEditAccount = newMap.get(contacts.get(0).AccountId);
   
        for (Contact c : contacts)
        {
            boolean bChanged = false;
            if (preEditAccount.BillingStreet != postEditAccount.BillingStreet) { 
                c.MailingStreet = postEditAccount.BillingStreet;
                bChanged = true;
            }
                
            if (preEditAccount.BillingCity != postEditAccount.BillingCity) {
                c.MailingCity = postEditAccount.BillingCity;
                bChanged = true;
            }
                
            if (preEditAccount.BillingState != postEditAccount.BillingState) {
                c.MailingState = postEditAccount.BillingState;
                bChanged = true;
            }
            
            if (preEditAccount.BillingPostalCode != postEditAccount.BillingPostalCode) {
                c.MailingPostalCode = postEditAccount.BillingPostalCode;
                bChanged = true;
            }
            
            if (preEditAccount.BillingCountry != postEditAccount.BillingCountry) {
                c.MailingCountry = postEditAccount.BillingCountry;
                bChanged = true;
            }
            
            if (preEditAccount.pw_ccpro__BillingAddressStatus__c != postEditAccount.pw_ccpro__BillingAddressStatus__c) {
                c.pw_ccpro__MailingAddressStatus__c = postEditAccount.pw_ccpro__BillingAddressStatus__c;
                bChanged = true;
            }
            
            if (preEditAccount.pw_ccpro__BillingStateLookup__c != postEditAccount.pw_ccpro__BillingStateLookup__c) {
                c.pw_ccpro__MailingStateLookup__c = postEditAccount.pw_ccpro__BillingStateLookup__c;
                bChanged = true;
            }
            
            if (preEditAccount.pw_ccpro__BillingZipCodeLookup__c != postEditAccount.pw_ccpro__BillingZipCodeLookup__c) {
                c.pw_ccpro__MailingZipCodeLookup__c = postEditAccount.pw_ccpro__BillingZipCodeLookup__c;
                bChanged = true;
            }
            
            if (preEditAccount.pw_ccpro__BillingCountryLookup__c != postEditAccount.pw_ccpro__BillingCountryLookup__c) {
                c.pw_ccpro__MailingCountryLookup__c = postEditAccount.pw_ccpro__BillingCountryLookup__c;
                bChanged = true;
            }
            
            if (bChanged) contactsToUpdate.add(c);
        }
    }
    
    if (contactsToUpdate.size() > 0) update contactsToUpdate;
   }
    
  }
} // End of AccountTriggerHandler class