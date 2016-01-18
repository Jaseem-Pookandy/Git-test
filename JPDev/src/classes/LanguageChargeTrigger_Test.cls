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

@isTest (SeeAllData=true)
private class LanguageChargeTrigger_Test {
	//Account create
       
       public static Account createAccount()
       {

             Account testAcc = new Account();

             testAcc.Name = 'testAccount';
             testAcc.BillingCity = 'Somewhere';
             testAcc.BillingState = 'CA';
             testAcc.BillingCountry = 'USA';
             testAcc.BillingPostalCode = '12345';
             testAcc.BillingStreet = '123';

             insert testAcc;

             return testAcc;

       }

       
       //contact create
       
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
       
       
       //create opportunity
       
       public static Opportunity createOpportunity(Account acc)
       {

             Opportunity testOpp = new Opportunity();

             testOpp.Name = 'testopp';

             Date mydate = date.newinstance(2012, 1, 1);

             testOpp.CloseDate = mydate;            

             testOpp.StageName = 'Closed Won';

             testOpp.Type = 'New Business';

             List<Account> acclist = [select id, name from Account where name = :acc.Name];

            
             testOpp.AccountId = acclist[0].Id;

             insert testOpp;

             return testOpp;
       }

       
       //create quote
       
       public static zqu__Quote__c createQuote(Contact con, Opportunity opp)
       {

             zqu__Quote__c testQuote = new zqu__Quote__c();

             testQuote.zqu__SubscriptionType__c = 'Amend Subscription';

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

             testQuote.Global_Deal__c = false;

          	 testQuote.zqu__RecordReadOnly__c = false;

             testQuote.zqu__Status__c = 'New';

             testQuote.zqu__StartDate__c = date.newinstance(2012, 1, 1);

             testQuote.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);

             testQuote.zqu__SubscriptionTermEndDate__c = date.newinstance(2013, 1, 1);

             insert testQuote;

             return testQuote;
       }

       //create a tiered product rate plan charge tier 2

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

       //create the first tiered product rate plan charge tier

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

       //create a volume product rate plan charge tier 2

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

       //create the first volume product rate plan charge tier

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

       //create a product rate plan charge

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

       //create a volume product rate plan charge

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

       //create a volume product rate plan charge

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

       //create a product rate plan charge
       
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
             
             testprpc.DutchChargeName__c = 'testDutchChrg';
             
             testprpc.EnglishChargeName__c = 'testEnglishChrg';
             
             testprpc.FrenchChargeName__c = 'testFrenchChrg';
             
             testprpc.GermanChargeName__c = 'testGermanChrg';
             
             testprpc.ItalianChargeName__c = 'testItalianChrg';
             
             testprpc.RussianChargeName__c = 'testRussChrg';
             
             testprpc.SpanishChargeName__c = 'testSpanishChrg';
             
             testprpc.SimplifiedChineseChargeName__c = 'testChineseChrg';           

             insert testprpc;

             return testprpc;

       }

       //create a product rate plan

       public static zqu__ProductRatePlan__c makeProductRatePlan(String zproduct)

       {

             zqu__ProductRatePlan__c testrp = new zqu__ProductRatePlan__c();

             testrp.name = 'test rp';

             testrp.zqu__ZProduct__c = zproduct;

             testrp.zqu__EffectiveStartDate__c = date.newinstance(2000, 1, 1);

             testrp.zqu__EffectiveEndDate__c = date.newinstance(2050, 1, 1);

             testrp.zqu__Deleted__c = false;
             
             testrp.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);

             insert testrp;

             return testrp;

       }

       //create a product

       public static zqu__ZProduct__c makeProduct()

       {

             zqu__ZProduct__c testProduct = new zqu__ZProduct__c();

             //testProduct.Id = '123';

             testProduct.Name = 'testing';

             testProduct.zqu__SKU__c = 'testSKU';

             testProduct.zqu__EffectiveStartDate__c = date.newinstance(2000, 1, 1);

             testProduct.zqu__EffectiveEndDate__c = date.newinstance(2050, 1, 1);

             testProduct.zqu__Deleted__c = false;
                        
			 testProduct.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
			 
             insert testProduct;

             return testProduct;

       }
       
       
	static testMethod void LanguageChargeScenario_Test() {
        
        Account testAcc = createAccount();                         
        Contact testCon = createContact();     
        insert testCon;
        Opportunity testOpp = createOpportunity(testAcc);
        zqu__Quote__c testQuote = createQuote(testCon, testOpp);

        zqu__ZProduct__c testProd = makeProduct();
        zqu__ProductRatePlan__c testRatePlan = makeProductRatePlan(testProd.Id);
        zqu__ProductRatePlanCharge__c testRecurringCharge = makeProductRatePlanCharge(testRatePlan.Id);

        zqu__ProductRatePlanChargeTier__c testChargeTier = makeProductRatePlanChargeTier(testRecurringCharge.Id);

        zqu__ProductRatePlanCharge__c testVolumeCharge = makeVolumeProductRatePlanCharge(testRatePlan.Id);

        zqu__ProductRatePlanChargeTier__c testVolumeChargeTier1 = makeVolumeProductRatePlanChargeTier1(testVolumeCharge.Id);

        zqu__ProductRatePlanChargeTier__c testVolumeChargeTier2 = makeVolumeProductRatePlanChargeTier2(testVolumeCharge.Id);
           
        zqu__ProductRatePlanCharge__c testTieredCharge = makeTieredProductRatePlanCharge(testRatePlan.Id);

        zqu__ProductRatePlanChargeTier__c testTieredChargeTier1 = makeTieredProductRatePlanChargeTier1(testTieredCharge.Id);

        zqu__ProductRatePlanChargeTier__c testTieredChargeTier2 = makeTieredProductRatePlanChargeTier2(testTieredCharge.Id);

		Test.startTest();
		
        //add a rate plan to the quote

        zqu.zChargeGroup newChargeGroup = zqu.zQuoteUtil.getChargeGroup(testQuote.Id,testRecurringCharge.zqu__ProductRatePlan__c);

       	//add the charge group to the quote

      	zqu.ZQuoteUtil.addChargeGroup(newChargeGroup);
 		
	
		List<zqu__ProductRatePlanCharge__c> prpcsList = new List<zqu__ProductRatePlanCharge__c>();
		zqu__ProductRatePlanCharge__c prpCharge = new zqu__ProductRatePlanCharge__c();
        prpCharge.Name = 'Test PRPC';
        prpCharge.zqu__ZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        prpCharge.DutchChargeName__c = 'TestDutchChargeName';
        prpCharge.EnglishChargeName__c = 'TestEnglishChargeName';
        prpCharge.FrenchChargeName__c = 'TestFrenchChargeName';
        prpCharge.GermanChargeName__c = 'TestGermanChargeName';
        prpCharge.ItalianChargeName__c = 'TestItalianChargeName';
        prpCharge.RussianChargeName__c = 'TestRussianChargeName';
        prpCharge.SpanishChargeName__c = 'TestSpanishChargeName';
        prpCharge.SimplifiedChineseChargeName__c = 'TestSimpChineseChargeName';          
        prpCharge.zqu__Type__c = 'Recurring';
        prpCharge.zqu__Model__c = 'RatePlan';
        prpCharge.zqu__ProductRatePlan__c = testRatePlan.Id;
   		insert prpCharge;
    	
    	prpcsList.add(prpCharge);
    
    	prpcsList.add(testRecurringCharge);

	    // create a quote amendment
		zqu__QuoteAmendment__c qa = new zqu__QuoteAmendment__c();
		qa.zqu__Quote__c = testQuote.Id;
		qa.zqu__QuoteAmendmentZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
		qa.zqu__Type__c = 'UpdateProduct';
		qa.zqu__TotalAmount__c = 2000.00;
		qa.zqu__Status__c = 'Draft';
		insert qa;
      		 
		// create a quote rate plan
		zqu__QuoteRatePlan__c qrp = new zqu__QuoteRatePlan__c();
		qrp.zqu__Quote__c = testQuote.Id;
		qrp.Name = 'test qrp name';
		qrp.zqu__QuoteAmendment__c = qa.Id;
		qrp.zqu__AmendmentType__c = 'NewProduct';
		qrp.zqu__ProductRatePlanZuoraId__c = testRatePlan.zqu__ZuoraId__c;
		qrp.zqu__QuoteRatePlanZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
		insert qrp;
             
		List<zqu__QuoteRatePlanCharge__c> listQrpcs = new List<zqu__QuoteRatePlanCharge__c>();
		
		// create a quote rate plan charge
		zqu__QuoteRatePlanCharge__c qrpCharge = new zqu__QuoteRatePlanCharge__c();
        qrpCharge.zqu__QuoteRatePlan__c = qrp.Id;
        qrpCharge.Name = 'Test QRPC';
        qrpCharge.zqu__ProductRatePlanChargeZuoraId__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        qrpCharge.DutchChargeName__c = 'TDC';
        qrpCharge.EnglishChargeName__c = 'TEC';
        qrpCharge.FrenchChargeName__c = 'TFC';
        qrpCharge.GermanChargeName__c = 'TGC';
        qrpCharge.ItalianChargeName__c = 'TIC';
        qrpCharge.RussianChargeName__c = 'TRC';
        qrpCharge.SpanishChargeName__c = 'TSC';
        qrpCharge.SimplifiedChineseChargeName__c = 'TSCC';
        qrpCharge.Region__c = 'testRegion';
       	qrpCharge.EnergyRegion__c = 'testEngergyRegion';
       	qrpCharge.SubRegion1__c = 'testSubRegion1';
       	qrpCharge.SubRegion2__c = 'testSubRegion2';
        qrpCharge.Country__c = 'United States';
        qrpCharge.zqu__Quantity__c = 1;
        qrpCharge.ServiceEnd__c = date.newinstance(2014, 12, 1);
        qrpCharge.ServiceStart__c = date.newinstance(2013, 12, 1);
        qrpCharge.Event__c = null;
        qrpCharge.Notes__c = 'test notes';
        qrpCharge.zqu__ListTotal__c = 200;
        qrpCharge.Sales_Representative__c = 'Test Rep';
        qrpCharge.zqu__Total__c = 200;
        insert qrpCharge;
        
     	listQrpcs.add(qrpCharge);
    

	    Test.stopTest();
	
	
	}
}