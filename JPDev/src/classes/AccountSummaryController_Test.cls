/*******************************************************************
Name  : AccountSummaryController_Test
Author: Byrnes
Date  : 2013.12.18
*************************************************************************/
@isTest(SeeAllData=false)
public with sharing class AccountSummaryController_Test {

	static testMethod void testMethod1() {
		
		CreateData();
		
		test.startTest();
		
		String thisAccountId = [SELECT Id FROM Account WHERE Name = 'Test' and Phone = '9829198291' LIMIT 1].Id;
		
		ApexPages.Standardcontroller sc;
		
		PageReference pageRef = Page.AccountSummary;
		pageRef.getParameters().put('Id', thisAccountId);
		
		Test.setCurrentPage(pageRef);
		
		AccountSummaryController controller = new AccountSummaryController(sc);	
		
		List<Contact> blah = controller.getProductUsers();
		List<Contact_ContactType_WrapperClass> blahblah = controller.getWrappedContacts();
		
		pageRef = controller.ReturnToAccount();
		
		Contact_ContactType_WrapperClass ccw = new Contact_ContactType_WrapperClass(new Contact());
		
		test.stopTest();
	}
	
	static void CreateCustomSettingsRecords() {
		
		List<CreditCardPaymentSettings__c> ccps = new List<CreditCardPaymentSettings__c>();
		
		CreditCardPaymentSettings__c c = new CreditCardPaymentSettings__c();
		c.Name = Constants.BASE_PAYMENT_ADDRESS_URL;
		c.URL__c = 'https://payments.diceholdings.com/index.php?id=';
		ccps.add(c);
		
		CreditCardPaymentSettings__c c2 = new CreditCardPaymentSettings__c();
		c2.Name = Constants.ENCRYPTION_URL_NAME;
		c2.URL__c = 'https://payments.diceholdings.com/services.php?action=encrypt&id=';
		ccps.add(c2);
		
		insert ccps;
		
		List<CreditCardPaymentGateways__c> cpg = new List<CreditCardPaymentGateways__c>();
		CreditCardPaymentGateways__c cg = new CreditCardPaymentGateways__c();
		cg.Approved__c = true;
		cg.Gateway__c = '_Paymentech_Gateway';
		cg.Name = 'Paymentech';
		cpg.add(cg);
		
		CreditCardPaymentGateways__c cg2 = new CreditCardPaymentGateways__c();
		cg2.Approved__c = true;
		cg2.Gateway__c = '_WorldPay_Gateway';
		cg2.Name = 'Worldpay';
		cpg.add(cg2);
		
		insert cpg;
		
	}
	
	static void CreateData() {
		//Creating brands
        TestUtils.createBrands();
        
        CreateCustomSettingsRecords();
        
        //Account
        Account testAccount = TestUtils.createAccount();
        insert testAccount;
        //Contact
        List<Contact> contactList = TestUtils.createContacts(testAccount, 1);
        insert contactList;
        //Fetching account brand for Oppty
        //List<Account_Brand__c> abList = [Select ID FROM Account_Brand__c WHERE Account__c =: testAccount.ID];
        List<Account_Brand__c> abList = createABList(testAccount);
        //Opportunity
        Opportunity testOppty = TestUtils.createOpportunity('Test Opty 001', testAccount);
        testOppty.Contact__c = contactList.get(0).ID;
        testOppty.Account_Brand__c = abList.get(0).ID;
        testOppty.Validation_Rule_Override__c = DateTime.now().addDays(4);
        testOppty.Renewal_Owner_Assigned__c = UserInfo.getUserId();
        testOppty.BrandTag__c = 'Dice';
        testOppty.Primary_Brand__c = 'Dice';
        insert testOppty;
        
        zqu__Quote__c quote = new zqu__Quote__c();
        quote.Name = 'Test Quote';
        quote.zqu__Opportunity__c = testOppty.ID;
        quote.IsSyncing__c = true;
        quote.zqu__BillToContact__c = contactList.get(0).ID;
        quote.zqu__SoldToContact__c = contactList.get(0).ID;
        quote.zqu__PaymentMethod__c = 'Credit Card';
        quote.zqu__PaymentTerm__c = 'Net 30';
        quote.zqu__InitialTerm__c = 3;
        quote.zqu__RenewalTerm__c = 3;
        quote.zqu__Status__c = 'Sent to Z-Billing';
        quote.zqu__ZuoraAccountID__c = '12345678901234567890123456789012';
        quote.BrandTag__c = 'Dice';
        quote.Deferred_Bill_Date__c = Date.today().addDays(30);       //byrnes, 2014.05.13 for CC-2496
        insert quote;
        
        //testOppty.SyncedQuote__c = quote.ID;
        //update testOppty;
        
        zqu__QuoteAmendment__c quoteAmendment = new zqu__QuoteAmendment__c();
        quoteAmendment.zqu__Status__c = 'Draft';
        quoteAmendment.zqu__Quote__c = quote.ID;
        quoteAmendment.zqu__Type__c = 'Renewal';
        quoteAmendment.Name = 'test qt amendment 001';
        insert quoteAmendment;
        
        zqu__QuoteRatePlan__c quoteRP = new zqu__QuoteRatePlan__c();
        quoteRP.zqu__Quote__c = quote.ID;
        quoteRP.Name = 'Test Quote RP 001';
        quoteRP.zqu__QuoteAmendment__c = quoteAmendment.ID;
        quoteRP.zqu__AmendmentType__c = 'NewProduct';
        insert quoteRP;
        
        zqu__ZProduct__c zProduct = new zqu__ZProduct__c(Name = 'DicezProduct');
        zProduct.zqu__ZuoraId__c = 'DICE0001';
        
        zProduct.zqu__Active__c = true;
        zProduct.zqu__SKU__c = 'DICE00001';
        insert zProduct;
        
        zqu__ProductRatePlan__c prp = new zqu__ProductRatePlan__c();
        prp.Name = 'Dice Product Rate Plan';
        prp.zqu__ZuoraId__c = 'PRPTEST001';
        
        prp.Brand__c = Constants.BRAND_DICE;
        prp.zqu__ZProduct__c = zProduct.ID;
        prp.ApprovalType__c = 'Manager';
        insert prp;
        
        zqu__ProductRatePlanCharge__c prpCharge = new zqu__ProductRatePlanCharge__c();
        prpCharge.Name = 'Test PRP 001';
        prpCharge.zqu__ZuoraId__c = 'TESTPRP01';        

        prpCharge.zqu__Type__c = 'Recurring';
        prpCharge.zqu__Model__c = 'RatePlan';
        prpCharge.zqu__ProductRatePlan__c = prp.ID;
        insert prpCharge;
	}
	
	private static List<Account_Brand__c> createABList(Account testAccount) {
  		List<Account_Brand__c> accBrandList = new List<Account_Brand__c>();
  		testAccount = [SELECT Migration_Id__c From Account Where ID = :testAccount.Id];
  		Profile sysAdmin = TestUtils.usrProfile('System Administrator');
      	List<User> userList = new List<User>();      
      	User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                          'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
	    userList.add(adminUser);        
	    User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
	                      'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id,'testUser_adName2');
	    userList.add(adminUser2);
	    User adminUser3 = TestUtils.createUser('lname3','firstName3', 'email3@c.com',
	                      'tests3@b0.com', 'test3', 'nickName3', sysAdmin.Id,'testUser_adName3');
	    userList.add(adminUser3);
	            
	    insert userList;    
          Account_Brand__c abObj = new Account_Brand__c();
          abObj.Brand_Picklist__c = 'Dice';
          abObj.Account__c = testAccount.Id;
          abObj.Primary_Owner__c = userList.get(0).Id;
          abObj.CS__c = userList.get(1).Id;
          abObj.Status__c = 'Active';
          accBrandList.add(abObj);
       insert accBrandList;
    return accBrandList; 
  } 	
}