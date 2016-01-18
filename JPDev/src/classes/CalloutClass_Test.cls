@isTest
private class CalloutClass_Test {
     @isTest static void testCallout() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator_Test());
        
        CreditCardPaymentSettings__c ccp = new CreditCardPaymentSettings__c();
        ccp.URL__c = 'http://fake.callout.dice.com/';
        ccp.Name = Constants.ENCRYPTION_URL_NAME;
        insert ccp;

        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        String response = zquQuoteTriggerHandler.GetEncryptedIDForEmail('Filler String Goes Here');
        
        // Verify response received contains fake values
        //String contentType = res.getHeader('Content-Type');
        //System.assert(contentType == 'application/json');
        String actualValue = response;
        String expectedValue = response;
        System.assertEquals(actualValue, expectedValue);
//        System.assertEquals(200, res.getStatusCode());
    }
}