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
public with sharing class RegionsQuoteChargeTrigger_Test {
	
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

             Opportunity testOpp = new Opportunity();

             testOpp.Name = 'testopp';
             
             //testOpp.Owner = 'test name';

             Date mydate = date.newinstance(2012, 1, 1);

             testOpp.CloseDate = mydate;            

             testOpp.StageName = 'Closed Won';

             testOpp.Type = 'New Business';
             
             

             List<Account> acclist = [select id, name from Account where name = :acc.Name];

            
             testOpp.AccountId = acclist[0].Id;

             insert testOpp;

             return testOpp;
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
             
             testQuote.Global_Deal__c = false;

             insert testQuote;

             return testQuote;
       }
       
       // create a quote
       
       public static zqu__Quote__c createQuote2(Contact con, Opportunity opp)
       {

             zqu__Quote__c testQuote2 = new zqu__Quote__c();

            

             testQuote2.name = 'testquote';

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

             testQuote2.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);

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
      
       public static testMethod void testQCRegions()
       {
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
             
      		       		       		 
      		 Test.startTest();
      		 
      		 //add a rate plan to the quote

			 zqu.zChargeGroup newChargeGroup = zqu.zQuoteUtil.getChargeGroup(testQuote.Id,testRecurringCharge.zqu__ProductRatePlan__c);

       	 	 //add the charge group to the quote

      		 zqu.ZQuoteUtil.addChargeGroup(newChargeGroup);
      		 			 
			 Set<String> quoteChrgCountries = new Set<String>();
			 				         
			 List<pw_ccpro__CountryObject__c> countries = new List<pw_ccpro__CountryObject__c>();
			 pw_ccpro__CountryObject__c testCountry = new pw_ccpro__CountryObject__c();
			 testCountry.Region__c = 'test region';
			 testCountry.Region_Energy__c = 'test region energy';
			 testCountry.Sub_Region1__c = 'test sub region';
			 testCountry.Sub_Region2__c = 'test sub region 2';
			 testCountry.Name = 'test country';
			 testCountry.pw_ccpro__IsoCode_2__c = 'i2';
			 testCountry.pw_ccpro__IsoCode_3__c = 'i3';
			 insert testCountry;
			 countries.add(testCountry);
			 							         
			 List<zqu__QuoteCharge__c> qcList = new List<zqu__QuoteCharge__c>();
			 zqu__QuoteCharge__c qc = new zqu__QuoteCharge__c();
			 qc.Region__c = 'testRegion';
			 qc.EnergyRegion__c = 'testEnergyRegion';
			 qc.SubRegion1__c = 'testSubReg1';
			 qc.SubRegion2__c = 'testSubReg2';
			 qc.Country__c = 'test country';
			 qc.zqu__Quote__c = testQuote.Id;
			 qc.zqu__ProductRatePlanCharge__c = testRecurringCharge.Id;
			 qc.ServiceStart__c = date.newinstance(2014, 12, 1);
			 qc.ServiceEnd__c = date.newinstance(2015, 12, 1);
			 qc.zqu__Quantity__c = 1;
			 qc.Event__c = null;
			 qc.Notes__c = 'test notes';
			 qc.Sales_Representative__c = 'test rep';
			 qc.zqu__ListTotal__c = 200;
			 qc.zqu__Total__c = 200;
			 upsert qc;
			 
			 zqu__QuoteCharge__c qc2 = new zqu__QuoteCharge__c();
			 qc2.Region__c = 'testRegion2';
			 qc2.EnergyRegion__c = 'testEnergyRegion2';
			 qc2.SubRegion1__c = 'test SubReg1';
			 qc2.SubRegion2__c = 'test SubReg2';
			 qc2.Country__c = 'test country 2';
			 qc2.zqu__Quote__c = testQuote.Id;
			 qc2.zqu__ProductRatePlanCharge__c = testRecurringCharge2.Id;
			 qc2.ServiceStart__c = date.newinstance(2014, 12, 1);
			 qc2.ServiceEnd__c = date.newinstance(2015, 12, 1);
			 qc2.zqu__Quantity__c = 1;
			 qc2.Event__c = null;
			 qc2.Notes__c = 'test notes 2';
			 qc2.Sales_Representative__c = 'test rep 2';
			 qc2.zqu__ListTotal__c = 100;
			 qc2.zqu__Total__c = 100;
			 //qc2.Sales_Representative__c = 'new rep';
			 upsert qc2;
			 qcList.add(qc);
			 qcList.add(qc2);
			 qcList[1].Country__c = 'test country';
			 //update qcList;
			 

			 Test.stopTest();
	
		}

       
        
}