/***************************************************************************
// (c) 2013 Doextra CRM Solutions
//
// Description    : Class that contains all of the public webService methods needed
//                  To execute custom code on button clicks.
//                  
// Sep 27th, 2013 : Byrnes
//***************************************************************************/

@isTest
private class WebServices_Test {

	static testMethod void CloseCloneTask_Test() {

        //Create Account
        Account account = TestUtils.createAccount();
        insert account;
            		
        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        insert contactList;
            
		Task t = new Task();
		t.Priority = 'Normal';
		t.WhoId = contactList.get(0).id;
		insert t;
		
		WebServices ws = new WebServices();
		
		string returnedID = WebServices.CloseCloneTask(t.Id);
		System.assertNotEquals(returnedID, null);		
	}

	static testMethod void UpdateABPR_Test() {

        //Create Account
        Account account = TestUtils.createAccount();
        insert account;
            		
        Account_Brand__c ab = new Account_Brand__c();
        ab.Account__c = account.Id;
        ab.Brand_Picklist__c = 'Dice';
        insert ab;

        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        insert contactList;           		
		
		WebServices ws = new WebServices();
		
		string returnedBlah = WebServices.SetABPrimaryRecipient('clear', contactList[0].Id, 'Dice', account.Id);
		System.assertEquals(returnedBlah, null);		
	}	

	static testMethod void PaymentLinkWS_Test() {

        //Create Account
        Account account = TestUtils.createAccount();
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

		WebServices ws = new WebServices();
		
		string returnedBlah = WebServices.CreatePaymentLink(oppList[0].Id, '', null, null, null, false, false);

		Boolean isError = false;

		if (returnedBlah.startsWithIgnoreCase('error')) isError = true;

		System.assertEquals(isError, true);

        //reset for the next one
        
        returnedBlah = WebServices.CreatePaymentLink(oppList[0].Id, oppList[0].Contact__c, null, null, null, false, false);

        isError = false;

        if (returnedBlah.startsWithIgnoreCase('error')) isError = true;

        System.assertEquals(isError, false);
	}		
}