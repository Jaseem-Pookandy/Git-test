/*******************************************************************
Name  : PersonalSettingsController_Test
Author: Byrnes
Date  : 2014.07.23
*************************************************************************/
@isTest
private class PersonalSettingsController_Test {
	
	static testMethod void testMethod1() {

		ApexPages.Standardcontroller sc;		
		PageReference pageRef = Page.PersonalSettings;
				
		Test.setCurrentPage(pageRef);
					
		PersonalSettingsController controller = new PersonalSettingsController(sc);

		pageRef = controller.PrepPage();

		//the pageref better be null.
		System.assertEquals(null, pageRef);

		pageRef = controller.Save();

		//the pageref better be null.
		System.assertEquals(null, pageRef);

		pageRef = controller.Cancel();

		//the pageref better NOT be null.
		System.assertNotEquals(null, pageRef);
	}
}