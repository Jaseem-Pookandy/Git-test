/*******************************************************************
Name  : AccountReassignmentSearchController_Test
Author: Godfrey Mwamsoyo
Date  : 03-03-2015
*************************************************************************/
@isTest(SeeAllData=false)
public with sharing class AccountReassignmentSearchController_Test {

    static testMethod void testMethod1() {
        
        CreateData();
        
        test.startTest();
        
        String thisAccountNumber = [SELECT Account_Number_Assigned__c FROM Account LIMIT 1].Account_Number_Assigned__c;
        
        PageReference pageRef = Page.AccountReassignmentSearch;
        pageRef.getParameters().put('uploadedFileRef', '');
        pageRef.getParameters().put('accountNumber', thisAccountNumber);
        pageRef.getParameters().put('name', 'Account1');
        pageRef.getParameters().put('salesRep', 'John');
        pageRef.getParameters().put('supportRep', 'Doe');
        pageRef.getParameters().put('status', 'Pending');
        
        Test.setCurrentPage(pageRef);
        
        AccountReassignmentSearchController controller = new AccountReassignmentSearchController(); 
        controller.runSearch(); 
        controller.toggleSort();
        List<String> lst = controller.statusLst;
        ApexPages.StandardSetController stdcon = controller.setCon;
        List<AccountReassignment__c> pg = controller.PaginatedAccountReassignments;
        String dbg = controller.debugSoql;
        
        test.stopTest();
    }
    
    static void CreateData() {
        //Creating brands
        TestUtils.createBrands();
        
        //Account
        Account testAccount = TestUtils.createAccount();
        insert testAccount;
        
        List<Account_Brand__c> abList = createABList(testAccount);        
    }
    
    private static List<Account_Brand__c> createABList(Account testAccount) {
        List<Account_Brand__c> accBrandList = new List<Account_Brand__c>();
        testAccount = [SELECT Migration_Id__c From Account Where ID = :testAccount.Id];
        Profile sysAdmin = TestUtils.usrProfile('System Administrator');
        List<User> userList = new List<User>();      
        User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                          'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
        userList.add(adminUser);        
        User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
                          'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id,'testUser_adName2');
        userList.add(adminUser2);
        User adminUser3 = TestUtils.createUser('lname3','firstName3', 'email3@c.com',
                          'tests3@b0.com', 'test3', 'nickName3', sysAdmin.Id,'testUser_adName3');
        userList.add(adminUser3);
                
        insert userList;    
          Account_Brand__c abObj = new Account_Brand__c();
          abObj.Brand_Picklist__c = 'Dice';
          abObj.Account__c = testAccount.Id;
          abObj.Primary_Owner__c = userList.get(0).Id;
          abObj.CS__c = userList.get(1).Id;
          abObj.Status__c = 'Active';
          accBrandList.add(abObj);
       insert accBrandList;
    return accBrandList; 
  }     
}