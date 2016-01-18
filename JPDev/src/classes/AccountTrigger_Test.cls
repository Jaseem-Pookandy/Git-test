/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Description   : Class that tests the functionality of Account Trigger.
//     
// Dec 13th, 2012    Karun Gangwani(Appirio Off)
********************************************************************/
@isTest
private class AccountTrigger_Test {
  
  static testMethod void testCreateAccountBrandRecords() {
    Profile sysAdmin = TestUtils.usrProfile('System Administrator');
    
    User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                      'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
    insert adminUser;
    
    createTestData();
    
    TestUtils.createBrands();
    
    
    system.runAs(adminUser) {
      
      TestUtils.CreateCustomSettingsRecords();
      
      Account account = TestUtils.createAccount();
      insert account;
      
      List<Contact> contactList = TestUtils.createContacts(account, 5);
      insert contactList;
      
      List<Task> taskList = TestUtils.createTasks(null, account.Id, 'Dice', 5);
      insert taskList;
      
      Task closedT = taskList[0];
      closedT.Status = 'Completed';
      update closedT;
      
      //update the dice brand record to create the tasks for at risk...
      Brand__c diceBrand = [SELECT Id, Name, Create_At_Risk_Tasks__c FROM Brand__c WHERE Name = 'Dice' LIMIT 1];
      diceBrand.Create_At_Risk_Tasks__c = true;
      update diceBrand;

      Test.startTest();
      
      List<Brand__c> brandList = [SELECT Name, External_Id__c, isMigrated__c, 
                                  Migration_Source__c  
                                  FROM Brand__c];
      List<Account_Brand__c> accBrandList = [SELECT ID, Account__c, Brand__c, Brand_Picklist__c,
                                             Migration_Id__c, At_Risk__c
                                             FROM  Account_Brand__c 
                                             WHERE Account__c = :account.Id];
      system.assertEquals(brandList.size(), accBrandList.size());    

      List<Account_Brand__c> abToUpdate = new List<Account_Brand__c>();

      for (Account_Brand__c ab : accBrandList) {
        if (ab.Brand_Picklist__c == 'Dice') {
            ab.At_Risk__c = true;
            abToUpdate.add(ab);
          }
      }

      if (abToUpdate.size() > 0) update abToUpdate;

      PreventRecursiveExecution.isFirstRun = true;
      
      //Set the contacts address now...
      contactList = new List<Contact>();
      for (Contact c : [SELECT Id, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, pw_ccpro__MailingAddressStatus__c, pw_ccpro__MailingStateLookup__c, pw_ccpro__MailingZipCodeLookup__c, pw_ccpro__MailingCountryLookup__c FROM Contact WHERE AccountId = :account.Id]) {
        c.MailingStreet = '123 Fake St. Suite B';
        c.MailingCity = 'Ankeny';
        c.MailingState = 'MN';
        c.MailingCountry = 'France';
        c.MailingPostalCode = '50021';
        contactList.add(c);
      }
      update contactList;
      
      Account a = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account WHERE Name = 'Test'];
      
      a.BillingStreet = '123 Fake St. Suite B';
      a.BillingCity = 'Ankeny';
      a.BillingState = 'MN';
      a.BillingCountry = 'France';
      a.BillingPostalCode = '50021';
      
      update a;
      //Addresses match now.  Make them different...
      
      a.BillingStreet = '123 Fake St. Suite C';
      a.BillingCity = 'Ankiny';
      a.BillingState = 'IA';
      a.BillingCountry = 'Botswana';
      a.BillingPostalCode = '50022';
      
      update a;
      
      Account a2 = TestUtils.createAccount();
      insert a2;
      
      merge a2 a;
      
      //delete a;
      
      Test.stopTest();      
    }
  }
  
private static void createTestData() {
        
        //Create Job_Title__c
        
        List<Job_Title__c> jobTitleList = new List<Job_Title__c>();
        List<Contact> contactList = new List<Contact>();
        
        Job_Title__c jobTitle = new Job_Title__c();
        jobTitle.Name = 'testJobTitle1';
        jobTitleList.add(jobTitle);
        
        jobTitle = new Job_Title__c();
        jobTitle.Name = 'testJobTitle2';
        jobTitleList.add(jobTitle);
        
        insert jobTitleList;
                     
        //Create Account 
        Account account = new Account();
        account.Name = 'testAccount';
        account.BillingStreet = '123 Fake St.';
        account.BillingCity = 'Des Moines';
        account.BillingState = 'IA';
        account.BillingCountry = 'United States';
        account.BillingPostalCode = '50309';
        
        insert account;
        
        //Create contacts
        Contact contact = new Contact();
        contact.AccountId = account.id;
        contact.LastName = 'LName1';
        contact.Title = 'testJobTitle1';    
        contact.No_Email__c = false;
        
        contact.MailingStreet = '123 Fake St.';
        contact.MailingCity = 'Des Moines';
        contact.MailingState = 'IA';
        contact.MailingCountry = 'United States';
        contact.MailingPostalCode = '50309';        
        
        contactList.add(contact);
        
        contact = new Contact();
        contact.AccountId = account.id;
        contact.LastName = 'LName2';
        contact.Title = 'testJobTitle1';
        contact.No_Email__c = false;    
        
        contact.MailingStreet = '123 Fake St.';
        contact.MailingCity = 'Des Moines';
        contact.MailingState = 'IA';
        contact.MailingCountry = 'United States';
        contact.MailingPostalCode = '50310';        
        
        contactList.add(contact);   
        
        insert contactList;                                          
    }  
  
}