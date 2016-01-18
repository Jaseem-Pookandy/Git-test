@isTest
private class ScheduleProcessDeleteJunkCasesBatch_Test {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        test.startTest();
        
        ScheduleProcessDeleteJunkCases saf = new ScheduleProcessDeleteJunkCases();
        
                // Schedule the test job
        String CRON_EXP = '0 0 0 * * ?';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new ScheduleProcessDeleteJunkCases());
        
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
        //System.AssertEquals(database.countquery('SELECT COUNT() FROM Case LIMIT 10'), database.countquery('SELECT COUNT() FROM Case LIMIT 10'));
        
        
        
    }
}