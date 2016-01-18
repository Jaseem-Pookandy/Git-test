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
  
 /***
*Class          ---- BatchUpdzClineItemforAccBrand_TEST
*Author         ---- Jaseem Pookandy
*Story          ---- CCBOB-194
*Created Date   ---- 2015.12.15
*Description    ---- Test class for BatchUpdzClineItemforAccBrand that updates all zContract Line Item with account brand
----------------------------- Modifications & Updates -----------------------------
***/
@isTest
private class BatchUpdzClineItemforAccBrand_TEST {
     
     //Method that creates the test data for all the test methods
	@testSetup static void testdatasetup(){
		 Account acc = Testutils.createAccount();
         Brand__c dicebrand = new Brand__c();
        dicebrand.name = 'Dice';
        dicebrand.External_Id__c = 'Dice';
        insert dicebrand;
        insert acc;
        
         zqu__ZProduct__c zP = new zqu__ZProduct__c();
        zP.name = 'Recruitment Pkg 1&5';
        zP.zqu__ZuoraId__c = 'test';
        zP.zqu__SKU__c = 'SKU-00000047_13fef912efe';
        insert zP;
        
        
        zqu__ProductRatePlan__c zPRP  = new zqu__ProductRatePlan__c();
        zPRP.name = 'Testrateplan';
        zPRP.zqu__ZProduct__c = zP.id;
        zPRP.brand__c  = 'Dice';
        zPRP.zqu__ZuoraId__c = 'testz';
        insert zPRP;
        
        Zuora__Subscription__c zsub = new Zuora__Subscription__c();
        zsub.name = 'Testsub';
        zsub.Zuora__Account__c = acc.id;
        insert zsub;
        
        Zuora__SubscriptionProductCharge__c zlineitem = new Zuora__SubscriptionProductCharge__c();
        zlineitem.name = 'testzlineitem';
        zlineitem.Product_Rate_Plan__c = zPRP.id;
        zlineitem.Zuora__RatePlanName__c = zPRP.name;
        zlineitem.Zuora__ProductName__c = zP.name;
        zlineitem.Zuora__Account__c = acc.id;
        zlineitem.Zuora__Subscription__c = zsub.id;
        insert zlineitem;
	}
     static testMethod void testupdzClineitemforAccBrand() {        
        
        Zuora__SubscriptionProductCharge__c zlineitem = [select id, account_brand__c,lastmodifieddate from Zuora__SubscriptionProductCharge__c ];
        system.assert(zlineitem.account_brand__C!=null); //insert itself will populate the account brand as the logic is in the trigger handler
        
        Pagereference Ref = Page.UpdsObjforAccBrand;
        Test.setcurrentpage(Ref);
        UpdsObjforAccBrandController controller = new UpdsObjforAccBrandController();
        controller.totalzlineitembatchsize= '5';
        controller.countzlineitem(); // execute the controller method that counts the scope
        Test.starttest();
        controller.runbatchupdforzlineitem(); // execute the controller method that calls the batch
        Test.stoptest();
        Account_Brand__c AB = [select id from ACcount_Brand__c];
        zlineitem = [select id,lastmodifieddate, account_brand__c from Zuora__SubscriptionProductCharge__c where id =:zlineitem.id];
        
        system.assertequals(AB.id,zlineitem.account_brand__C);
        
     }
}