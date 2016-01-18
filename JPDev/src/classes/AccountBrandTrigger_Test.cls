/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Description   : Class that tests the functionality of Account_Brand__c Trigger.
//     
// Dec 13th, 2012    Karun Gangwani(Appirio Off)
********************************************************************
Modified by : Jaseem Pookandy
Description : added the orphan fix logic test on acconut brand delete
ssdfs
*/
@isTest  
private class AccountBrandTrigger_Test {
    

    static testMethod void test_Create_Delete_AccountTeamMembers() {
        Profile sysAdmin = TestUtils.usrProfile('System Administrator');
      List<User> userList = new List<User>();      
        List<Brand__c> brandList = new List<Brand__c>();
        Brand__c brand = new Brand__c(isActive__c = true, Name = 'Dice', External_Id__c = 'Dice');
        brandList.add(brand);
        brand = new Brand__c(isActive__c = true, Name = 'Rigzone', External_Id__c = 'RZ');
        brandList.add(brand);
        insert brandList;
      TestUtils.CreateCustomSettingsRecords();

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
        
        system.runAs(userList.get(0)) { 
          Test.startTest();
            
          Account account = TestUtils.createAccount();
          insert account;
          
          Account_Brand__c abObj = new Account_Brand__c();
          abObj.Brand_Picklist__c = 'Dice';
          abObj.Account__c = account.Id;
          abObj.Primary_Owner__c = userList.get(0).Id;
          abObj.CS__c = userList.get(1).Id;
          abObj.Status__c = 'Active';
          insert abObj;
          
         
          AccountTeamMember atmObj = [SELECT UserId, ID FROM AccountTeamMember 
                                             WHERE AccountId =: account.Id 
                                             AND UserId =: userList.get(0).Id];
          
          System.assertNotEquals(atmObj, null);
    
                
          atmObj = [SELECT UserId, ID FROM AccountTeamMember 
                                             WHERE AccountId =: account.Id 
                                             AND UserId =: userList.get(1).Id];
          system.assertNotEquals(atmObj, null);      
          
        Test.stopTest();     
                                                            
        delete abObj;           
                
        }
    } // End of test_Create_Update_deleteAccountTeamMembers()

static testMethod void test_Create_Update_AccountTeamMembers() {
        Profile sysAdmin = TestUtils.usrProfile('System Administrator');
      List<User> userList = new List<User>();
      List<Brand__c> brandList = new List<Brand__c>();
      Brand__c brand = new Brand__c(isActive__c = true, Name = 'Dice', External_Id__c = 'Dice');
      brand.Create_At_Risk_Tasks__c = true;
      brandList.add(brand);
      brand = new Brand__c(isActive__c = true, Name = 'Rigzone', External_Id__c = 'RZ');
      brand.Create_At_Risk_Tasks__c = true;
      brandList.add(brand);
      insert brandList;

      TestUtils.CreateCustomSettingsRecords();    

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
            
          Account account = TestUtils.createAccount();
          insert account;
          
          Account_Brand__c abObj = new Account_Brand__c();
          abObj.Brand_Picklist__c = 'Dice';
          abObj.Account__c = account.Id;
          abObj.Primary_Owner__c = userList.get(0).Id;
          abObj.CS__c = userList.get(1).Id;
          abObj.Status__c = 'Active';
          abObj.Rank__c = 'Rank 3';
          insert abObj;

          insert TestUtils.CreateTasks(null, abObj.Id, 'Dice', 5);          
         
          AccountTeamMember atmObj = [SELECT UserId, ID FROM AccountTeamMember 
                                             WHERE AccountId =: account.Id 
                                             AND UserId =: userList.get(0).Id];
          
          System.assertNotEquals(atmObj, null);
    
                
          atmObj = [SELECT UserId, ID FROM AccountTeamMember 
                                             WHERE AccountId =: account.Id 
                                             AND UserId =: userList.get(1).Id];
          system.assertNotEquals(atmObj, null);
    
system.runAs(userList.get(0)) { 
          Test.startTest();

          Boolean b = AccountBrandTriggerHandler.AdminsCanDeleteWillyNilly();
              
          // Update Part
          abObj.Status__c = 'InActive';      
          abObj.CS__c = null;
          abObj.At_Risk__c = true;
          abObj.Rank__c = 'Rank 2';
          update abObj;


        List<AccountTeamMember> atmList = [SELECT UserId, ID FROM AccountTeamMember 
                                           WHERE AccountId =: account.Id 
                                           AND UserId =: userList.get(1).Id];
                                           
        System.assertEquals(atmList.size(), 0);
        
        abObj.Primary_Owner__c = userList.get(2).ID;
        abObj.CS__c = userList.get(1).Id;
        update abObj;

        atmList = [SELECT UserId, ID FROM AccountTeamMember 
                                           WHERE AccountId =: account.Id 
                                           AND UserId =: userList.get(2).Id];
        
        System.assertNotEquals(atmList.size(), 0);
          
        Test.stopTest();                                                               
                
        }
    } // End of test_Create_Update_deleteAccountTeamMembers()    
    //test the orphanfix logic on a account brand delete
    static testMethod void testmergeaccountfixorphans(){
        
        List<Brand__c> brandList = new List<Brand__c>();
        Brand__c brand = new Brand__c(isActive__c = true, Name = 'Dice', External_Id__c = 'Dice');
        brandList.add(brand);
        insert brandList; //create a dice brand 
        Account account = TestUtils.createAccount();//account creation
        account.name = 'Testcompany Inc';
        insert Account; // insert account and also dice account brand
        
        Account Acc1 = TestUtils.createAccount();//a duplicate account being created for merging
        Acc1.name = 'Testcompany';
        insert Acc1;
        
        Account master = [select id,name from Account where name = 'Testcompany Inc' LIMIT 1]; //this is the master account in merge
        Account mergeaccount = [select id,name from Account where name= 'Testcompany' LIMIT 1]; //account to be merged
        
        Account_Brand__c DiceAB = [select id,name from Account_Brand__c where account__c =: mergeaccount.id LIMIT 1]; // Account brand associated to the merged account which wil be reassigned
        Account_Brand__c DiceABMaster = [select id,name from Account_Brand__c where account__c =: master.id LIMIT 1];
        list<Task> tasklist = TestUtils.createTasks(null,mergeaccount.id,'Dice',1);//creating a task for fixorpahan logic, task is associated to merged account, which will be reassigned
        insert tasklist;
        
        system.assertequals('Dice@Testcompany',DiceAB.name);
        Task tasktomerge = [select id,brand__c,account_brand__c from task where whatid =:mergeaccount.id];
        system.assert(tasktomerge!=null);
        system.assertequals('Dice',tasktomerge.brand__c);
        system.assertequals(DiceAB.id,tasktomerge.account_brand__c); //task account brand is the merged account's
        
        merge master mergeaccount; // call account merge
        
        Account[] result = [select id from Account where name = 'Testcompany']; 
        system.assert(result.size()==0); // assert the merged accoutn is deleted
        
        DiceAB = [select id,account__c,name from Account_Brand__c where id =:DiceAB.id]; //query the orphan account brand
        
        system.assertequals(master.id,DiceAB.account__c); //assert orphan account brand is reassigned to master account
        system.assertequals('Dice@Testcompany',DiceAB.name); //name still denotes the old merged account...this is a reduntand acconut brand which we will soon delete
        tasktomerge = [select id,whatid from Task where id=:tasktomerge.id]; //orphan task
        system.assertequals(master.id,tasktomerge.whatid); //assert task is reassigned to master after merge
        
        delete DiceAB; // delete reduntant account brand 
        
        tasktomerge = [select id,whatid,account_brand__c from Task where id=:tasktomerge.id]; // orphan logic has run...
        system.assertequals(master.id,tasktomerge.whatid); // task is anyways reassigned in merge itself
        system.assertequals(DiceABMaster.id,tasktomerge.account_brand__c); //orphan logic is run on a delete of account brand, and task reassigned to master account brand
        
        
    }
}