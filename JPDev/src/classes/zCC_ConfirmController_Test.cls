/************************************************************************
// (c) 2013 Appirio, Inc.
// Description    : Class that tests functionality of zCC_ConfirmController
//                  main class.
//                  
// April 23rd, 2013  :  Naresh Ojha (Appirio Offshore)
************************************************************************/
@isTest
public with sharing class zCC_ConfirmController_Test {

    @isTest
    private static void testOpptyGettingUpdatedForPaymentId(){
        String pmid = '2c92c0f93e16675b013e313aeb0e49e9';
        
        //Custom settings...
        TestUtils.CreateCustomSettingsRecords();
        
        //Test data creation
        Account accTest = TestUtils.createAccount();   
        insert accTest;
        
        
        List<Contact> cList = TestUtils.createContacts(accTest, 3);
        insert cList;
        
        Opportunity oppTest = TestUtils.createOpportunity('test opportunity', accTest);
        insert oppTest;

        zqu__Quote__c quoteTest = new zqu__Quote__c(zqu__Opportunity__c = oppTest.id, Name='test quote', zqu__Currency__c='USD', zqu__PaymentMethod__c = 'Credit Card', zqu__BillToContact__c = cList[0].Id, zqu__SoldToContact__c = cList[0].Id);
        quoteTest.Deferred_Bill_Date__c = Date.today().addDays(30);       //byrnes, 2014.05.13 for CC-2496
        insert quoteTest;
        
        //oppTest.SyncedQuote__c = quoteTest.id;
        update oppTest;
        
        System.Test.startTest();
        PageReference pageRef = Page.zCC_Confirm;
        System.Test.setCurrentPage(pageRef);
        zCC_ConfirmController confirmController = new zCC_ConfirmController();
        
        //Assert to check default is not as the payment id
        Opportunity assertOppty = [SELECT Id, ZuoraPaymentID__c FROM Opportunity WHERE ID =: oppTest.ID]; 
        System.assertNotEquals(assertOppty.ZuoraPaymentID__c, pmid);
        
        //Quote ID and any randon payment method id.
        ApexPages.currentPage().getParameters().put( 'QID', quoteTest.Id );            	
        ApexPages.currentPage().getParameters().put( 'pmid', pmid);
        confirmController.updateOpportunity();
        
        assertOppty = [SELECT Id, ZuoraPaymentID__c FROM Opportunity WHERE ID =: oppTest.ID];
        //Assert to check payment id is updated on opportunity.
        System.assertEquals(assertOppty.ZuoraPaymentID__c, pmid);
        System.Test.stopTest();
    }
}