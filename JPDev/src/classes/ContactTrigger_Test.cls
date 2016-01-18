/*******************************************************************************
Name        : ContactTrigger_Test
Description : Test Class for ContactTriggerHandler.
Author      : Sonal Shrivastava (Appirio Offshore)
Date        : Jan 15th, 2013
*******************************************************************************/
@isTest
private class ContactTrigger_Test {

    static List<Contact> contactList = new List<Contact>();
    static List<Brand__c> brandList = new List<Brand__c>();
    
    public static testMethod void myUnitTest() {
        //Creating Test data
        createTestData();             
        
        //Query newly inserted contacts
        List<Contact> newContacts = [SELECT Title, Job_Title__c FROM Contact];
        //List<Contact> newContacts = [SELECT Title, Job_Title__c FROM Contact WHERE Id in :contactList];
        
        if (newContacts.size() > 0) {
        	List<Task> taskList = TestUtils.createTasks(newContacts[0].Id, null, 'Dice', 5);
      		insert taskList;
      
      		Task closedT = taskList[0];
      		closedT.Status = 'Completed';
      		update closedT;
      		
      		contactList = new List<Contact>();
      		for (Contact c : [SELECT Id, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, pw_ccpro__MailingAddressStatus__c, pw_ccpro__MailingStateLookup__c, pw_ccpro__MailingZipCodeLookup__c, pw_ccpro__MailingCountryLookup__c FROM Contact]) {
      			c.MailingStreet = '123 Fake St. Suite C';
      			c.MailingCity = 'Ankeny';
      			c.MailingState = 'WV';
      			c.MailingCountry = 'Madagascar';
      			c.MailingPostalCode = '50021';
      			c.No_Email__c = true;
      			contactList.add(c);
      		}
      		
      		ContactTriggerHelper.isFirstRun = true;
      		update contactList;
        }
        
        //Verify that Job_Title__c is same as Title.
        System.assertEquals( newContacts.get(0).Title, [SELECT Name FROM Job_Title__c WHERE Id = :newContacts.get(0).Job_Title__c].Name);   
    }

    public static testMethod void test2() {

      ApexPages.Standardcontroller sc;

      NewOpportunityController_Test.CreateData();
      
      List<Opportunity> oppList = [SELECT Id, AccountId, OwnerId, Owner.Name, Account_Brand__c, Account_Brand__r.CS__r.Name FROM Opportunity WHERE IsClosed = false LIMIT 10];
      List<Contact> listoContacts = [SELECT Id FROM Contact LIMIT 10];

      if (oppList != null && !oppList.isEmpty()) {
        String sourceOppId = oppList[0].Id;

        PageReference pageRef = Page.ZuoraQuote;
        pageRef.getParameters().put('oppId', sourceOppId);
      
        Test.setCurrentPage(pageRef);

        ZuoraQuoteController controller = new ZuoraQuoteController(sc);

        if (listoContacts != null && !listoContacts.isEmpty()) {
          controller.thisQuote.zqu__SoldToContact__c = listoContacts[0].Id;
          controller.thisQuote.zqu__BillToContact__c = listoContacts[0].Id;
        }

        controller.thisQuote.Name = 'Test Quote';
        controller.thisQuote.zqu__Opportunity__c = sourceOppId;
        controller.thisQuote.BrandTag__c = 'Dice';
        controller.thisQuote.IsSyncing__c = true;
        controller.thisQuote.zqu__ValidUntil__c = System.Date.today().addDays(5);
        controller.thisQuote.Billing_Frequency__c = 'Annual';
        controller.thisQuote.zqu__Currency__c = 'USD';
        controller.thisQuote.zqu__PaymentTerm__c = 'Due Upon Receipt';
        controller.thisQuote.zqu__PaymentMethod__c = 'Credit Card';
        controller.thisQuote.zqu__StartDate__c = controller.thisQuote.zqu__ValidUntil__c;
        controller.thisQuote.zqu__Subscription_Term_Type__c = 'Termed';
        controller.thisQuote.zqu__InitialTerm__c = 12; 

        insert controller.thisQuote;

        //change the language on the contact now.
        listoContacts[0].Language__c = 'Russian';
        update listoContacts[0];

      }
    }
    
    private static void createTestData() {
        
        //Create Job_Title__c
        
        List<Job_Title__c> jobTitleList = new List<Job_Title__c>();
        
        Job_Title__c jobTitle = new Job_Title__c();
        jobTitle.Name = 'testJobTitle1';
        jobTitleList.add(jobTitle);
        
        jobTitle = new Job_Title__c();
        jobTitle.Name = 'testJobTitle2';
        jobTitleList.add(jobTitle);
        
        insert jobTitleList;
        
        //Create Brand__c       
        
        Brand__c brand = new Brand__c();
        brand.Name = 'Brand1';
        brand.External_Id__c = 'B001';
        brand.CurrencyIsoCode = 'USD';
        
        brandList.add(brand);
        
        brand = new Brand__c();
        brand.Name = 'Brand2';
        brand.External_Id__c = 'B002';
        brand.CurrencyIsoCode = 'USD';
        
        brandList.add(brand);
        
        insert brandList; 
        
        //Create Account 
        Account account = new Account();
        account.Name = 'testAccount';
        account.BillingStreet = 'TestStreet';
        account.BillingCity = 'TestCity';
        account.BillingState = 'TestState';
        account.BillingCountry = 'TestCountry';
        account.BillingPostalCode = '99999';
        
        insert account;
        
        //Create contacts
        Contact contact = new Contact();
        contact.AccountId = account.id;
        contact.LastName = 'LName1';
        contact.Title = 'testJobTitle1';    
        contact.No_Email__c = false;
        
        contactList.add(contact);
        
        contact = new Contact();
        contact.AccountId = account.id;
        contact.LastName = 'LName2';
        contact.Title = 'testJobTitle1';
        contact.No_Email__c = false;    
        
        contactList.add(contact);   
        
        insert contactList;                                          
    }
}