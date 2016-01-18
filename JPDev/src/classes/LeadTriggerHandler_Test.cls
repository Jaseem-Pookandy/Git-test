/*******************************************************************************
Name        : LeadTrigger_Test
Description : Test Class for LeadTriggerHandler.
Author      : Naresh Kr. Ojha (Appirio Offshore)
Date        : Jan 16th, 2013
*******************************************************************************/
@isTest (SeeAllData=true)
private class LeadTriggerHandler_Test {

    static testMethod void myUnitTest() {
        Profile prof = TestUtils.usrProfile();

        //Create Users
        List<User> userList = new List<User>();
        User testUser = TestUtils.createUser('lastName1', 'firstName1', 'email1@email.com', 
                                             'testUserName1@uname.com', 'alias1',
                                             'nickName1', prof.ID, 'testAdUsername1');
        userList.add(testUser);     
        testUser = TestUtils.createUser('lastName2', 'firstName2', 'email2@email.com', 
                                        'testUserName2@uname.com', 'alias2', 
                                        'nickName2', prof.ID, 'testAdUsername2');
        userList.add(testUser); 
        testUser = TestUtils.createUser('lastName3', 'firstName3', 'email3@email.com', 
                                        'testUserName3@uname.com', 'alias3', 
                                        'nickName3', prof.ID, 'testAdUsername3');
        userList.add(testUser);     
        insert userList;
        
        //Create Job_Title__c       
        Job_Title__c jobTitle = new Job_Title__c();
        jobTitle.Name = 'testJobTitle1';
        insert jobTitle;
        
        //Create Account
        Account account = TestUtils.createAccount();
        account.name = 'TestAccount'+String.valueOf(DateTime.now());
        insert account;
                
        Map<String, Brand__c> brID_BrandMap = TestUtils.getBrands();
        List<Account_Brand__c> accountBrandList = [SELECT Primary_Owner__c, Rank__c 
                                                    FROM Account_Brand__c 
                                                    WHERE Account__c =: account.ID 
                                                      AND Brand__c =: brID_BrandMap.get('Dice').ID];
        accountBrandList.get(0).Primary_owner__c = userList.get(0).Id;   
        update accountBrandList.get(0);                                                  
        
        Lead lead;

        System.runAs(userList.get(1)) {
          //>>create lead with some brand and the owner of the lead should be different
          lead = new Lead();
          lead.LastName = 'Lead Last Name';
          lead.Company = account.Name;
          lead.Brand__c = 'Dice';
          lead.Street = 'test';
          lead.City = 'test';
          //lead.zip = '302022';
          lead.Country = 'India';
          lead.Status = 'Open - Not Contacted';
          lead.Title = 'testJobTitle1';
          lead.Type__c = 'Accounts Payable';
          insert lead;                                                                                                      
                                                  
          Lead newLead = [SELECT Title, Company, Job_Title__c, Related_Account__c, OwnerId 
                          FROM Lead WHERE Id = :lead.id LIMIT 1];
              
          //Verify that Job_Title__c is same as Title.
          System.assertEquals(newLead.Title, [SELECT Name FROM Job_Title__c 
                                              WHERE Id = :newLead.Job_Title__c].Name);
                                              
          //Verify that related_account__c is the account related to company                                  
          System.assertEquals(account.id, newLead.Related_Account__c);
                                                        
          //>>convert lead                     
          Test.startTest();
          
          Database.LeadConvert lc = new database.LeadConvert();
          lc.setLeadId(lead.id); 
          lc.setOpportunityName('Test convert opp');   
          lc.setDoNotCreateOpportunity(false);
          lc.setSendNotificationEmail(false);
          lc.setOwnerId(UserInfo.getUserId());
          LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
          lc.setConvertedStatus(convertStatus.MasterLabel);
          Database.LeadConvertResult lcr = Database.convertLead(lc);
          System.assert(lcr.isSuccess());
          Id oppId = lcr.getOpportunityId();                           
                    
          Test.stopTest();                  
        }        
    }
    
  
    
    static testMethod void myUnitTest2() {
        Profile prof = TestUtils.usrProfile();

        //Create Users
        List<User> userList = new List<User>();
        User testUser = TestUtils.createUser('lastName1', 'firstName1', 'email1@email.com', 
                                             'testUserName1@uname.com', 'alias1',
                                             'nickName1', prof.ID, 'testAdUsername1');
        userList.add(testUser);     
        testUser = TestUtils.createUser('lastName2', 'firstName2', 'email2@email.com', 
                                        'testUserName2@uname.com', 'alias2', 
                                        'nickName2', prof.ID, 'testAdUsername2');
        userList.add(testUser); 
        testUser = TestUtils.createUser('lastName3', 'firstName3', 'email3@email.com', 
                                        'testUserName3@uname.com', 'alias3', 
                                        'nickName3', prof.ID, 'testAdUsername3');
        userList.add(testUser);     
        insert userList;
        
        //Create Job_Title__c       
        Job_Title__c jobTitle = new Job_Title__c();
        jobTitle.Name = 'testJobTitle1';
        insert jobTitle;
        
        //Create Account
        Account account = TestUtils.createAccount();
        account.name = 'TestAccount'+String.valueOf(DateTime.now());
        insert account;

        //Contact
        List<Contact> contactList = TestUtils.createContacts(account, 1);
        insert contactList;
        //Fetching account brand for Oppty
        List<Account_Brand__c> abList = [Select ID FROM Account_Brand__c WHERE Account__c =: account.ID];
        //Opportunity
        Opportunity testOppty = TestUtils.createOpportunity('Test Opty 001', account);
        testOppty.Contact__c = contactList.get(0).ID;
        testOppty.Account_Brand__c = abList.get(0).ID;
        testOppty.Validation_Rule_Override__c = DateTime.now();
        testOppty.Renewal_Owner_Assigned__c = UserInfo.getUserId();
        insert testOppty;
        
        //Campaign
        Campaign testCampaign = new Campaign(Name = 'Test Campaign 001');
        testCampaign.IsActive = true;
        testCampaign.isCall_List__c = true;
        testCampaign.Brand__c = 'Dice';
        insert testCampaign;
                                
        Lead lead;    
        System.runAs(userList.get(1)) {
          //>>create lead with some brand and the owner of the lead should be different
          lead = new Lead();
          lead.LastName = 'Lead Last Name';
          lead.Company = account.Name;
          lead.Brand__c = 'Dice';
          lead.Street = 'test';
          lead.City = 'test';
          lead.Country = 'India';
          lead.Status = 'Open - Not Contacted';
          lead.Title = 'testJobTitle1';
          lead.Related_Account__c = account.Id;
          lead.HasOptedOutOfEmail = true;
          lead.Market_Segment__c = 'Banks';
          lead.Type__c = 'Accounts Payable';
          insert lead;

          //Campaign Members
          CampaignMember cm = new CampaignMember();
          cm.CampaignId = testCampaign.ID;
          cm.LeadId = lead.ID;
          cm.Status = 'Sent';
          insert cm;
                  
          //lead = [SELECT Related_Account__c from Lead Where Id = :lead.Id];
          //lead.Related_Account__c = null;          
          //update lead;
                                              
          Test.startTest();
         
          Database.LeadConvert lc = new database.LeadConvert();
          lc.setLeadId(lead.id); 
          lc.setOpportunityName('Test convert opp');   
          lc.setDoNotCreateOpportunity(false);
          lc.setSendNotificationEmail(false);
          lc.setOwnerId(UserInfo.getUserId());
          //lc.setAccountId(account.Id);
          LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
          lc.setConvertedStatus(convertStatus.MasterLabel);
          Database.LeadConvertResult lcr = Database.convertLead(lc);
          System.assert(lcr.isSuccess());
          Id oppId = lcr.getOpportunityId();  
          
          Test.stopTest();
                  
        }        
    }
      
 static testMethod void myUnitTest3() {
        Profile prof = TestUtils.usrProfile();
        
        //Create Users
        List<User> userList = new List<User>();
        User testUser = TestUtils.createUser('lastName1', 'firstName1', 'email1@email.com', 
                                             'testUserName1@uname.com', 'alias1',
                                             'nickName1', prof.ID, 'testAdUsername1');
        userList.add(testUser);     
        testUser = TestUtils.createUser('lastName2', 'firstName2', 'email2@email.com', 
                                        'testUserName2@uname.com', 'alias2', 
                                        'nickName2', prof.ID, 'testAdUsername2');
        userList.add(testUser); 
        testUser = TestUtils.createUser('lastName3', 'firstName3', 'email3@email.com', 
                                        'testUserName3@uname.com', 'alias3', 
                                        'nickName3', prof.ID, 'testAdUsername3');
        userList.add(testUser);     
        insert userList;
        
        //Create Job_Title__c       
        Job_Title__c jobTitle = new Job_Title__c();
        jobTitle.Name = 'testJobTitle1';
        insert jobTitle;
        
        //Create Account
        Account account = TestUtils.createAccount();
        account.name = 'TestAccount'+String.valueOf(DateTime.now());
        insert account;
                
        Map<String, Brand__c> brID_BrandMap = TestUtils.getBrands();
        List<Account_Brand__c> accountBrandList = [SELECT Primary_Owner__c, Rank__c 
                                                    FROM Account_Brand__c 
                                                    WHERE Account__c =: account.ID 
                                                      AND Brand__c =: brID_BrandMap.get('Dice').ID];
        accountBrandList.get(0).Primary_owner__c = userList.get(0).Id;   
        update accountBrandList.get(0);                                                  
        
        Lead lead;
    
        System.runAs(userList.get(1)) {
          //>>create lead with some brand and the owner of the lead should be different
          lead = new Lead();
          lead.LastName = 'Lead Last Name';
          lead.Company = account.Name;
          lead.Brand__c = 'Dice';
          lead.Street = 'test';
          lead.City = 'test';
          //lead.zip = '302022';
          lead.Country = 'India';
          lead.Status = 'Open - Not Contacted';
          lead.Title = 'testJobTitle1';
          insert lead;                                                                                                      
                                                  
          Lead newLead = [SELECT Title, Company, Job_Title__c, Related_Account__c, OwnerId 
                          FROM Lead WHERE Id = :lead.id];
              
          //Verify that Job_Title__c is same as Title.
          System.assertEquals(newLead.Title, [SELECT Name FROM Job_Title__c 
                                              WHERE Id = :newLead.Job_Title__c].Name);
                                              
          //Verify that related_account__c is the account related to company                                  
          System.assertEquals(account.id, newLead.Related_Account__c);
 
          Test.startTest();

          Task t = new Task();
          t.WhoId = newLead.Id;
          t.Subject = 'Call';
          t.Type__c = 'Call Inbound';
          t.Brand__c = 'Dice';
          t.Due_Date__c = System.today();
          insert t;

          newLead.Country = 'United States';
          newLead.State = 'IA';  
          newLead.PostalCode = '50309';        
		  PreventRecursiveExecution.isFirstRun = true;
          update newLead;

          Task t1 = new Task();
          t1.WhatId = account.Id;
          t1.Subject = 'Call';
          t1.Type__c = 'Call Inbound';
          t1.Brand__c = 'Dice';
          t1.Due_Date__c = System.today();
          insert t1;
          
          Task t2 = new Task();
          t2.WhatId = accountBrandList.get(0).Id;
          t2.Subject = 'Call';
          t2.Type__c = 'Call Inbound';
          t2.Brand__c = 'Dice';
          t2.Due_Date__c = System.today();
          insert t2;          
          
          Webstore_Order__c wo = new Webstore_Order__c();
          wo.Account__c = account.Id;
          wo.Account_Brand__c = accountBrandList.get(0).Id;
          wo.Order_ID__c = '1234567890';
          insert wo;
                    
          t2 = new Task();
          t2.WhatId = wo.Id;
          t2.Subject = 'Call';
          t2.Type__c = 'Call Inbound';
          t2.Brand__c = 'Dice';
          t2.Due_Date__c = System.today();
          insert t2;                                 
                    
          Test.stopTest();                  
        }        
    }      
      
}