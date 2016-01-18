/*******************************************************************
Name  : LoadAcctReassignmentCSVController_Test
Author: Godfrey Mwamsoyo
Date  : 03-03-2015
*************************************************************************/
@isTest(SeeAllData=false)
public with sharing class LoadAcctReassignmentCSVController_Test {

    static testMethod void testMethod1() {
        
        CreateData();
        
        test.startTest();
        
        PageReference pageRef = Page.AccountReassignment;
        
        Test.setCurrentPage(pageRef);
        
        LoadAccountReassignmentCSVController controller = new LoadAccountReassignmentCSVController(); 
        
        String reassignStr = 'Account_Number_Assigned__c,AHJRep__c,AHJCSR__c,CJRep__c,CJCSR__c,DiceRep__c,DiceCSR__c,EFCRep__c,EFCCSR__c,RZRep__c,RZCSR__c';
        reassignStr  = reassignStr + '\r\n' + '0123456789,AHJRep__c,AHJCSR__c,CJRep__c,CJCSR__c,DiceRep__c,DiceCSR__c,EFCRep__c,EFCCSR__c,RZRep__c,RZCSR__c';
        Blob reassignBlob = Blob.valueof(reassignStr);
        controller.csvFileBody = reassignBlob;
        controller.uploadFileRef = 'TestFile';
        controller.importCSVFile(); 
        controller.deleteCSVFile();
        List<String> lst = controller.safeSplit(reassignStr,',');
        ApexPages.StandardSetController stdcon = controller.setCon;
        List<AccountReassignment__c> pg = controller.PaginatedAcctList;
        String soql = controller.soql; 
        controller.next(); 
        controller.previous(); 
        controller.last(); 
        controller.first();
        Integer pageNumber = controller.pageNumber;
        Boolean hasPrevious = controller.hasPrevious;
        Boolean hasNext = controller.hasNext;
        Boolean isReassign = controller.isReassign;
        PageReference redirectRef =  controller.redirectToList();
        PageReference reviewRef =  controller.reviewList();        
        
        test.stopTest();
    }
    
    static void CreateData() {
        //Creating brands
        TestUtils.createBrands();
        
        //Account
        Account testAccount = TestUtils.createAccount();
        insert testAccount;
        
    }
       
}