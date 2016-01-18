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
private class PropCompForEditQuoteDetails_Test {
    
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
        testcon.pw_ccpro__MailingCountryLookup__c = 'Test Country';
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

        testQuote.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);

        testQuote.zqu__SubscriptionTermEndDate__c = date.newinstance(2013, 1, 1);
        
        testQuote.Deferred_Bill_Date__c = date.newinstance(2014, 1, 1);

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
    
    @isTest(SeeAllData=true)
    private static void testConstructor() {
        // Create quote record but not insert
        zqu__Quote__c quote = new zqu__Quote__c();
        
        Account testAcc = createAccount();                   
        Contact soldTo = createContact();
        insert soldTo;
        Opportunity testOpp = createOpportunity(testAcc);
        
        quote.Deferred_Bill_Date__c = date.newinstance(2000, 1, 1);
        //zqu__Quote__c testQuote = createQuote(soldTo, testOpp);
        //quote = testQuote;
        Test.startTest();           
        
        // Create quote standard controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(quote);
    
        PropertyComponentForEditQuoteDetails controller = new PropertyComponentForEditQuoteDetails(stdController);
            
        
        //System.assert(controller.opp != null, 'The opportunity is null.');
        System.assert(controller.theOptions.isEditMode == true, 'The property sample is not in Edit mode.');
        
            
        //quote.zqu__Opportunity__c = testOpp.Id;
        quote.zqu__SoldToContact__c = soldTo.Id;
        
        // Detail mode
        ApexPages.currentPage().getParameters().put('mode', 'detail');
        
        // Insert the quote record      
        insert quote;
    
        stdController = new ApexPages.StandardController(quote);
        controller = new PropertyComponentForEditQuoteDetails(stdController);
        
        //controller.setOpportunity(testOpp.Id);
                
        controller.theOptions = new zqu.PropertyComponentOptions();


        
        PropertyComponentForEditQuoteDetails.PopulateCancelPlugin pcp = new PropertyComponentForEditQuoteDetails.PopulateCancelPlugin();
        pcp.doCancel(controller.quote, controller);

        
        //controller.quote.Id = null;         
        PropertyComponentForEditQuoteDetails.PopulateDefaultFieldValuePlugin pdfvp = new PropertyComponentForEditQuoteDetails.PopulateDefaultFieldValuePlugin();
        pdfvp.populateDefaultFieldValue(controller.quote, controller);

        PropertyComponentForEditQuoteDetails.PopulateUpdatePlugin pup = new PropertyComponentForEditQuoteDetails.PopulateUpdatePlugin();
        pup.doUpdate(controller.quote, controller);
        
        System.assert(controller.theOptions.isEditMode == false, 'The property sample is not in Detail mode.');
        Test.stopTest();
    
    }
}