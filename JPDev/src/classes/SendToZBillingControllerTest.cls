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
public with sharing class SendToZBillingControllerTest {

    public static Account createAccount()
    {

        Account testAcc = new Account();

        testAcc.Name = 'testAccount';
        testAcc.BillingCity = 'Somewhere';
        testAcc.BillingState = 'CA';
        testAcc.BillingCountry = 'USA';
        testAcc.BillingPostalCode = '12345';
        testAcc.BillingStreet = '123';
        testAcc.Tax_Number__c = '123567';
        testAcc.Tax_Exempt_Certificate_ID__c = '1234567890';

        return testAcc;

    }

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

        return testcon;
    }


    public static Zuora__Subscription__c createSubscription()
    {

        Zuora__Subscription__c testsub = new Zuora__Subscription__c();

        testsub.name = 'testconfirst';
        testsub.Zuora__Zuora_Id__c = '12345';

        return testsub;
    }


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
        
        testOpp.PO_Number__c = 'PO# 123';
        
        testOpp.IO_Number__c = 'IO# 123';

        return testOpp;
    }

    public static OpportunityContactRole createOpportunityContactRole(Opportunity opp, Contact con)
    {

        OpportunityContactRole testocr = new OpportunityContactRole();

        testocr.IsPrimary = true;

        testocr.ContactId = con.Id;

        testocr.OpportunityId = opp.Id;

        return testocr;
    }

    public static zqu__Quote__c createQuote(Contact con, Opportunity opp)
    {
        zqu__Quote__c testQuote = new zqu__Quote__c();

        testQuote.name = 'testopp';

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

        testQuote.zqu__RecordReadOnly__c = false;

        testQuote.zqu__Status__c = 'New';

        testQuote.zqu__StartDate__c = date.newinstance(2012, 1, 1);

        testQuote.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);

        testQuote.zqu__SubscriptionTermEndDate__c = date.newinstance(2013, 1, 1);
        
        testQuote.BrandTag__c = 'Dice';
        
        testQuote.zqu__ZuoraSubscriptionID__c = '12345';

        return testQuote;
    }
    
    public static zqu__Quote__c createQuote2(Contact con, Opportunity opp)
    {
        zqu__Quote__c testQuote = new zqu__Quote__c();

        testQuote.name = 'testquote';

        testQuote.zqu__Opportunity__c = opp.Id;

        testQuote.zqu__BillToContact__c = con.Id;

        Contact soldTo = createContact();  

        insert soldTo;
        
        testQuote.zqu__ZuoraAccountID__c = '123456789123';

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

        testQuote.zqu__RecordReadOnly__c = false;

        testQuote.zqu__Status__c = 'New';

        testQuote.zqu__StartDate__c = date.newinstance(2012, 1, 1);

        testQuote.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);

        testQuote.zqu__SubscriptionTermEndDate__c = date.newinstance(2013, 1, 1);
        
        testQuote.BrandTag__c = 'Dice';
        
        testQuote.zqu__ZuoraSubscriptionID__c = '12345';

        return testQuote;
    }

    public static zqu__QuoteAmendment__c makeQuoteAmendment(zqu__Quote__c testQuote)
    {
        zqu__QuoteAmendment__c  testAmend = new zqu__QuoteAmendment__c();

        testAmend.Name = 'testAmend';

        testAmend.zqu__Quote__c = testQuote.Id;

        testAmend.zqu__Status__c = 'Completed';

        testAmend.zqu__Type__c = 'New Product';

        insert testAmend;

        return testAmend;
    }

    public static zqu__QuoteRatePlan__c makeRatePlan(zqu__Quote__c testQuote)
    {
        zqu__QuoteRatePlan__c testPlan = new zqu__QuoteRatePlan__c();

        testPlan.zqu__Quote__c = testQuote.Id;

        testPlan.zqu__AmendmentType__c = 'New Product';

        testPlan.zqu__QuoteProductName__c = 'test product';

        testPlan.zqu__ProductRatePlanZuoraId__c = '123';

        testPlan.zqu__QuoteAmendment__c = makeQuoteAmendment(testQuote).Id;     

        insert testPlan;

        return testPlan;
    }

    public static zqu__ProductRatePlanCharge__c makeProductRatePlanCharge(String prp)
    {
        zqu__ProductRatePlanCharge__c testprpc = new zqu__ProductRatePlanCharge__c();

        testprpc.name='new rate plan charge';

        testprpc.zqu__ZuoraId__c = '1234';

        testprpc.zqu__ProductRatePlan__c = prp;

        insert testprpc;

        return testprpc;

    }

    public static zqu__ProductRatePlan__c makeProductRatePlan(String zproduct)
    {
        zqu__ProductRatePlan__c testrp = new zqu__ProductRatePlan__c();

        testrp.name = 'test rp';

        testrp.Brand__c = 'Dice';

        testrp.BrandTag__c = 'Dice';

        testrp.zqu__ZProduct__c = zproduct;

        testrp.zqu__ZuoraId__c = '1234';

        insert testrp;

        return testrp;
    }

    public static zqu__ZProduct__c makeProduct()
    {
        zqu__ZProduct__c testProduct = new zqu__ZProduct__c();

        //testProduct.Id = '123';

        testProduct.Name = 'testing';

        testProduct.zqu__SKU__c = 'testSKU';

        testProduct.zqu__ZuoraId__c = '1234';

        insert testProduct;

        return testProduct;
    } 

public static testMethod void testSendToZbillingController()
    {
        testUtils.createBrands();

        Account testAcc = createAccount();
        insert testAcc;

        Account_Brand__c abObj = new Account_Brand__c();
        abObj.Brand_Picklist__c = 'Dice';
        abObj.Account__c = testAcc.Id;
        //abObj.Primary_Owner__c = userList.get(0).Id;
        //abObj.CS__c = userList.get(1).Id;
        abObj.Status__c = 'Active';
        insert abObj;

        Contact testcon = createContact();
        insert testcon;

        Opportunity testOpp = createOpportunity(testAcc);
        insert testOpp;

        OpportunityContactRole testocr = createOpportunityContactRole(testOpp, testCon);
        insert testocr;   

Test.startTest();        

        zqu__Quote__c testQuote = createQuote(testCon, testOpp);
        testQuote.IsSyncing__c = true;
        insert testQuote; 
        
        Zuora__Subscription__c  testsub1 = createSubscription();
        testsub1.Zuora__Account__c = testAcc.Id;
        testsub1.BrandTag__c = 'Dice';
        insert  testsub1;         
        update testsub1;  

        testOpp.ZuoraSubscription__c = testSub1.Id;
        update testOpp;
        
        zqu__ZProduct__c zP = makeProduct();
        zqu__ProductRatePlan__c zPRP = makeProductRatePlan(zp.Id);

        Zuora__SubscriptionProductCharge__c testpc = new Zuora__SubscriptionProductCharge__c();
        testpc.name = 'test product charge'; 
        testpc.Zuora__Zuora_Id__c = '12345'; 
        testpc.Zuora__Subscription__c = testsub1.id;   
        testpc.Product_Rate_Plan__c = zPRP.Id;
        testpc.Zuora__Account__c = testAcc.Id;
        insert testpc;
        upsert testpc;
        
        ApexPages.StandardController controller = new ApexPages.StandardController(testQuote);
        SendToZBillingController mstzpc = new SendToZBillingController(controller);

        delete testpc;
        delete testsub1;
        
        //mstzpc.onload();
        //mstzpc.send();
        //mstzpc.cancel();        

        Test.stopTest();
    }
    
    public static testMethod void testOppAutoRenewalGeneration()
    {
        testUtils.createBrands();

        Account testAcc = createAccount();
        insert testAcc;

        Account_Brand__c abObj = new Account_Brand__c();
        abObj.Brand_Picklist__c = 'Dice';
        abObj.Account__c = testAcc.Id;
        abObj.Status__c = 'Active';
        insert abObj;

        Contact testcon = createContact();
        insert testcon;

        Opportunity testOpp = createOpportunity(testAcc);
        insert testOpp;

        OpportunityContactRole testocr = createOpportunityContactRole(testOpp, testCon);
        insert testocr;   

Test.startTest();    

        zqu__Quote__c testQuote = createQuote(testCon, testOpp);
        testQuote.IsSyncing__c = true;
        testQuote.Zuora_Subscription_Name__c = 'fakeSub';
        insert testQuote; 

        zqu__ZProduct__c zPQ = makeProduct();
        zqu__ProductRatePlan__c zPRPQ = makeProductRatePlan(zPQ.Id);
        zqu__ProductRatePlanCharge__c zPRPCQ = makeProductRatePlanCharge(zPRPQ.Id);

        zqu__QuoteCharge__c quoteCharge = new zqu__QuoteCharge__c();
        quoteCharge.Name = 'Test QuoteCharge 001';
        quoteCharge.zqu__Quote__c = testQuote.Id;
        quoteCharge.zqu__Total__c = 3003;
        quoteCharge.zqu__ProductRatePlanCharge__c = zPRPCQ.ID;
        quoteCharge.Country__c = 'United States'; 
        insert quoteCharge;

        //testOpp.SyncedQuote__c = testQuote.Id;
        update testOpp;



        Zuora__Subscription__c  testsub1 = createSubscription();
        testsub1.Zuora__Account__c = testAcc.Id;
        testsub1.Zuora__Zuora_Id__c = 'fakeSub';
        testsub1.BrandTag__c = 'Dice';
        testsub1.Service_End_Date__c = '2014-12-31';
        insert  testsub1;    

        testsub1.Service_End_Date__c = '2020-12-31';
        update testsub1;  
  
        testOpp.ZuoraSubscription__c = testSub1.Id;
        update testOpp;        

Test.stopTest();

    }

}