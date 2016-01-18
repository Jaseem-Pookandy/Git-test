/*******************************************************************
Name  : OnePostPageController_Test
Author: Byrnes
Date  : 2015.09.30
*************************************************************************/
@isTest(SeeAllData=true)
private class OnePostPageController_Test {
    
	static testMethod void scenario_1() {
		
		ApexPages.Standardcontroller sc;
		CreateData();
		
		Id accountId = [SELECT Id FROM Account WHERE Name = 'OnePostTestAccountRecord' ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		Id contactId = [SELECT Id FROM Contact WHERE Account.Channel_Partner__c = true AND FirstName = '___JustTesting___' ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		Id countryId = [SELECT Id FROM pw_ccpro__CountryObject__c WHERE Name = 'United States' LIMIT 1].Id;
		Id selectedRatePlanId = [SELECT Id FROM zqu__ProductRatePlan__c WHERE BrandTag__c = 'Dice' AND CurrencyIsoCode = 'USD' AND zqu__Deleted__c = false AND zqu__EffectiveStartDate__c <= today AND zqu__EffectiveEndDate__c >= today AND Auto_Creation_Process__c = 'OnePost' LIMIT 1].Id;

		PageReference pageRef = Page.OnePost;
		pageRef.getParameters().put('retURL', '%2F' + accountId);
		pageRef.getParameters().put('accid', accountId);
		
		Test.setCurrentPage(pageRef);
					
		OnePostPageController controller = new OnePostPageController(sc);	

		controller.NewOrder.Account__c = accountId;
		controller.NewOrder.Opportunity_Owner__c = System.UserInfo.getUserId();
		controller.NewOrder.BrandTag__c = 'Dice';
		controller.NewOrder.Country__c = countryId;
		controller.NewOrder.Quantity__c = 2;
		controller.NewOrder.CurrencyIsoCode = 'USD';
		controller.NewOrder.PaymentTerm__c = 'Due Upon Receipt';
		controller.NewOrder.PaymentMethod__c = 'Check';
		controller.NewOrder.Contact__c = contactId;
		controller.NewOrder.Purchase_Date__c = Date.newInstance(2015, 12, 15);		

		test.startTest();

		PageReference result = controller.RecalcData();
		system.assertEquals(null, result);

		controller.selectedRatePlanId = selectedRatePlanId;
		result = controller.ProductSelected();
		system.assertEquals(null, result);

		result = controller.SaveItAll();

		String inspector = controller.ClientAccountName;
		inspector = controller.RatePlanName;
		inspector = controller.ChargeName;
		inspector = controller.ChargeType;
		inspector = controller.ChargeLevel;
		inspector = controller.ChargeModel;
		inspector = controller.ChargeRecurringPeriod;
		inspector = controller.ChargeZuoraID;
		inspector = controller.ChargeUOM;
		inspector = controller.RatePlanChargeID;
		inspector = controller.ProductName;
		inspector = controller.OpptyName;
		inspector = controller.PrimaryBrand;
		inspector = controller.billingacctdet;
		inspector = controller.BillingAccountId;
		inspector = controller.BillingAccountNumber;
		inspector = controller.ClientAccountName;
		inspector = controller.ClientAccountName;
		inspector = controller.ClientAccountName;

		Opportunity o = controller.theOppty;
		zqu__Quote__c q = controller.theQuote;
		zqu__QuoteCharge__c qc = controller.theQuoteCharge;
		qc = controller.theDiscountCharge;
		List<zqu__QuoteCharge__c> qcList = controller.QuoteCharges;
		Decimal d = controller.DiscountPercent;

		test.stopTest();
	}

	//returns the user to home without passing in the retURL
	static testMethod void scenario_2() {
		
		ApexPages.Standardcontroller sc;
		CreateData();
		
		Id accountId = [SELECT Id FROM Account WHERE Name = 'OnePostTestAccountRecord' ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		Id contactId = [SELECT Id FROM Contact WHERE Account.Channel_Partner__c = true AND FirstName = '___JustTesting___' ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		Id countryId = [SELECT Id FROM pw_ccpro__CountryObject__c WHERE Name = 'United States' LIMIT 1].Id;

		PageReference pageRef = Page.OnePost;
		pageRef.getParameters().put('accid', accountId);
		
		Test.setCurrentPage(pageRef);
					
		OnePostPageController controller = new OnePostPageController(sc);
	}	

	public static void CreateData() {
        //Create Account
        Account account = TestUtils.createAccount();
        account.Validation_Status__c = 'Validated';
        account.Customer_Segment__c = 'Direct Hire';
        account.Name = 'OnePostTestAccountRecord';
        account.Channel_Partner__c = true;
        insert account;
    
        Account_Brand__c ab = [SELECT Id FROM Account_Brand__c WHERE Account__c = :account.Id AND Brand__r.Name = 'Dice' LIMIT 1];
        ab.Primary_Owner__c = System.UserInfo.getUserId();
        ab.CS__c = System.UserInfo.getUserId();
        update ab;

		Agency_Agreement__c aa = new Agency_Agreement__c();
		aa.Account__c = account.Id;
		aa.Name = 'Dice Agency Agreement for Test';
		aa.Status__c = 'Active';
		aa.Discount_Percent__c = 30;
		aa.Account_Brand__c = ab.Id;		
		aa.Start_Date__c = System.today().addDays(-30);
		aa.End_Date__c = System.today().addDays(335);

		insert aa;

		//Set the onepost field value
		List<zqu__ProductRatePlan__c> prpList = new List<zqu__ProductRatePlan__c>();
		for (zqu__ProductRatePlan__c prp : [SELECT Id, Name, Auto_Creation_Process__c FROM zqu__ProductRatePlan__c WHERE BrandTag__c = 'Dice' AND CurrencyIsoCode = 'USD' AND zqu__Deleted__c = false AND zqu__EffectiveStartDate__c <= today AND zqu__EffectiveEndDate__c >= today AND Name like 'DI OT%']) {
			prp.Auto_Creation_Process__c = 'OnePost';
			prpList.add(prp);
		}
		if (!prpList.isEmpty()) update prpList;

        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        for (Contact c : contactList) {
        	c.FirstName = '___JustTesting___';
        }
        insert contactList;
	}	

}