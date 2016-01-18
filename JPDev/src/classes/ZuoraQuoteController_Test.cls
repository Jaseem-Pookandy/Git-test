/*******************************************************************
Name  : ZuoraQuoteController_Test
Author: Byrnes
Date  : 2014.09.02
*************************************************************************/
@isTest
private class ZuoraQuoteController_Test {
    
    static testMethod void testMethodFailure() {

        ApexPages.Standardcontroller sc;

        NewOpportunityController_Test.CreateData();
        
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE IsClosed = false LIMIT 10];

        if (oppList != null && !oppList.isEmpty()) {
            String sourceOppId = oppList[0].Id;

            PageReference pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('oppId', sourceOppId);
        
            Test.setCurrentPage(pageRef);
                    
            ZuoraQuoteController controller = new ZuoraQuoteController(sc);     

            pageRef = controller.SwitcherooBillToClick();   //toggle to lookup
            pageRef = controller.SwitcherooSoldToClick();   //toggle to lookup
            pageRef = controller.SwitcherooBillToClick();   //toggle back to picklist
            pageRef = controller.SwitcherooSoldToClick();   //toggle back to picklist

            pageRef = controller.Cancel();
            pageRef = controller.ValidateStep1();

            pageRef = controller.SaveItAll();
            System.assertEquals(pageRef, null);                        
        }
    }

    static testMethod void testMethodSuccess() {

        ApexPages.Standardcontroller sc;

        NewOpportunityController_Test.CreateData();
        QuoteData_Test.CreateAttributeCustomSettings();
        QuoteData_Test.CreateZuoraProductRecords();

        List<zqu__ProductRatePlan__c> prpToAdd = [SELECT Id FROM zqu__ProductRatePlan__c WHERE RatePlanPricingModel__c = 'List Pricing' LIMIT 5];
        String prpToAddToQuote;
        if (!prpToAdd.isEmpty()) prpToAddToQuote = prpToAdd[0].Id;
        
        List<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity WHERE IsClosed = false LIMIT 10];
        List<Contact> contactList = [SELECT Id FROM Contact LIMIT 10];

        if (oppList != null && !oppList.isEmpty()) {
            String sourceOppId = oppList[0].Id;

            Test.startTest();

            //Insert a subscription now for the ol' prior bill to contacts...
            Zuora__CustomerAccount__c ca = new Zuora__CustomerAccount__c();         
            ca.Zuora__Account__c = oppList[0].AccountId;
            ca.BrandTag__c = 'Dice';
            ca.Zuora__Currency__c = 'USD';
            ca.Zuora__Status__c = 'Active';
            insert ca;

            Zuora__Subscription__c sub = new Zuora__Subscription__c();
            sub.Zuora__CustomerAccount__c = ca.Id;
            sub.Name = 'Fake Subscription';
            sub.Zuora__Account__c = oppList[0].AccountId;
            sub.Zuora__Zuora_Id__c = '1234567890';
            insert sub;

            PageReference pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('oppId', sourceOppId);
        
            Test.setCurrentPage(pageRef);
                    
            ZuoraQuoteController controller = new ZuoraQuoteController(sc);

            pageRef = controller.SwitcherooBillToClick();   //toggle to lookup
            pageRef = controller.SwitcherooSoldToClick();   //toggle to lookup
            pageRef = controller.SwitcherooBillToClick();   //toggle to lookup
            pageRef = controller.SwitcherooSoldToClick();   //toggle to lookup          

            if (contactList != null && !contactList.isEmpty()) {
                controller.thisQuote.zqu__SoldToContact__c = contactList[0].Id;
                controller.thisQuote.zqu__BillToContact__c = contactList[0].Id;
            }

            controller.thisQuote.Name = 'Test Quote';
            controller.thisQuote.zqu__Opportunity__c = sourceOppId;
            controller.thisQuote.BrandTag__c = 'Dice';
            controller.thisQuote.zqu__ValidUntil__c = System.Date.today().addDays(5);
            controller.thisQuote.Billing_Frequency__c = 'Annual';
            controller.thisQuote.zqu__Currency__c = 'USD';
            controller.thisQuote.zqu__PaymentTerm__c = 'Due Upon Receipt';
            controller.thisQuote.zqu__PaymentMethod__c = 'Credit Card';
            controller.thisQuote.zqu__StartDate__c = controller.thisQuote.zqu__ValidUntil__c;
            controller.thisQuote.zqu__Subscription_Term_Type__c = 'Termed';
            controller.thisQuote.zqu__InitialTerm__c = 12;                      
            controller.thisQuote.Service_End_Date__c = controller.thisQuote.zqu__StartDate__c.addMonths(Integer.valueOf(controller.thisQuote.zqu__InitialTerm__c));

            pageRef = controller.PopulatePriorBillingAccounts();
            System.assertEquals(pageRef, null);

            pageRef = controller.SaveItAll();            
            System.assertNotEquals(pageRef, null);

            pageRef = controller.Cancel();
            System.assertNotEquals(pageRef, null);

            pageRef = controller.ValidateStep1();
            System.assertEquals(pageRef, null);                 

            //Now go back and edit it...
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('Id', controller.thisQuote.Id);
            pageRef.getParameters().put('retURL', sourceOppId);
            Test.setCurrentPage(pageRef);
            controller = new ZuoraQuoteController(sc);

            controller.thisQuote.zqu__PaymentTerm__c = 'Net 60';

            pageRef = controller.SaveQuoteOnly();
            pageRef = controller.SaveItAll();   
            System.assertNotEquals(pageRef, null);

            pageRef = controller.KickFromEditIfReadOnly();
            System.assertEquals(pageRef, null);

            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('PRPToAdd', prpToAddToQuote);
            Test.setCurrentPage(pageRef);
            pageRef = controller.AddProductRatePlan();

            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('DynamicParamName', 'MethodToExecute:blahblahblahblahIdfield');
            Test.setCurrentPage(pageRef);
            pageRef = controller.ProcessDynamicPostbackAction();
            System.assertEquals(pageRef, null);

            ZuoraQuoteController.FilterPreset fp = new ZuoraQuoteController.FilterPreset();
            String s = fp.GetOLIBrandTag;
            s = fp.GetOLICountry;
            s = fp.GetOLIProductGroup;

            //SetFilter pagereference
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('filterId', 'fakeFilterId');
            Test.setCurrentPage(pageRef);
            pageRef = controller.SetFilter();

            pageRef = controller.ReturnToOpp();
            System.assertNotEquals(pageRef, null);

            pageRef = controller.ReturnToQuote();
            System.assertNotEquals(pageRef, null);

            pageRef = controller.CalcServiceEndDateWipeProducts();
            System.assertEquals(pageRef, null);

            pageRef = controller.PRPSaleTypeValueChanged();
            System.assertEquals(pageRef, null);

            test.stopTest();
        }
    } 

    static testMethod void testMethodEdit() {

        ApexPages.Standardcontroller sc;

        NewOpportunityController_Test.CreateData();
        QuoteData_Test.CreateAttributeCustomSettings();
        QuoteData_Test.CreateZuoraProductRecords();

        List<zqu__ProductRatePlan__c> prpToAdd = [SELECT Id FROM zqu__ProductRatePlan__c WHERE zqu__ZuoraId__c = 'PRPTEST001' LIMIT 5];
        String prpToAddToQuote;
        if (!prpToAdd.isEmpty()) prpToAddToQuote = prpToAdd[0].Id;
        
        List<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity WHERE IsClosed = false LIMIT 10];
        List<Contact> contactList = [SELECT Id FROM Contact LIMIT 10];

        if (oppList != null && !oppList.isEmpty()) {
            String sourceOppId = oppList[0].Id;

            Test.startTest();

            //Insert a subscription now for the ol' prior bill to contacts...
            Zuora__CustomerAccount__c ca = new Zuora__CustomerAccount__c();         
            ca.Zuora__Account__c = oppList[0].AccountId;
            ca.BrandTag__c = 'Dice';
            ca.Zuora__Currency__c = 'USD';
            ca.Zuora__Status__c = 'Active';
            insert ca;

            Zuora__Subscription__c sub = new Zuora__Subscription__c();
            sub.Zuora__CustomerAccount__c = ca.Id;
            sub.Name = 'Fake Subscription';
            sub.Zuora__Account__c = oppList[0].AccountId;
            sub.Zuora__Zuora_Id__c = '1234567890';
            insert sub;

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
            controller.thisQuote.zqu__ValidUntil__c = System.Date.today().addDays(5);
            controller.thisQuote.Billing_Frequency__c = 'Annual';
            controller.thisQuote.zqu__Currency__c = 'USD';
            controller.thisQuote.zqu__PaymentTerm__c = 'Due Upon Receipt';
            controller.thisQuote.zqu__PaymentMethod__c = 'Credit Card';
            controller.thisQuote.zqu__StartDate__c = controller.thisQuote.zqu__ValidUntil__c;
            controller.thisQuote.zqu__Subscription_Term_Type__c = 'Termed';
            controller.thisQuote.zqu__InitialTerm__c = 12;                      
            controller.thisQuote.Service_End_Date__c = controller.thisQuote.zqu__StartDate__c.addMonths(Integer.valueOf(controller.thisQuote.zqu__InitialTerm__c));

            pageRef = controller.SaveQuoteOnly();            
            System.assertNotEquals(pageRef, null);

            //Now go back and edit it...
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('Id', controller.thisQuote.Id);
            pageRef.getParameters().put('retURL', sourceOppId);
            Test.setCurrentPage(pageRef);
            controller = new ZuoraQuoteController(sc);

            controller.thisQuote.zqu__PaymentTerm__c = 'Net 60';

            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('PRPToAdd', prpToAddToQuote);
            Test.setCurrentPage(pageRef);
            pageRef = controller.AddProductRatePlan();

            //add it twice
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('PRPToAdd', prpToAddToQuote);
            Test.setCurrentPage(pageRef);
            pageRef = controller.AddProductRatePlan();                        

            zqu__ProductRatePlanCharge__c prpCharge = new zqu__ProductRatePlanCharge__c();
            zqu__QuoteCharge__c quoteCharge = new zqu__QuoteCharge__c();

            for (ProductRatePlanWrapper prpw : controller.selectedRatePlans) {
                for (QuoteChargeWrapper qcw : prpw.quoteChargeWrappers) {
                    qcw.quoteCharge.FakeQuantity__c = 1;         
                    qcw.quoteCharge.ServiceStart__c = system.today();
                    qcw.quoteCharge.ServiceEnd__c = system.today().addYears(1);
                    qcw.Country = 'United States of Awesome';
                    qcw.quoteCharge.Country__c = 'United States of Awesome';    
                    qcw.quoteCharge.SalesRepId__c = Userinfo.getUserId();      
                    if (!qcw.isDiscountCharge) qcw.quoteCharge.zqu__EffectivePrice__c = 123.45;          
                    else qcw.quoteCharge.zqu__EffectivePrice__c = 10;

                    quoteCharge = qcw.quoteCharge;
                    prpCharge = prpw.prpCharges[0];
                }
            }

            pageRef = Page.ZuoraQuote;
            system.assertEquals(controller.selectedRatePlans.size(), 2);
            pageRef.getParameters().put('rowToDelete', '1');
            Test.setCurrentPage(pageRef);
            controller.DeleteProductRatePlanRow();

            pageRef = controller.PopulatePriorBillingAccounts();
            System.assertEquals(pageRef, null);
            pageRef = controller.PopulatePriorBillingAccountsBecauseCurrencyMayHaveChanged();
            System.assertEquals(pageRef, null);

            pageRef = controller.SwitcherooBillToClick();   //toggle to lookup
            System.assertEquals(pageRef, null);
            pageRef = controller.SwitcherooSoldToClick();   //toggle to lookup
            System.assertEquals(pageRef, null);
            pageRef = controller.SwitcherooBillToClick();   //toggle to lookup
            System.assertEquals(pageRef, null);
            pageRef = controller.SwitcherooSoldToClick();   //toggle to lookup          
            System.assertEquals(pageRef, null);

            pageRef = controller.ValidateStep1();
            System.assertEquals(pageRef, null);

            pageRef = controller.KickFromEditIfReadOnly();
            pageRef = controller.CalcServiceEndDateWipeProducts();
            System.assertEquals(pageRef, null);

            pageRef = controller.CalcServiceEndDate();
            System.assertEquals(pageRef, null);


            Boolean b = controller.ValidateQuoteChargeDetails();            

            pageRef = controller.SetFilter();
            
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('DynamicParamName', 'blahblahblah:morelbahlbahlbha');
            Test.setCurrentPage(pageRef);
            pageRef = controller.ProcessDynamicPostbackAction();
            System.assertEquals(pageRef, null);

            controller.thisQuote.Discount_Percent__c = 5;
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('sourceField', 'Discount_Percent__c');
            Test.setCurrentPage(pageRef);           
            pageRef = controller.RecalcTheQuoteNumbers();

            controller.thisQuote.Discount_Fixed__c = 5;
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('sourceField', 'Discount_Fixed__c');
            Test.setCurrentPage(pageRef);           
            pageRef = controller.RecalcTheQuoteNumbers();

            controller.thisQuote.Discount_New_Net__c = 5;
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('sourceField', 'Discount_New_Net__c');
            Test.setCurrentPage(pageRef);           
            pageRef = controller.RecalcTheQuoteNumbers();

            controller.thisQuote.Discount_Percent__c = 0;
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('sourceField', 'Discount_Percent__c');
            Test.setCurrentPage(pageRef);           
            pageRef = controller.RecalcTheQuoteNumbers();

            controller.thisQuote.Discount_Fixed__c = 0;
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('sourceField', 'Discount_Fixed__c');
            Test.setCurrentPage(pageRef);           
            pageRef = controller.RecalcTheQuoteNumbers();

            controller.thisQuote.Discount_New_Net__c = 0;
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('sourceField', 'Discount_New_Net__c');
            Test.setCurrentPage(pageRef);           
            pageRef = controller.RecalcTheQuoteNumbers();

            system.assertEquals(0, controller.thisQuote.Discount_Fixed__c);

            pageRef = controller.WipeDiscountValues();

            ZuoraQuoteController.FilterPreset fp = new ZuoraQuoteController.FilterPreset();
            String s = fp.GetOLICountry;
            s = fp.GetOLIBrandTag;
            s = fp.GetOLIProductGroup;
            
            pageRef = controller.WipeDiscountValues();
            System.assertEquals(pageRef, null);

            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('sourceField', 'Discount_New_Net__c');
            Test.setCurrentPage(pageRef);
            controller.thisQuote.Discount_New_Net__c = 5;
            pageRef = controller.RecalcTheQuoteNumbers();
            System.assertEquals(pageRef, null);            

            //System.assertNotEquals(pageRef, null);

            //Now go back and edit it now that charges have been added...
            //pageRef = Page.ZuoraQuote;
            //pageRef.getParameters().put('Id', controller.thisQuote.Id);
            //pageRef.getParameters().put('retURL', sourceOppId);
            //Test.setCurrentPage(pageRef);

            //ProductRatePlanWrapper prpw = controller.selectedRatePlans[0];
            //prpw.AddProductRatePlanWithExistingQuoteCharge(prpCharge, quoteCharge, 4, new List<QuoteChargeAttributes__c>(), controller.sourceOpp, 'United States of Awesome', controller.thisQuote);
            //prpw.AppendExistingQuoteCharge(prpCharge, quoteCharge, new List<QuoteChargeAttributes__c>(), controller.sourceOpp, 'United States of Awesome', controller.thisQuote);

            //pageRef = controller.PopulatePriorBillingAccountsBecauseCurrencyMayHaveChanged();
            //System.assertEquals(pageRef, null);

            //pageRef = controller.CalcServiceEndDate();
            //System.assertEquals(pageRef, null);

            //pageRef = Page.ZuoraQuote;
            //pageRef.getParameters().put('sourceField', 'Discount_Percent__c');
            //Test.setCurrentPage(pageRef);

            test.stopTest();
        }
    } 

    static testMethod void testMethodEditTwo() {

        ApexPages.Standardcontroller sc;

        NewOpportunityController_Test.CreateData();
        QuoteData_Test.CreateAttributeCustomSettings();
        QuoteData_Test.CreateZuoraProductRecords();

        List<zqu__ProductRatePlan__c> prpToAdd = [SELECT Id FROM zqu__ProductRatePlan__c WHERE zqu__ZuoraId__c = 'PRPTEST001' LIMIT 5];
        String prpToAddToQuote;
        if (!prpToAdd.isEmpty()) prpToAddToQuote = prpToAdd[0].Id;
        
        List<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity WHERE IsClosed = false LIMIT 10];
        List<Contact> contactList = [SELECT Id FROM Contact LIMIT 10];

        if (oppList != null && !oppList.isEmpty()) {
            String sourceOppId = oppList[0].Id;

            Test.startTest();

            //Insert a subscription now for the ol' prior bill to contacts...
            Zuora__CustomerAccount__c ca = new Zuora__CustomerAccount__c();         
            ca.Zuora__Account__c = oppList[0].AccountId;
            ca.BrandTag__c = 'Dice';
            ca.Zuora__Currency__c = 'USD';
            ca.Zuora__Status__c = 'Active';
            insert ca;

            Zuora__Subscription__c sub = new Zuora__Subscription__c();
            sub.Zuora__CustomerAccount__c = ca.Id;
            sub.Name = 'Fake Subscription';
            sub.Zuora__Account__c = oppList[0].AccountId;
            sub.Zuora__Zuora_Id__c = '1234567890';
            insert sub;

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
            controller.thisQuote.zqu__ValidUntil__c = System.Date.today().addDays(5);
            controller.thisQuote.Billing_Frequency__c = 'Annual';
            controller.thisQuote.zqu__Currency__c = 'USD';
            controller.thisQuote.zqu__PaymentTerm__c = 'Due Upon Receipt';
            controller.thisQuote.zqu__PaymentMethod__c = 'Credit Card';
            controller.thisQuote.zqu__StartDate__c = controller.thisQuote.zqu__ValidUntil__c;
            controller.thisQuote.zqu__Subscription_Term_Type__c = 'Termed';
            controller.thisQuote.zqu__InitialTerm__c = 12;                      
            controller.thisQuote.Service_End_Date__c = controller.thisQuote.zqu__StartDate__c.addMonths(Integer.valueOf(controller.thisQuote.zqu__InitialTerm__c));

            pageRef = controller.SaveQuoteOnly();            
            System.assertNotEquals(pageRef, null);

            //Now go back and edit it...
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('Id', controller.thisQuote.Id);
            pageRef.getParameters().put('retURL', sourceOppId);
            Test.setCurrentPage(pageRef);
            controller = new ZuoraQuoteController(sc);

            controller.thisQuote.zqu__PaymentTerm__c = 'Net 60';

            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('PRPToAdd', prpToAddToQuote);
            Test.setCurrentPage(pageRef);
            pageRef = controller.AddProductRatePlan();

            //add it twice
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('PRPToAdd', prpToAddToQuote);
            Test.setCurrentPage(pageRef);
            pageRef = controller.AddProductRatePlan();                        

            zqu__ProductRatePlanCharge__c prpCharge = new zqu__ProductRatePlanCharge__c();
            zqu__QuoteCharge__c quoteCharge = new zqu__QuoteCharge__c();

            for (ProductRatePlanWrapper prpw : controller.selectedRatePlans) {
                for (QuoteChargeWrapper qcw : prpw.quoteChargeWrappers) {
                    qcw.quoteCharge.FakeQuantity__c = 1;         
                    qcw.quoteCharge.ServiceStart__c = system.today();
                    qcw.quoteCharge.ServiceEnd__c = system.today().addYears(1);
                    qcw.Country = 'United States of Awesome';
                    qcw.quoteCharge.Country__c = 'United States of Awesome';    
                    qcw.quoteCharge.SalesRepId__c = Userinfo.getUserId();      
                    if (!qcw.isDiscountCharge) qcw.quoteCharge.zqu__EffectivePrice__c = 123.45;          
                    else qcw.quoteCharge.zqu__EffectivePrice__c = 10;

                    quoteCharge = qcw.quoteCharge;
                    prpCharge = prpw.prpCharges[0];
                }
            }

            pageRef = controller.PopulatePriorBillingAccounts();
            System.assertEquals(pageRef, null);
            pageRef = controller.PopulatePriorBillingAccountsBecauseCurrencyMayHaveChanged();
            System.assertEquals(pageRef, null);

            pageRef = controller.ValidateStep1();
            System.assertEquals(pageRef, null);

            pageRef = controller.CalcServiceEndDateWipeProducts();
            System.assertEquals(pageRef, null);

            pageRef = controller.CalcServiceEndDate();
            System.assertEquals(pageRef, null);

            Boolean b = controller.ValidateQuoteChargeDetails();            

            pageRef = controller.SetFilter();
            
            controller.thisQuote.Discount_Percent__c = 5;
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('sourceField', 'Discount_Percent__c');
            Test.setCurrentPage(pageRef);           
            pageRef = controller.RecalcTheQuoteNumbers();

            controller.thisQuote.Discount_Fixed__c = 5;
            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('sourceField', 'Discount_Fixed__c');
            Test.setCurrentPage(pageRef);           
            pageRef = controller.RecalcTheQuoteNumbers();

            pageRef = Page.ZuoraQuote;
            pageRef.getParameters().put('sourceField', 'Discount_New_Net__c');
            Test.setCurrentPage(pageRef);           
            controller.thisQuote.Discount_New_Net__c = 5;
            pageRef = controller.RecalcTheQuoteNumbers();
            System.assertEquals(pageRef, null);          

            ZuoraQuoteController.FilterPreset fp = new ZuoraQuoteController.FilterPreset();
            String s = fp.GetOLICountry;
            s = fp.GetOLIBrandTag;
            s = fp.GetOLIProductGroup;              

            test.stopTest();

            pageRef = controller.SaveItAll();
            //System.assertNotEquals(pageRef, null);

            
        }
    }     
}