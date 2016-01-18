/*    Copyright (c) 2013 Zuora, Inc.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy of 
 *   this software and associated documentation files (the "Software"), to use copy, 
 *   modify, merge, publish the Software and to distribute, and sublicense copies of 
 *   the Software, provided no fee is charged for the Software.  In addition the
 *   rights specified above are conditioned upon the following:
 *
 *   The above copyright notice and this permission notice shall be included in all
 *   copies or substantial portions of the Software.
 *
 *   Zuora, Inc. or any other trademarks of Zuora, Inc.  may not be used to endorse
 *   or promote products derived from this Software without specific prior written
 *   permission from Zuora, Inc.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
 *   ZUORA, INC. BE LIABLE FOR ANY DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES
 *   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *   ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  

 *   IN THE EVENT YOU ARE AN EXISTING ZUORA CUSTOMER, USE OF THIS SOFTWARE IS GOVERNED

 *   BY THIS AGREEMENT AND NOT YOUR MASTER SUBSCRIPTION AGREEMENT WITH ZUORA.
*/

@isTest(SeeAllData=true)
public with sharing class TestGlobalDealTriggerForQuote {
	
	//
	//Account create
	//
	public static Account createAccount()
	{

		Account testAcc = new Account();
		testAcc.Name = 'testAccount';
		testAcc.BillingCity = 'Somewhere';
		testAcc.BillingState = 'CA';
		testAcc.BillingCountry = 'USA';
		testAcc.BillingPostalCode = '12345';
		testAcc.BillingStreet = '123';
	    //testAcc.zd_ID__c = '123';
		insert testAcc;
		return testAcc;
	}

	//
	//contact create
	//
	public static Contact createContact()
	{
		Contact testcon = new Contact();
		testcon.firstname = 'testconfirst';
		testcon.lastname = 'testconlast';
		testcon.Phone = '7777777777';
		testcon.MobilePhone = '6666666666';
		testcon.HomePhone = '5555555555';
		testcon.OtherPhone = '4444444444';
		testcon.OtherStreet = 'Other Street';
		testcon.MailingCountry = 'USA';
		testcon.MailingState = 'CA';
		testcon.email = 'test@test.com';
		testcon.Language__c = 'English';
		return testcon;
	}

	public static Contact createContact2()
	{
		Contact testcon = new Contact();

		testcon.firstname = 'testconfirst';
		testcon.lastname = 'testconlast';
		testcon.Phone = '7777777777';
		testcon.MobilePhone = '6666666666';
		testcon.HomePhone = '5555555555';
		testcon.OtherPhone = '4444444444';
		testcon.OtherStreet = 'Other Street';
		testcon.MailingCountry = 'USA';
		testcon.MailingState = 'CA';
 		testcon.email = 'test@test.com';
		testcon.Language__c = 'English';
		return testcon;
	}

	//
	//create opportunity
	//
	public static Opportunity createOpportunity(Account acc)
	{
		// User testUser = new User();     		

		Opportunity testOpp = new Opportunity();    
         
		//testOpp.Owner = 'test name';

		Date mydate = date.newinstance(2012, 1, 1);

		testOpp.CloseDate = mydate;            

		testOpp.StageName = 'Closed Won';

		testOpp.Type = 'New Business';
             
		testOpp.Name = 'test Opp Name';

		List<Account> acclist = [select id, name from Account where name = :acc.Name];

		testOpp.AccountId = acclist[0].Id;

		insert testOpp;

		return testOpp;
	}
	
	public static Opportunity createOpportunity2(Account acc)
	{
		// User testUser = new User();     		

		Opportunity testOpp2 = new Opportunity();    
         
		//testOpp.Owner = 'test name';

		Date mydate2 = date.newinstance(2012, 1, 1);

		testOpp2.CloseDate = mydate2;            

		testOpp2.StageName = 'Closed Won';

		testOpp2.Type = 'New Business';
             
		testOpp2.Name = 'test Opp Amendment';

		List<Account> acclist = [select id, name from Account where name = :acc.Name];

		testOpp2.AccountId = acclist[0].Id;

		insert testOpp2;

		return testOpp2;
	}

	//
	//create quote
	//
	public static zqu__Quote__c createQuote(Contact con, Opportunity opp)
	{
		zqu__Quote__c testQuote = new zqu__Quote__c();

		testQuote.name = 'testquote';

		testQuote.zqu__Opportunity__c = opp.Id;

		testQuote.zqu__BillToContact__c = con.Id;

		Contact soldTo = createContact();
		
		insert soldTo;

		testQuote.zqu__SoldToContact__c = soldTo.Id;

		testQuote.zqu__PaymentMethod__c = 'Check';

		testQuote.zqu__PaymentTerm__c = 'Due Upon Receipt';

		testQuote.zqu__InitialTerm__c = 12;

		testQuote.zqu__RenewalTerm__c = 12;

		testQuote.zqu__Service_Activation_Date__c = date.newinstance(2012, 1, 1);

		testQuote.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);

		testQuote.zqu__AutoRenew__c = false;

		testQuote.zqu__StartDate__c = date.newinstance(2012, 1, 1);

		testQuote.zqu__ValidUntil__c = date.newinstance(2012, 1, 1);

		testQuote.zqu__Currency__c = 'USD';

		testQuote.zqu__SubscriptionType__c = 'New Subscription';

		testQuote.zqu__RecordReadOnly__c = false;

		testQuote.zqu__Status__c = 'New';
		
		testQuote.zqu__StartDate__c = date.newinstance(2012, 1, 1);

		testQuote.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);

		testQuote.zqu__SubscriptionTermEndDate__c = date.newinstance(2013, 1, 1);
             
		testQuote.BrandTag__c = 'ClearanceJobs';
		
		testQuote.Global_Deal__c = false;

		insert testQuote;

		return testQuote;
	}
       
    // create a quote
       
	public static zqu__Quote__c createQuote2(Contact con, Opportunity opp)
	{
		zqu__Quote__c testQuote2 = new zqu__Quote__c();

		testQuote2.name = 'testquote2';

		testQuote2.zqu__Opportunity__c = opp.Id;

		testQuote2.zqu__BillToContact__c = con.Id;

		Contact soldTo = createContact();

		insert soldTo;

		testQuote2.zqu__SoldToContact__c = soldTo.Id;

		testQuote2.zqu__PaymentMethod__c = 'Check';

		testQuote2.zqu__PaymentTerm__c = 'Due Upon Receipt';

		testQuote2.zqu__InitialTerm__c = 12;

		testQuote2.zqu__RenewalTerm__c = 12;

		testQuote2.zqu__Service_Activation_Date__c = date.newinstance(2012, 1, 1);

		testQuote2.zqu__AutoRenew__c = false;

		testQuote2.zqu__StartDate__c = date.newinstance(2012, 1, 1);

		testQuote2.zqu__ValidUntil__c = date.newinstance(2012, 1, 1);

		testQuote2.zqu__Currency__c = 'USD';

		testQuote2.zqu__SubscriptionType__c = 'Amend Subscription';

	   	testQuote2.zqu__RecordReadOnly__c = false;

		testQuote2.zqu__Status__c = 'New';

		testQuote2.zqu__StartDate__c = date.newinstance(2012, 1, 1);

		testQuote2.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);

		testQuote2.zqu__SubscriptionTermEndDate__c = date.newinstance(2013, 1, 1);
             
		testQuote2.Global_Deal__c = false;
             
		testQuote2.BrandTag__c = 'ClearanceJobs';		
		
		insert testQuote2;

		return testQuote2;
	}

	//
	//create a tiered product rate plan charge tier 2
	//
	public static zqu__ProductRatePlanChargeTier__c makeTieredProductRatePlanChargeTier2(String prpc)
	{
		zqu__ProductRatePlanChargeTier__c testprpct = new zqu__ProductRatePlanChargeTier__c();

		testprpct.zqu__Currency__c = 'USD';

		testprpct.zqu__Deleted__c = false;

		testprpct.zqu__StartingUnit__c = 3;

		testprpct.zqu__EndingUnit__c = 10;

		testprpct.zqu__IsOveragePrice__c = false;

		testprpct.zqu__ProductRatePlanCharge__c = prpc;

		testprpct.zqu__Tier__c = 2;

		testprpct.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpct.zqu__Price__c = 10;

		testprpct.zqu__PriceFormat__c = 'Per Unit';

		insert testprpct;

		return testprpct;
	}

	//
	//create the first tiered product rate plan charge tier
	//
	public static zqu__ProductRatePlanChargeTier__c makeTieredProductRatePlanChargeTier1(String prpc)
	{
		zqu__ProductRatePlanChargeTier__c testprpct = new zqu__ProductRatePlanChargeTier__c();

		testprpct.zqu__Currency__c = 'USD';

		testprpct.zqu__Deleted__c = false;

		testprpct.zqu__StartingUnit__c = 1;

		testprpct.zqu__EndingUnit__c = 3;

		testprpct.zqu__IsOveragePrice__c = false;

		testprpct.zqu__ProductRatePlanCharge__c = prpc;

		testprpct.zqu__Tier__c = 1;

		testprpct.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpct.zqu__Price__c = 13;

		testprpct.zqu__PriceFormat__c = 'Flat Fee';

		insert testprpct;

		return testprpct;
	}

	//
	//create a volume product rate plan charge tier 2
	//
	public static zqu__ProductRatePlanChargeTier__c makeVolumeProductRatePlanChargeTier2(String prpc)
	{
		zqu__ProductRatePlanChargeTier__c testprpct = new zqu__ProductRatePlanChargeTier__c();

		testprpct.zqu__Currency__c = 'USD';

		testprpct.zqu__Deleted__c = false;

		testprpct.zqu__StartingUnit__c = 3;

		testprpct.zqu__EndingUnit__c = 10;

		testprpct.zqu__IsOveragePrice__c = false;

		testprpct.zqu__ProductRatePlanCharge__c = prpc;

		testprpct.zqu__Tier__c = 2;

		testprpct.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpct.zqu__Price__c = 10;

		testprpct.zqu__PriceFormat__c = 'Per Unit';

		insert testprpct;

		return testprpct;
	}

	//
	//create the first volume product rate plan charge tier
	//
	public static zqu__ProductRatePlanChargeTier__c makeVolumeProductRatePlanChargeTier1(String prpc)
	{
		zqu__ProductRatePlanChargeTier__c testprpct = new zqu__ProductRatePlanChargeTier__c();
			
		testprpct.zqu__Currency__c = 'USD';

		testprpct.zqu__Deleted__c = false;

		testprpct.zqu__StartingUnit__c = 1;

		testprpct.zqu__EndingUnit__c = 3;

		testprpct.zqu__IsOveragePrice__c = false;

		testprpct.zqu__ProductRatePlanCharge__c = prpc;

		testprpct.zqu__Tier__c = 1;

		testprpct.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpct.zqu__Price__c = 13;

		testprpct.zqu__PriceFormat__c = 'Flat Fee';

		insert testprpct;

		return testprpct;
	}

	//
	//create a product rate plan charge
	//
	public static zqu__ProductRatePlanChargeTier__c makeProductRatePlanChargeTier(String prpc)
	{
		zqu__ProductRatePlanChargeTier__c testprpct = new zqu__ProductRatePlanChargeTier__c();

		testprpct.zqu__Currency__c = 'USD';

		testprpct.zqu__Deleted__c = false;

		testprpct.zqu__StartingUnit__c = 0;

		testprpct.zqu__IsOveragePrice__c = false;

		testprpct.zqu__ProductRatePlanCharge__c = prpc;

		testprpct.zqu__Tier__c = 1;

		testprpct.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpct.zqu__Price__c = 100;

		testprpct.zqu__PriceFormat__c = 'Per Unit';

		insert testprpct;

		return testprpct;

	}

	//
	//create a volume product rate plan charge
	//
	public static zqu__ProductRatePlanCharge__c makeTieredProductRatePlanCharge(String prp)

	{
		zqu__ProductRatePlanCharge__c testprpc = new zqu__ProductRatePlanCharge__c();

		testprpc.name='new rate plan charge';

		testprpc.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpc.zqu__ProductRatePlan__c = prp;

		testprpc.zqu__Model__c = 'Tiered Pricing';

		testprpc.zqu__Type__c = 'Recurring';

		testprpc.zqu__UOM__c = 'Each';

		testprpc.zqu__RecurringPeriod__c = 'Month';

		testprpc.zqu__Deleted__c = false;

		testprpc.zqu__DefaultQuantity__c = 1;

		insert testprpc;

		return testprpc;

	}

	//
	//create a volume product rate plan charge
	//
	public static zqu__ProductRatePlanCharge__c makeVolumeProductRatePlanCharge(String prp)
	{
		zqu__ProductRatePlanCharge__c testprpc = new zqu__ProductRatePlanCharge__c();

		testprpc.name='new rate plan charge';

		testprpc.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpc.zqu__ProductRatePlan__c = prp;

		testprpc.zqu__Model__c = 'Volume Pricing';

		testprpc.zqu__Type__c = 'Recurring';

		testprpc.zqu__UOM__c = 'Each';

		testprpc.zqu__RecurringPeriod__c = 'Month';

		testprpc.zqu__Deleted__c = false;

		testprpc.zqu__DefaultQuantity__c = 1;

		insert testprpc;

		return testprpc;

	}
       
	//
	//create a Discount Subscription Percent charge
	//
	public static zqu__ProductRatePlanCharge__c makeDiscountSubRatePlanCharge(String prp)
	{
		zqu__ProductRatePlanCharge__c testprpc = new zqu__ProductRatePlanCharge__c();

		testprpc.name='new rate plan charge';

		testprpc.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpc.zqu__ProductRatePlan__c = prp;

		testprpc.zqu__Model__c = 'Discount-Percentage';

		testprpc.zqu__Type__c = 'Recurring';
             
		testprpc.zqu__Discount_Level__c = 'Subscription';

		testprpc.zqu__UOM__c = 'Each';

		testprpc.zqu__RecurringPeriod__c = 'Month';

		testprpc.zqu__Deleted__c = false;

		testprpc.zqu__DefaultQuantity__c = 1;
 			 
		testprpc.zqu__Discount_Apply_Type__c = 7;
 
		insert testprpc;

		return testprpc;

	}
       
	//
	//create a Discount Rate Plan Percent charge
	//
	public static zqu__ProductRatePlanCharge__c makeDiscountRPRatePlanCharge(String prp)
	{
		zqu__ProductRatePlanCharge__c testprpc = new zqu__ProductRatePlanCharge__c();

		testprpc.name='new rate plan charge';

		testprpc.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpc.zqu__ProductRatePlan__c = prp;

		testprpc.zqu__Model__c = 'Discount-Percentage';

		testprpc.zqu__Type__c = 'Recurring';
             
		testprpc.zqu__Discount_Level__c = 'RatePlan';

		testprpc.zqu__UOM__c = 'Each';

		testprpc.zqu__RecurringPeriod__c = 'Month';

		testprpc.zqu__Deleted__c = false;

		testprpc.zqu__DefaultQuantity__c = 1;
 			 
		testprpc.zqu__Discount_Apply_Type__c = 7;
            
		insert testprpc;

		return testprpc;

	}
       
	//
	//create a Discount Fixed-Amount Rate Plan Percent charge
	//
	public static zqu__ProductRatePlanCharge__c makeFixedRPRatePlanCharge(String prp)
	{

		zqu__ProductRatePlanCharge__c testprpc = new zqu__ProductRatePlanCharge__c();

		testprpc.name='new rate plan charge';

		testprpc.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpc.zqu__ProductRatePlan__c = prp;

		testprpc.zqu__Model__c = 'Discount-Fixed Amount';

		testprpc.zqu__Type__c = 'Recurring';
             
		testprpc.zqu__Discount_Level__c = 'RatePlan';

		testprpc.zqu__UOM__c = 'Each';

		testprpc.zqu__RecurringPeriod__c = 'Month';

		testprpc.zqu__Deleted__c = false;

		testprpc.zqu__DefaultQuantity__c = 1;
 			 
		testprpc.zqu__Discount_Apply_Type__c = 7;
            
		insert testprpc;

		return testprpc;

	}

	//
	//create a product rate plan charge
	//
	public static zqu__ProductRatePlanCharge__c makeProductRatePlanCharge(String prp)
	{
		zqu__ProductRatePlanCharge__c testprpc = new zqu__ProductRatePlanCharge__c();

		testprpc.name='new rate plan charge';

		testprpc.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testprpc.zqu__ProductRatePlan__c = prp;

		testprpc.zqu__Model__c = 'Per Unit Pricing';

		testprpc.zqu__Type__c = 'Recurring';

		testprpc.zqu__UOM__c = 'Each';

		testprpc.zqu__ListPrice__c = 100;

		testprpc.zqu__RecurringPeriod__c = 'Month';

		testprpc.zqu__Deleted__c = false;

		testprpc.zqu__DefaultQuantity__c = 1;
		
		insert testprpc;

		return testprpc;

	}

	//create a product rate plan
	public static zqu__ProductRatePlan__c makeProductRatePlan(String zproduct)
	{

		zqu__ProductRatePlan__c testrp = new zqu__ProductRatePlan__c();

		testrp.name = 'test rp';

		testrp.zqu__ZProduct__c = zproduct;

		testrp.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
             
		testrp.zqu__EffectiveStartDate__c = date.newinstance(2000, 1, 1);

		testrp.zqu__EffectiveEndDate__c = date.newinstance(2050, 1, 1);

		testrp.zqu__Deleted__c = false;

		insert testrp;

		return testrp;

	}

	//create a product
	public static zqu__ZProduct__c makeProduct()
	{
		zqu__ZProduct__c testProduct = new zqu__ZProduct__c();

		//testProduct.Id = ;

		testProduct.Name = 'testing';

		testProduct.zqu__SKU__c = 'testSKU';

		testProduct.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

		testProduct.zqu__EffectiveStartDate__c = date.newinstance(2000, 1, 1);

		testProduct.zqu__EffectiveEndDate__c = date.newinstance(2050, 1, 1);

		testProduct.zqu__Deleted__c = false;

		insert testProduct;

		return testProduct;

	}
      
	public static testMethod void testNewSubscription()
	{
		ClassForGlobalDealTriggerForQuote c = new ClassForGlobalDealTriggerForQuote();

		Account testAcc = createAccount();                         
		Contact testCon = createContact();     
		insert testCon;
		Opportunity testOpp = createOpportunity(testAcc);
		zqu__Quote__c testQuote = createQuote(testCon, testOpp);
         
		zqu__ZProduct__c testProd = makeProduct();
             
		zqu__ProductRatePlan__c testRatePlan = makeProductRatePlan(testProd.Id);
		zqu__ProductRatePlanCharge__c testRecurringCharge = makeProductRatePlanCharge(testRatePlan.Id);
		zqu__ProductRatePlanChargeTier__c testChargeTier = makeProductRatePlanChargeTier(testRecurringCharge.Id);
             
		zqu__ProductRatePlanCharge__c discountRPCharge = makeDiscountRPRatePlanCharge(testRatePlan.Id);
		zqu__ProductRatePlanChargeTier__c testDiscountRPChargeTier = makeProductRatePlanChargeTier(discountRPCharge.Id);
             
		zqu__ProductRatePlan__c testDiscountSubRatePlan = makeProductRatePlan(testProd.Id);
		zqu__ProductRatePlanCharge__c discountSubCharge = makeDiscountSubRatePlanCharge(testDiscountSubRatePlan.Id);
		zqu__ProductRatePlanChargeTier__c testDiscountSubChargeTier = makeProductRatePlanChargeTier(discountSubCharge.Id);
             
		zqu__ProductRatePlan__c testDiscountFARPRatePlan = makeProductRatePlan(testProd.Id);
		zqu__ProductRatePlanCharge__c testRecurringCharge2 = makeProductRatePlanCharge(testDiscountFARPRatePlan.Id);
		zqu__ProductRatePlanChargeTier__c testChargeTier2 = makeProductRatePlanChargeTier(testRecurringCharge2.Id);
             
		zqu__ProductRatePlanCharge__c discountFARPCharge = makeFixedRPRatePlanCharge(testDiscountFARPRatePlan.Id);
		zqu__ProductRatePlanChargeTier__c testChargeTier3 = makeProductRatePlanChargeTier(discountFARPCharge.Id);
             
		zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Country__c', 'Notes__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
		List<zqu.zChargeGroup> testChrgGrpList = new List<zqu.zChargeGroup>();
		testChrgGrpList = zqu.zQuoteUtil.getChargeGroups(testQuote.Id);
             
		//add a rate plan to the quote
		zqu.zChargeGroup newChargeGroup = zqu.zQuoteUtil.getChargeGroup(testQuote.Id,testRecurringCharge.zqu__ProductRatePlan__c);            
		zqu.zChargeGroup discountRPChargeGroup = zqu.zQuoteUtil.getChargeGroup(testQuote.Id,discountRPCharge.zqu__ProductRatePlan__c);             
		zqu.zChargeGroup discountChargeGroup = zqu.zQuoteUtil.getChargeGroup(testQuote.Id,discountSubCharge.zqu__ProductRatePlan__c);             
		zqu.zChargeGroup discountFARPChargeGroup = zqu.zQuoteUtil.getChargeGroup(testQuote.Id,discountFARPCharge.zqu__ProductRatePlan__c);			 
		List<zqu.zChargeGroup> listOfChargeGroups = new List<zqu.zChargeGroup>();
		listOfChargeGroups.add(newChargeGroup);			 
		listOfChargeGroups.add(discountRPChargeGroup);			 
		listOfChargeGroups.add(discountChargeGroup);			
		listOfChargeGroups.add(discountFARPChargeGroup);
			 
		//add the charge group to the quote
		zqu.ZQuoteUtil.addChargeGroups(listOfChargeGroups);
      		 
		Test.startTest();
      		 
		// Create a quote charge
		zqu__QuoteCharge__c qc = new zqu__QuoteCharge__c();
		qc.zqu__Quote__c = testQuote.Id;
		qc.zqu__Quantity__c = 1;
		qc.zqu__Currency__c = 'USD';
		qc.zqu__ProductRatePlanCharge__c = testRecurringCharge.Id;		
		qc.Country__c = 'United States';
		//qc.Notes__c = 'testing';
		//qc.Event__c = 'test event';
		qc.Sales_Representative__c = 'test rep';
		qc.ServiceStart__c = date.newinstance(2013, 12, 20);
		qc.ServiceEnd__c = date.newinstance(2014, 12, 20);
		System.Debug('quote charge: '+ qc);
		//qc2.IsPrimarySalesRepOwner__c = false;
		//qc.Name = 'test name 1';
		insert qc;
	 

		zqu__QuoteCharge__c qc2 = new zqu__QuoteCharge__c();
		qc2.zqu__Quote__c = testQuote.Id;
		qc2.zqu__ProductRatePlanCharge__c = discountRPCharge.Id;
		qc2.Country__c = 'United States';
		qc2.Sales_Representative__c = 'new rep';
 		qc2.ServiceStart__c = date.newinstance(2013, 12, 20);
		qc2.ServiceEnd__c = date.newinstance(2014, 12, 20);
		//qc2.IsPrimarySalesRepOwner__c = false;
		qc2.Name = 'test Name 2';
		insert qc2;
		
		Test.stopTest();			 
			 /*			 
			 zqu__QuoteCharge__c qc3 = new zqu__QuoteCharge__c();
			 qc3.zqu__Quote__c = testQuote.Id;
			 qc3.Country__c = 'Australia';
			 qc3.Sales_Representative__c = 'test rep';
			 //qc3.IsPrimarySalesRepOwner__c = false;
			 qc3.Name = 'test Opp Name';
			 //upsert qc3;*/
			

       }
	// For testing ClassForGlobalDealTriggerForQuote (amendments):
	/*public static testMethod void testAmendSubscription()
	{	  	  
		Account testAcc = createAccount();                         
		Contact testCon = createContact();     
		insert testCon;
		Opportunity testOpp2 = createOpportunity2(testAcc);
             
		zqu__Quote__c testQuote2 = createQuote2(testCon, testOpp2);
                          
		zqu__ZProduct__c testProd = makeProduct();
             
		zqu__ProductRatePlan__c testRatePlan = makeProductRatePlan(testProd.Id);
		zqu__ProductRatePlanCharge__c testRecurringCharge = makeProductRatePlanCharge(testRatePlan.Id);
		zqu__ProductRatePlanChargeTier__c testChargeTier = makeProductRatePlanChargeTier(testRecurringCharge.Id);
             
		zqu__ProductRatePlanCharge__c discountRPCharge = makeDiscountRPRatePlanCharge(testRatePlan.Id);
		zqu__ProductRatePlanChargeTier__c testDiscountRPChargeTier = makeProductRatePlanChargeTier(discountRPCharge.Id);
             
		zqu__ProductRatePlan__c testDiscountSubRatePlan = makeProductRatePlan(testProd.Id);
		zqu__ProductRatePlanCharge__c discountSubCharge = makeDiscountSubRatePlanCharge(testDiscountSubRatePlan.Id);
		zqu__ProductRatePlanChargeTier__c testDiscountSubChargeTier = makeProductRatePlanChargeTier(discountSubCharge.Id);
             
		zqu__ProductRatePlan__c testDiscountFARPRatePlan = makeProductRatePlan(testProd.Id);
		zqu__ProductRatePlanCharge__c testRecurringCharge2 = makeProductRatePlanCharge(testDiscountFARPRatePlan.Id);
		zqu__ProductRatePlanChargeTier__c testChargeTier2 = makeProductRatePlanChargeTier(testRecurringCharge2.Id);
             
		zqu__ProductRatePlanCharge__c discountFARPCharge = makeFixedRPRatePlanCharge(testDiscountFARPRatePlan.Id);
		zqu__ProductRatePlanChargeTier__c testChargeTier3 = makeProductRatePlanChargeTier(discountFARPCharge.Id);
             
		zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Country__c', 'Notes__c', 'Event__c', 'ServiceStart__c', 'ServiceEnd__c','Sales_Representative__c'};
             
		//add a rate plan to the quote
		zqu.zChargeGroup newChargeGroup2 = zqu.zQuoteUtil.getChargeGroup(testQuote2.Id,testRecurringCharge.zqu__ProductRatePlan__c);
		//newChargeGroup2.groupType = 3;
		       
		zqu.zChargeGroup discountRPChargeGroup2 = zqu.zQuoteUtil.getChargeGroup(testQuote2.Id,discountRPCharge.zqu__ProductRatePlan__c);             
		zqu.zChargeGroup discountChargeGroup2 = zqu.zQuoteUtil.getChargeGroup(testQuote2.Id,discountSubCharge.zqu__ProductRatePlan__c);             
		zqu.zChargeGroup discountFARPChargeGroup2 = zqu.zQuoteUtil.getChargeGroup(testQuote2.Id,discountFARPCharge.zqu__ProductRatePlan__c);		 
		List<zqu.zChargeGroup> listOfChargeGroups2 = new List<zqu.zChargeGroup>();
		listOfChargeGroups2.add(newChargeGroup2);			 
		listOfChargeGroups2.add(discountRPChargeGroup2);			 
		listOfChargeGroups2.add(discountChargeGroup2);			
		listOfChargeGroups2.add(discountFARPChargeGroup2);

		zqu.ZQuoteUtil.addChargeGroups(listOfChargeGroups2);   	*/	
		/*      		 
		// create a quote amendment
		zqu__QuoteAmendment__c qa = new zqu__QuoteAmendment__c();
		qa.zqu__Quote__c = testQuote2.Id;
		qa.zqu__QuoteAmendmentZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
		qa.zqu__Type__c = 'UpdateProduct';
		qa.zqu__TotalAmount__c = 2000.00;
		qa.zqu__Status__c = 'Draft';
		insert qa;
      		 
		// create a quote rate plan
		zqu__QuoteRatePlan__c qrp = new zqu__QuoteRatePlan__c();
		qrp.zqu__Quote__c = testQuote2.Id;
		qrp.Name = 'test qrp name';
		qrp.zqu__QuoteAmendment__c = qa.Id;
		qrp.zqu__AmendmentType__c = 'NewProduct';
		qrp.zqu__ProductRatePlanZuoraId__c = testRatePlan.zqu__ZuoraId__c;
		qrp.zqu__QuoteRatePlanZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
		insert qrp;
      		 
		// Create a quote rate plan charge
		zqu__QuoteRatePlanCharge__c qrpc = new zqu__QuoteRatePlanCharge__c();
		qrpc.zqu__QuoteRatePlan__c = qrp.Id;
		qrpc.ServiceStart__c = date.newinstance(2013, 12, 20);
		qrpc.ServiceEnd__c = date.newinstance(2014, 12, 20);
		qrpc.Country__c = 'United States';
		qrpc.Sales_Representative__c = 'new rep';
		qrpc.Name = 'test qrpc name';
		insert qrpc;
		*/
		
		//Test.startTest(); 
		/*
		Zuora__SubscriptionProductCharge__c oldAmendCharge = new Zuora__SubscriptionProductCharge__c();
		oldAmendCharge.Country__c = 'United Kingdom';
		oldAmendCharge.Sales_Representative__c = 'new rep'; 

		Zuora__SubscriptionProductCharge__c oldAmendCharge2 = new Zuora__SubscriptionProductCharge__c();
		oldAmendCharge2.Country__c = 'United States';
		oldAmendCharge.Sales_Representative__c = 'test rep';

		List<Zuora__SubscriptionProductCharge__c> listOldAmendCharges = new List<Zuora__SubscriptionProductCharge__c>();
		listOldAmendCharges.add(oldAmendCharge);
		listOldAmendCharges.add(oldAmendCharge2);
		System.Debug('listOldAmendCharges :'+listOldAmendCharges);*/
		
		//ClassForGlobalDealTriggerForQuote gdtfq = new ClassForGlobalDealTriggerForQuote(String.valueOf(testQuote2.Id));
		
		//testQuote2.RecordType = 'Amend';
		//testQuote2.zqu__SubscriptionType__c = 'Amend Subscription';

			 
		// Get all existing charge groups
		//List<zqu.zChargeGroup> existingChrgGrpList = zqu.zQuoteUtil.getChargeGroups(String.valueOf(testQuote2.Id));
		
		     
		//Test.stopTest();
 
	//}
}