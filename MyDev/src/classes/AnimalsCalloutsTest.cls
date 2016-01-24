@isTest
public class AnimalsCalloutsTest {
    @isTest static void testGetcallout(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock ();
        mock.setStaticResource('GetAnimalResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Test.setMock(HttpCalloutMock.class,mock);
        
        Httpresponse result = AnimalsCallouts.makeGetCallout();
        
        system.assertNotEquals(null,result,'The callout returned a null response.');
        system.assertEquals(200, result.getStatusCode(),'The status code is not 200.');
        system.assertEquals('application/json;charset=UTF-8', result.getHeader('Content-Type'),'content type');
        Map<String,Object> results = (Map<String,Object>)JSON.deserializeUntyped(result.getBody());
        list<Object> animals = (list<Object>)results.get('animals');
        system.assertequals(3,animals.size(),'array size');
    }
    
    @isTest static void testPOSTcallout(){
        
        Test.setMock(HttpCalloutmock.class, new AnimalsHttpCalloutMock());
        Httpresponse response = AnimalsCallouts.makePostCallout();
        String contenttype = response.getHeader('Content-Type');
        System.assert(contentType == 'application/json');
        String actualvalue = response.getBody();
        String expectedValue = '{"animals": ["majestic badger", "fluffy bunny", "scary bear", "chicken", "mighty moose"]}';
        System.assertEquals(actualValue, expectedValue);

        System.assertEquals(200, response.getStatusCode());

    }
}