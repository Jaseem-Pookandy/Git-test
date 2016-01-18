/***
*Class 			---- PaymentMethodTriggerHandler_Test
*Author 		---- Tim Byrnes
*Story 			---- CCBOB-92
*Created Date 	---- 2015.11.10
*Description 	---- Initial creation for covering PaymentMethodTriggerHandler.trigger & PaymentMethodTriggerHandler_Test.cls
----------------------------- Modifications & Updates -----------------------------
*Modified By 	---- 
*Story 			---- 
*Modified Date 	---- 
*Description 	---- 
***/

@isTest
private class PaymentMethodTriggerHandler_Test {
    
	static final String zuoraBillingAccountGUID = '8452162def012548f42e6a1b9c4bb900';
	static final String zuoraPaymentMethodGUID =  '8452162def012548f42e6a1b9c4bb901';
	static final String opportunityName = 'Opp_8452162def012548f42e6a1b9c4bb900';

	static testMethod void NegativeTest() {

		CreateData();

		List<Zuora__CustomerAccount__c> billingAccount = [SELECT Id FROM Zuora__CustomerAccount__c ORDER BY CreatedDate DESC LIMIT 1];

		if (billingAccount != null && billingAccount.size() != 1) return;

		//Create a payment method now and check to see if the provided by field is populated.  it should *not* be.

		Zuora__PaymentMethod__c pm = new Zuora__PaymentMethod__c();
		pm.Name = zuoraPaymentMethodGUID;
		pm.Zuora__External_Id__c = zuoraPaymentMethodGUID;
		pm.Zuora__BillingAccount__c = billingAccount[0].Id;

		insert pm;

		List<Zuora__PaymentMethod__c> pmList = [SELECT Id, Provided_By__c FROM Zuora__PaymentMethod__c WHERE Id = :pm.Id];

		system.assertEquals(null, pmList[0].Provided_By__c);
	}

	static testMethod void PositiveTest() {

		CreateData();

		//Now update the remittance link to have the payment method id
		List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE Name = :opportunityName ORDER BY CreatedDate DESC LIMIT 1];

		List<Payment_Link__c> plList = [SELECT Id, Link_Created_For__c FROM Payment_Link__c WHERE Opportunity__c = :oppList[0].Id LIMIT 1];

		if (plList != null && plList.size() == 1) {

			plList[0].Zuora_Payment_Method_Id__c = zuoraPaymentMethodGUID;
			update plList;

			List<Zuora__CustomerAccount__c> billingAccount = [SELECT Id FROM Zuora__CustomerAccount__c ORDER BY CreatedDate DESC LIMIT 1];

			if (billingAccount != null && billingAccount.size() != 1) return;

			//Create a payment method now and check to see if the provided by field is populated.  it *should* be.

			Zuora__PaymentMethod__c pm = new Zuora__PaymentMethod__c();
			pm.Name = zuoraPaymentMethodGUID;
			pm.Zuora__External_Id__c = zuoraPaymentMethodGUID;
			pm.Zuora__BillingAccount__c = billingAccount[0].Id;

			insert pm;

			List<Zuora__PaymentMethod__c> pmList = [SELECT Id, Provided_By__c FROM Zuora__PaymentMethod__c WHERE Id = :pm.Id];

			system.assertEquals('Sold By Partner', pmList[0].Provided_By__c);

			pm.Name = 'name change now';
			update pm;

			delete pm;
		}		
	}

	private static void CreateData() {

		TestUtils.createBrands();

		TestUtils.CreateCustomSettingsRecords();

		Account testAccount = TestUtils.createAccount();
		testAccount.Name = 'PaymentMethodTriggerHandler_Test';
		insert testAccount;

		List<Contact> testContactList = TestUtils.createContacts(testAccount, 5);
		insert testContactList;

		Zuora__CustomerAccount__c testBillingAccount = new Zuora__CustomerAccount__c();
		testBillingAccount.Name = testAccount.Name;
		testBillingAccount.Zuora__Account__c = testAccount.Id;
		testBillingAccount.Zuora__External_Id__c = zuoraBillingAccountGUID;
		testBillingAccount.Zuora__BillToId__c = testContactList[0].Id;
		testBillingAccount.Zuora__SoldToId__c = testContactList[0].Id;
		insert testBillingAccount;		

		Opportunity testOpp = TestUtils.createOpportunity('TestOpp', testAccount);
		testOpp.Name = opportunityName;
		insert testOpp;

		CreateRemittanceLink(testContactList[0], testOpp, 'Sold By Partner');
	}

	private static void CreateRemittanceLink(Contact c, Opportunity o, String createdFor) {
		Payment_Link__c pl = new Payment_Link__c();
		pl.Contact__c = c.Id;
		pl.Opportunity__c = o.Id;
		pl.Link_Created_For__c = createdFor;

		insert pl;
	}

}