@isTest
private class ChangeOpportunityDatesController_Test {

  static testMethod void testSpecificDate() {

    CreateData();

    ApexPages.Standardcontroller sc;

    User u = [SELECT Id, Name FROM User WHERE LastName = 'lastName1' LIMIT 1];
  
    List<Opportunity> oppsToUpdate = [SELECT Id FROM Opportunity WHERE OwnerId = :u.Id];

    String s = '';

    for (Opportunity t : oppsToUpdate) {
      if (s.length() > 1) s+= ',';
      s += t.Id;
    }

    test.startTest();
    System.runAs(u) {

      PageReference pageRef = Page.ChangeOpportunityDates;
      pageRef.getParameters().put('Ids', s);
      pageRef.getParameters().put('retURL', '%2Fhome%2Fhome.jsp');
      
      Test.setCurrentPage(pageRef);
            
      ChangeOpportunityDatesController controller = new ChangeOpportunityDatesController(sc);    

      controller.specificDateMethod = true;
      controller.setVariableValue('6');
      String varVal = controller.getVariableValue();

      System.assertEquals(varVal, '6');

      PageReference pg = controller.Cancel();
      //pg = controller.Save();
      pg = controller.PrepPage();

      List<SelectOption> result = controller.getVariableOptions();
      List<ChangeOpportunityDatesController.WrapperForOpp> wftList = controller.getOpps();
      controller.dummyOpp.Developer_VF_Date__c = System.today().addDays(5);
      controller.specificDateChanged();
pg = controller.Save();
      test.stopTest();
    }
  }

  static testMethod void testVariableDate() {

    CreateData();

    ApexPages.Standardcontroller sc;

    User u = [SELECT Id, Name FROM User WHERE LastName = 'lastName1' LIMIT 1];
  
    List<Opportunity> OppsToUpdate = [SELECT Id FROM Opportunity WHERE OwnerId = :u.Id];

    String s = '';

    for (Opportunity t : oppsToUpdate) {
      if (s.length() > 1) s+= ',';
      s += t.Id;
    }

    test.startTest();
    System.runAs(u) {

      PageReference pageRef = Page.ChangeActivityDates;
      pageRef.getParameters().put('Ids', s);
      pageRef.getParameters().put('retURL', '%2Fhome%2Fhome.jsp');
      
      Test.setCurrentPage(pageRef);
            
      ChangeOpportunityDatesController controller = new ChangeOpportunityDatesController(sc);        

      List<SelectOption> result = controller.getVariableOptions();
      List<ChangeOpportunityDatesController.WrapperForOpp> wftList = controller.getOpps();

      controller.variableDateMethod = true;

      controller.setVariableValue('2');
      controller.variableDateChanged();
      
      for (ChangeOpportunityDatesController.WrapperForOpp wt : wftList) {
        String val = wt.PrettyNewCloseDate;
      }

      test.stopTest();
    }
  }  

  static void CreateData() {

    Profile prof = TestUtils.usrProfile();
        
        //Trying to use a specific Role to increase coverage of RoleUtils, but getting error
        //UserRole r = [Select id from UserRole where Name = 'Dice Holdings'];

    //Create Users
        List<User> userList = new List<User>();
        User testUser = TestUtils.createUser('lastName1', 'firstName1', 'email1@email.com', 
                                             'testUserName1@uname.com', 'alias1',
                                             'nickName1', prof.ID, 'testAdUsername1');
        //testUser.UserRoleId = r.Id;
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


    //Create Account
        Account account = TestUtils.createAccount();
        account.name = 'TestAccount'+String.valueOf(DateTime.now());
        insert account;
                
        Opportunity t = new Opportunity();
        
      t.AccountId = account.Id;
        t.Description = 'Testing123';
        t.Name = 'Testing123';
        t.StageName = 'Qualified Need';
        t.CloseDate = System.today();
        t.BrandTag__c = 'Dice';
        t.Primary_Brand__c = 'Dice';
        t.OwnerId = userList[0].Id;
        insert t;

      t = new Opportunity();
      
      t.AccountId = account.Id;
        t.Description = 'Testing123';
        t.Name = 'Testing123';
        t.StageName = 'Qualified Need';
        t.CloseDate = System.today().addDays(2);
        t.BrandTag__c = 'Dice';
        t.Primary_Brand__c = 'Dice';
        t.OwnerId = userList[0].Id;
        insert t;

  }
}