@isTest
private class DailyProductivityTriggerHandler_Test {

    static testMethod void Scenario1() {

        //Users
        Profile sysAdmin = TestUtils.usrProfile('System Administrator');
        User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                      'tests@b0.com', 'test', 'nickName', sysAdmin.Id, 'testUser_adName');
        insert adminUser; 
        User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
                      'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id, 'testUser_adName2');
        insert adminUser2;
    
        system.runAs(adminUser) { 
              Test.startTest();
              //Create Daily Log
              Daily_Productivity__c dlog = new Daily_Productivity__c();
              dLog.Dials_Completed__c = 1;
              dLog.I_worked_on_this_date__c = true;
              dLog.Level__c = 'Level 1';
              dLog.Number_of_Demos__c = 2;
              dLog.Total_Dollars_Sold__c = 2000;
              dLog.Total_Talk_Time__c = 200;
              insert dLog;
              
        }
        
                
    }
}