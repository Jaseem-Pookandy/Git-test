/*******************************************************************
// (c) 2013 Appirio, Inc.
// Name          : MassUpdateCampMemberController_Test
// Description   : Class that tests the functionality of 
//                 MassUpdateCampMemberController.
//
// Apr 12th, 2013    Naersh Ojha(Appirio Off)
********************************************************************/
@isTest
private class MassUpdateCampMemberController_Test {

    static testMethod void allScenario_Test() {
	      Profile sysAdmin = TestUtils.usrProfile('System Administrator');
	      List<User> userList = new List<User>();

	      User defaultOwner = TestUtils.createUser('lname','firstName', 'email@c.com',
	                        'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
	      userList.add(defaultOwner);
	      
	      User newOwner = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
	                        'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id,'testUser_adName2');
	      userList.add(newOwner);
	
	      insert userList;
				
        //Creating brands
        TestUtils.createBrands();
        //Account
        Account testAccount = TestUtils.createAccount();
        insert testAccount;
        //Contact
        List<Contact> contactList = TestUtils.createContacts(testAccount, 15);
        insert contactList;
        Campaign testCampaign;
        
        //Total creating 15 campaignMember records with default owner.
        System.runAs(defaultOwner) {
	        //Campaign
	        testCampaign = new Campaign(Name = 'Test Campaign 001');
	        testCampaign.IsActive = true;
	        testCampaign.isCall_List__c = true;
	        testCampaign.Brand__c = 'Dice';
	        insert testCampaign;
	
	        //Campaign Members
	        List<CampaignMember> cmList = new List<CampaignMember>();
	        CampaignMember cm;
	        for (Contact contact : contactList) {
		        cm = new CampaignMember();
		        cm.CampaignId = testCampaign.ID;
		        cm.ContactId = contact.ID;
		        cmList.add(cm);
	        }
	        insert cmList;
        }
        
        //Testign pages
        PageReference pageRef = Page.MassUpdateCampaignMemberOwner;
        Test.setCurrentPageReference(pageRef);
        ApexPages.currentPage().getParameters().put('campaignId', testCampaign.ID);
        
        
        MassUpdateCampMemberController controller = new MassUpdateCampMemberController();
        
        //On single page 10 records are being shown and total 15 records inserted.
        System.assertEquals(controller.CampaignMemberList.size(), 10);
        System.assertEquals([SELECT ID FROM CampaignMember WHERE CampaignID =: testCampaign.ID].size(), 15);
        
        controller.next();
        controller.previous();
        
        //Setting page size to 20
        controller.pageSize = 20;
        controller.checkPageSize();
        System.assertEquals(controller.CampaignMemberList.size(), 15);
        
        //Selecting 5 records to change owner.
        controller.CampaignMemberList.get(0).selected = true;
        controller.CampaignMemberList.get(1).selected = true;
        controller.CampaignMemberList.get(2).selected = true;
        controller.CampaignMemberList.get(3).selected = true;
        controller.CampaignMemberList.get(4).selected = true;
        
        //New owner.
        controller.camp.Owner_Assigned__c = newOwner.ID;
        controller.processSelected();
        controller.save();
        
        //After Updated new owner 5 records.        
        controller.searchByOwner();
        System.assertEquals(controller.CampaignMemberList.size(), 5);
        
        controller.sortField = 'Campaign.Name';
        controller.sortData();
        controller.sortData();
        controller.cancel();

        pageRef = controller.reset();
    }
}