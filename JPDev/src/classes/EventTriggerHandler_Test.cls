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

@isTest
private class EventTriggerHandler_Test {

    static testMethod void PostiveAccountWhatIdTest() {

        CreateData();

        Test.startTest();

            List<Account> accountList = [SELECT Id, Name FROM Account ORDER BY CreatedDate DESC Limit 1];

            if (accountList.isEmpty()) return;

            Event e = new Event();

            e.WhatId = accountList[0].Id;
            e.Subject = 'Test';
            e.StartDateTime = System.now();
            e.EndDateTime = System.now().addHours(1);
            e.Brand__c = 'Dice';

            insert e;

        Test.stopTest();

        List<Event> eventList = [SELECT Id, Account_Brand__c FROM Event WHERE WhatId = :accountList[0].Id];

        system.assertNotEquals(null, eventList[0].Account_Brand__c);

        update e;

    }

    static testMethod void PostiveCaseWhatIdTest() {

        CreateData();

        Test.startTest();

            List<Account> accountList = [SELECT Id, Name FROM Account ORDER BY CreatedDate DESC Limit 1];

            if (accountList.isEmpty()) return;

            List<Contact> contactList = [SELECT Id, Name FROM Contact WHERE AccountId = :accountList[0].Id];

            if (contactList.isEmpty()) return;

            Case c = new Case();
            c.AccountId = accountList[0].Id;
            c.Assign_to_CSR__c = false;
            c.Brand__c = 'Dice';
            c.Reason = 'Customer Support';
            c.Origin = 'Phone';
            c.Status = 'New';
            insert c;

            Event e = new Event();

            e.WhatId = c.Id;
            e.WhoId = contactList[0].Id;
            e.Subject = 'Test';
            e.StartDateTime = System.now();
            e.EndDateTime = System.now().addHours(1);
            e.Brand__c = 'Dice';

            insert e;

        Test.stopTest();

        List<Event> eventList = [SELECT Id, Account_Brand__c FROM Event WHERE WhatId = :c.Id];

        system.assertNotEquals(null, eventList[0].Account_Brand__c);

    }    

    static testMethod void PostiveOppWhatIdTest() {

        CreateData();

        Test.startTest();

            List<Account> accountList = [SELECT Id, Name FROM Account ORDER BY CreatedDate DESC Limit 1];

            if (accountList.isEmpty()) return;

            List<Contact> contactList = [SELECT Id, Name FROM Contact WHERE AccountId = :accountList[0].Id];

            if (contactList.isEmpty()) return;

            List<Opportunity> oppList = [SELECT Id, Name FROM Opportunity WHERE AccountId = :accountList[0].Id];

            if (oppList.isEmpty()) return;

            Event e = new Event();

            e.WhatId = oppList[0].Id;
            e.WhoId = contactList[0].Id;
            e.Subject = 'Test';
            e.StartDateTime = System.now();
            e.EndDateTime = System.now().addHours(1);
            e.Brand__c = 'Dice';

            insert e;

        Test.stopTest();

        List<Event> eventList = [SELECT Id, Account_Brand__c FROM Event WHERE WhatId = :oppList[0].Id];

        system.assertNotEquals(null, eventList[0].Account_Brand__c);

    }      

static testMethod void PostiveWebstoreOrderWhatIdTest() {

        CreateData();

        Test.startTest();

            List<Account> accountList = [SELECT Id, Name FROM Account ORDER BY CreatedDate DESC Limit 1];

            if (accountList.isEmpty()) return;

            List<Contact> contactList = [SELECT Id, Name FROM Contact WHERE AccountId = :accountList[0].Id];

            if (contactList.isEmpty()) return;

            List<Opportunity> oppList = [SELECT Id, Name FROM Opportunity WHERE AccountId = :accountList[0].Id];

            if (oppList.isEmpty()) return;

            Webstore_Order__c wo = new Webstore_Order__c();
            wo.Order_ID__c = 'Random order Id number goes here';
            wo.Status__c = 'Pending';
            wo.Account__c = accountList[0].Id;
            insert wo;

            Event e = new Event();

            e.WhatId = wo.Id;
            e.WhoId = contactList[0].Id;
            e.Subject = 'Test';
            e.StartDateTime = System.now();
            e.EndDateTime = System.now().addHours(1);
            e.Brand__c = 'Dice';

            insert e;

        Test.stopTest();

        List<Event> eventList = [SELECT Id, Account_Brand__c FROM Event WHERE WhatId = :wo.Id];

        system.assertNotEquals(null, eventList[0].Account_Brand__c);

    }          

    public static void CreateData() {

        TestUtils.createBrands();
        TestUtils.CreateCustomSettingsRecords();
        TestUtils.createDomaintoBrandMap();

        //Create Account
        Account account = TestUtils.createAccount();
        account.Name = '=-=|~~~_!_ Test _!_~~~|=-=';
        insert account;
        
        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        insert contactList;

        //Create Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;
        for(integer i=0; i<2; i++) {
            opp = TestUtils.createOpportunity('Opp_'+i, account);
            opp.Contact__c = contactList.get(i).id;
            oppList.add(opp);           
        }
        insert oppList;         
  
    }       
}