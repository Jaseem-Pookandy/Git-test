@isTest
private class ChangeActivityDatesController_Test {

	static testMethod void testSpecificDate() {

		CreateData();

		ApexPages.Standardcontroller sc;

		User u = [SELECT Id, Name FROM User WHERE LastName = 'lastName1' LIMIT 1];
	
		List<Task> tasksToUpdate = [SELECT Id FROM Task WHERE OwnerId = :u.Id];

		String s = '';

		for (Task t : tasksToUpdate) {
			if (s.length() > 1) s+= ',';
			s += t.Id;
		}

		test.startTest();
		System.runAs(u) {

			PageReference pageRef = Page.ChangeActivityDates;
			pageRef.getParameters().put('Ids', s);
			pageRef.getParameters().put('retURL', '%2Fhome%2Fhome.jsp');
			
			Test.setCurrentPage(pageRef);
						
			ChangeActivityDatesController controller = new ChangeActivityDatesController(sc);		

			controller.variableDateMethod = false;
			controller.specificDateMethod = true;

			controller.setVariableValue('6');
			controller.dummyTask = new Task();
			controller.dummyTask.ActivityDate = System.today().addDays(10);
			String varVal = controller.getVariableValue();

			System.assertEquals(varVal, '6');

			PageReference pg = controller.Cancel();
			pg = controller.Save();
			pg = controller.PrepPage();

			List<SelectOption> result = controller.getVariableOptions();
			List<ChangeActivityDatesController.WrapperForTask> wftList = controller.getTasks();
			controller.dummyTask.ActivityDate = System.today().addDays(5);
			controller.specificDateChanged();

			test.stopTest();
		}
	}

	static testMethod void testVariableDate() {

		CreateData();

		ApexPages.Standardcontroller sc;

		User u = [SELECT Id, Name FROM User WHERE LastName = 'lastName1' LIMIT 1];
	
		List<Task> tasksToUpdate = [SELECT Id FROM Task WHERE OwnerId = :u.Id];

		String s = '';

		for (Task t : tasksToUpdate) {
			if (s.length() > 1) s+= ',';
			s += t.Id;
		}

		test.startTest();
		System.runAs(u) {

			PageReference pageRef = Page.ChangeActivityDates;
			pageRef.getParameters().put('Ids', s);
			pageRef.getParameters().put('retURL', '%2Fhome%2Fhome.jsp');
			
			Test.setCurrentPage(pageRef);
						
			ChangeActivityDatesController controller = new ChangeActivityDatesController(sc);				

			List<SelectOption> result = controller.getVariableOptions();
			List<ChangeActivityDatesController.WrapperForTask> wftList = controller.getTasks();

			controller.variableDateMethod = true;

			controller.setVariableValue('6');
			controller.variableDateChanged();
			
			for (ChangeActivityDatesController.WrapperForTask wt : wftList) {
				String val = wt.PrettyNewDueDate;
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
                
        Task t = new Task();
	    t.WhatId = account.Id;
        t.Subject = 'Call';
        t.Type__c = 'Call Inbound';
        t.Brand__c = 'Dice';
        t.Due_Date__c = System.today();
        t.ActivityDate = System.today();
        t.OwnerId = userList[0].Id;
        insert t;

        t = new Task();
	    t.WhatId = account.Id;
        t.Subject = 'Call';
        t.Type__c = 'Call Inbound';
        t.Brand__c = 'Dice';
        t.Due_Date__c = System.today().addDays(2);
        t.ActivityDate = System.today().addDays(2);
        t.OwnerId = userList[0].Id;
        insert t;
	}
}