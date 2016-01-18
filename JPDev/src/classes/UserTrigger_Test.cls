/*******************************************************************************
Name        : UserTrigger_Test
Description : Test Class for UserTriggerHandler.
Author      : Naresh Kr. Ojha (Appirio Offshore)
Date        : Jan 16th, 2013
*******************************************************************************/
@isTest
private class UserTrigger_Test {
	  
	static List<User> userList = new List<User>();
	static Profile sysAdmin;
	
	public static testMethod void myUnitTest() {
		//Creating test data for test.
		createTestData();
		
		//Creating users
		insert userList;
		
		//Query all inserted users
		List<User> newUsers = [SELECT FederationIdentifier, ProfileId, Email, UserName, AD_Username__c
								    FROM User WHERE id in :userList];
		
		//Verify that FederationIdentifier is same as AD_Username__c.					        		
		System.assertEquals( userList.get(0).AD_Username__c, 
		                     newUsers.get(0).FederationIdentifier);
														
	    System.assertEquals( userList.get(1).AD_Username__c, 
		                     newUsers.get(1).FederationIdentifier);
		                     
		//Verify that profile name for user having null in profileID should have limited access profile.					 
	    System.assertEquals(Label.Default_User_Profile_Name, 
	                        [SELECT Name FROM Profile WHERE ID =: newUsers.get(1).ProfileId].Name);
		
		//Update user records as migration user
		System.runAs(newUsers.get(2)) {		
							 
			//Update AD_Username__c, username and email of the users.
			newUsers.get(0).AD_Username__c = 'NewUser_adName1';
			newUsers.get(0).Email = 'new_email@c.com';
			newUsers.get(0).UserName = 'new_tests@b0.com';
      			
			newUsers.get(1).AD_Username__c = 'NewUser_adName2';	
			newUsers.get(1).Email = 'new_email2@c.com';
			newUsers.get(1).UserName = 'new_tests2@b0.com';
			
			update newUsers;
			
			List<User> updatedUsers = [SELECT FederationIdentifier, Email, UserName
								       FROM User WHERE id in :userList];
			
			//Verify that FederationIdentifier is updated as new AD_Username__c.
			System.assertEquals( newUsers.get(0).AD_Username__c, 
								 updatedUsers.get(0).FederationIdentifier);
															
		    System.assertEquals( newUsers.get(1).AD_Username__c, 
								 updatedUsers.get(1).FederationIdentifier); 
								 
			//Verify that Email and Username of Users are not updated to new values
			System.assertNotEquals( newUsers.get(0).Email, 
								    updatedUsers.get(0).Email);
								 
			System.assertNotEquals( newUsers.get(0).UserName, 
								    updatedUsers.get(0).UserName);		
			
			System.assertNotEquals( newUsers.get(1).Email, 
								    updatedUsers.get(1).Email);
								 
			System.assertNotEquals( newUsers.get(1).UserName, 
								    updatedUsers.get(1).UserName);
		}						 				    													
	}
    
    private static void createTestData() {
    		
		//Create Profile
		sysAdmin = TestUtils.usrProfile('System Administrator');
		
	    //Create Users
		User TestUser = TestUtils.createUser('lname','firstName', 'email@c.com',
	                  						 'tests@b0.com', 'test', 'nickName', 
	                  						 sysAdmin.Id, 'testUser_adName1');                     						 
        userList.add(TestUser);
        
        TestUser = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
                      					'tests2@b0.com', 'test2', 'nickName2', 
                      					sysAdmin.Id, 'testUser_adName2');
        TestUser.ProfileId = null;
                     					
        userList.add(TestUser); 
       
        TestUser = TestUtils.createUser('Migration','firstNameMig', 'emailMig@c.com',
                      					'testsMig@b0.com', 'testMig', 'nickNameMig', 
                      					sysAdmin.Id, 'testUser_adNameMig');
        userList.add(TestUser);        

    }
}