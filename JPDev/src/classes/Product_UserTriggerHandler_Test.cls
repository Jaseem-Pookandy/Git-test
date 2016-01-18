/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Description   : Class that tests the functionality of Account_Team_MemberTrigger.
//     
// Dec 13th, 2012    Karun Gangwani(Appirio Off)
// T-151014 
********************************************************************/
@isTest
private class Product_UserTriggerHandler_Test {

  static testMethod void test_Create_Update_deleteProductUsers() {
	  Profile sysAdmin = TestUtils.usrProfile('System Administrator');
    List<User> userList = new List<User>();
    User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                      'tests@b0.com', 'test', 'nickName', sysAdmin.Id, 'testUser_adName');
    userList.add(adminUser);    
    User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
                      'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id, 'testUser_adName2');
    userList.add(adminUser2);    
    insert userList;
    
    Account account = TestUtils.createAccount();
	  insert account;
	  List<Contact> contactList = TestUtils.createContacts(account, 1);
	  insert contactList;
    
    List<Account_Brand__c> abList = new List<Account_Brand__c>(); 
    Account_Brand__c abObj1 = new Account_Brand__c();
    abObj1.Brand_Picklist__c = 'Dice';
    abObj1.Account__c = account.Id;
    abObj1.Primary_Owner__c = userList.get(0).Id;
    abObj1.CS__c = userList.get(1).Id;
    abObj1.Status__c = 'Active';
    abList.add(abObj1); 
    Account_Brand__c abObj2 = new Account_Brand__c();
    abObj2.Brand_Picklist__c = 'Rigzone';
    abObj2.Account__c = account.Id;
    abObj2.Primary_Owner__c = userList.get(0).Id;
    abObj2.CS__c = userList.get(1).Id;
    abObj2.Status__c = 'Active';
    abList.add(abObj2);
    insert abList; 
    
    User_Group__c userGroup = new User_Group__c(Account__c=account.ID, Group_Id_Assigned__c='1001');
    insert userGroup;
    
    Test.startTest();
    
    Product_User__c pu1 = new Product_User__c(Account__c=account.ID, Account_Brand__c=abObj1.ID, 
                                              User_Group__c=userGroup.ID, Contact__c=contactList[0].ID, 
                                              Role__c='Recruiter', Status__c='Active', Username__c='testUSer1',
                                              Start_Date__c=system.today() , End_Date__c=system.today().addDays(3));
    Product_User__c pu2 = new Product_User__c(Account__c=account.ID, Account_Brand__c=abObj2.ID, 
                                              User_Group__c=userGroup.ID, Contact__c=contactList[0].ID, 
                                              Role__c='Recruiter', Status__c='Inactive', Username__c='testUSer2',
                                              Start_Date__c=system.today() , End_Date__c=system.today().addDays(3));
    List<Product_User__c> puList = new List<Product_User__c>();
    puList.add(pu1);
    puList.add(pu2);
    insert puList;
    
    Contact con = [SELECT User_Allocations_Active__c, User_Allocations_Inactive__c 
                   FROM Contact Where Id = :contactList[0].ID];
    
    system.assertEquals(con.User_Allocations_Active__c, abObj1.Brand_Picklist__c);
    system.assertEquals(con.User_Allocations_Inactive__c, abObj2.Brand_Picklist__c);
    
    // Now testing for the Batch
    pu1.Status__c = 'Inactive';
    pu2.Status__c = 'Active';
    update pu1;
    update pu2;
    
    CommonUtil.recalcContact4PU('ALL');
    con = [SELECT User_Allocations_Active__c, User_Allocations_Inactive__c 
           FROM Contact Where Id = :contactList[0].ID];
           
    system.assertEquals(con.User_Allocations_Active__c, abObj2.Brand_Picklist__c);
    system.assertEquals(con.User_Allocations_Inactive__c, abObj1.Brand_Picklist__c);
    
    Test.stopTest();  
    
    delete pu2;
    
    undelete pu2; 
	}
}