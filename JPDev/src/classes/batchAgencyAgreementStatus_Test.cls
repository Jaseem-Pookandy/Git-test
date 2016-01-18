@isTest (SeeAllData=false)
Private class batchAgencyAgreementStatus_Test {
  static testMethod void unitTest1() {
	String query = 'SELECT Id,Status__c,Start_Date__c,End_Date__c FROM Agency_Agreement__c';
      
    //Create Some Test Data
    Profile sysAdmin = TestUtils.usrProfile('System Administrator');
    User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                      'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
    insert adminUser;
    //Create Account
    TestUtils.createBrands();
    Account account = TestUtils.createAccount();
    insert account;
    Account_Brand__c accBrand = [SELECT ID, Account__c, Brand__c, Brand_Picklist__c,
                                             Migration_Id__c, At_Risk__c
                                             FROM  Account_Brand__c 
                                             WHERE Account__c = :account.Id LIMIT 1];
      
    //Create Agency Agreement 1 - create one that should be changed to active
    Agency_Agreement__c Agree1 = new Agency_Agreement__c();
    Agree1.Name = 'Test1';
    Agree1.Account__c = account.id;
    Agree1.Account_Brand__c = accBrand.id;
    Agree1.Start_Date__c = system.today().addDays(-30);
    Agree1.End_Date__c = system.today().addDays(30);
    Agree1.Status__c = 'Inactive';  
    //Agree1.Country__c = 'United States';
    Agree1.Discount_Percent__c = 18;
    insert Agree1;
      
    //Create Agency Agreement 2 - create one that should be changed to inactive
    Agency_Agreement__c Agree2 = new Agency_Agreement__c();
    Agree2.Name = 'Test2';
    Agree2.Account__c = account.id;
    Agree2.Account_Brand__c = accBrand.id;
    Agree2.Start_Date__c = system.today().addDays(-45);
    Agree2.End_Date__c = system.today().addDays(-30);
    Agree2.Status__c = 'Active';  
    //Agree2.Country__c = 'United States';
    Agree2.Discount_Percent__c = 18;
    insert Agree2;      
      
    //Create Agency Agreement 3 - create one that should be changed to inactive
    Agency_Agreement__c Agree3 = new Agency_Agreement__c();
    Agree3.Name = 'Test3';
    Agree3.Account__c = account.id;
    Agree3.Account_Brand__c = accBrand.id;
    Agree3.Start_Date__c = system.today().addDays(30);
    Agree3.End_Date__c = system.today().addDays(45);
    Agree3.Status__c = 'Active';  
    //Agree3.Country__c = 'United States';
    Agree3.Discount_Percent__c = 18;
    insert Agree3;       
    
    Test.startTest();
        // Schedule the test job
        String CRON_EXP = '0 0 0 * * ?';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new ScheduleAgencyAgreementStatus());
        
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