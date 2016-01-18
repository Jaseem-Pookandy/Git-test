/*******************************************************************
// 
// Description   : Class that tests the functionality of GenerateQuotePDFController.cls
//     
********************************************************************/
@isTest(seeAllData=true)
private class GenerateQuotePDFController_Test {
	
	static testMethod void testMethod1() {

		ApexPages.Standardcontroller sc;

		NewOpportunityController_Test.CreateData();
		
		List<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity WHERE IsClosed = false LIMIT 10];
		List<Contact> contactList = [SELECT Id FROM Contact LIMIT 10];

		if (oppList != null && !oppList.isEmpty()) {
			String sourceOppId = oppList[0].Id;

			PageReference pageRef = Page.ZuoraQuote;
			pageRef.getParameters().put('oppId', sourceOppId);
		
			Test.setCurrentPage(pageRef);

			ZuoraQuoteController controller = new ZuoraQuoteController(sc);

			if (contactList != null && !contactList.isEmpty()) {
				controller.thisQuote.zqu__SoldToContact__c = contactList[0].Id;
				controller.thisQuote.zqu__BillToContact__c = contactList[0].Id;
			}

			controller.thisQuote.Name = 'Test Quote';
			controller.thisQuote.zqu__Opportunity__c = sourceOppId;
			controller.thisQuote.BrandTag__c = 'Dice';
			controller.thisQuote.zqu__ValidUntil__c = System.Date.today().addDays(5);
			controller.thisQuote.Billing_Frequency__c = 'Annual';
			controller.thisQuote.zqu__Currency__c = 'USD';
			controller.thisQuote.zqu__PaymentTerm__c = 'Due Upon Receipt';
			controller.thisQuote.zqu__PaymentMethod__c = 'Credit Card';
			controller.thisQuote.zqu__StartDate__c = controller.thisQuote.zqu__ValidUntil__c;
			controller.thisQuote.zqu__Subscription_Term_Type__c = 'Termed';
			controller.thisQuote.zqu__InitialTerm__c = 12;						

			insert controller.thisQuote;

			Test.startTest();

				pageRef = Page.GenerateQuotePDF;
				pageRef.getParameters().put('QID', controller.thisQuote.Id);
			
				Test.setCurrentPage(pageRef);
						
				GenerateQuotePDFController controllerpdf = new GenerateQuotePDFController(sc);		

				pageRef = controllerpdf.Cancel();

				System.assertEquals(pageRef, null);				

				pageRef = controllerpdf.ConfirmTemplate();

				controllerpdf.SelectQT();

				pageRef = controllerpdf.PreviewTemplate();

				pageRef = controllerpdf.SearchQuoteTemplates();

			Test.stopTest();	
		}

	}
}