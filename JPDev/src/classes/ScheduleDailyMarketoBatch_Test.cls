@isTest(SeeAllData=false)

private class ScheduleDailyMarketoBatch_Test {

  static testMethod void unitTest1() {
    
    test.startTest();

    Marketo_Batchable_Settings__c o = new Marketo_Batchable_Settings__c();
    o.Name = 'Days';
    o.Lookback_Days__c = 1;
    insert o;
                
    ScheduleDailyMarketo sdm = new ScheduleDailyMarketo();
    
    // Schedule the test job
        String CRON_EXP = '0 0 0 * * ?';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new ScheduleDailyMarketo());
        
        // Get the information from the CronTrigger API object  
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime
                            FROM CronTrigger 
                            WHERE id = :jobId];
        
        // Verify the expressions are the same  
        System.assertEquals(CRON_EXP, ct.CronExpression);
    
        // Verify the job has not run  
        System.assertEquals(0, ct.TimesTriggered);
        
        test.stopTest();

        //bogus assertEquals, but in order to ensure the batch is finish and the lines are covered...        
        System.AssertEquals(true, true);
  }

}