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
public class QuotePreviewSample_Test {

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
    
    //Create Country Object
    public static pw_ccpro__CountryObject__c createCountry() 
    {
        pw_ccpro__CountryObject__c testCountry = new pw_ccpro__CountryObject__c();
        testCountry.Region__c = 'test region';
        testCountry.Region_Energy__c = 'test region energy';
        testCountry.Sub_Region1__c = 'test sub region';
        testCountry.Sub_Region2__c = 'test sub region 2';
        testCountry.Name = 'Test Country';
        testCountry.pw_ccpro__IsoCode_2__c = 'i2';
        testCountry.pw_ccpro__IsoCode_3__c = 'i3';
        
        insert testCountry;
        
        return testCountry;
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
    private static void testQuotePreviewSample() {
        
        Account testAcc = createAccount();                         
        Contact testCon = createContact();     
        insert testCon;
        Opportunity testOpp = createOpportunity(testAcc);        
        
        Invoice_Template__c invTemp = new Invoice_Template__c();
        invTemp.Invoice_Template_Id__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        invTemp.Name = 'test template';
        invTemp.Form_Number__c = 'Form Number';
        insert invTemp;
        
        pw_ccpro__CountryObject__c testCountry = createCountry();
        List<pw_ccpro__CountryObject__c> countryList = new List<pw_ccpro__CountryObject__c>();
        countryList.add(testCountry);
        
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
            
        //Create and insert test quote
        //zqu__Quote__c testQuote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(false);
        zqu__Quote__c testQuote = new zqu__Quote__c();
        testQuote.zqu__ElectronicPaymentMethodId__c = 'pmid1234';
        //testQuote.zqu__ZuoraAccountId__c = 'zaid1234';
        testQuote.zqu__SoldToContact__c = testCon.Id;
        testQuote.zqu__BillToContact__c = testCon.Id;
        testQuote.zqu__Opportunity__c = testOpp.Id;
        testQuote.zqu__SubscriptionType__c = 'New Subscription';
        testQuote.zqu__ZuoraAccountID__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        testQuote.AR_Special_Notes__c = 'test notes';
        testQuote.BrandTag__c = 'ClearanceJobs';
        testQuote.zqu__ZuoraSubscriptionID__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        testQuote.Global_Deal__c = false;
        testQuote.Deferred_Bill_Date__c = date.newinstance(2014, 12, 1);
        testQuote.zqu__StartDate__c = date.newinstance(2014, 1, 13);
        testQuote.AR_Special_Handling__c = true;

        insert testQuote;
        
        Test.startTest();   
        QuotePreviewSample stzbp = new QuotePreviewSample(new ApexPages.StandardController(testQuote));

        /* CASE 1: Quote successfully sent to Z-Billing */

        testZBillingResult.success = true;

        //Init custom plugin instance
        Type customCreateOrderPlugin = Type.forName('QuotePreviewSample.CreateOrderPlugin');
        QuotePreviewSample.CreateOrderPlugin pluginInstance = (QuotePreviewSample.CreateOrderPlugin) customCreateOrderPlugin.newInstance();

        //User clicks create order
        PageReference successCreateOrderPage = pluginInstance.CreateOrder(stzbp);

        //Verify success message was posted to current page
        System.assertEquals(null, successCreateOrderPage);
        System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.CONFIRM));

        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    private static void testPaymentMethodCash() {
        
        Account testAcc = createAccount();                         
        Contact testCon = createContact();     
        insert testCon;
        Opportunity testOpp = createOpportunity(testAcc);        
        
        Invoice_Template__c invTemp = new Invoice_Template__c();
        invTemp.Invoice_Template_Id__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        invTemp.Name = 'test template';
        invTemp.Form_Number__c = 'Form Number 2';
        insert invTemp;
        
        pw_ccpro__CountryObject__c testCountry = createCountry();
        List<pw_ccpro__CountryObject__c> countryList = new List<pw_ccpro__CountryObject__c>();
        countryList.add(testCountry);
        
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
            
        //Create and insert test quote
        zqu__Quote__c testQuote = new zqu__Quote__c();
        testQuote.zqu__ElectronicPaymentMethodId__c = 'pmid1234';
        testQuote.zqu__SoldToContact__c = testCon.Id;
        testQuote.zqu__BillToContact__c = testCon.Id;
        testQuote.zqu__Opportunity__c = testOpp.Id;
        testQuote.zqu__SubscriptionType__c = 'New Subscription';
        testQuote.zqu__ZuoraAccountID__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        testQuote.AR_Special_Notes__c = 'test notes';
        testQuote.BrandTag__c = 'ClearanceJobs';
        testQuote.zqu__ZuoraSubscriptionID__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        testQuote.Global_Deal__c = false;
        testQuote.Deferred_Bill_Date__c = date.newinstance(2014, 12, 1);
        testQuote.zqu__StartDate__c = date.newinstance(2014, 1, 13);
        testQuote.AR_Special_Handling__c = true;

        insert testQuote;
        
        Test.startTest();
        QuotePreviewSample stzbp = new QuotePreviewSample(new ApexPages.StandardController(testQuote));
        
        
        Type customCreateOrderPlugin = Type.forName('QuotePreviewSample.CreateOrderPlugin');
        QuotePreviewSample.CreateOrderPlugin pluginInstance = (QuotePreviewSample.CreateOrderPlugin) customCreateOrderPlugin.newInstance();
        /* CASE 2: Quote not successfully sent to Z-Billing */

        //Set test result success to false
        testZBillingResult.success = false;
        testZBillingResult.message = 'test error message';

        //User clicks create order
        PageReference failureCreateOrderPage = pluginInstance.CreateOrder(stzbp);
        
        //Verify failure message was posted to current page
        System.assertEquals(null, failureCreateOrderPage);
        System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.ERROR));

        //QuotePreviewSample.toQuoteDetail();               
        
        QuotePreviewSample.updateQuote(testQuote.Id);
        
        QuotePreviewSample.updateSubscription(testQuote.Id);
        
        QuotePreviewSample.updateAccount(String.valueOf(testQuote.Id), 'Batch5');
        
        testQuote.zqu__PaymentMethod__c = 'Cash';
        testQuote.zqu__SubscriptionType__c = 'New Subscription';
        testQuote.zqu__ZuoraAccountID__c = null;
        testQuote.AR_Special_Notes__c = 'test notes';
        QuotePreviewSample stzbp1 = new QuotePreviewSample(new ApexPages.StandardController(testQuote));

        stzbp1.toQuoteDetail();
        
        testQuote.InvoiceTemplateName__c = null;
        QuotePreviewSample stzbp3 = new QuotePreviewSample(new ApexPages.StandardController(testQuote));
        testZBillingResult.success = true;

        //Init custom plugin instance
        Type custmCreateOrderPlugin = Type.forName('QuotePreviewSample.CreateOrderPlugin');
        QuotePreviewSample.CreateOrderPlugin plugin = (QuotePreviewSample.CreateOrderPlugin) custmCreateOrderPlugin.newInstance();

        //User clicks create order
        PageReference successPage = pluginInstance.CreateOrder(stzbp3);

        //Verify success message was posted to current page
        System.assertEquals(null, successPage);
        System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.CONFIRM));
        
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    private static void testInvoiceTemplate() {
        
        Account testAcc = createAccount();                         
        Contact testCon = createContact();     
        insert testCon;
        Opportunity testOpp = createOpportunity(testAcc);        
        
        Invoice_Template__c invTemp = new Invoice_Template__c();
        invTemp.Invoice_Template_Id__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        invTemp.Name = 'test template';
        invTemp.Form_Number__c = 'Form Number 3';
        insert invTemp;
        
        pw_ccpro__CountryObject__c testCountry = createCountry();
        List<pw_ccpro__CountryObject__c> countryList = new List<pw_ccpro__CountryObject__c>();
        countryList.add(testCountry);
        
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
            
        //Create and insert test quote
        zqu__Quote__c testQuote = new zqu__Quote__c();
        testQuote.zqu__ElectronicPaymentMethodId__c = 'pmid1234';
        testQuote.zqu__SoldToContact__c = testCon.Id;
        testQuote.zqu__BillToContact__c = testCon.Id;
        testQuote.zqu__Opportunity__c = testOpp.Id;
        testQuote.zqu__SubscriptionType__c = 'Amend Subscription';
        testQuote.zqu__ZuoraAccountID__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        testQuote.AR_Special_Notes__c = 'test notes';
        testQuote.BrandTag__c = 'ClearanceJobs';
        testQuote.zqu__ZuoraSubscriptionID__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        testQuote.Global_Deal__c = false;
        testQuote.Deferred_Bill_Date__c = date.newinstance(2014, 12, 1);
        testQuote.zqu__StartDate__c = date.newinstance(2014, 1, 13);
        testQuote.AR_Special_Handling__c = true;

        insert testQuote;
        
        Test.startTest();
        
        QuotePreviewSample stzbp = new QuotePreviewSample(new ApexPages.StandardController(testQuote));
        /* CASE 3: Quote not successfully sent to Z-Billing */
        //Set test result success to false
        testZBillingResult.success = false;
        testZBillingResult.message = 'test error message';
        
        Type customCreateOrderPlugin = Type.forName('QuotePreviewSample.CreateOrderPlugin');
        QuotePreviewSample.CreateOrderPlugin pluginInstance = (QuotePreviewSample.CreateOrderPlugin) customCreateOrderPlugin.newInstance();

        //User clicks create order
        PageReference failurePage = pluginInstance.CreateOrder(stzbp);

        //Verify failure message was posted to current page
        System.assertEquals(null, failurePage);
        System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.ERROR));
    
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    private static void testBrandTag() {
        
        Account testAcc = createAccount();                         
        Contact testCon = createContact();     
        insert testCon;
        Opportunity testOpp = createOpportunity(testAcc);        
        
        pw_ccpro__CountryObject__c testCountry = createCountry();
        List<pw_ccpro__CountryObject__c> countryList = new List<pw_ccpro__CountryObject__c>();
        countryList.add(testCountry);
        
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
            
        //Create and insert test quote
        zqu__Quote__c testQuote = new zqu__Quote__c();
        testQuote.zqu__SoldToContact__c = testCon.Id;
        testQuote.zqu__BillToContact__c = testCon.Id;
        testQuote.zqu__ElectronicPaymentMethodId__c = 'pmid123';
        testQuote.zqu__Opportunity__c = testOpp.Id;
        testQuote.InvoiceTemplateName__c = null;
        testQuote.zqu__SubscriptionType__c = 'Amend Subscription';
        testQuote.Deferred_Bill_Date__c = date.newinstance(2000, 1, 1);

        insert testQuote;
        
        Test.startTest();
        
        QuotePreviewSample stzbp = new QuotePreviewSample(new ApexPages.StandardController(testQuote));
        /* CASE 4: Quote not successfully sent to Z-Billing */
        //Set test result success to false
        testZBillingResult.success = true;
        testZBillingResult.message = 'test error message';
        
        Type customCreateOrderPlugin = Type.forName('QuotePreviewSample.CreateOrderPlugin');
        QuotePreviewSample.CreateOrderPlugin pluginInstance = (QuotePreviewSample.CreateOrderPlugin) customCreateOrderPlugin.newInstance();

        //User clicks create order
        PageReference failurePage = pluginInstance.CreateOrder(stzbp);

        //Verify failure message was posted to current page
        System.assertEquals(null, failurePage);
        System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.CONFIRM));
    
        Test.stopTest();
    }

    //Mock ZBilling result for testing purposes
    public static zqu.zQuoteUtil.ZBillingResult testZBillingResult {
        get {
            if(testZBillingResult == null) testZBillingResult = new zqu.zQuoteUtil.ZBillingResult();
            return testZBillingResult;
        }
        private set;
    }
}