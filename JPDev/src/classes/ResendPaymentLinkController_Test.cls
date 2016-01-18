@isTest(SeeAllData=true)
private class ResendPaymentLinkController_Test {

	static testMethod void testMethod1_ExistingContact() {

		ApexPages.StandardController sc;

		Date closeDateFilter = System.today().addDays(-60);

		Opportunity o = [SELECT Id, Contact__c, Contact__r.Email, Contact__r.Id, Contact__r.Account.Channel_Partner__c FROM Opportunity WHERE CloseDate >= :closeDateFilter AND StageName = 'Closed Won' AND SyncedQuote__c != null AND Contact__r.Email != null ORDER BY LastModifiedDate DESC LIMIT 1];

		PageReference pageRef = Page.ResendPaymentLink;
		pageRef.getParameters().put('oppId', o.Id);
		pageRef.getParameters().put('send', '1');

		Test.setCurrentPage(pageRef);

		ResendPaymentLinkController controller = new ResendPaymentLinkController(sc);

		pageRef = controller.SwitcherooClick();
		pageRef = controller.SwitcherooClick();
		pageRef = controller.SwitcherooClick();

		controller.thisPL.Reason__c = 'Collections Process';
		pageRef = controller.ProcessReasonSelection();

		controller.tabInFocus = 'existingContact';
		controller.existingContact = o.Contact__r;
		controller.thisPL.Case_Description__c = 'Notes go here...';

		pageRef = controller.SaveItAll();

	}	

	static testMethod void testMethod1_ExistingContact_WithoutSend() {

		ApexPages.StandardController sc;

		Date closeDateFilter = System.today().addDays(-60);

		Opportunity o = [SELECT Id, Contact__c, Contact__r.Email, Contact__r.Id FROM Opportunity WHERE CloseDate >= :closeDateFilter AND StageName = 'Closed Won' AND SyncedQuote__c != null AND Contact__r.Email != null ORDER BY LastModifiedDate DESC LIMIT 1];

		PageReference pageRef = Page.ResendPaymentLink;
		pageRef.getParameters().put('oppId', o.Id);
		pageRef.getParameters().put('send', '0');

		Test.setCurrentPage(pageRef);

		ResendPaymentLinkController controller = new ResendPaymentLinkController(sc);

		pageRef = controller.SwitcherooClick();
		pageRef = controller.SwitcherooClick();
		pageRef = controller.SwitcherooClick();

		controller.thisPL.Reason__c = 'Collections Process';
		pageRef = controller.ProcessReasonSelection();

		controller.tabInFocus = 'existingContact';
		controller.existingContact = o.Contact__r;
		controller.thisPL.Case_Description__c = 'Notes go here...';

		pageRef = controller.SaveItAll();

	}		

	static testMethod void testMethod1_Cancel() {

		ApexPages.StandardController sc;

		Date closeDateFilter = System.today().addDays(-60);

		Opportunity o = [SELECT Id, Contact__c, Contact__r.Email, Contact__r.Id FROM Opportunity WHERE CloseDate >= :closeDateFilter AND StageName = 'Closed Won' AND SyncedQuote__c != null AND Contact__r.Email != null ORDER BY LastModifiedDate DESC LIMIT 1];

		PageReference pageRef = Page.ResendPaymentLink;
		pageRef.getParameters().put('oppId', o.Id);
		pageRef.getParameters().put('send', '0');

		Test.setCurrentPage(pageRef);

		ResendPaymentLinkController controller = new ResendPaymentLinkController(sc);

		pageRef = controller.Cancel();
	}

	static testMethod void testMethod1_NewContact() {

		ApexPages.StandardController sc;

		Date closeDateFilter = System.today().addDays(-60);

		Opportunity o = [SELECT Id, Contact__c, Contact__r.Email, Contact__r.Id FROM Opportunity WHERE CloseDate >= :closeDateFilter AND StageName = 'Closed Won' AND SyncedQuote__c != null AND Contact__r.Email != null ORDER BY LastModifiedDate DESC LIMIT 1];

		PageReference pageRef = Page.ResendPaymentLink;
		pageRef.getParameters().put('oppId', o.Id);
		pageRef.getParameters().put('send', '1');

		Test.setCurrentPage(pageRef);

		ResendPaymentLinkController controller = new ResendPaymentLinkController(sc);

		pageRef = controller.SwitcherooClick();
		pageRef = controller.SwitcherooClick();
		pageRef = controller.SwitcherooClick();

		controller.thisPL.Reason__c = 'Collections Process';
		pageRef = controller.ProcessReasonSelection();

		controller.tabInFocus = 'newContact';
		controller.existingContact = null;
		controller.newContact.FirstName = 'Jimbo';
		controller.newContact.LastName = 'Jones';
		controller.newContact.Email = 'jjones@simpsons.com';
		controller.newContact.MailingCountry = 'United States';
		controller.newContact.MailingState = 'IA';
		controller.newContact.Language__c = 'English';
		controller.thisPL.Case_Description__c = 'Notes go here...';

		pageRef = controller.SaveItAll();

	}		
}