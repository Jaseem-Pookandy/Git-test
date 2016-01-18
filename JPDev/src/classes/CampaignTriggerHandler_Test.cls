/*******************************************************************
// (c) 2013 Appirio, Inc.
// 
// Description   : Class that tests the functionality of 
//                 CampaignTriggerHandler.
//
// Apr 9th, 2013    Naersh Ojha(Appirio Off)
********************************************************************/
@isTest
private class CampaignTriggerHandler_Test {

    static testMethod void AllScenario_Test() {
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
        
        try {
            //Campaign
            Campaign testCampaign = new Campaign(Name = 'Test Campaign 001');
            testCampaign.IsActive = true;
            testCampaign.isCall_List__c = true;
            testCampaign.Brand__c = 'Dice;Rigzone';
            insert testCampaign;
        } 
                catch(Exception e) {
                  Boolean expectedExceptionThrown =  e.getMessage().contains('Call List Campaigns require (1) and only (1) Brand to be selected') ? true : false;
                  System.AssertEquals(expectedExceptionThrown, true);
                }
                
                  Campaign testCampaign2 = new Campaign(Name = 'Test Campaign 001');
          testCampaign2.IsActive = true;
          testCampaign2.isCall_List__c = false;
          testCampaign2.Brand__c = 'Dice;Rigzone';
          insert testCampaign2;
          
          try {
              testCampaign2.isCall_List__c = true;
              update testCampaign2;
          }
          catch(Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Call List Campaigns require (1) and only (1) Brand to be selected') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
          }
    }
}