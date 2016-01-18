/*******************************************************************
Name  : NewContactController_Test
Author: Byrnes
Date  : 2013.10.08 
*************************************************************************/
@isTest(SeeAllData=true)
private class NewContactController_Test {

	static testMethod void testMethod1() {
		
		ApexPages.Standardcontroller sc;
		//CreateData();
		
		PageReference pageRef = Page.NewContact;
		pageRef.getParameters().put('retURL', '%2Fhome%2Fhome.jsp');
		
		Test.setCurrentPage(pageRef);
					
		NewContactController controller = new NewContactController(sc);
		
		controller.RedirectUser();		
	}
}