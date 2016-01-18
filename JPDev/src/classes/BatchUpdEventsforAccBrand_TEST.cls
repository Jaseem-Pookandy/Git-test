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
private class BatchUpdEventsforAccBrand_TEST {
	//method that creates the testdata
	@testsetup static void testdatasetup(){
		Account acc = Testutils.createAccount();
		Brand__c dicebrand = new Brand__c();
        dicebrand.name = 'Dice';
        dicebrand.External_Id__c = 'Dice';
        insert dicebrand;
        insert Acc;
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
        User thisuser = [select id from User where id =:UserInfo.getUserId()];
        Event testevent = new Event();
        testevent.ownerid = thisuser.id;
        testevent.whoid = c.id;
        testevent.brand__c = 'Dice';
        testevent.DurationInMinutes = 30;
        testevent.ActivityDate = Date.today();
        testevent.ActivityDateTime = Date.today()+30;
        insert testevent;
        
	}
    static testMethod void testeventupdforaccbrand() {
        Event eventrecord = [select id,account_brand__c from Event];
        system.assert(eventrecord.account_brand__c !=null);
        
        Pagereference Ref = Page.UpdsObjforAccBrand;
        Test.setcurrentpage(Ref);
        UpdsObjforAccBrandController controller = new UpdsObjforAccBrandController();
        controller.totalactivitiesopenbatchsize= '5';
        controller.countopenactivity(); // execute the controller method that counts the scope
        Test.starttest();
        controller.runbatchupdforopenactivities(); // execute the controller method that calls the batch
        Test.stoptest();
        Account_Brand__c AB = [select id from ACcount_Brand__c]; // only one account brand record is there, becuase we have only one brand record test data
        eventrecord = [select id,account_brand__c from Event where id =:eventrecord.id]; // querying the case record to see account brand is populated
        
        system.assert(eventrecord.account_brand__c !=null);// checking the account brand is populated again after running the batch and to make sure the update from the batch is successful
        system.assertequals(AB.id,eventrecord.account_brand__c);
        
    }
}