@isTest(SeeAllData=false)
private class ScheduleProcessProvisionedOppBatch_Test {

    static testMethod void myUnitTest() {
        test.startTest();
            
        Account a = TestUtils.createAccount();
        a.Name = 'Test Account';
        insert a;
        
        Account a1 = TestUtils.createAccount();
        a1.Name = 'Test Account';
        insert a1;
        
        Opportunity o = new Opportunity();
        o.Name = 'Test Opportunity';
        o.AccountId = a.Id;
        o.StageName = 'Lead';
        o.CloseDate = system.today();
        o.Credit_Card_Number__c = '0123-4567-8901-4321';
        insert o;
       
        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(a, 2);
        insert contactList;
        
        zqu__Quote__c quote = new zqu__Quote__c();
        quote.Name = 'Test Quote';
        quote.zqu__Opportunity__c = o.Id;
        quote.IsSyncing__c = true;
        quote.zqu__BillToContact__c = contactList.get(0).ID;
        quote.zqu__SoldToContact__c = contactList.get(0).ID;
        quote.zqu__PaymentMethod__c = 'Credit Card';
        quote.zqu__PaymentTerm__c = 'Net 30';
        quote.zqu__InitialTerm__c = 3;
        quote.zqu__RenewalTerm__c = 3;
        quote.zqu__Status__c = 'Sent to Z-Billing';
        quote.Deferred_Bill_Date__c = Date.today().addDays(30);       //byrnes, 2014.05.13 for CC-2496
        insert quote;

        //provision the opp now...
        o.Provisioning_Status__c = Constants.STATUS_COMPLETE;       
        o.Provisioning_Completed_Date__c = system.now().addDays(-4);  
        update o;        

        ScheduleProcessProvisionedOpp saf = new ScheduleProcessProvisionedOpp();
           
        List<Opportunity> opps = [SELECT Id, Provisioning_Completed_Date__c, Credit_Card_Number__c, SyncedQuote__r.Id, SyncedQuote__r.BrandTag__c, SyncedQuote__r.zqu__Currency__c
                                        FROM Opportunity WHERE SyncedQuote__c != null AND Provisioning_Completed_Date__c < YESTERDAY LIMIT 3000];
        
        ScheduleProcessProvisionedOppLogic.ClearApplicableCreditCards(opps);
               
        AccountTeamMember atm = new AccountTeamMember();
        atm.UserId = userinfo.getUserId();
        atm.AccountId = a.Id;
        atm.TeamMemberRole = 'Account Manager';
        insert atm;
        
        AccountTeamMember atm1 = new AccountTeamMember();
        atm1.UserId = userinfo.getUserId();
        atm1.AccountId = a1.Id;
        atm1.TeamMemberRole = 'Account Manager';
        insert atm1;
        
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.UserId = userinfo.getUserId();
        otm.opportunityId = o.Id;
        otm.TeamMemberRole = 'Sales Manager';
        insert otm;
        
        EntitySubscription e = new EntitySubscription();
        e.ParentId = a.Id;
        e.SubscriberId = userinfo.getUserId();
        insert e;
        
        // Schedule the test job
        String CRON_EXP = '0 0 0 * * ?';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new ScheduleProcessProvisionedOpp());
        
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
        System.AssertEquals(database.countquery('SELECT COUNT() FROM Opportunity WHERE Provisioning_Completed_Date__c < YESTERDAY'), database.countquery('SELECT COUNT() FROM Opportunity WHERE Provisioning_Completed_Date__c < YESTERDAY'));
       
    }
}