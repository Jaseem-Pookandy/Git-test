/*******************************************************************
Name  : MassUpdateAccountBrandsController_Test
Author: Byrnes
Date  : 2014.06.18
*************************************************************************/

@isTest
private class MassUpdateAccountBrandsController_Test {

	static testMethod void testMethod1() {
		
		ApexPages.Standardcontroller sc;
		
		TestUtils.createBrands();
		Account a = TestUtils.createAccount();
		insert a;
		
		Account validate = [Select Id, (Select Id FROM Account_Brands__r) FROM Account WHERE Id = :a.Id];
		List<Brand__c> brands = [Select Id FROM Brand__c];

		System.assertEquals(brands.size(), validate.Account_Brands__r.size());
		//make sure this account has the same number of brands as brands exist.

		MassUpdateAccountBrandsController controller = new MassUpdateAccountBrandsController(sc);
		
		PageReference pg = controller.Cancel();

		pg = controller.SaveItAll();	
	}

	static testMethod void testMethod2() {
		
		ApexPages.Standardcontroller sc;
		
		TestUtils.createBrands();
		Account a = TestUtils.createAccount();
		insert a;
		
		Account validate = [Select Id, (Select Id FROM Account_Brands__r) FROM Account WHERE Id = :a.Id];
		List<Brand__c> brands = [Select Id FROM Brand__c];

		System.assertEquals(brands.size(), validate.Account_Brands__r.size());
		//make sure this account has the same number of brands as brands exist.

		PageReference pageRef = Page.MassUpdateAccountBrands;
		pageRef.getParameters().put('accid', validate.Id);
		
		Test.setCurrentPage(pageRef);

		MassUpdateAccountBrandsController controller = new MassUpdateAccountBrandsController(sc);

		//controller.accountID = validate.Id;	

		pageRef = controller.SaveItAll();	
	}	
}