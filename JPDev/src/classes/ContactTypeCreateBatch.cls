/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Class to create contact types for the contacts and assigns account brands
//
// Mar 01st, 2013    Naresh Ojha (Appirio Off)    
********************************************************************/
global class ContactTypeCreateBatch implements Database.Batchable<sObject>{

	String email;

  global Database.querylocator start(Database.BatchableContext BC){
    //String query = 'SELECT ID, AccountID FROM Contact';
    String query = 'SELECT ID, AccountID FROM Contact Where Name Like \'%test 001%\'';
    email = 'nojha@appirio.com'; 
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope){
    List<Contact> newList = new List<Contact>();
  
    for(sObject s : scope) {
    	Contact c = (Contact)s;
    	newList.add(c);
    }

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
      if (c.AccountId <> null) accountIDset.add(c.AccountId);
    }
    
    accID_abList_Map = ContactTriggerHandler.getAccountBrands(accountIDset);

    // Checking if there are some Records in the Brand__c List
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
              contactTypeList.add(contactTypeObj);
            }
          }
        }
    }
    
    for(Contact_Type__c ct: [SELECT Account_Brand__c, Contact__c, ID 
                                    FROM Contact_Type__c 
                                    WHERE Contact__c IN: contactIDset]) {
        if(!contIDbrand_ContactTypeMap.containsKey(ct.Contact__c+'-'+ct.Account_Brand__c)) {
            contIDbrand_ContactTypeMap.put(ct.Contact__c+'-'+ct.Account_Brand__c, ct);
        }
    }
    
    for(Contact_Type__c ct : contactTypeList) {
        if(!contIDbrand_ContactTypeMap.containsKey(ct.Contact__c+'-'+ct.Account_Brand__c)) contactTypeToInsertList.add(ct);
    }
    // Checking List size before inserting
    if(contactTypeToInsertList.size() > 0) insert contactTypeToInsertList;
  }
  
  global void finish(Database.BatchableContext BC){
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    String email = 'nojha@appirio.com'; 
    mail.setToAddresses(new String[] {email});
    mail.setSenderDisplayName('Batch Processing');
    mail.setSubject('Batch Process Completed');
    mail.setPlainTextBody('Batch Process has completed');

    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }
}