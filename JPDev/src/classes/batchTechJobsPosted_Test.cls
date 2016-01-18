@isTest (SeeAllData=false)
Private class batchTechJobsPosted_Test {
  static testMethod void unitTest1() {
  String query = 'SELECT Id,Tech_Jobs_Posted__c,Tech_Jobs_Posted_Updated__c FROM Account WHERE Tech_Jobs_Posted_Updated__c < LAST_90_DAYS';
      
    //Create Some Test Data
    Profile sysAdmin = TestUtils.usrProfile('System Administrator');
    User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                      'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
    insert adminUser;
    //Create Account
    TestUtils.createBrands();
    Account account = TestUtils.createAccount();
    insert account;
    
    Account a = [SELECT Id, Tech_Jobs_Posted__c,Tech_Jobs_Posted_Updated__c FROM Account LIMIT 1];
    a.Tech_Jobs_Posted__c = 10;
    update a;
    a.Tech_Jobs_Posted_Updated__c = date.ValueOf('1971-03-09');
    update a;


    Test.startTest();
        // Schedule the test job
        String CRON_EXP = '0 0 0 * * ?';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new ScheduleTechJobsUpdate());
        
        // Get the information from the CronTrigger API object  
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime
                            FROM CronTrigger 
                            WHERE id = :jobId];
        
        // Verify the expressions are the same  
        System.assertEquals(CRON_EXP, ct.CronExpression);
    
        // Verify the job has not run  
        System.assertEquals(0, ct.TimesTriggered);
        
   test.stopTest();      
  }    
}