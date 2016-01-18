/*******************************************************************
// (c) 2014 Doextra
// 
// Description    : Class that tests the Contact Table component & all immediately related classes
//     
// Jan 31st, 2014 : Byrnes
********************************************************************/
@isTest  
private class ContactTable_Test {

    static List<Contact> contactList = new List<Contact>();
    static List<Brand__c> brandList = new List<Brand__c>();

    static testMethod void UnitTest1() {
        //Creating Test data
        createTestData();             
       
        ContactTableAccessor cta = new ContactTableAccessor();
        Boolean bTest = cta.getUserCanDeleteContacts();

        PageReference pr = cta.NewContactAction();
        pr = cta.MergeContactsClick();

        List<ContactWrapper> cwList = new List<ContactWrapper>();
        cwList = cta.getWrappedContacts();
    }

    static testMethod void UnitTest1a() {
        //ContactTableAccessor specifically...
        //Creating Test data
        createTestData();                     

        ContactWrapper cw = new ContactWrapper();
        cw.Contact = [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact LIMIT 1];

        //Create Account
        Account account = TestUtils.createAccount();
        insert account;
        
        //Create Contacts
        contactList = TestUtils.createContacts(account, 2);
        insert contactList;
        
        Account_Brand__c abc = [SELECT Id, Account__c FROM Account_Brand__c WHERE Account__c = :account.Id LIMIT 1];

        //Create Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;
        for(integer i=0; i<2; i++) {
            opp = TestUtils.createOpportunity('Opp_'+i, account);
            opp.Contact__c = contactList.get(i).id;
            opp.Account_Brand__c = abc.Id;
            opp.StageName = 'Close Won';
            oppList.add(opp);           
        }
        insert oppList;

        Test.StartTest();
        
        ContactBrandDetails cbd = new ContactBrandDetails();
        cbd.AccountID = [SELECT AccountID FROM Contact Where Id = :cw.Contact.Id LIMIT 1].AccountID;

        ContactTableAccessor cta = new ContactTableAccessor();
        Integer i = cta.contactCount;

        Boolean bTest = cta.getUserCanDeleteContacts();

        PageReference pr = cta.NewContactAction();
        pr = cta.MergeContactsClick();

        List<ContactWrapper> cwList = new List<ContactWrapper>();
        cta.accountID = cbd.AccountID;
        cwList = cta.getWrappedContacts();

        cwList = new List<ContactWrapper>();
        cta.accountId = account.Id;
        cwList = cta.getWrappedContacts();
        Test.StopTest();

    }

    static testMethod void UnitTest1b() {
        //ContactTableAccessor specifically...
        //Creating Test data
        createTestData();                     

        test.startTest();

        ContactWrapper cw = new ContactWrapper();
        cw.Contact = [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact LIMIT 1];

        Account a = new Account(Name = 'Test');
        a.Status__c = 'Active';
        a.Phone = '9829198291';
        a.BillingCity = 'Jaipur';
        a.BillingStreet = 'test street';
        a.BillingState = 'Rajasthan';
        a.BillingCountry = 'India';
        a.BillingPostalCode = '302022';
        a.Channel_Partner__c = false;
        insert a;

        Brand__c b = new Brand__c();
        b.Name = 'Test Brand';
        b.isActive__c = true;
        b.External_Id__c = 'TB';
        insert b;

        Account_Brand__c ab = new Account_Brand__c();
        ab.Account__c = a.Id;
        ab.Brand_Picklist__c = 'Test Brand';
        ab.Name = 'Test Brand@Test';
        insert ab;

        //Create contact
        Contact contact = new Contact();
        contact.AccountId = a.id;
        contact.LastName = 'LName1';
        contact.Title = 'testJobTitle1';    
        contact.Language__c = 'English';
        contact.No_Email__c = false;
        insert contact;

        //contact type records...
        List<Contact_Type__c> listCT = [SELECT Id, Brand_Name__c, Type__c FROM Contact_Type__c WHERE Contact__c = :cw.Contact.Id];
        List<Contact_Type__c> updatedCTs = new List<Contact_Type__c>();
        for (Contact_Type__c ct : listCT) {
            ct.Type__c = 'Influencer';
            updatedCTs.add(ct);
        }       
        if (updatedCTs.size() > 0) update updatedCTs;

        Account_Brand__c abc = [SELECT Id FROM Account_Brand__c WHERE Account__c = :a.Id LIMIT 1];

        ContactBrandDetails cbd = new ContactBrandDetails();
        cbd.AccountID = [SELECT AccountID FROM Contact Where Id = :cw.Contact.Id LIMIT 1].AccountID;

        ContactTableAccessor cta = new ContactTableAccessor();
        Integer i = cta.contactCount;

        Boolean bTest = cta.getUserCanDeleteContacts();

        PageReference pr = cta.NewContactAction();
        pr = cta.MergeContactsClick();

        List<ContactWrapper> cwList = new List<ContactWrapper>();
        cta.accountID = cbd.AccountID;
        cwList = cta.getWrappedContacts();

        test.stopTest();
    }

    static testMethod void UnitTest2() {
        //Creating Test data
        createTestData();             
       
        ContactWrapper cw = new ContactWrapper();
        cw.Contact = [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact LIMIT 1];

        ContactBrandDetails cbd = new ContactBrandDetails();
        cbd.AccountID = [SELECT AccountId FROM Contact Where Id = :cw.Contact.Id LIMIT 1].AccountId;
        cbd.Brand = 'Dice';
        cbd.LastCloseWonOpp = [SELECT CloseDate, Id, Amount FROM Opportunity WHERE Contact__c = :cw.Contact.Id LIMIT 1];

        cw.listCBD.add(cbd);

        String sBlah = cbd.PrettyAmount;
        sBlah = cbd.PrettyOppDate;
        sBlah = cbd.PrettyTitle;


        String sTT = cw.Tooltip;
    }   

    static testMethod void UnitTest3() {
        //Creating Test data
        createTestData();             
       
        ContactWrapper cw = new ContactWrapper();

        String sTT = cw.Tooltip;

        System.assertEquals(sTT, '');
    }       

    static testMethod void UnitTest4() {
        //Creating Test data
        createTestData();             
       
        ContactWrapper cw = new ContactWrapper();
        cw.Contact = [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact LIMIT 1];

        ContactBrandDetails cbd = new ContactBrandDetails();
        cbd.AccountID = [SELECT AccountID FROM Contact Where Id = :cw.Contact.Id LIMIT 1].AccountID;
        cbd.Brand = 'Dice';
        cbd.LastCloseWonOpp = [SELECT CloseDate, Id, Amount FROM Opportunity WHERE Contact__c = :cw.Contact.Id LIMIT 1];

        cw.listCBD.add(cbd);

        String sBlah = cbd.PrettyAmount;
        sBlah = cbd.PrettyOppDate;
        sBlah = cbd.PrettyTitle;

        String sTT = cw.Tooltip;
    }

    static testMethod void UnitTest5() {
        //Creating Test data
        createTestData();             

        ContactWrapper cw = new ContactWrapper();
        cw.Contact = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Account a = [SELECT Id FROM Account LIMIT 1];
       
        Opportunity opp;
        opp = TestUtils.createOpportunity('Opp_Manual', a);
        opp.Contact__c = cw.Contact.Id;
        opp.StageName = 'Closed - Won';
        opp.Primary_Brand__c = 'Dice';
        insert opp;

        Contact_Type__c ct = [SELECT Id, Type__c FROM Contact_Type__c WHERE Contact__c = :cw.Contact.Id LIMIT 1];
        ct.Type__c = 'Other';
        update ct;

        ContactBrandDetails cbd = new ContactBrandDetails();
        cbd.AccountID = [SELECT AccountID FROM Contact Where Id = :cw.Contact.Id LIMIT 1].AccountID;
        cbd.Brand = 'Dice';
        cbd.LastCloseWonOpp = null;
        cbd.ContactType = ct;

        String sBlah = cbd.PrettyAmount;
        sBlah = cbd.PrettyOppDate;
        sBlah = cbd.PrettyTitle;
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
        brand.Name = 'Dice';
        brand.External_Id__c = 'Dice';
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

        //Create Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;
        for(integer i=0; i<2; i++) {
            opp = TestUtils.createOpportunity('Opp_'+i, account);
            opp.Contact__c = contactList.get(i).id;
            opp.StageName = 'Closed Won';
            opp.Primary_Brand__c = 'Dice';
            opp.Amount = 3243;
            opp.CloseDate = System.Today().addDays(-i);
            oppList.add(opp);           
        }
        insert oppList;
    }
}