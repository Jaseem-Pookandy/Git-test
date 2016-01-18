/***************************************************************************
// (c) 2013 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  ContactTrigger. All contexts should be in this class.
//                  
// Jan 09th, 2013  :  Naresh Ojha (Appirio Offshore)
//***************************************************************************/
public with sharing class ContactTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  
  //Constructor
  public ContactTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }
  
  //On before insert trigger method
  public void OnBeforeInsert(List<Contact> newList) { 
    CommonUtil.AssignJobTitle(newList, null, 'Contact');
  }  
  // On before update trigger method
  public void OnBeforeUpdate (Map<Id, Contact> oldMap, 
                              Map<Id, Contact> newMap) {
    CommonUtil.AssignJobTitle(newMap.values(), oldMap, 'Contact');
    
    if (ContactTriggerHelper.isFirstRun)
    {
        ContactTriggerHelper.isFirstRun = false;
        UpdateContactTypeNeverEmail(oldMap, newMap);    //byrnes
    }   
  } 

  // On before update trigger method
  public void OnAfterInsert(Map<Id, Contact> newMap) {
    if (System.Userinfo.getLastName() != 'Migration') createContactTypes(newMap.values());
  } 
  
  //On after update
  public void onAfterUpdate(Map<Id, Contact> oldMap, Map<Id, Contact> newMap) {    
    UpdateStateCountryOnOpenTasks(oldMap, newMap);    
    RecalcInvoiceTemplate(oldMap, newMap);
  }
    
  //byrnes, new 2013.09.05, CC-597
  private void UpdateStateCountryOnOpenTasks (Map<Id, Contact> oldMap, Map<Id, Contact> newMap)
  {
    Set<Task> tasksToUpdate = new Set<Task>();
    List<Task> tasksToUpdateList = new List<Task>();
    
    Map<String, List<Task>> mapTasks = new Map<String, List<Task>>();
    
    String currentID = '';
    List<Task> tasksForMap = new List<Task>();
    
    for (Task t : [SELECT Id, State_Person__c, Country_Person__c, WhoId FROM Task WHERE IsClosed = false AND WhoId IN : oldMap.Values()]) {
        if (currentID != String.valueOf(t.WhoId)) {
            
            if ((currentID != '') && (tasksForMap.size() > 0) && (!mapTasks.containsKey(currentID))) mapTasks.put(currentID, tasksForMap);
            tasksForMap.clear();
            currentID = t.WhoId;
        }
        
        tasksForMap.add(t);
    }
    //very last one to add...
    if ((currentID != '') && (tasksForMap.size() > 0) && (!mapTasks.containsKey(currentID))) mapTasks.put(currentID, tasksForMap);
    
    for (Contact c : oldMap.values()) {
        if ((c.MailingState != newMap.get(c.Id).MailingState) || (c.MailingCountry != newMap.get(c.Id).MailingCountry)) {
            
            //Then either the state or country changed.  In that case, update tasks...
            if (mapTasks.containsKey(c.Id)) {
                List<Task> affectedTasks = mapTasks.get(c.Id);
                if (affectedTasks.size() > 0) {
                    for (Task affectedTask : affectedTasks) {
                        affectedTask.State_Person__c = newMap.get(c.Id).MailingState;
                        affectedTask.Country_Person__c = newMap.get(c.Id).MailingCountry;
                        
                        tasksToUpdate.add(affectedTask);
                    }
                }
            }
        }
    }
    tasksToUpdateList.addAll(tasksToUpdate);
    if (tasksToUpdate.size() > 0) update tasksToUpdateList;
  }
    
  //T-108557: Create contact types on insert of contact for each brand.
  private void createContactTypes(List<Contact> newList) {
    //Contact Type's Object 
    Contact_Type__c contactTypeObj;

    //Map to check existing contact types.
    Map<String, Contact_Type__c> contIDbrand_ContactTypeMap 
                                          = new Map<String, Contact_Type__c>(); 
    //Map holds account and its account brands
    Map<String, List<Account_Brand__c>> accID_abList_Map = new Map<String, List<Account_Brand__c>>();
    
    // List of Contact_Type__c to be inserted
    List<Contact_Type__c> contactTypeList = new List<Contact_Type__c>();
    List<Contact_Type__c> contactTypeToInsertList = new List<Contact_Type__c>();

    Set<String> contactIDset = new Set<String>();
    Set<String> accountIDset = new Set<String>();
    
    for (Contact c : newList) {
        if (c.AccountId <> null && !c.Contact_Type_Trigger_Skip__c) accountIDset.add(c.AccountId);
    }
    
    accID_abList_Map = getAccountBrands(accountIDset);

    //Checking if there are some Records in the Brand__c List
    if(accID_abList_Map.size() > 0) {
        // Now Iterating for Each Account
        for(Contact contact : newList){
            contactIDset.add(contact.ID);
          // Creating One Contact Type record for Each Account Brand
          if (contact.AccountID <> null && accID_abList_Map.containsKey(contact.AccountID)) {
              for(Account_Brand__c ab : accID_abList_Map.get(contact.AccountID)) {
                contactTypeObj = new Contact_Type__c();
                contactTypeObj.Account_Brand__c = ab.ID;
                contactTypeObj.Contact__c = contact.Id;
                contactTypeObj.Never_Email__c = contact.No_Email__c;    //byrnes
                contactTypeList.add(contactTypeObj);
              }
          }
        }
    }
    
    for(Contact_Type__c ct: [SELECT Account_Brand__c, Contact__c, ID 
                                    FROM Contact_Type__c 
                                    WHERE Contact__c IN: contactIDset]) {
        if(!contIDbrand_ContactTypeMap.containsKey(ct.Contact__c+'-'+ct.Account_Brand__c)) contIDbrand_ContactTypeMap.put(ct.Contact__c+'-'+ct.Account_Brand__c, ct);
    }
    
    for(Contact_Type__c ct : contactTypeList) {
        if(!contIDbrand_ContactTypeMap.containsKey(ct.Contact__c+'-'+ct.Account_Brand__c)) contactTypeToInsertList.add(ct);
    }
    
    // Checking List size before inserting
    if(contactTypeToInsertList.size() > 0) insert contactTypeToInsertList;
  }
  
  //Task T-120517.
  public static Map<String, List<Account_Brand__c>> getAccountBrands (Set<String> accIDs) {
    Map<String, List<Account_Brand__c>> accID_AccountBrandList_Map = new Map<String, List<Account_Brand__c>>();
    
    for (Account_Brand__c ab : [SELECT Id, Brand__c, Brand_Name__c, Account__c 
                                   FROM Account_Brand__c
                                   WHERE Account__c IN : accIDs]) {
        if (!accID_AccountBrandList_Map.containsKey(ab.Account__c)) accID_AccountBrandList_Map.put(ab.Account__c, new List<Account_Brand__c>());
        accID_AccountBrandList_Map.get(ab.Account__c).add(ab);
    }
    
    return accID_AccountBrandList_Map;
  }
  
  private void UpdateContactTypeNeverEmail(Map<Id, Contact> oldMap, Map<Id, Contact> newMap)
  {
    Set<Id> contactIdsThatChanged = new Set<Id>();      
    List<Contact_Type__c> contactTypesToUpdate = new List<Contact_Type__c>();
    
    for (Contact c : newMap.values()) {
        if (oldMap.get(c.Id).No_Email__c <> newMap.get(c.Id).No_Email__c) contactIdsThatChanged.add(c.Id);
    }
    
    if (contactIdsThatChanged.size() > 0) {
        //We don't need to select No_Email__c because that's already updated and included from the map...
        Map<Id, Contact> cMap = new map<Id, Contact>([SELECT Id, (SELECT Id, Contact__c, Never_Email__c FROM Contact_Types__r) FROM Contact WHERE Id IN :contactIdsThatChanged]);   
        
        for (Id contactId : cMap.Keyset()) {
            Boolean NoEmailValue = newMap.get(contactId).No_Email__c;
            
            Contact currentContact = cMap.get(contactId);
            List<Contact_Type__c> currentContactTypeList = currentContact.Contact_Types__r;
            
            //iterate over the list now and update the email checkbox to equal the newMap value...
            for (Contact_Type__c ct : currentContactTypeList) {
                if (ct.Never_Email__c != NoEmailValue) {
                    ct.Never_Email__c = NoEmailValue;
                    contactTypesToUpdate.add(ct);   
                }               
            }
        }
        
        if (contactTypesToUpdate.size() > 0) update contactTypesToUpdate;
    }
  }

  //CC-2756, part 2.  Part 1 is on the zquQuoteTriggerHandler
  //on after update only.
  private void RecalcInvoiceTemplate(Map<Id, Contact> oldMap, Map<Id, Contact> newMap) {

    Set<Id> contactIDSet = new Set<Id>();
    List<zqu__Quote__c> quotesToUpdate = new List<zqu__Quote__c>();

    for (Contact c : newMap.values()) {
      //check and see if the language is initially populated or changed...
      if ((oldMap.containsKey(c.Id)) && ((c.Language__c != null) && (c.Language__c != oldMap.get(c.Id).Language__c )) || (oldMap.get(c.Id).pw_ccpro__MailingCountryLookup__c != c.pw_ccpro__MailingCountryLookup__c)) contactIdSet.add(c.Id);
    }

    if (!contactIdSet.isEmpty()) {      
      //Then we have at least one contact that had a language change - search and update any applicable (New) Quote.InvoiceTemplates they are tied to...

      Map<Id, zqu__Quote__c> mapQuotes = new Map<Id, zqu__Quote__c>([
            SELECT Id, zqu__SoldToContact__r.pw_ccpro__MailingCountryLookup__r.Sub_Region1__c, zqu__SoldToContact__c, zqu__SoldToContact__r.pw_ccpro__MailingCountryLookup__r.Region_Energy__c, zqu__Currency__c, zqu__SoldToContact__r.Language__c, BrandTag__c
            FROM zqu__Quote__c
            Where zqu__SoldToContact__c IN :contactIdSet AND zqu__Status__c = 'New']);

      if (!mapQuotes.isEmpty()) {
        //Then we have some quotes to fix...

        List<Invoice_Template__c> invoiceTemplates = [SELECT Id, Name, Invoice_Template_Id__c FROM Invoice_Template__c];

        //Map of Invoice Templates
        Map<String, String> mapInvoiceTemplates = new Map<String, String>();
          
        for(Invoice_Template__c invoiceTemplate : invoiceTemplates) {
          mapInvoiceTemplates.put(invoiceTemplate.Name.toUpperCase(), invoiceTemplate.Id);
        }

        List<pw_ccpro__CountryObject__c> countries = [SELECT Id, Name, Sub_Region1__c, Region_Energy__c FROM pw_ccpro__CountryObject__c ];      

        for (zqu__Quote__c quote : mapQuotes.values()) {
          if (quote.BrandTag__c != null) {
            if (((quote.zqu__SoldToContact__c != null) && (quote.BrandTag__c.startsWithIgnoreCase('efc')) && (newMap.get(quote.zqu__SoldToContact__c).pw_ccpro__MailingCountryLookup__c != null) && (newMap.get(quote.zqu__SoldToContact__c).pw_ccpro__MailingCountryLookup__r.Sub_Region1__c == 'Middle East')))     quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(('eFC-MiddleEast_'               + (String)newMap.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());
            else if ((quote.BrandTag__c.equalsIgnoreCase('rigzone')) && (newMap.get(quote.zqu__SoldToContact__c).pw_ccpro__MailingCountryLookup__r.Region_Energy__c != 'AMERICAS'))                                                                                                                                        quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(('Rigzone-ROW_'                  + (String)newMap.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());
            else if (mapInvoiceTemplates.get(((String)quote.BrandTag__c + '_' + (String)newMap.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase()) != null)                                                                                                                quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(((String)quote.BrandTag__c + '_' + (String)newMap.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());
            else quote.InvoiceTemplateName__c = null;
          }
          else quote.InvoiceTemplateName__c = null;

          //Indicate that the language changed and the billing account may need to be recalculated.
          quote.Billing_Account_Selection_Response__c = CONSTANTS.CONTACT_LANGUAGE_CHANGED;
          
          quotesToUpdate.add(quote);
        }
      }
    }

    if (!quotesToUpdate.isEmpty()) update quotesToUpdate;
  }
}