@isTest (seeAllData=true)
private class CCCaptureController_Test {
    
    static testMethod void scenarioNoAuthToken() {

        ApexPages.StandardController sc;
        CCCaptureController controller = new CCCaptureController(sc);

        PageReference pageRef = Page.CCCapture;

        Test.setCurrentPage(pageRef);

        pageRef = controller.PrepthePage();

        System.assertEquals(controller.errors.size(), 1);
    }

    static testMethod void scenarioGoodAuthToken() {

        String oppId = CreateData();

        Test.startTest();
            ApexPages.StandardController sc;        

            PageReference pageRef = Page.CCCapture;
            List<Payment_Link__c> plList = [SELECT Id, Token__c, SFDC_Token_URL_Friendly__c, Opportunity__c FROM Payment_Link__c WHERE Opportunity__c = :oppId ORDER BY CreatedDate DESC LIMIT 1];

            Test.setCurrentPage(pageRef);
            CCCaptureController controller = new CCCaptureController(sc);       
            pageRef.getParameters().put('auth', plList[0].Token__c);        //because we're not truly in a browser do NOT use the urlencoded token here, instead the normal one must be used.

            pageRef = controller.PrepthePage();

            Boolean result = CCCaptureController.PostToSalesforce('************1234', plList[0].Opportunity__c, plList[0].Id, '127.0.0.1', 'Money Bags', '01', '2099', 'Discover', 'Notes go here', true, false, false, false, null, true, '01234567890123456789012345678901', '01234567890123456789012345678902');

            String message = controller.getccMessage();

            if (!controller.creditCardsInZuora.isEmpty()) {
                message = controller.creditCardsInZuora[0].headerLabel;
                message = controller.creditCardsInZuora[0].ccImageName;
                message = controller.creditCardsInZuora[0].notes;
                message = controller.creditCardsInZuora[0].expirationMonthTwoDigit;
                message = controller.creditCardsInZuora[0].expirationMonthShortAndLongForm;
                result  = controller.creditCardsInZuora[0].defaultPaymentMethod;
            }

            result = CCCaptureController.UpdatePaymentMethodInZuora('01234567890123456789012345678901', '10', '2020');

            CCCaptureController.CreditCardObject cco = CCCaptureController.CheckZuoraIfExpirationWasAltered('01234567890123456789012345678901');

            result = CCCaptureController.SubmitExistingCCToZuoraAndSFDC('444444444448', plList[0].Id, '127.0.0.1', 'Homer Simpson', '10', '2020', 'Visa', 'Notes', true, '01234567890123456789012345678901', false, false, false, '12345678901234567890123456789012', true, '98765432109876543210987654321098');

        Test.stopTest();
    }

    static testMethod void scenarioGoodAuthTokenNum2() {

        String oppId = CreateData();

        Test.startTest();
            ApexPages.StandardController sc;        

            PageReference pageRef = Page.CCCapture;
            List<Payment_Link__c> plList = [SELECT Id, Token__c, SFDC_Token_URL_Friendly__c, Opportunity__c FROM Payment_Link__c WHERE Opportunity__c = :oppId ORDER BY CreatedDate DESC LIMIT 1];

            Test.setCurrentPage(pageRef);
            CCCaptureController controller = new CCCaptureController(sc);       
            pageRef.getParameters().put('auth', plList[0].Token__c);        //because we're not truly in a browser do NOT use the urlencoded token here, instead the normal one must be used.

            pageRef = controller.PrepthePage();

            Boolean result = CCCaptureController.PostToSalesforce('************1234', plList[0].Opportunity__c, plList[0].Id, '127.0.0.1', 'Money Bags', '01', '2099', 'Discover', 'Notes go here', true, false, false, false, null, true, '01234567890123456789012345678901', '01234567890123456789012345678907');

            String message = controller.getccMessage();

            if (!controller.creditCardsInZuora.isEmpty()) {
                message = controller.creditCardsInZuora[0].headerLabel;
                message = controller.creditCardsInZuora[0].ccImageName;
                message = controller.creditCardsInZuora[0].notes;
                message = controller.creditCardsInZuora[0].expirationMonthTwoDigit;
                message = controller.creditCardsInZuora[0].expirationMonthShortAndLongForm;
                result  = controller.creditCardsInZuora[0].defaultPaymentMethod;
            }

            String s = controller.HMACToken;
            s = controller.HMACSignature;

            result = CCCaptureController.UpdatePaymentMethodInZuora('01234567890123456789012345678901', '10', '2020');

            CCCaptureController.CreditCardObject cco = CCCaptureController.CheckZuoraIfExpirationWasAltered('01234567890123456789012345678901');            

            result = CCCaptureController.SubmitExistingCCToZuoraAndSFDC('444444444448', plList[0].Id, '127.0.0.1', 'Homer Simpson', '10', '2020', 'Visa', 'Notes', false, '01234567890123456789012345678901', true, false, false, '12345678901234567890123456789012', true, '98765432109876543210987654321098');

        Test.stopTest();        
    }    

    static testMethod void scenarioGoodAuthTokenNum3() {

        String oppId = CreateData();

        Test.startTest();
            ApexPages.StandardController sc;        

            PageReference pageRef = Page.CCCapture;
            List<Payment_Link__c> plList = [SELECT Id, Token__c, SFDC_Token_URL_Friendly__c, Opportunity__c FROM Payment_Link__c WHERE Opportunity__c = :oppId ORDER BY CreatedDate DESC LIMIT 1];

            Test.setCurrentPage(pageRef);
            CCCaptureController controller = new CCCaptureController(sc);       
            pageRef.getParameters().put('auth', plList[0].Token__c);        //because we're not truly in a browser do NOT use the urlencoded token here, instead the normal one must be used.

            pageRef = controller.PrepthePage();

            Boolean result = CCCaptureController.PostToSalesforce('************1234', plList[0].Opportunity__c, plList[0].Id, '127.0.0.1', 'Money Bags', '01', '2099', 'Discover', 'Notes go here', true, false, false, false, null, true, '01234567890123456789012345678901', '01234567890123456789012345678909');

            String message = controller.getccMessage();

            if (!controller.creditCardsInZuora.isEmpty()) {
                message = controller.creditCardsInZuora[0].headerLabel;
                message = controller.creditCardsInZuora[0].ccImageName;
                message = controller.creditCardsInZuora[0].notes;
                message = controller.creditCardsInZuora[0].expirationMonthTwoDigit;
                message = controller.creditCardsInZuora[0].expirationMonthShortAndLongForm;
                result  = controller.creditCardsInZuora[0].defaultPaymentMethod;
            }

            String s = controller.HMACToken;
            s = controller.HMACSignature;

            result = CCCaptureController.UpdatePaymentMethodInZuora('01234567890123456789012345678901', '10', '2020');

            CCCaptureController.CreditCardObject cco = CCCaptureController.CheckZuoraIfExpirationWasAltered('01234567890123456789012345678901');

            result = CCCaptureController.SubmitExistingCCToZuoraAndSFDC('444444444448', plList[0].Id, '127.0.0.1', 'Homer Simpson', '10', '2020', 'Visa', 'Notes', false, '01234567890123456789012345678901', true, false, true, '12345678901234567890123456789012', true, '98765432109876543210987654321098');

        Test.stopTest();        
    }    

    static testMethod void scenarioGoodAuthTokenNum4() {

        String oppId = CreateData();

        Test.startTest();
            ApexPages.StandardController sc;        

            PageReference pageRef = Page.CCCapture;
            List<Payment_Link__c> plList = [SELECT Id, Token__c, SFDC_Token_URL_Friendly__c, Opportunity__c FROM Payment_Link__c WHERE Opportunity__c = :oppId ORDER BY CreatedDate DESC LIMIT 1];

            Test.setCurrentPage(pageRef);
            CCCaptureController controller = new CCCaptureController(sc);       
            pageRef.getParameters().put('auth', plList[0].Token__c);        //because we're not truly in a browser do NOT use the urlencoded token here, instead the normal one must be used.

            pageRef = controller.PrepthePage();
        
            Boolean result = CCCaptureController.SubmitExistingCCToZuoraAndSFDC('444444444448', plList[0].Id, '127.0.0.1', 'Homer Simpson', '10', '2020', 'Visa', 'Notes', false, '01234567890123456789012345678901', true, false, true, '01234567890123456789012345678901', true, '98765432109876543210987654321098');
            result = CCCaptureController.SubmitExistingCCToZuoraAndSFDC('444444444448', plList[0].Id, '127.0.0.1', 'Homer Simpson', '10', '2020', 'Visa', 'Notes', true, '01234567890123456789012345678901', true, false, true, '12345678901234567890123456789012', true, '98765432109876543210987654321098');
            result = CCCaptureController.SubmitExistingCCToZuoraAndSFDC('444444444448', plList[0].Id, '127.0.0.1', 'Homer Simpson', '10', '2020', 'Visa', 'Notes', false, '01234567890123456789012345678901', false, false, true, '12345678901234567890123456789012', true, '98765432109876543210987654321098');
            result = CCCaptureController.SubmitExistingCCToZuoraAndSFDC('444444444448', plList[0].Id, '127.0.0.1', 'Homer Simpson', '10', '2020', 'Visa', 'Notes', false, '01234567890123456789012345678901', true, false, true, '12345678901234567890123456789012', false, '98765432109876543210987654321098');

        Test.stopTest();        
    }      

    static testMethod void scenarioGoodAuthTokenNum5() {

        String oppId = CreateData();

        Test.startTest();
            ApexPages.StandardController sc;        

            PageReference pageRef = Page.CCCapture;
            List<Payment_Link__c> plList = [SELECT Id, Token__c, SFDC_Token_URL_Friendly__c, Opportunity__c FROM Payment_Link__c WHERE Opportunity__c = :oppId ORDER BY CreatedDate DESC LIMIT 1];

            Test.setCurrentPage(pageRef);
            CCCaptureController controller = new CCCaptureController(sc);       
            pageRef.getParameters().put('auth', plList[0].Token__c);        //because we're not truly in a browser do NOT use the urlencoded token here, instead the normal one must be used.

            pageRef = controller.PrepthePage();

            Boolean result = CCCaptureController.SubmitExistingCCToZuoraAndSFDC('444444444448', plList[0].Id, '127.0.0.1', 'Homer Simpson', '10', '2020', 'Visa', 'Notes', true, '01234567890123456789012345678901', true, false, true, '12345678901234567890123456789012', false, '98765432109876543210987654321098');
            result = CCCaptureController.SubmitExistingCCToZuoraAndSFDC('444444444448', plList[0].Id, '127.0.0.1', 'Homer Simpson', '10', '2020', 'Visa', 'Notes', true, '01234567890123456789012345678901', false, false, true, '12345678901234567890123456789012', false, '98765432109876543210987654321098');
            result = CCCaptureController.SubmitExistingCCToZuoraAndSFDC('444444444448', plList[0].Id, '127.0.0.1', 'Homer Simpson', '10', '2020', 'Visa', 'Notes', false, '01234567890123456789012345678901', false, false, true, '12345678901234567890123456789012', false, '98765432109876543210987654321098');

        Test.stopTest();        
    }        

    static testMethod void scenarioExpiredAuthToken() {

        String oppId = CreateData();

        Test.startTest();
            ApexPages.StandardController sc;        

            PageReference pageRef = Page.CCCapture;
            List<Payment_Link__c> plList = [SELECT Id, Token__c, SFDC_Token_URL_Friendly__c, Opportunity__c FROM Payment_Link__c WHERE Opportunity__c = :oppId ORDER BY CreatedDate DESC LIMIT 1];
            plList[0].Status_Workflow__c = 'Expired';

            update plList;

            Test.setCurrentPage(pageRef);
            CCCaptureController controller = new CCCaptureController(sc);       
            pageRef.getParameters().put('auth', plList[0].Token__c);        //because we're not truly in a browser do NOT use the urlencoded token here, instead the normal one must be used.

            pageRef = controller.PrepthePage();

        Test.stopTest();
    }    

    public static String CreateData() {

        NewOpportunityController_Test.CreateData();

        List<zqu__Quote__c> quoteList = [SELECT Id, zqu__Opportunity__c, zqu__Opportunity__r.Contact__c FROM zqu__Quote__c WHERE IsSyncing__c = true AND zqu__ZuoraAccountID__c != null AND Payment_Gateway__c like '%paymentech%' LIMIT 5];
        if (quoteList != null && !quoteList.isEmpty()) {

            String result = WebServices.CreatePaymentLink(quoteList[0].zqu__Opportunity__c, quoteList[0].zqu__Opportunity__r.Contact__c, null, null, null, false, false);

            return quoteList[0].zqu__Opportunity__c;

        }

        return null;        
    }
}