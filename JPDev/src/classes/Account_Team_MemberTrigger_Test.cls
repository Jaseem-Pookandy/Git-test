/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Description   : Class that tests the functionality of Account_Team_MemberTrigger.
//     
// Dec 13th, 2012    Karun Gangwani(Appirio Off)
********************************************************************/
@isTest
private class Account_Team_MemberTrigger_Test { 

  static testMethod void test_Create_Update_deleteAccountTeamMembers() {

    Profile sysAdmin = TestUtils.usrProfile('System Administrator');
    
    User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                      'tests@b0.com', 'test', 'nickName', sysAdmin.Id, 'testUser_adName');
    insert adminUser;
    
    User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
                      'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id, 'testUser_adName2');
    insert adminUser2;
    
    system.runAs(adminUser) { 
      Test.startTest();
      
      Brand__c brandObj = new Brand__c();
      brandObj.Name = 'Dice';
      brandObj.External_Id__c = 'Dice';
      insert brandObj;
      
      brandObj = [SELECT Id, Name FROM Brand__c where id = :brandObj.Id];
      
      Account account = TestUtils.createAccount();
      insert account;
      List<Account_Brand__c> abList = [Select ID FROM Account_Brand__c WHERE Account__c =: account.ID];
            
      Account_Team_Member__c a_t_mObj = new Account_Team_Member__c();
      a_t_mObj.Account_Brand__c = abList.get(0).ID;
      a_t_mObj.User__c = adminUser.Id;
      a_t_mObj.Role__c = 'Sales Rep';
      a_t_mObj.Account__c = account.Id;
      insert a_t_mObj;
      
      a_t_mObj = [Select User__c, Role__c, Brand_Name__c, Account__c 
                  FROM Account_Team_Member__c WHERE Id = :a_t_mObj.Id];      
      
      AccountTeamMember atmObj = [SELECT UserId, ID FROM AccountTeamMember 
                                         WHERE AccountId = :account.Id 
                                         AND UserId = :adminUser.Id];
      system.assertNotEquals(atmObj, null);
      system.assertEquals(atmObj.UserID, adminUser.ID);      
           
          
      // Update Part    
      a_t_mObj.User__c = adminUser2.Id;
      update a_t_mObj;
      
      atmObj = [SELECT UserId, ID FROM AccountTeamMember 
                                         WHERE AccountId =: account.Id 
                                         AND UserId =: adminUser2.Id];
      system.assertNotEquals(atmObj, null);
      system.assertEquals(atmObj.UserID, adminUser2.ID);      
      
      delete a_t_mObj;
     
      Test.stopTest();      
    }

    
  } // End of test_Create_Update_deleteAccountTeamMembers()
}