/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
public class CCAPI_ProductCatalogServiceTest {

    static testMethod void GetProductCatalog() {
    	
    	string testTag = 'testTag';
        string testSku1 = 'abc123';
        string testSku2 = 'xyz321';
        zqu__ProductRatePlanCharge__c productTree1 = SetupZuoraProducts(testSku1, testTag);
        zqu__ProductRatePlanCharge__c productTree2 = SetupZuoraProducts(testSku2, testTag);
        string ratePlanChargeID1 = productTree1.zqu__ZuoraId__c;
        string ratePlanChargeID2 = productTree2.zqu__ZuoraId__c;
                //Run the test
        Test.startTest();
            	  //do request
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.requestURI = '/ccapi/productcatalog/';  
        req.addParameter('brandTag', testTag);

        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        CCAPI_ProductCatalogService.ProductCatalog testResult = CCAPI_ProductCatalogService.getProductCatalog();
        Test.stopTest();
        
        system.assertEquals(testResult.numberOfItems, 2);
        system.assert(testResult.products.size() == 2);
        system.assert(testResult.products.get(0).ProductSku == testSku1 || testResult.products.get(0).ProductSku == testSku2);
        system.assert(testResult.products.get(0).RatePlanChargeID == ratePlanChargeID1 || testResult.products.get(0).RatePlanChargeID == ratePlanChargeID2);
        
    }
    static zqu__ProductRatePlanCharge__c SetupZuoraProducts(string sku, string brandTag)
    {
        zqu__ZProduct__c testProduct = (zqu__ZProduct__c)TestFactory.createSObject(new zqu__ZProduct__c(zqu__ZuoraId__c = 'p12345678903'+sku, 
                                                                                                     zqu__SKU__c = sku,                                                                                                     
                                                                                                     ProductSubCategory__c = CCAPI_ZuoraProductSkuQuery.WEBSTORE_SUBCATEGORY
                                                                                                    ), true);
        
    	zqu__ProductRatePlan__c testPlan = (zqu__ProductRatePlan__c)TestFactory.createSObject(new zqu__ProductRatePlan__c(zqu__ZuoraId__c = 'prp1234567890'+sku, 
                                                                                                                          zqu__EffectiveStartDate__c = date.today().addDays(-7),
                                                                                                                          zqu__EffectiveEndDate__c = date.today().addDays(7),
                                                                                                                          BrandTag__c = brandTag,
                                                                                                                          zqu__ZProduct__c = testProduct.Id), true);
        
        
    	zqu__ProductRatePlanCharge__c testCharge = (zqu__ProductRatePlanCharge__c)TestFactory.createSObject(new zqu__ProductRatePlanCharge__c(zqu__ZuoraId__c = 'prpc12345678903'+sku,
                                                                                                                                              zqu__ProductRatePlan__c = testPlan.Id
                                                                                                                                             ), true);
        List<zqu__ProductRatePlanCharge__c> selectedCharges = [SELECT zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__ZuoraId__c, 
	            zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__SKU__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c,
	            zCharge.zqu__ProductRatePlan__r.BrandTag__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__ZuoraId__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c,
	            zCharge.zqu__ZuoraId__c
	         FROM zqu__ProductRatePlanCharge__c zCharge
	         WHERE zCharge.zqu__ZuoraId__c = :testCharge.zqu__ZuoraId__c];
	         
        //You better have one, you just made it.
        return selectedCharges.get(0);
        
    }
}