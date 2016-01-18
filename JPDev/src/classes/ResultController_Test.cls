@isTest
private class ResultController_Test {
	
	static testMethod void testMethod1() {

		ResultController controller = new ResultController();

		PageReference pageRef = Page.Result;

		pageRef.getParameters().put('code', 'bad_code');

		Test.setCurrentPage(pageRef);

		System.assertNotEquals(controller.messageToUser, null);

		//Passing in not auth token, the urlEncoded should be null
		String urlEncodedAuth = controller.authTokenURLEncoded;
		System.assertEquals(urlEncodedAuth, null);
	}
}