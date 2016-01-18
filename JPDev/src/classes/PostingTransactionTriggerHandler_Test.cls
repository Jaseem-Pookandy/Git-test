@isTest
private class PostingTransactionTriggerHandler_Test{
    
    static testMethod void Scenario1(){
            
        //Create users
        Profile sysAdmin = TestUtils.usrProfile('System Administrator');
        List<User> userList = new List<User>();
        User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                      'tests@b0.com', 'test', 'nickName', sysAdmin.Id, 'testUser_adName');
        userList.add(adminUser);    
        User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
                      'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id, 'testUser_adName2');
        userList.add(adminUser2);    
        insert userList;
        
        //Creating brands
        TestUtils.createBrands();
        //Account & Contact
        Account testAccount = TestUtils.createAccount();
        insert testAccount;
        List<Contact> contactList = TestUtils.createContacts(testAccount, 1);
        insert contactList;
    
        User_Group__c userGroup = new User_Group__c(Account__c=testAccount.ID, Group_Id_Assigned__c='1001');
        insert userGroup;        
        
        //Create JobBot
        Automated_Posting__c JobBot = new Automated_Posting__c(Name = 'Test JobBot001');
        JobBot.Change_Threshold__c = 20;
        JobBot.WARN_ON_ZERO__c = false;
        JobBot.User_Group__c = userGroup.ID; 
        JobBot.External_Key__c = 'E#EE#Ee3e';   
        insert JobBot;
        
        //Create JobBot Transaction
        Posting_Transaction__c trans = new Posting_Transaction__c();
        DateTime dt = System.Now();
        DateTime earlier = dt.addMinutes(-60), fullHour = dt.addMinutes(- dt.minute()).addSeconds(- dt.second()); 
        trans.Date_Time__c = earlier;
        trans.Automated_Posting__c = JobBot.Id;
        trans.Jobs_failed_to_be_processed__c = 0;
        trans.Jobs_successfully_processed__c = 100;
        trans.Total_Jobs_Submitted__c = 100;
        insert trans;
        
        //jobBot.Latest_Transaction__c = trans.Id;
        //update jobBot;

        //Create JobBot Transaction #2 to update latest transaction
        Posting_Transaction__c trans2 = new Posting_Transaction__c();
        DateTime dt2 = System.Now();
        DateTime later = dt2.addMinutes(60), fullHour2 = dt2.addMinutes(- dt2.minute()).addSeconds(- dt2.second());
        trans2.Date_Time__c = later;
        trans2.Automated_Posting__c = JobBot.Id;
        trans2.Jobs_failed_to_be_processed__c = 0;
        trans2.Jobs_successfully_processed__c = 100;
        trans2.Total_Jobs_Submitted__c = 100;
        insert trans2;
    }
}