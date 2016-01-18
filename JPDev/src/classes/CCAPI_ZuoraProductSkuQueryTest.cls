@isTest(SeeAllData=true)
public class CCAPI_ZuoraProductSkuQueryTest {

    static testMethod void testMethodNoSkuFoundNullProductReturned() {
        //Run the test
        Test.startTest();
    	CCAPI_ZuoraProductSkuQuery.ZuoraProduct product = CCAPI_ZuoraProductSkuQuery.GetEFCWebstoreZuoraProduct('abc123', 'eFC-EMEA');
        Test.stopTest();
        
        system.assert(product == null);
    }
    
    static testMethod void testMethodMultipleRatePlansFound() {
        string testTag = 'efc-TestTag';
        string testSku = 'xyz666';
        boolean exceptionThrown = false;
        SetupInValidZuoraProducts(testSku, testTag);
        Test.startTest();
        try
        {
    		CCAPI_ZuoraProductSkuQuery.ZuoraProduct product = CCAPI_ZuoraProductSkuQuery.GetEFCWebstoreZuoraProduct(testSku, testTag);
        }
        catch(QueryException qe)
        {
            exceptionThrown = true;
        }
        Test.stopTest();
        system.assert(exceptionThrown == true);
    }
    static  testMethod void testFindValidSku_ProductReturned(){
    	//Setup test data
        string testSku = 'skuForTest123';
        string testTag = 'testTag';
        zqu__ProductRatePlanCharge__c testSetupRatePlanCharge = SetupValidZuoraProducts(testSku, testTag);
        
        //Run the test
        Test.startTest();
        CCAPI_ZuoraProductSkuQuery.ZuoraProduct testResult = CCAPI_ZuoraProductSkuQuery.GetEFCWebstoreZuoraProduct(testSku, testTag);
        Test.stopTest();
        
        //make assertions
                //Test all available product properties
        system.assertEquals(testSku, testResult.sku);
        system.assertEquals(testSetupRatePlanCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__ZuoraId__c, testResult.productID);
        system.assertEquals(testSetupRatePlanCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c, testResult.productSubCategory);
        //Test all available rate plan properties
        
        system.assertEquals(testSetupRatePlanCharge.zqu__ProductRatePlan__r.zqu__ZuoraId__c, testResult.productRatePlanID);
        system.assertEquals(testSetupRatePlanCharge.zqu__ProductRatePlan__r.BrandTag__c, testResult.brandTag);
        system.assertEquals(testSetupRatePlanCharge.zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c, testResult.effectiveStartDate);
        system.assertEquals(testSetupRatePlanCharge.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c, testResult.effectiveEndDate);
        
        //Test all available rate plan charge properties
        system.assertEquals(testSetupRatePlanCharge.zqu__ZuoraId__c, testResult.productRatePlanChargeID);
        
    }
    
    static zqu__ProductRatePlanCharge__c SetupValidZuoraProducts(string sku, string brandTag)
    {
        zqu__ZProduct__c testProduct = (zqu__ZProduct__c)TestFactory.createSObject(new zqu__ZProduct__c(zqu__ZuoraId__c = 'p12345678903', 
                                                                                                     zqu__SKU__c = sku,                                                                                                     
                                                                                                     ProductSubCategory__c = CCAPI_ZuoraProductSkuQuery.WEBSTORE_SUBCATEGORY
                                                                                                    ), true);
        
    	zqu__ProductRatePlan__c testPlan = (zqu__ProductRatePlan__c)TestFactory.createSObject(new zqu__ProductRatePlan__c(zqu__ZuoraId__c = 'prp1234567890', 
                                                                                                                          zqu__EffectiveStartDate__c = date.today().addDays(-7),
                                                                                                                          zqu__EffectiveEndDate__c = date.today().addDays(7),
                                                                                                                          BrandTag__c = brandTag,
                                                                                                                          zqu__ZProduct__c = testProduct.Id), true);
        
        
    	zqu__ProductRatePlanCharge__c testCharge = (zqu__ProductRatePlanCharge__c)TestFactory.createSObject(new zqu__ProductRatePlanCharge__c(zqu__ZuoraId__c = 'prpc12345678903',
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
   
    
    static void SetupInValidZuoraProducts(string sku, string brandTag)
    {
        zqu__ZProduct__c testProduct = (zqu__ZProduct__c)TestFactory.createSObject(new zqu__ZProduct__c(zqu__ZuoraId__c = 'invP12345678903', 
                                                                                                     zqu__SKU__c = sku,                                                                                                     
                                                                                                     ProductSubCategory__c = CCAPI_ZuoraProductSkuQuery.WEBSTORE_SUBCATEGORY
                                                                                                    ), true);
        
    	zqu__ProductRatePlan__c testPlan = (zqu__ProductRatePlan__c)TestFactory.createSObject(new zqu__ProductRatePlan__c(zqu__ZuoraId__c = 'invPrp1234567890', 
                                                                                                                          zqu__EffectiveStartDate__c = date.today().addDays(-7),
                                                                                                                          zqu__EffectiveEndDate__c = date.today().addDays(7),
                                                                                                                          BrandTag__c = brandTag,
                                                                                                                          zqu__ZProduct__c = testProduct.Id), true);
        
        
    	zqu__ProductRatePlanCharge__c testCharge1 = (zqu__ProductRatePlanCharge__c)TestFactory.createSObject(new zqu__ProductRatePlanCharge__c(zqu__ZuoraId__c = 'invPrpc12345678903',
                                                                                                                                              zqu__ProductRatePlan__c = testPlan.Id
                                                                                                                                             ), true);
        
       zqu__ProductRatePlanCharge__c testCharge2 = (zqu__ProductRatePlanCharge__c)TestFactory.createSObject(new zqu__ProductRatePlanCharge__c(zqu__ZuoraId__c = 'invPrpc03123456789',
                                                                                                                                              zqu__ProductRatePlan__c = testPlan.Id
                                                                                                                                             ), true);
       
        
    }
   
}