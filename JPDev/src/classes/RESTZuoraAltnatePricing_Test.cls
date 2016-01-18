@isTest(SeeAllData=true)
private class RESTZuoraAltnatePricing_Test {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        //test.startTest();
        CreateData();
        //test.stopTest();    
        System.AssertEquals(1, 1);
    }  
  static void CreateData() {
         test.startTest(); 
       RESTZuoraAltnatePricing.ReturnClass altnatePricingResult; 
       Map<String, String> requestParameterMap = new Map<String, String>();
       
 
       //Mimick Client Call as a Restful API      
       RestRequest req = new RestRequest(); 
       RestResponse res = new RestResponse();
       req.requestURI = 'https://dice--full.cs9.my.salesforce.com/services/apexrest/ZuoraAltnatePricing?NumberOfJobs=1&NumberOfMonths=3';  
       req.httpMethod = 'GET';
       RestContext.request = req;
       RestContext.response = res;
       altnatePricingResult = RESTZuoraAltnatePricing.doGet();
       
       //NullProduct Id
       requestParameterMap.put('NumberOfJobs', '2');
       requestParameterMap.put('NumberOfMonths', '3');
       altnatePricingResult = RESTZuoraAltnatePricing.ZuoraAltnatePricingHandler(requestParameterMap);
       
       //Invalid Product Id
       requestParameterMap.put('RatePlanChargeId', 'invalidrateplanid');
       requestParameterMap.put('NumberOfJobs', '2');
       requestParameterMap.put('NumberOfMonths', '3');
       altnatePricingResult = RESTZuoraAltnatePricing.ZuoraAltnatePricingHandler(requestParameterMap);
       
       //Actual Product Id
       requestParameterMap.put('RatePlanChargeId', '8a80815d4c5d4f0a014da0075d121fb6');
       requestParameterMap.put('NumberOfJobs', '2');
       requestParameterMap.put('NumberOfMonths', '3');
       altnatePricingResult = RESTZuoraAltnatePricing.ZuoraAltnatePricingHandler(requestParameterMap);
       
       //Exception invalid integer for number of jobs
       requestParameterMap.put('RatePlanChargeId', '8a80815c4c5d4f23014dba60942f28e6');
       requestParameterMap.put('NumberOfJobs', 'z');
       requestParameterMap.put('NumberOfMonths', '3');
       altnatePricingResult = RESTZuoraAltnatePricing.ZuoraAltnatePricingHandler(requestParameterMap);     
           
       //Exception invalid integer for number of months
       requestParameterMap.put('RatePlanChargeId', '8a80815c4c5d4f23014dba60942f28e6');
       requestParameterMap.put('NumberOfJobs', '2');
       requestParameterMap.put('NumberOfMonths', 'e');
       altnatePricingResult = RESTZuoraAltnatePricing.ZuoraAltnatePricingHandler(requestParameterMap);         
       
       //Exception Null Price 
       requestParameterMap.put('RatePlanChargeId', '8a80815c4c5d4f23014d7bae2d2b1618');
       requestParameterMap.put('NumberOfJobs', '2');
       requestParameterMap.put('NumberOfMonths', '3');
       altnatePricingResult = RESTZuoraAltnatePricing.ZuoraAltnatePricingHandler(requestParameterMap); 
  }
}