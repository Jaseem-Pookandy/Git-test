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
*Class          ---- BatchUpdCustFBforAccBrand_TEST
*Author         ---- Jaseem Pookandy
*Story          ---- CCBOB-193
*Created Date   ---- 2015.12.11
*Description    ---- Test class for BatchUpdCustFBforAccBrand that updates all customer feedback records with account brand
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Pookandy
*Story          ---- CCBOB-193
*Modified Date  ---- 2015.12.15
*Description    ---- Added @testsetup method.
***/
@isTest
private class BatchUpdCustFBforAccBrand_TEST {
	
	@testSetup static void testdatasetup(){
		 Account acc = Testutils.createAccount();
        Brand__c dicebrand = new Brand__c();
        dicebrand.name = 'Dice';
        dicebrand.External_Id__c = 'Dice';
        insert dicebrand;
        insert acc;
        Contact c = new Contact();
        c.AccountId = acc.Id;
        c.FirstName = 'FirstName';
        c.LastName = 'LastName';
        c.MailingCity = 'Test';
        c.MailingState = 'Test State';
        c.MailingPostalCode = '110011';
        c.MailingCountry = 'India';         
        c.Language__c = 'English';
        c.Email = 'no@thanks.dice.com';
        insert c;
        
        Customer_Feedback__c cf = new Customer_Feedback__C();
        cf.primary_brand__c = 'Dice';
        cf.Contact__c = c.id;
        
        insert cf;
	}
    static testMethod void TestupdcfforAccBrand() {
       
        Account_Brand__c ab = [select id from Account_Brand__c];
        Customer_Feedback__c cf = [select account_brand__c from customer_feedback__c];
        system.assertequals(ab.id,cf.account_brand__c);//insert itself will populate the account brand as the logic is in the trigger handler
        
        Pagereference Ref = Page.UpdsObjforAccBrand;
        Test.setcurrentpage(Ref);
        UpdsObjforAccBrandController controller = new UpdsObjforAccBrandController();
        controller.totalcfbatchsize= '5';
        controller.countcustomerfeedback(); // execute the controller method that counts the total scope
        Test.starttest();
        controller.runbatchupdforcustomerfeedback(); //execute the controller method that calls the batch
        Test.stoptest();
        cf = [select account_brand__c from customer_feedback__c where id=:cf.id];
        system.assertequals(ab.id,cf.account_brand__c);
        
    }
}