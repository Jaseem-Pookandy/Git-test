/***
*Class          ---- CustomerFeedbackTriggerHandler_Test
*Author         ---- Tim Byrnes
*Story          ---- Account Restructure
*Created Date   ---- 2015.12.07
*Description    ---- Test classes for the CustomerFeedbackTrigger & CustomerFeedbackTriggerHandler
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- 
*Story          ---- 
*Modified Date  ---- 
*Description    ---- 
***/

@isTest
private class CustomerFeedbackTriggerHandler_Test {
    
	static testMethod void PositiveTest() {

		CreateData();

		Test.startTest();

			List<Account> accountList = [SELECT Id FROM Account WHERE Name = '=-=|~~~_!_ Test _!_~~~|=-=' LIMIT 1];
			if (accountList.isEmpty()) return;

			Case c = new Case();
			c.AccountId = accountList[0].Id;
			c.Assign_to_CSR__c = false;
			c.Brand__c = 'Dice';
			c.Reason = 'Customer Support';
			c.Origin = 'Phone';
			c.Status = 'New';
			insert c;

			Customer_Feedback__c cf = new Customer_Feedback__c();
			cf.Case__c = c.Id;
			cf.Account__c = c.AccountId;
			cf.Primary_Brand__c = 'Dice';

			insert cf;

		Test.stopTest();

		List<Customer_Feedback__c> cfList = [SELECT Id, Account_Brand__c FROM Customer_Feedback__c WHERE Account__c = :c.AccountId LIMIT 1];

		if (cfList.isEmpty()) return;

		else system.assertNotEquals(null, cfList[0].Account_Brand__c);

		update cf;

		delete cf;
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