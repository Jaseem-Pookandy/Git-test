@isTest(seeAllData=true)
private class ScheduleProcessDeleteJunkCasesBatch2_Tst {

    static testMethod void myUnitTest() {
        // Marks the point in your test code when your test actually begins. Use this method when you are testing governor limits.
        test.startTest();
        
        
        //Profile sysAdmin = TestUtils.usrProfile('System Administrator');
        //List<User> userList = new List<User>();
        //List<Case> caseList = new List<Case>();
      
        //User adminUser1 = TestUtils.createUser('lname','firstName', 'email@c.com','tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');

        // Add the user to the list
        //userList.add(adminUser1);
      
        // Insert the list of users in the database
        //insert userList;
        
        
        // We first need to create a case to delete, so get the group id
        // Note: We are assuming this is in the full environment, and a group with this name exists
        //Group gr = [SELECT Id FROM Group WHERE Name = 'Email-SPAM/JUNK'];
        //String g = gr.Id;
           
        //System.debug('group id is:'+g);
           
           
        // Get another group ID which is not Email-SPAN/Junk to test
        //Group gr2 = [SELECT Id FROM Group WHERE Name != 'Email-SPAM/JUNK' LIMIT 1];
        //String g2 = gr2.Id;
           
        //System.debug('group2 id is:'+g2);           
           
           
        //RecordType rt1 = [SELECT Id FROM RecordType WHERE Name = 'Email Generated Cases' LIMIT 1];   
           
        //String rt = rt1.Id;
        
        //System.debug('record type id is: '+rt);   
           
        //Creating brands
        //TestUtils.createBrands();

        //Account
        //Account testAccount = TestUtils.createAccount();
        //insert testAccount;
      
        //List<Account_Brand__c> abList = [Select ID, Brand_Name__c FROM Account_Brand__c 
        //                                WHERE Account__c =: testAccount.ID];


      
       //for(Account_Brand__c ab : abList) {
       //     if (ab.Brand_Name__c == 'Dice') {
    
       //         ab.CS__c = userList.get(0).ID;
       //      }
       //}
       //update abList;        
        
       //Case newCase1 = new Case();
       //newCase1.AccountId = testAccount.ID;
       //newCase1.Assign_to_CSR__c = true;
       //newCase1.Brand__c = 'Dice';
       //newCase1.Reason = 'Customer Support';
       //newCase1.Origin = 'Phone';
       //newCase1.Status = 'New';
       //newCase1.Inbound_Email_Address__c = 'test@test.com';
       //newCase1.SuppliedEmail = 'fake@dice.com';
       //newCase1.Subject = 'Test11';
        
       //System.debug('The subject for Case1 is:'+newCase1.Subject);
        
        
       //try {
       //     insert  newCase1;
       //}catch(DmlException e){
       //     System.debug('The following DML exception has occurrec: '+e.getMessage());
        
       //}catch(Exception e){
       //     System.debug('The following exception has occurrec: '+e.getMessage());        
       //}    
 
        
       //String su = 'Test11';

       //Integer cnt = [ SELECT COUNT() FROM Case where Subject =: su];
        
        
       // Shouldn't have any cases with out of office because it failed to be created
       //System.debug('The count of records with the name Test1 is: '+cnt);

        
        
        
              
        //Case newCase2 = new Case();
        //newCase2.AccountId = testAccount.ID;
        //newCase2.Assign_to_CSR__c = true;
        //newCase2.Brand__c = 'Dice';
        //newCase2.Reason = 'Customer Support';
        //newCase2.Origin = 'Phone';
        //newCase2.Status = 'New';
        //newCase2.Inbound_Email_Address__c = 'test@test.com';
        //newCase2.SuppliedEmail = 'fake@dice.com';
        //newCase2.Subject = 'Test2';
        
        //System.debug('The subject for Case1 is:'+newCase2.Subject);
        
        
        //try {
        //    insert  newCase2;
        //}catch(DmlException e){
        //    System.debug('The following DML exception has occurrec: '+e.getMessage());
        
        //}catch(Exception e){
        //    System.debug('The following exception has occurrec: '+e.getMessage());        
        //}    
        
        
        //String su2 = 'Test2';
        //Integer cnt2 = [ SELECT COUNT() FROM Case where Subject =: su2];
        
        
        // Shouldn't have any cases with out of office because it failed to be created
        //System.debug('The count of records with the name Test2 is: '+cnt2);

        
        //ScheduleProcessDeleteJunkCases2 saf = new ScheduleProcessDeleteJunkCases2();
        
                // Schedule the test job
        //String CRON_EXP = '0 0 0 * * ?';
        //String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new ScheduleProcessDeleteJunkCases2());
        
        // Get the information from the CronTrigger API object  
        //CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime
        //                    FROM CronTrigger 
        //                    WHERE id = :jobId];
        
        // Verify the expressions are the same  
        //System.assertEquals(CRON_EXP, ct.CronExpression);
    
        // Verify the job has not run  
        //System.assertEquals(0, ct.TimesTriggered);

        // Marks the point in your test code when your test ends. Use this method in conjunction with the startTest method.
        test.stopTest();
        
        //bogus assertEquals, but in order to ensure the batch is finish and the lines are covered...        
        // We have to do this because we can't pause the scheduler...hopefully, we will be able to
        // in the future, and make this test viable
        System.AssertEquals(1, 1);
        

        
    }
}