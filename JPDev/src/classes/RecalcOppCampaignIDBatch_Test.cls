@isTest
public with sharing class RecalcOppCampaignIDBatch_Test {
	static testmethod void TestThisThing()
    {
    	//Insert the records...
    	
		//Creating brands
        TestUtils.createBrands();
        //Account
        Account testAccount = TestUtils.createAccount();
        insert testAccount;
        //Contact
        List<Contact> contactList = TestUtils.createContacts(testAccount, 1);
        insert contactList;
        //Fetching account brand for Oppty
        List<Account_Brand__c> abList = [Select ID FROM Account_Brand__c WHERE Account__c =: testAccount.ID];
        //Opportunity
        Opportunity testOppty = TestUtils.createOpportunity('Test Opty 001', testAccount);
        testOppty.Contact__c = contactList.get(0).ID;
        testOppty.Account_Brand__c = abList.get(0).ID;
        insert testOppty;
        
        //Campaign
        Campaign testCampaign = new Campaign(Name = 'Test Campaign 001');
        testCampaign.IsActive = true;
        testCampaign.isCall_List__c = true;
        testCampaign.Brand__c = 'Dice';
        insert testCampaign;

        Lead newLead = new Lead(LastName = 'Test Lead 001', Company = 'Test Company001', Status = 'Working');
        insert newLead;

        //Campaign Members
        CampaignMember cm = new CampaignMember();
        cm.CampaignId = testCampaign.ID;
        cm.ContactId = contactList.get(0).ID;
        cm.Status = 'Sent';
        insert cm;
    	
		RecalcOppCampaignIDBatch batchApex = new RecalcOppCampaignIDBatch();
		//batchApex.query = query;       
		
        Test.startTest();
        Integer i = 2000;
        database.executebatch(batchApex, i);
        test.stopTest();        
    }
}