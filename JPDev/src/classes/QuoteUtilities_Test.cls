/*******************************************************************
// 
// Description   : Class that tests the functionality of QuoteUtilities.cls
//     
********************************************************************/
@isTest
private class QuoteUtilities_Test {
    
    static testMethod void TestScenario1() {


        ApexPages.Standardcontroller sc;

        NewOpportunityController_Test.CreateData();
        QuoteData_Test.CreateAttributeCustomSettings();
        QuoteData_Test.CreateZuoraProductRecords();

        List<zqu__ProductRatePlan__c> prpToAdd = [SELECT Id FROM zqu__ProductRatePlan__c WHERE zqu__ZuoraId__c = 'PRPTEST001' LIMIT 5];
        String prpToAddToQuote;
        if (!prpToAdd.isEmpty()) prpToAddToQuote = prpToAdd[0].Id;

        String sourceOppId;
        
        List<Opportunity> oppList = [SELECT Id, AccountId, OwnerId, Owner.Name, Owner.Division, Account_Brand__c, Account_Brand__r.CS__r.Name FROM Opportunity WHERE IsClosed = false LIMIT 10];
        List<Contact> contactList = [SELECT Id FROM Contact LIMIT 10];

        if (oppList != null && !oppList.isEmpty()) {
            sourceOppId = oppList[0].Id;

            PageReference pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('oppId', sourceOppId);
        
            Test.setCurrentPage(pageRef);

            ZuoraQuoteController controller = new ZuoraQuoteController(sc);

            if (contactList != null && !contactList.isEmpty()) {
                controller.thisQuote.zqu__SoldToContact__c = contactList[0].Id;
                controller.thisQuote.zqu__BillToContact__c = contactList[0].Id;
            }

            controller.thisQuote.Name = 'Test Quote';
            controller.thisQuote.zqu__Opportunity__c = sourceOppId;
            controller.thisQuote.BrandTag__c = 'Dice';
            controller.thisQuote.IsSyncing__c = true;
            controller.thisQuote.zqu__ValidUntil__c = System.Date.today().addDays(5);
            controller.thisQuote.Billing_Frequency__c = 'Annual';
            controller.thisQuote.zqu__Currency__c = 'USD';
            controller.thisQuote.zqu__PaymentTerm__c = 'Due Upon Receipt';
            controller.thisQuote.zqu__PaymentMethod__c = 'Credit Card';
            controller.thisQuote.zqu__StartDate__c = controller.thisQuote.zqu__ValidUntil__c;
            controller.thisQuote.zqu__Subscription_Term_Type__c = 'Termed';
            controller.thisQuote.zqu__InitialTerm__c = 12;                      

            insert controller.thisQuote;

            //Empty rate plan list
            Map<String, Decimal> resultMap = QuoteUtilities.GetEstimatedSalesTaxFromAvalara(controller.thisQuote, new List<ProductRatePlanWrapper>());

            //Add a PRP
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('PRPToAdd', prpToAddToQuote);
            Test.setCurrentPage(pageRef);
            pageRef = controller.AddProductRatePlan();

            //One rate plan
            resultMap = QuoteUtilities.GetEstimatedSalesTaxFromAvalara(controller.thisQuote, controller.selectedRatePlans);

            zqu__Quote__c preEditQuote = controller.thisQuote;
            zqu__Quote__c postEditQuote = controller.thisQuote;

            postEditQuote.zqu__PaymentMethod__c = 'Wire Transfer';          


            QuoteUtilities qu = new QuoteUtilities();

            Boolean bResult = QuoteUtilities.QuoteNeedsBillingAccountRecalculated(preEditQuote, postEditQuote); 

            RESTZuoraOperationPlugIn.ReturnClass result = QuoteUtilities.GetBillingAccount(postEditQuote, oppList[0], '');

            bResult = QuoteUtilities.QuoteNeedsBillingAccountRecalculated(postEditQuote, postEditQuote);
            System.assertEquals(false, bResult);

            String sTemplateName = QuoteUtilities.CalcQuotesInvoiceTemplateName(preEditQuote, postEditQuote);

            Invoice_Template__c it = QuoteUtilities.GetInvoiceTemplate(postEditQuote);
        }

        Integer i = QuoteUtilities.GetPeriodNumber('gibberish');
        System.assertEquals(0, i);

        Map<Id, List<zqu__ProductRatePlanChargeTier__c>> prpctMap = QuoteUtilities.GetTierMapBasedOnPRPCharges(new Set<Id>(), 'USD');

        Date startDT = Date.newInstance(2015, 02, 03);    //feb 3, 2015
        Date endDT = startDT.addDays(-3).addMonths(3);
        i = QuoteUtilities.CalculateChargeLineTerm(startDT, endDT);
        system.assertEquals(i, startDT.monthsBetween(endDT) + 1);

        //One-time should always yield only one invoice required.
        Decimal d = QuoteUtilities.NumberofInvoicesRequired(24, 'One-Time');
        System.assertEquals(d, 1);

        //1 is the fail-safe
        d = QuoteUtilities.NumberofInvoicesRequired(24, 'gibberish');
        System.assertEquals(d, 1);  

        //Now for the rendering coverage...
        zqu__ProductRatePlan__c prp = new zqu__ProductRatePlan__c();
        zqu__ProductRatePlanCharge__c prpc = new zqu__ProductRatePlanCharge__c();

        QCAttributeLogic qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'Notes__c', prpc, false);
        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'Country__c', prpc, false);

        prpc.zqu__Model__c = 'Per Unit';
        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'FakeQuantity__c', prpc, false);
        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'SalesRepId__c', prpc, false);

        prp.RatePlanPricingModel__c = 'List Price';
        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'zqu__ListPriceDisplay__c', prpc, false);
        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'ServiceStart__c', prpc, false);
        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'ServiceEnd__c', prpc, false);

        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'Event__c', prpc, false);

        prpc.zqu__Type__c = 'garbledeegook';
        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'zqu__Period__c', prpc, false);
        System.assertEquals(qca.isVisible, true);

        prp.RatePlanPricingModel__c = 'Custom Pricing';
        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'zqu__EffectivePrice__c', prpc, false);
        System.assertEquals(qca.isVisible, true);
        System.assertEquals(qca.isEditable, true);

        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'zqu__Model__c', prpc, false);
        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'zqu__UOM__c', prpc, false);

        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'ChargeLineTerm__c', prpc, false);

        //garbage should be false, false
        qca = QuoteUtilities.CalcQuoteChargeRendering(prp, 'garbage', prpc, false);
        System.assertEquals(qca.isEditable, false);        
        System.assertEquals(qca.isVisible, false);

        Boolean approvalCheck = QuoteUtilities.IsOpportunityWaitingOnApproval(sourceOppId);

        System.assertEquals(null, QuoteUtilities.ReturnRestrictedFromWhereClauseForCPQ('Blah blah blah'));

        QuoteChargeWrapper qcw = new QuoteChargeWrapper();
        zqu__QuoteCharge__c qc = new zqu__QuoteCharge__c();
        qc.zqu__Period__c = '';
        qc.zqu__ChargeType__c = 'One-Time';
        qcw.quoteCharge = qc;
        Boolean b = QuoteUtilities.InvoiceQC(1, qcw);
        System.assertEquals(b, true);

        qcw = new QuoteChargeWrapper();
        qc = new zqu__QuoteCharge__c();
        qc.zqu__Period__c = '';
        qc.zqu__ChargeType__c = 'One-Time';
        qcw.quoteCharge = qc;
        b = QuoteUtilities.InvoiceQC(2, qcw);
        System.assertEquals(b, false);

        qcw = new QuoteChargeWrapper();
        qc = new zqu__QuoteCharge__c();
        qc.zqu__Period__c = 'annual';
        qc.zqu__ChargeType__c = 'Recurring';
        qcw.quoteCharge = qc;
        b = QuoteUtilities.InvoiceQC(13, qcw);
        System.assertEquals(b, true);

        //the following should never happen - it just covers the last 'return false' statement in the function.
        //it's deliberately bad data.
        qcw = new QuoteChargeWrapper();
        qc = new zqu__QuoteCharge__c();
        qc.zqu__Period__c = 'biannual';     //not valid - will return false
        qc.zqu__ChargeType__c = 'Recurring';
        qcw.quoteCharge = qc;
        b = QuoteUtilities.InvoiceQC(13, qcw);
        System.assertEquals(b, false);

        qcw = new QuoteChargeWrapper();
        qc = new zqu__QuoteCharge__c();
        qc.zqu__Period__c = '';
        qc.zqu__ChargeType__c = 'Recurring';
        qcw.quoteCharge = qc;
        b = QuoteUtilities.InvoiceQC(13, qcw);
        System.assertEquals(b, false); 

        Set<Id> filteredRatePlans = QuoteUtilities.FilteredRatePlans('USD', System.today().addMonths(-12));

        Date newFirstBillDate = QuoteUtilities.ReturnFirstBillDate(null, null);
        System.assertEquals(null, newFirstBillDate);

        newFirstBillDate = QuoteUtilities.ReturnFirstBillDate(Date.newInstance(System.today().year(), System.today().month(), System.today().day()), null);
        System.assertEquals(null, newFirstBillDate);

        newFirstBillDate = QuoteUtilities.ReturnFirstBillDate(Date.newInstance(System.today().year(), System.today().month(), System.today().day()), Date.newInstance(System.today().year(), System.today().month(), System.today().day()));
        System.assertEquals(Date.newInstance(System.today().year(), System.today().month(), System.today().day()), newFirstBillDate);        

        newFirstBillDate = QuoteUtilities.ReturnFirstBillDate(Date.newInstance(System.today().year(), System.today().month(), System.today().day()), Date.newInstance(System.today().year()+1, System.today().month(), System.today().day()));
        System.assertEquals(Date.newInstance(System.today().year()+1, System.today().month(), System.today().day()), newFirstBillDate);        

        newFirstBillDate = QuoteUtilities.ReturnFirstBillDate(Date.newInstance(System.today().year(), System.today().month()+1, System.today().day()), Date.newInstance(System.today().year()+1, System.today().month(), System.today().day()));
        System.assertEquals(Date.newInstance(System.today().year()+1, System.today().month(), System.today().day()), newFirstBillDate);        

        newFirstBillDate = QuoteUtilities.ReturnFirstBillDate(Date.newInstance(System.today().year(), System.today().month()-1, System.today().day()), Date.newInstance(System.today().year()+1, System.today().month(), System.today().day()));
        System.assertEquals(Date.newInstance(System.today().year()+1, System.today().month(), System.today().day()), newFirstBillDate);                
    }
}