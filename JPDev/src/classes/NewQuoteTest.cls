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
private class NewQuoteTest {

	
   		//
       //Account create
       //
       public static Account createAccount()
       {

             Account testAcc = new Account();

             testAcc.Name = 'testAccount';
             testAcc.BillingCity = 'Somewhere';
             testAcc.BillingState = 'CA';
             testAcc.BillingCountry = 'US';
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
			 testcon.Salutation = 'Mr.';
             testcon.email = 'test@test.com';
			 testcon.MailingState = 'Georgia';
             testcon.MailingPostalCode = '30324';
             testcon.MailingCity = 'Atlanta';
             testcon.MailingCountry = 'United States';             

			
			 //insert testcon; 
			 
             return testcon;
       }


       //
       //create opportunity
       //
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

       //
       //create quote
       //
       public static zqu__Quote__c createQuote(Contact con, Opportunity opp, Account account)
       {

             zqu__Quote__c testQuote = new zqu__Quote__c();

			
             testQuote.name = 'testquote';

             testQuote.zqu__Opportunity__c = opp.Id;

             testQuote.zqu__BillToContact__c = con.Id;

             Contact soldTo = createContact();

            soldTo.AccountId = account.Id;

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

          

           testQuote.zqu__RecordReadOnly__c = false;

             testQuote.zqu__Status__c = 'New';

             testQuote.zqu__StartDate__c = date.newinstance(2012, 1, 1);

             testQuote.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);

             testQuote.zqu__SubscriptionTermEndDate__c = date.newinstance(2013, 1, 1);

             insert testQuote;

             return testQuote;
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

             testprpct.zqu__ZuoraId__c = '12349';

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

             testprpct.zqu__EndingUnit__c = 2;

             testprpct.zqu__IsOveragePrice__c = false;

             testprpct.zqu__ProductRatePlanCharge__c = prpc;

             testprpct.zqu__Tier__c = 1;

             testprpct.zqu__ZuoraId__c = '12348';

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

             testprpct.zqu__ZuoraId__c = '12345';

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

             testprpc.zqu__ZuoraId__c = '1236';

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

       //create a product rate plan charge

       //

       public static zqu__ProductRatePlanCharge__c makeProductRatePlanCharge(String prp)

       {

             zqu__ProductRatePlanCharge__c testprpc = new zqu__ProductRatePlanCharge__c();

             testprpc.name='new rate plan charge';

             testprpc.zqu__ZuoraId__c = '1234';

             testprpc.zqu__ProductRatePlan__c = prp;

             testprpc.zqu__Model__c = 'Tiered Pricing';

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

             testrp.zqu__ZuoraId__c = '123';

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

             //testProduct.Id = '123';

             testProduct.Name = 'testing';

             testProduct.zqu__SKU__c = 'testSKU';

             testProduct.zqu__ZuoraId__c = '12';

             testProduct.zqu__EffectiveStartDate__c = date.newinstance(2000, 1, 1);

             testProduct.zqu__EffectiveEndDate__c = date.newinstance(2050, 1, 1);

             testProduct.zqu__Deleted__c = false;

            

             insert testProduct;

             return testProduct;

       }
      
	   
	
	public static testMethod void test()
	{
		Account testAcc = createAccount();                         
             Contact testCon = createContact();     
             testCon.AccountId = testAcc.Id;
             insert testCon;
             Opportunity testOpp = createOpportunity(testAcc);
             zqu__Quote__c testQuote = createQuote(testCon, testOpp, testAcc);

            Test.startTest();

             zqu__ZProduct__c testProd = makeProduct();
             zqu__ProductRatePlan__c testRatePlan = makeProductRatePlan(testProd.Id);
            
             zqu__ProductRatePlanCharge__c testRecurringCharge = makeProductRatePlanCharge(testRatePlan.Id);

             zqu__ProductRatePlanChargeTier__c testChargeTier = makeProductRatePlanChargeTier(testRecurringCharge.Id);
           
             zqu__ProductRatePlanCharge__c testTieredCharge = makeTieredProductRatePlanCharge(testRatePlan.Id);

             zqu__ProductRatePlanChargeTier__c testTieredChargeTier1 = makeTieredProductRatePlanChargeTier1(testTieredCharge.Id);

            zqu__ProductRatePlanChargeTier__c testTieredChargeTier2 = makeTieredProductRatePlanChargeTier2(testTieredCharge.Id);
             

            //add a rate plan to the quote

            zqu.zChargeGroup newChargeGroup = zqu.zQuoteUtil.getChargeGroup(testQuote.Id,testTieredCharge.zqu__ProductRatePlan__c);

       		//add the charge group to the quote

      		zqu.ZQuoteUtil.addChargeGroup(newChargeGroup);
		
		
		
		ApexPages.StandardController controller = new ApexPages.StandardController(testQuote);
		Apexpages.currentPage().getParameters().put('quoteType', 'Renew');
		NewQuoteController nqc = new NewQuoteController(controller);
		
		nqc.save();
		
		Test.stopTest();
	}
	
	public static testMethod void test2()
	{
		Account testAcc = createAccount();                         
             Contact testCon = createContact();     
             testCon.AccountId = testAcc.Id;
             insert testCon;
             Opportunity testOpp = createOpportunity(testAcc);
             zqu__Quote__c testQuote = createQuote(testCon, testOpp, testAcc);

            Test.startTest();

             zqu__ZProduct__c testProd = makeProduct();
             zqu__ProductRatePlan__c testRatePlan = makeProductRatePlan(testProd.Id);
            
             zqu__ProductRatePlanCharge__c testRecurringCharge = makeProductRatePlanCharge(testRatePlan.Id);

             zqu__ProductRatePlanChargeTier__c testChargeTier = makeProductRatePlanChargeTier(testRecurringCharge.Id);
           
             zqu__ProductRatePlanCharge__c testTieredCharge = makeTieredProductRatePlanCharge(testRatePlan.Id);

             zqu__ProductRatePlanChargeTier__c testTieredChargeTier1 = makeTieredProductRatePlanChargeTier1(testTieredCharge.Id);

            zqu__ProductRatePlanChargeTier__c testTieredChargeTier2 = makeTieredProductRatePlanChargeTier2(testTieredCharge.Id);
             

            //add a rate plan to the quote

            zqu.zChargeGroup newChargeGroup = zqu.zQuoteUtil.getChargeGroup(testQuote.Id,testTieredCharge.zqu__ProductRatePlan__c);

       		//add the charge group to the quote

      		zqu.ZQuoteUtil.addChargeGroup(newChargeGroup);
				
		ApexPages.StandardController controller = new ApexPages.StandardController(testQuote);
		Apexpages.currentPage().getParameters().put('quoteType', 'New');
		NewQuoteController nqc = new NewQuoteController(controller);
		
		nqc.save();
		
		Test.stopTest();
	}
}