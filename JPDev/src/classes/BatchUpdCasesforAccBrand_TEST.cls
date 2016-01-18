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
*Class          ---- BatchUpdCasesforAccBrand_TEST
*Author         ---- Jaseem Pookandy
*Story          ---- CCBOB-192
*Created Date   ---- 2015.12.11
*Description    ---- Test class for BatchUpdCasesforAccBrand that updates all cases with account brand
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Pookandy
*Story          ---- CCBOB-192
*Modified Date  ---- 2015.12.15
*Description    ---- Added @testsetup method, added code to cover error handling.
***/
@isTest
private class BatchUpdCasesforAccBrand_TEST {
	//Method that creates the test data for all the test methods
	@testSetup static void testdatasetup(){
		Map < String, Schema.Recordtypeinfo > recordTypeInfos = Case.SObjectType.getDescribe().getRecordTypeInfosByName();
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
        hot_issue__c ht = new hot_issue__c ();
        ht.name = '#Testhotissue';
		ht.active__c = true;
		insert ht;
        Case caserecord = new Case();
        
        caserecord.recordtypeid = recordTypeInfos.get('Email Generated Cases').getrecordtypeid();
        caserecord.reason = 'provisioning';
        caserecord.contactid = c.id;
        caserecord.brand__c = 'Dice';
        caserecord.origin = 'Email - Candidate';
        caserecord.status = 'New';
        caserecord.hot_issue__c = ht.id; // hot issue record is associated to test the filter criteria and thereby cover the error handling piece
        insert caserecord; // insert case record. This insert itself will populate the account brand as all the necessary fields - brand__c,ontactid - is populated 
        
	}
	//This method tests whether account brand is populated after we run the batch from UI. 
    static testMethod void testupdCaseforAccBrand() {
        
        Case caserecord = [select id,lastmodifieddate,account_brand__c from Case];      
        
        Pagereference Ref = Page.UpdsObjforAccBrand;
        Test.setcurrentpage(Ref);
        UpdsObjforAccBrandController controller = new UpdsObjforAccBrandController();
        controller.totalcasebatchsize= '5';
        controller.countcase(); // execute the controller method that counts the scope
        Test.starttest();
        controller.runbatchupdforcases(); // execute the controller method that calls the batch
        Test.stoptest();
        Account_Brand__c AB = [select id from ACcount_Brand__c]; // only one account brand record is there, becuase we have only one brand record test data
        caserecord = [select id,lastmodifieddate,account_brand__c from Case where id =: caserecord.id]; // querying the case record to see account brand is populated
        
        system.assert(caserecord.account_brand__c!=null);
        system.assertequals(AB.id,caserecord.account_brand__c); //Asserting the account brand populated is the account brand that got inserted while inserting account test data. 
        
       
    }
    //This method tests the error handling logic. Case update will fail because of the filter validation on Case's hot_issue__c lookup. 
    static testMethod void testupdCaseforErrorHandling(){
    	Hot_Issue__c htissue = [select id,active__c from hot_issue__c ];
        htissue.active__c = false; // making active false so that case's hot_issue__c filter validation fails.
        update htissue;
        Pagereference Ref = Page.UpdsObjforAccBrand;
        Test.setcurrentpage(Ref);
        UpdsObjforAccBrandController controller = new UpdsObjforAccBrandController();
        controller.totalcasebatchsize= '5';
        Test.starttest();
        controller.runbatchupdforcases(); // call the batch. Batch will fail to update
        Test.stoptest();
        
        Error__c error = [select id from Error__c limit 1];
        system.assert(error!=null); // asserting that at least one error record is being inserted.
    	
    }
}