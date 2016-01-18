/*******************************************************************
// (c) 2013 Appirio, Inc.
// 
// Description   : Class that tests the functionality of 
//                 CampaignTriggerHandler.
//
// Apr 9th, 2013    Naersh Ojha(Appirio Off)
********************************************************************/
@isTest
private class CaseTriggerHandler_Test {

    static testMethod void AllScenario_Test() {
      Profile sysAdmin = TestUtils.usrProfile('System Administrator');
      List<User> userList = new List<User>();
      List<Case> caseList = new List<Case>();
      
      User adminUser1 = TestUtils.createUser('lname','firstName', 'email@c.com',
                        'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
      userList.add(adminUser1);
      
      User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
                        'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id,'testUser_adName2');
      userList.add(adminUser2);

      insert userList;
      
      //Creating brands
      TestUtils.createBrands();
      //Account
      Account testAccount = TestUtils.createAccount();
      insert testAccount;
      
      List<Account_Brand__c> abList = [Select ID, Brand_Name__c FROM Account_Brand__c 
                                        WHERE Account__c =: testAccount.ID];

      System.assertEquals(abList.size(), 5);
      
      for(Account_Brand__c ab : abList) {
        if (ab.Brand_Name__c == 'Dice') {
          ab.CS__c = userList.get(1).ID;
        } else {
            ab.CS__c = userList.get(0).ID;
        }
      }
      update abList;
    
      Test.startTest();
    
      Case newCase = new Case();
      newCase.AccountId = testAccount.ID;
      newCase.Assign_to_CSR__c = true;
      newCase.Brand__c = 'Dice';
      newCase.Reason = 'Customer Support';
      newCase.Origin = 'Phone';
      newCase.Status = 'New';
      newCase.Inbound_Email_Address__c = 'test@test.com';
      newCase.SuppliedEmail = 'fake@dice.com';
      newCase.Subject = 'Case1 Test';
      insert newCase;
      
      //Second case...
      Case newCase2 = new Case();
      newCase2.AccountId = testAccount.ID;
      newCase2.Assign_to_CSR__c = true;
      newCase2.Brand__c = 'Dice';
      newCase2.Reason = 'Customer Support';
      newCase2.Origin = 'Phone';
      newCase2.Status = 'New';
      newCase2.Inbound_Email_Address__c = 'test@test.com';
      newCase2.SuppliedEmail = 'fake@dice.com';
      newCase2.Subject = 'Case2 Test';
      insert newCase2;      
      
      System.assertEquals([SELECT OwnerId, ID FROM Case WHERE ID =: newCase.ID].OwnerId, userList.get(1).ID);
      
      newCase.Brand__c = 'Rigzone';
      newCase.Inbound_Email_Address__c = 'no@thanks.com';
      update newCase;
      
      System.assertEquals([SELECT OwnerId, ID FROM Case WHERE ID =: newCase.ID].OwnerId, userList.get(0).ID);
      
      
      // Now we need to get the id for the Email-SPAM/Junk owner

      //Group newGroup = new Group();
      //newGroup.Name = 'Email-SPAM/JUNK';
      //insert newGroup;
      
      Group g = [SELECT Id FROM Group WHERE Name = 'Email-SPAM/JUNK' LIMIT 1];

           
      //Third case...
      Case newCase3 = new Case();
      newCase3.AccountId = testAccount.ID;
      newCase3.Assign_to_CSR__c = true;
      newCase3.Brand__c = 'Dice';
      newCase3.Reason = 'Customer Support';
      newCase3.Origin = 'Phone';
      newCase3.Status = 'New';
      newCase3.Inbound_Email_Address__c = 'test@test.com';
      newCase3.SuppliedEmail = 'fake@dice.com';
      newCase3.Subject = 'Out of Office';
      newCase3.OwnerId = g.ID;
      
      try {
            insert  newCase3;
            
            // Should not make it here...if we do, it is a failure
            System.assertEquals([SELECT COUNT() FROM Case WHERE OwnerId =: g.ID], 0);
             
            //System.assertEquals(1,1);
            
      }catch(DmlException e){
            //System.debug('The following DML exception has occurrec: '+e.getMessage());
            //System.assertEquals(1,1);
            System.assertEquals([SELECT COUNT() FROM Case WHERE OwnerId =: g.ID], 0);
        
      }catch(Exception e){
            //System.debug('The following exception has occurrec: '+e.getMessage());        
            //System.assertEquals(1,1);
            System.assertEquals([SELECT COUNT() FROM Case WHERE OwnerId =: g.ID], 0);
      }  
      

      
      
      //Forth case...
      Case newCase4 = new Case();
      newCase4.AccountId = testAccount.ID;
      newCase4.Assign_to_CSR__c = true;
      newCase4.Brand__c = 'Dice';
      newCase4.Reason = 'Customer Support';
      newCase4.Origin = 'Phone';
      newCase4.Status = 'New';
      newCase4.Inbound_Email_Address__c = 'test@test.com';
      newCase4.SuppliedEmail = 'fake@dice.com';
      newCase4.Subject = 'Undeliverable:';
      newCase4.OwnerId = g.ID;

      
      try {
            insert  newCase4;
            
            // Should not make it here...if we do, it is a failure
            //System.assertEquals(1,1);
            System.assertEquals([SELECT COUNT() FROM Case WHERE OwnerId =: g.ID], 0);            
      }catch(DmlException e){
            //System.debug('The following DML exception has occurrec: '+e.getMessage());
            //System.assertEquals(1,1);
            System.assertEquals([SELECT COUNT() FROM Case WHERE OwnerId =: g.ID], 0);        
      }catch(Exception e){
            //System.debug('The following exception has occurrec: '+e.getMessage());        
            //System.assertEquals(1,1);
            System.assertEquals([SELECT COUNT() FROM Case WHERE OwnerId =: g.ID], 0);
      }  
      
      
      Test.stopTest();
      
      delete newCase;
    }
    
    

    
    
    

    
}