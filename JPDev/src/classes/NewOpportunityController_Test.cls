/*******************************************************************
Name  : NewOpportunityController_Test
Author: Byrnes
Date  : 2013.10.08 
*************************************************************************/
@isTest(SeeAllData=true)
public class NewOpportunityController_Test {

	static testMethod void testMethod1() {
		
		ApexPages.Standardcontroller sc;
		CreateData();
		
		PageReference pageRef = Page.NewOpportunity;
		pageRef.getParameters().put('retURL', '%2Fhome%2Fhome.jsp');
		
		Test.setCurrentPage(pageRef);
					
		NewOpportunityController controller = new NewOpportunityController(sc);		
	}
	
	//cancel
	static testMethod void testMethod2() {
		
		ApexPages.Standardcontroller sc;
		CreateData();
		
		PageReference pageRef = Page.NewOpportunity;
		pageRef.getParameters().put('retURL', '/home/home.jsp');
		
		Test.setCurrentPage(pageRef);
					
		NewOpportunityController controller = new NewOpportunityController(sc);
		
		pageRef = controller.Cancel();
		
		PageReference pageRefCancel = new PageReference('/home/home.jsp');
		
		system.assertEquals(pageRef.getURL(), pageRefCancel.getURL());
	}
	
	//from a contact...
	static testMethod void testMethod3() {
		
		Id contactID = [SELECT Id FROM Contact LIMIT 1].Id;
		
		Opportunity o;
		
		ApexPages.Standardcontroller sc;
		CreateData();
		
		PageReference pageRef = Page.NewOpportunity;
		pageRef.getParameters().put('retURL', '/home/home.jsp');
		pageRef.getParameters().put('conid', contactID);
		
		Test.setCurrentPage(pageRef);
					
		NewOpportunityController controller = new NewOpportunityController(sc);		
		
		pageRef.getParameters().put('index', '0');
		controller.DeleteProductBrandRow();
				
		pageRef = controller.AddProductBrandRow();
		pageRef = controller.AddProductBrandRow();
				
		pageRef = controller.AccountChanged();
		
		pageRef = controller.SwitcherooClick();
		pageRef = controller.SwitcherooClick();
						
	}
	
	//from another opp
	static testMethod void testMethod4() {
		
		Id opportunityID = [SELECT Id FROM Opportunity WHERE Amount > 1000 LIMIT 1].Id;
				
		ApexPages.Standardcontroller sc;
		CreateData();
		
		PageReference pageRef = Page.NewOpportunity;
		pageRef.getParameters().put('retURL', '/home/home.jsp');
		pageRef.getParameters().put('renewOpp', opportunityID);
		
		Test.setCurrentPage(pageRef);
					
		NewOpportunityController controller = new NewOpportunityController(sc);		
		
		controller.newOpp.Name = 'Test Opp';
		controller.newOpp.CloseDate = System.today();

		pageRef = controller.SaveItAll();
	}
	
	//from another opp
	static testMethod void testMethod5() {
		
		Id opportunityID = [SELECT Id FROM Opportunity WHERE Amount > 1000 LIMIT 1].Id;		
		Id accountID = [SELECT Id FROM Account LIMIT 1].Id;
				
		ApexPages.Standardcontroller sc;
		CreateData();
		
		PageReference pageRef = Page.NewOpportunity;
		pageRef.getParameters().put('retURL', '/home/home.jsp');
		pageRef.getParameters().put('renewOpp', opportunityID);
		
		Test.setCurrentPage(pageRef);
					
		NewOpportunityController controller = new NewOpportunityController(sc);		
		
		controller.newOpp.Name = 'Test Opp';
		controller.newOpp.CloseDate = System.today();
		controller.newOpp.AccountId = accountID;
		
		
		controller.SetLeadSource();
		controller.SetAvailableProducts();
		
		controller.ContactChanged();
	}	
	
	//successful save?
	static testMethod void testMethod6() {
		
		Id opportunityID = [SELECT Id FROM Opportunity WHERE Amount > 1000 LIMIT 1].Id;		
		Id accountID = [SELECT Id FROM Account LIMIT 1].Id;
		
		Id contactID = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1].Id;
		Id countryID = [SELECT Id FROM pw_ccpro__CountryObject__c WHERE Name = 'United States'].Id;
		Id currencyID = [SELECT Id FROM CurrencyType WHERE IsoCode = 'USD'].Id;
				
		ApexPages.Standardcontroller sc;
		CreateData();
		
		PageReference pageRef = Page.NewOpportunity;
		pageRef.getParameters().put('retURL', '/home/home.jsp');
		pageRef.getParameters().put('renewOpp', opportunityID);
		
		Test.setCurrentPage(pageRef);
					
		NewOpportunityController controller = new NewOpportunityController(sc);		
		
		controller.newOpp.Name = 'Test Opp';
		controller.newOpp.CloseDate = System.today();
		controller.newOpp.AccountId = accountID;				
		controller.newOpp.Contact__c = contactID;
		//controller.newOpp.Currency__c = currencyID;
		controller.newOpp.StageName = 'Qualified Need';
		
		controller.newOpp.Primary_Brand__c = 'Dice';
		
		controller.SetLeadSource();
		controller.SetAvailableProducts();	
		
		controller.oppLineItems.clear();
		
		OpportunityLineItem oli = new OpportunityLineItem();
		oli.Quantity = 1;
		oli.Country__c = countryID;
		oli.UnitPrice = 50;
		oli.Description = 'Dice';
		
		controller.oppLineItems.add(oli);	
		controller.SaveItAll();
	}	
	
	static testMethod void testMethod7() {
		
		Id opportunityID = [SELECT Id FROM Opportunity WHERE Amount > 1000 LIMIT 1].Id;		
		Id accountID = [SELECT Id FROM Account LIMIT 1].Id;
		
		Id contactID = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1].Id;
		Id countryID = [SELECT Id FROM pw_ccpro__CountryObject__c WHERE Name = 'United States'].Id;
		Id currencyID = [SELECT Id FROM CurrencyType WHERE IsoCode = 'USD'].Id;
				
		ApexPages.Standardcontroller sc;
		CreateData();
		
		PageReference pageRef = Page.NewOpportunity;
		pageRef.getParameters().put('retURL', '/home/home.jsp');
		pageRef.getParameters().put('renewOpp', opportunityID);
		
		Test.setCurrentPage(pageRef);
					
		NewOpportunityController controller = new NewOpportunityController(sc);		
		
		controller.newOpp.Name = 'Test Opp';
		controller.newOpp.CloseDate = System.today();
		controller.newOpp.AccountId = accountID;				
		controller.newOpp.Contact__c = contactID;
		//controller.newOpp.Currency__c = currencyID;
		controller.newOpp.StageName = 'Qualified Need';
		
		controller.newOpp.Primary_Brand__c = 'Dice';
		
		controller.SetLeadSource();
		controller.SetAvailableProducts();	
		
		controller.oppLineItems.clear();
		
		OpportunityLineItem oli = new OpportunityLineItem();
		oli.Quantity = 1;
		oli.Country__c = countryID;
		oli.UnitPrice = 50;
		oli.Description = 'Dice';
		
		controller.oppLineItems.add(oli);
		controller.SetSoldByPartner();	
		controller.SaveItAll();
	}	
	
	
	public static void CreateData() {
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