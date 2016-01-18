/*******************************************************************
// (c) 2013 Appirio, Inc.
// 
// Description   : Class that tests the functionality of 
//                 CampaignMemberTriggerHandler.
//
// Apr 9th, 2013    Naersh Ojha(Appirio Off)
********************************************************************/
@isTest
private class CampaignMemberTriggerHandler_Test {

    static testMethod void Scenario1_and_Scenario2_Test() {
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
        
        //System.assertEquals(testCampaign.ID, [SELECT ID, CampaignID FROM Opportunity WHERE ID =: testOppty.ID LIMIT 1].CampaignID); // Removed 9/17/2013 JH

        cm = new CampaignMember();
        cm.CampaignId = testCampaign.ID;
        cm.LeadId = newLead.ID;
        cm.Status = 'Sent';
        insert cm;
                
    }
}