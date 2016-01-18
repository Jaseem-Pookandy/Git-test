/***
*Class          ---- CCCaptureController
*Author         ---- Tim Byrnes
*Story          ---- Credit Card Capture
*Created Date   ---- 2015.05.??
*Description    ---- Controller behind the CCCapture.page visualforce page for Credit Card Capture
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Tim Byrnes
*Story          ---- CCBOB-112
*Modified Date  ---- 2015.11.17
*Description    ---- Altered logic to use custom settings (CreditCardPaymentGateways__c) to control which gateways post to Zuora.
***/

global without sharing class CCCaptureController {

    public Payment_Link__c thisLink {get; set;}
    public List<String> errors {get; set;}
    public String HMACToken {get; set;}
    public String HMACSignature {get; set;}
    public Boolean postCardToZuora {get; set;}            //true if the gateway flag indicates we're posting to Zuora, false if we're posting directly to SFDC and NOT Zuora.
    public Boolean readyToReceivePayment {get; set;}    //simple boolean to indicate if the UI should be exposed or hidden.
    public Boolean easyPath {get; set;}                 //simple boolean to indicate which UI to expose.  Happy path = true, convoluted path = false.  (Happy path is new card only, convoluted path = existing cards & ability for new path)
    public Boolean billingAccountHasOpenInvoices {get; set;}
    public List<SelectOption> countryOptions {get; set;}
    public List<SelectOption> stateOptions {get; set;}
    public String defaultCountry {get; set;}
    public String billingAccountName {get; set;}
    public String billingContactName {get; set;}
    public String headerText {get; set;}
    public String ipAddress {get; set;}
    public String zuoraBillingAccountId {get; set;}
    public String finalURL {get; set;}
    public String authTokenURLEncoded {get; set;}
    public List<CreditCardObject> creditCardsInZuora {get; set;}
    public List<SelectOption> ccExpirationYearOptions {get; set;}
    public List<SelectOption> ccExpirationYearOptionsWithEmpty {get; set;}
    public List<SelectOption> ccExpirationMonthOptions {get; set;}

    public Boolean remittanceLinkWasSentManually {get; set;}
    public Boolean isBillingAccountActivelyBilling {get; set;}
    public Boolean isAutoPayCurrentlyOn {get; set;}
    public String billingAccountsDefaultPaymentMethodId {get; set;}

    private Zuora.zApi api = new Zuora.zApi();    
    private String authToken {get; set;}
    private Id paymentLinkId {get; set;}    
    private List<Payment_Link_History__c> historyToInsert {get; set;}
    private List<Zuora.zObject> paymentMethodsFound {get; set;}
    private RESTZuoraOperationPlugIn.ReturnClass zuoraAccountDetails {get; set;}

    public CCCaptureController(ApexPages.StandardController controller) {

        paymentLinkId = null;

        remittanceLinkWasSentManually = false;
        isBillingAccountActivelyBilling = false;
        isAutoPayCurrentlyOn = false;
        billingAccountHasOpenInvoices = false;
        billingAccountsDefaultPaymentMethodId = null;

        errors = new List<String>();
        creditCardsInZuora = new List<CreditCardObject>();
        ccExpirationYearOptions = new List<SelectOption>();
        ccExpirationMonthOptions = new List<SelectOption>();
        ccExpirationYearOptionsWithEmpty = new List<SelectOption>();
        paymentMethodsFound = new List<Zuora.zObject>();
        thisLink = new Payment_Link__c();
        readyToReceivePayment = false;
        easyPath = true;    
        historyToInsert = new List<Payment_Link_History__c>();
        countryOptions = new List<SelectOption>();
        stateOptions = new List<SelectOption>();                //only used for the United States currently.
        defaultCountry = 'United States';
        postCardToZuora = false;
        zuoraAccountDetails = null;
        finalURL = Label.RemittanceLinkZuoraCCURI;
    }

    public PageReference PrepthePage() {
    
        authToken = ApexPages.currentPage().getParameters().get('auth');        
        if (authToken == null) errors.add('Unable to continue as no authorization token was provided.');
        else {

            authTokenURLEncoded = EncodingUtil.urlEncode(authToken, 'UTF-8');

            PrepSelectOptions();

            SetTheCountryList();

            SetTheStateList();

            SettheClientIPAddress();

            VerifyToken();  

            FinishPagePrep();

            if (postCardToZuora) {
                HMACReturnClass result = GetHMACToken(zuoraBillingAccountId, Label.RemittanceLinkZuoraCCURI);  
                if (result.errors.isEmpty()) {
                    HMACToken = result.HMACToken;
                    HMACSignature = result.HMACSignature;
                }
            } 

            //Insert any necessary history records now
            if (!historyToInsert.isEmpty()) insert historyToInsert;
            //reset the collection
            historyToInsert = new List<Payment_Link_History__c>();
        } 

        return null;
    }

    private void PrepSelectOptions() {

        ccExpirationYearOptions = new List<SelectOption>();
        ccExpirationYearOptionsWithEmpty = new List<SelectOption>();
        ccExpirationMonthOptions = new List<SelectOption>();

        Integer curYear = System.today().year();

        ccExpirationYearOptionsWithEmpty.add(new SelectOption('', 'Year'));

        for (Integer i = curYear; i <= curYear + 15; i++) {
            ccExpirationYearOptions.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
            ccExpirationYearOptionsWithEmpty.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
        }

        //Months now...
        ccExpirationMonthOptions.add(new SelectOption('01', '01 - January'));
        ccExpirationMonthOptions.add(new SelectOption('02', '02 - February'));
        ccExpirationMonthOptions.add(new SelectOption('03', '03 - March'));
        ccExpirationMonthOptions.add(new SelectOption('04', '04 - April'));
        ccExpirationMonthOptions.add(new SelectOption('05', '05 - May'));
        ccExpirationMonthOptions.add(new SelectOption('06', '06 - June'));
        ccExpirationMonthOptions.add(new SelectOption('07', '07 - July'));
        ccExpirationMonthOptions.add(new SelectOption('08', '08 - August'));
        ccExpirationMonthOptions.add(new SelectOption('09', '09 - September'));
        ccExpirationMonthOptions.add(new SelectOption('10', '10 - October'));
        ccExpirationMonthOptions.add(new SelectOption('11', '11 - November'));
        ccExpirationMonthOptions.add(new SelectOption('12', '12 - December'));
    }

    public String getccMessage() {
        if (creditCardsInZuora.size() == 1) return '<strong>1 active credit card</strong> has been found on file for your account.<br/><strong>Please either confirm this card or enter a new card.</strong>';
        else if (creditCardsInZuora.size() > 1) return '<strong>' +  creditCardsInZuora.size() + ' active credit cards</strong> have been found on file for your account.<br/><strong>Please either confirm the card you wish to use or enter a new card.</strong>';
        else return 'Well that is strange...';
    }

    @RemoteAction
    global static Boolean PostToSalesforce( String ccNum, 
                                            String oppId, 
                                            String plId, 
                                            String ipAddy, 
                                            String ccName, 
                                            String ccExpMonth, 
                                            String ccExpYear, 
                                            String cardType, 
                                            String ccNotes, 
                                            Boolean newCard, 
                                            Boolean isBillingAccountActivelyBilling,
                                            Boolean isAutoPayCurrentlyOn,
                                            Boolean billingAccountHasOpenInvoices,
                                            String billingAccountsDefaultPaymentMethodId,
                                            Boolean remittanceLinkWasSentManually,
                                            String zuoraBillingAccountId,
                                            String zuoraPaymentMethodId) {
        
        //This called when a NEW card is inserted - for both worldpay & paymentech.

        //So, if this has a zuoraBillingAccountId && gateway is approved to send to Zuora, update the zuorabillingaccount object now:

        //zuoraPaymentMethodId could either be an empty string ('') in case if the card goes to Salesforce only, or if successfully posted, the actual Zuora payment method id.

        String thisGateway = null;
        Opportunity thisOpp = [SELECT Id, SyncedQuote__r.Payment_Gateway__c FROM Opportunity WHERE Id = :oppId LIMIT 1];

        List<Payment_Link__c> thisLinkList = [SELECT Id, AutoPay_Off__c FROM Payment_Link__c WHERE Id = :plId LIMIT 1];
        Boolean forceAutoPayOff = false;

        if (thisLinkList != null && thisLinkList[0].AutoPay_Off__c != null) forceAutoPayOff = thisLinkList[0].AutoPay_Off__c;

        if (thisOpp != null) thisGateway = thisOpp.SyncedQuote__r.Payment_Gateway__c;

        Boolean hasNotes = false;

        if (ccNotes == null || ccNotes.trim().length() < 1) hasNotes = false;
        else hasNotes = true;    

        List<String> systemNotesList = new List<String>();

        if (zuoraBillingAccountId != null && thisGateway != null && CommonUtil.IsPaymentGatewayApproved(thisGateway)) systemNotesList = UpdateBillingAccountInZuora(zuoraBillingAccountId, isBillingAccountActivelyBilling, isAutoPayCurrentlyOn, forceAutoPayOff, billingAccountHasOpenInvoices, remittanceLinkWasSentManually, billingAccountsDefaultPaymentMethodId, newCard, null, hasNotes);

        CCCaptureUtilities.PostProcessRemittanceLink(   ccNum, 
                                                        oppId, 
                                                        plId, 
                                                        ipAddy,
                                                        ccName, 
                                                        ccExpMonth, 
                                                        ccExpYear, 
                                                        cardType, 
                                                        ccNotes, 
                                                        newCard, 
                                                        thisGateway, 
                                                        null, 
                                                        isBillingAccountActivelyBilling, 
                                                        isAutoPayCurrentlyOn, 
                                                        billingAccountHasOpenInvoices,
                                                        billingAccountsDefaultPaymentMethodId, 
                                                        remittanceLinkWasSentManually,
                                                        systemNotesList,
                                                        zuoraPaymentMethodId);

        return true;
    }

    public static CreditCardObject CheckZuoraIfExpirationWasAltered(String zuoraPaymentMethodId) {

        //This queries Zuora and looks for a CC on file for the Billing Account in ACTIVE status.
        //If at least one is found, easy path is FALSE.
        //Else, easy path is TRUE.

        //This was originally going to use the fancy-schmancy new REST interface, but since Zuora is horribly inconsistent
        //and they don't expose the payment method STATUS field with the REST interface we have to go old-school and bust out the SOAP action...

        List<Zuora.zObject> paymentMethodsFound = new List<Zuora.zObject>();

        String  zoql = 'SELECT AccountId, ';
                //zoql += 'Active, ';
                zoql += 'CreditCardExpirationMonth, ';
                zoql += 'CreditCardExpirationYear, ';
                zoql += 'CreditCardHolderName, ';
                zoql += 'CreditCardMaskNumber, ';
                zoql += 'CreditCardType, ';
                zoql += 'Id, ';
                zoql += 'PaymentMethodStatus, ';
                zoql += 'Type ';
            zoql += 'from PaymentMethod ';
            zoql += 'where Id = \'' + zuoraPaymentMethodId + '\'';
        
        Zuora.zApi api = new Zuora.zApi();    

        try {
            if (!test.isRunningTest()) {
                Zuora.zApi.LoginResult loginResult = api.zLogin();
                paymentMethodsFound = api.zquery(zoql);
            }
            else {
                Zuora.zObject zob = new Zuora.zObject('PaymentMethod');
                zob.setValue('Id', '12345678901234567890123456789012');
                zob.setValue('CreditCardType', 'Discover');
                zob.setValue('CreditCardMaskNumber', '************1234');
                zob.setValue('CreditCardExpirationYear', 2028);
                zob.setValue('CreditCardExpirationMonth', 12);
                zob.setValue('PaymentMethodStatus', 'Active');
                zob.setValue('CreditCardHolderName', 'James Franco');
                paymentMethodsFound.add(zob);
            }
        }
        catch (Zuora.zAPIException e) {
            system.debug('### - Error: ' + e);
            throw e;
        }

        for (Zuora.zObject zob : paymentMethodsFound) {

            CreditCardObject cco = new CreditCardObject();

            cco.id                      = (String)zob.getValue('Id');
            cco.cardType                = (String)zob.getValue('CreditCardType');
            cco.cardNumber              = (String)zob.getValue('CreditCardMaskNumber');
            cco.expirationYear          = (Integer)zob.getValue('CreditCardExpirationYear');
            cco.expirationMonth         = (Integer)zob.getValue('CreditCardExpirationMonth');
            cco.status                  = (String)zob.getValue('PaymentMethodStatus');
            cco.cardholderName          = (String)zob.getValue('CreditCardHolderName');

            //there's only 1, so we can return it immediately.
            return cco;
        }

        return null;
    }

    @RemoteAction
    global static Boolean SubmitExistingCCToZuoraAndSFDC(   String ccNum, 
                                                            String plId, 
                                                            String ipAddy, 
                                                            String ccName, 
                                                            String ccExpMonth, 
                                                            String ccExpYear, 
                                                            String cardType, 
                                                            String ccNotes, 
                                                            Boolean newCard, 
                                                            String zpmid, 
                                                            Boolean isBillingAccountActivelyBilling, 
                                                            Boolean isAutoPayCurrentlyOn, 
                                                            Boolean billingAccountHasOpenInvoices,
                                                            String billingAccountsDefaultPaymentMethodId, 
                                                            Boolean remittanceLinkWasSentManually,
                                                            String zuoraBillingAccountId) {
        
        //Problems sending in relational data so I'll just query it (again) from the payment link Id.
        Payment_Link__c completedLink = [SELECT     Id, 
                                                    Expiration__c, 
                                                    Status__c, 
                                                    Status_Workflow__c, 
                                                    Name, 
                                                    AutoPay_Off__c,
                                                    Opportunity__c, 
                                                    Contact__c, 
                                                    Opportunity__r.Account.Name,
                                                    Opportunity__r.Account_Brand__r.Brand__r.Name,
                                                    Opportunity__r.SyncedQuote__c, 
                                                    Opportunity__r.SyncedQuote__r.Id,
                                                    Opportunity__r.SyncedQuote__r.zqu__SoldToContact__r.Name,
                                                    Opportunity__r.SyncedQuote__r.zqu__ZuoraAccountID__c, 
                                                    Opportunity__r.SyncedQuote__r.Payment_Gateway__c
                                                FROM Payment_Link__c WHERE Id = :plId LIMIT 1];

        String cleanMonth = ccExpMonth;
        if (cleanMonth != null && cleanMonth.length() > 1 && cleanMonth.startsWith('0')) cleanMonth = cleanMonth.substring(1);

        CreditCardObject originalCC = CheckZuoraIfExpirationWasAltered(zpmid);
        Boolean result = UpdatePaymentMethodInZuora(zpmid, cleanMonth, ccExpYear);

        Boolean forceAutoPayOff = false;

        if (completedLink != null && completedLink.AutoPay_Off__c != null) forceAutoPayOff = completedLink.AutoPay_Off__c;

        Boolean hasNotes = false;
        if (ccNotes == null || ccNotes.trim().length() < 1) hasNotes = false;
        else hasNotes = true;

        List<String> systemNotesList = new List<String>();

        systemNotesList = UpdateBillingAccountInZuora(zuoraBillingAccountId, isBillingAccountActivelyBilling, isAutoPayCurrentlyOn, forceAutoPayOff, billingAccountHasOpenInvoices, remittanceLinkWasSentManually, billingAccountsDefaultPaymentMethodId, newCard, zpmid, hasNotes);

        if (result) {

            //Send the data to Salesforce
            CCCaptureUtilities.PostProcessRemittanceLink(   ccNum, 
                                                            completedLink.Opportunity__c, 
                                                            plId, 
                                                            ipAddy, 
                                                            ccName, 
                                                            cleanMonth, 
                                                            ccExpYear, 
                                                            cardType, 
                                                            ccNotes, 
                                                            newCard, 
                                                            completedLink.Opportunity__r.SyncedQuote__r.Payment_Gateway__c, 
                                                            originalCC,
                                                            isBillingAccountActivelyBilling,
                                                            isAutoPayCurrentlyOn,
                                                            billingAccountHasOpenInvoices,
                                                            billingAccountsDefaultPaymentMethodId,
                                                            remittanceLinkWasSentManually,
                                                            systemNotesList,
                                                            null
                                                            );
            return true;
        }

        else return false;
    }    

    private static String PrettyUpBooleanText(Boolean bFlag) {
        if (bFlag) return 'ON';
        else return 'OFF';
    }

    public static List<String> UpdateBillingAccountInZuora(String zBillingAccountId, Boolean isActivelyBilling, Boolean isAutoPayOn, Boolean forceAutoPayOff, Boolean billingAccountHasOpenInvoices, Boolean rlSentManually, String zBillingAccountDefaultPMId, Boolean newCard, String existingPaymentIdReused, Boolean hasNotes) {

        final String FINAL_Batch2 = 'Batch2';

        String autopayOriginalValue = PrettyUpBooleanText(isAutoPayOn);
        List<String> resultList = new List<String>();  //contains the programmatic changes to the account object so that it can be passed on to create the system notes later

        String batchVal = null;
        String autopayVal = null;
        String defaultPaymentVal = null;

        Boolean restorePriorDefaultPaymentMethod = false;

        //If the link was sent manually & the account is currently actively billing...
        if (rlSentManually) {
            if (isActivelyBilling) {
                //IF link is sent manually and IS actively billing
                if (newCard) {
                    autopayVal = 'false';                
                    resultList.add('Default Payment is unchanged.');
                    restorePriorDefaultPaymentMethod = true;
                }
                else {
                    //if the card that is reused is the same card as the default payment method
                    if (zBillingAccountDefaultPMId == existingPaymentIdReused) {                    
                        /* do nothing */ 
                        resultList.add('AutoPay was unchanged (Left ' + autopayOriginalValue + ')');
                        resultList.add('Default Payment is unchanged.');
                    }
                    //if the card that is reused is NOT the same as the default payment method
                    else {
                        autopayVal = 'false';
                        resultList.add('Default Payment is unchanged.');
                    }
                }
            }
            else {
                //IF link is sent manually and NOT actively billing
                //No difference here if it's a new card or not, but I'm leaving it separated for easy updates later...
                if (billingAccountHasOpenInvoices) {
                    if (newCard) {
                        autopayVal = 'false';
                        restorePriorDefaultPaymentMethod = true;
                        resultList.add('Default Payment is unchanged.');
                    }
                    //else reusing an existing card
                    else {
                        //if the card that is reused is the same card as the default payment method
                        if (zBillingAccountDefaultPMId == existingPaymentIdReused) {
                            if (!forceAutoPayOff) resultList.add('AutoPay was unchanged (Left ' + autopayOriginalValue + ')');
                            resultList.add('Default Payment is unchanged.');
                        }
                        //if the card that is reused is NOT the same as the default payment method
                        else {
                            autopayVal = 'false';
                            resultList.add('Default Payment is unchanged.');
                        }
                    }
                }
                //else billing Account has NO open invoices
                else {
                    if (newCard) {
                        if (!forceAutoPayOff) {
                            autopayVal = 'true';
                            resultList.add('AutoPay was ' + autopayOriginalValue + ', now ON.');
                        }
                        defaultPaymentVal = existingPaymentIdReused;
                        resultList.add('Default Payment is now this card.');
                    }
                    else {
                        if (!forceAutoPayOff) {
                            autopayVal = 'true';
                            resultList.add('AutoPay was ' + autopayOriginalValue + ', now ON.');
                        }                        
                        defaultPaymentVal = existingPaymentIdReused;
                        resultList.add('Default Payment is now this card.');
                    }
                }
            }
        }
        else {
            //ELSE link is NOT sent manually (Docusign!)
            if (isActivelyBilling) {
                if (newCard) {
                    if (isAutoPayOn) {
                        autopayVal = 'false';
                        resultList.add('Default Payment is unchanged.');
                        batchVal = FINAL_Batch2;
                        restorePriorDefaultPaymentMethod = true;
                    }
                    else {
                        resultList.add('AutoPay was unchanged (Left ' + autopayOriginalValue + ')');
                        resultList.add('Default Payment is unchanged.');
                        restorePriorDefaultPaymentMethod = true;
                        batchVal = FINAL_Batch2;
                    }
                }
                //else resused existing card
                else {
                    if ((zBillingAccountDefaultPMId == existingPaymentIdReused) && (isAutoPayOn == false)) {
                        resultList.add('AutoPay was unchanged (Left ' + autopayOriginalValue + ')');
                        resultList.add('Default Payment is unchanged.');
                        batchVal = FINAL_Batch2;
                    } 
                    else if ((zBillingAccountDefaultPMId == existingPaymentIdReused) && (isAutoPayOn == true)) {
                         /* do nothing */ 
                         resultList.add('AutoPay was unchanged (Left ' + autopayOriginalValue + ')');
                         resultList.add('Default Payment is unchanged.');
                    }
                    else if ((zBillingAccountDefaultPMId != existingPaymentIdReused) && (isAutoPayOn == false)) {
                        batchVal = FINAL_Batch2;
                        resultList.add('AutoPay was unchanged (Left ' + autopayOriginalValue + ')');
                        resultList.add('Default Payment is unchanged.');
                    }
                    else if ((zBillingAccountDefaultPMId != existingPaymentIdReused) && (isAutoPayOn == true)) {
                        autopayVal = 'false';
                        batchVal = FINAL_Batch2;
                        resultList.add('Default Payment is unchanged.');
                    }
                }
            }
            else {
                //is NOT actively billing
                if (billingAccountHasOpenInvoices) {
                    if (newCard) {
                        autopayVal = 'false';
                        batchVal = FINAL_Batch2;
                        restorePriorDefaultPaymentMethod = true;
                        resultList.add('Default Payment is unchanged.');
                    }
                    else {
                        if (zBillingAccountDefaultPMId == existingPaymentIdReused) {
                            if (isAutoPayOn) {
                                resultList.add('AutoPay was unchanged (Left ' + autopayOriginalValue + ')');
                                resultList.add('Default Payment is unchanged.');
                            }
                            else {
                                resultList.add('AutoPay was unchanged (Left ' + autopayOriginalValue + ')');
                                resultList.add('Default Payment is unchanged.');
                                batchVal = FINAL_Batch2;
                            }
                        }
                        else {
                            autopayVal = 'false';
                            batchVal = FINAL_Batch2;
                            resultList.add('Default Payment is unchanged.');
                        }
                    }
                }
                else {
                    //has NO open invoices
                    if (newCard) {
                        if (!forceAutoPayOff) {
                            autopayVal = 'true';
                            resultList.add('AutoPay was ' + autopayOriginalValue + ', now ON.');
                        }                        
                        defaultPaymentVal = existingPaymentIdReused;   
                        resultList.add('Default Payment is now this card.');
                    }
                    else {
                        if (!forceAutoPayOff) {
                            autopayVal = 'true';
                            resultList.add('AutoPay was ' + autopayOriginalValue + ', now ON.');
                        }                        
                        defaultPaymentVal = existingPaymentIdReused;
                        resultList.add('Default Payment is now this card.');
                    }
                }
            }
        }

        if (autopayVal == 'false' && forceAutoPayOff != true) resultList.add('AutoPay was ' + autopayOriginalValue + ', now OFF.');

        if (forceAutoPayOff == true) {
            autopayVal = 'false';
            resultList.add('AutoPay was ' + autopayOriginalValue + ', now forced OFF.');
        } 

        if (hasNotes) batchVal = FINAL_Batch2;

        if (batchVal == FINAL_Batch2) resultList.add('Billing Account was changed to Batch2.');    
        else resultList.add('Billing Account batch was unchanged.');

        //If any one of these three has a value, that means we need to update!
        if (batchVal != null || defaultPaymentVal != null || autopayVal != null) {

            //Apparently a few fields are not available to update via the REST api, so we've got to go old-school.  Thanks, Zuora...
            Zuora.zApi zApiInstance = new Zuora.zApi();
        
            try {
                if(!Test.isRunningTest())   zApiInstance.zlogin(); 
            } 

            catch (Exception ex) { ex.getMessage(); }

            try {   

                Zuora.zObject acc = new Zuora.zObject('Account');
                acc.setValue('Id', zBillingAccountId);

                if (batchVal != null) acc.setValue('Batch', batchVal);  

                if (defaultPaymentVal != null && !restorePriorDefaultPaymentMethod) acc.setValue('DefaultPaymentMethodId', defaultPaymentVal);
                else if (restorePriorDefaultPaymentMethod) acc.setValue('DefaultPaymentMethodId', zBillingAccountDefaultPMId);

                if (autopayVal != null) acc.setValue('AutoPay', autopayVal);

                //system.debug('### - acc, line 522: ' + acc);

                List<Zuora.zObject> objs = new List<Zuora.zObject> {acc};
                List<Zuora.zApi.SaveResult> results;
                
                if (!Test.isRunningTest()) results = zApiInstance.zupdate(objs);
                else {
                    results = new List<Zuora.zApi.SaveResult>();
                    Zuora.zApi.SaveResult result = new Zuora.zApi.SaveResult();
                    result.Success = false;
                    results.add(result);
                }
                
                for (Zuora.zApi.SaveResult result : results) {
                    if (result.Success) String updatedId = result.Id;                
                    else  {
                        Zuora.zObject[] errors = result.errors;
                    
                        resultList.clear();
                        for (Zuora.zObject error : errors) { 
                            String errorCode = (String)error.getValue('Code'); 
                            String message = (String)error.getValue('Message');
                            
                            resultList.add(message);
                            system.debug('### Error: ' + message);
                        }
                    }
                }
            }
            catch (Exception ex) { 
                resultList.clear();
                resultList.add(ex.getMessage());
                system.debug('### Error: ' + ex.getMessage());
            }
        }

        return resultList;
    }

    public static Boolean UpdatePaymentMethodInZuora(String zpmid, String ccExpMonth, String ccExpYear) {

        Http restHTTP = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        req.setEndpoint(Label.RemittanceLinkZuoraCCURI + '/' + zpmid);
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');

        Blob headerValue = Blob.valueOf(Label.RemittanceLinkZuoraUser + ':' + Label.RemittanceLinkZuoraPass);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);

        String body = '{';
            body += '"expirationMonth": ' + ccExpMonth + ',';
            body += '"expirationYear": ' + ccExpYear;
        body += '}';

        system.debug('### - body: ' + body);

        req.setBody(body);
        req.setTimeout(80000);
        
        if (!Test.isRunningTest()) res = restHTTP.send(req);
        else res.setStatusCode(200);

        if (res.getStatusCode() != 200) {
            system.debug('### - Error 213:  Communication Error.  ' + ' Status Code: ' + res.getStatusCode() + '   Status: ' + res.getStatus());
            return false;
        }

        String zuoraResponse = res.getBody();

        if (Test.isRunningTest()) zuoraResponse = '{"paymentMethodId" : "12345678901234567890123456789012", "success" : true}';
        
        //check if success is true or false now, start by parsing the repsonse:
        Map<String, Object> zuoraParsedResponse = (Map<String, Object>) JSON.deserializeUntyped(zuoraResponse);

        if (!zuoraParsedResponse.containsKey('success') || zuoraParsedResponse.get('success') != true) system.debug('### - Error 215:  ' + zuoraResponse);

        return true;
    }    

    private void SetTheCountryList() {
        countryOptions = new List<SelectOption>();

        for (pw_ccpro__CountryObject__c thisC : [SELECT Name, pw_ccpro__IsoCode_3__c FROM pw_ccpro__CountryObject__c WHERE pw_ccpro__Enabled__c = TRUE and IsDeleted = FALSE ORDER BY Name]) {
            SelectOption s = new SelectOption(thisC.pw_ccpro__IsoCode_3__c, thisC.Name);
            countryOptions.add(s);
        }
    }

    private void SetTheStateList() {
        stateOptions = new List<SelectOption>();

        stateOptions.add(new SelectOption('', ''));

        for (pw_ccpro__State__c thisS : [SELECT Name, pw_ccpro__IsoCode__c FROM pw_ccpro__State__c WHERE pw_ccpro__FullIsoCode__c LIKE 'US-%' ORDER BY Name]) {
            SelectOption s = new SelectOption(thisS.pw_ccpro__IsoCode__c, thisS.Name);
            stateOptions.add(s);
        }
    }


    private void VerifyToken() {

        Boolean idSuccessfullyRetrieved = false;

        //First, verify the authToken
        PaymentLinkCryptoKey__c thisKey = PaymentLinkCryptoKey__c.getInstance(CCCaptureUtilities.CC_PRIVATE_KEY);
        if (thisKey == null) errors.add('Error 019: Unable to located private key to decrypt token.');        
        
        String paymentLinkIdDecrypted = CCCaptureUtilities.DecryptText(thisKey.Key__c, authToken);

        if (paymentLinkIdDecrypted != null) idSuccessfullyRetrieved = CCCaptureUtilities.IsValidId(paymentLinkIdDecrypted);
        if (!idSuccessfullyRetrieved) errors.add('Error 023: Decryption failed.  Ensure the entirety of the URL address is correct.  Due to the complexity of the authentication token, please click on the link in your email and do not manually enter it.');
        else {

            paymentLinkId = paymentLinkIdDecrypted;
            
            if (paymentLinkId.getSobjectType().getDescribe().getName() != 'Payment_Link__c') errors.add('Error 029:  Decryption did not return the Id type that was expected.');

            //Then, log that this authToken was clicked.
            Payment_Link_History__c plh = PaymentLinkTriggerHandler.ReturnNewLinkHistoryRecord(paymentLinkId, 'Website Visited', ipAddress);
            if (plh != null) historyToInsert.add(plh);
        }            
    }

    private void FinishPagePrep() {

        if (paymentLinkId != null) {

            //Get the payment link & any other Salesforce record(s)
            thisLink = [SELECT  Id, 
                                Expiration__c, 
                                Status__c, 
                                Status_Workflow__c, 
                                Reason__c,
                                Name, 
                                AutoPay_Off__c,
                                Opportunity__c, 
                                Contact__c, 
                                Link_Created_For__c,
                                Opportunity__r.Account.Name,
                                Opportunity__r.Account_Brand__r.Brand__r.Name,
                                Opportunity__r.SyncedQuote__c, 
                                Opportunity__r.SyncedQuote__r.Id,
                                Opportunity__r.SyncedQuote__r.zqu__SoldToContact__r.Name,
                                Opportunity__r.SyncedQuote__r.zqu__ZuoraAccountID__c, 
                                Opportunity__r.SyncedQuote__r.Payment_Gateway__c
                            FROM Payment_Link__c WHERE Id = :paymentLinkId LIMIT 1];

            if ((thisLink.Status__c == 'Expired') || (thisLink.Expiration__c < System.now())) {
                errors.add('We\'re sorry but this link has expired.  Please contact your representative for a new link.');

                Payment_Link_History__c plh = PaymentLinkTriggerHandler.ReturnNewLinkHistoryRecord(paymentLinkId, 'Client Denied - Link was Expired', ipAddress);
                if (plh != null) historyToInsert.add(plh);

                return;
            }        

            //Find out if we're posting this card to Zuora and SFDC or just SFDC
            //Byrnes - 2015.11.17
            if (thisLink.Opportunity__r != null && thisLink.Opportunity__r.SyncedQuote__r != null && thisLink.Opportunity__r.SyncedQuote__r.zqu__ZuoraAccountID__c != null) {
                //Then we have the data to crawl... continue running checks

                if (CommonUtil.IsPaymentGatewayApproved(thisLink.Opportunity__r.SyncedQuote__r.Payment_Gateway__c)) postCardToZuora = true;
                else postCardToZuora = false;

                zuoraBillingAccountId = thisLink.Opportunity__r.SyncedQuote__r.zqu__ZuoraAccountID__c;
            }
            //If the data chain is broken (opportunity / quote, etc) kick out now before the 'readyToReceivePayment' flag is set to true.
            else {
                errors.add('Error 033: The necessary data relationship(s) are missing.  Unable to continue.');
                return;
            }
            //End Byrnes - 2015.11.17
            
            if (thisLink.Reason__c != null && thisLink.Reason__c.containsIgnoreCase('docusign')) remittanceLinkWasSentManually = false;
            else remittanceLinkWasSentManually = true;

            //Decide what UI to render - easy path or not so easy path.
            GetExistingCardsFromZuora(thisLink.Opportunity__r.SyncedQuote__r.zqu__ZuoraAccountID__c, thisLink.Link_Created_For__c);

            if (creditCardsInZuora.isEmpty()) easyPath = true;
            else easyPath = false;

            billingContactName = 'Purchaser';     //default, just in case.

            if (thisLink.Opportunity__r.SyncedQuote__r.zqu__SoldToContact__r != null) billingContactName = thisLink.Opportunity__r.SyncedQuote__r.zqu__SoldToContact__r.Name;
            billingAccountName = thisLink.Opportunity__r.Account.Name;

            //Get the billing account details now (is actively billing, default payment method and autopay flag)
            Map<String, String> requestParameterMap = new Map<String, String>();
            requestParameterMap.put('Operation', 'IsBillingAccountActive');
            requestParameterMap.put('BillingAccountId', thisLink.Opportunity__r.SyncedQuote__r.zqu__ZuoraAccountID__c);
            RESTZuoraOperationPlugIn.ReturnClass zuoraAccountDetails = RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap);

            if (zuoraAccountDetails != null) {

                if (zuoraAccountDetails.isActiveBilling != null && zuoraAccountDetails.isActiveBilling.toLowerCase() == 'true') isBillingAccountActivelyBilling = true;
                else isBillingAccountActivelyBilling = false;

                if (zuoraAccountDetails.isAutoPay != null && zuoraAccountDetails.isAutoPay.toLowerCase() == 'true') isAutoPayCurrentlyOn = true;
                else isAutoPayCurrentlyOn = false;

                if (zuoraAccountDetails.balance > 0) billingAccountHasOpenInvoices = true;
                else billingAccountHasOpenInvoices = false;

                billingAccountsDefaultPaymentMethodId = zuoraAccountDetails.defaultPaymentMethodId;
            }    

            if (thisLink.Opportunity__r != null && thisLink.Opportunity__r.Account_Brand__r != null && thisLink.Opportunity__r.Account_Brand__r.Brand__r != null) headerText = 'This is a secure site for collecting your credit card information for a purchase made from <font size="3em"><strong>' + thisLink.Opportunity__r.Account_Brand__r.Brand__r.Name + '</strong></font>.';
            else headerText = 'This is a secure site for collecting your credit card information for a purchase made from <strong>DHI Group, Inc</strong>.';
            headerText += '<br/>This purchase was made by <strong>' + billingContactName + '</strong> for <strong>' + billingAccountName + '</strong>.';
            headerText += '<br/><br/><strong>Note:</strong> This site is not a payment portal.  Your credit card will be charged on the date your company\'s invoice is due for payment.';

            // headerText += '<br/><br/>Gateway: ' + thisLink.Opportunity__r.SyncedQuote__r.Payment_Gateway__c;

            readyToReceivePayment = true;
        }
    }

    private void GetExistingCardsFromZuora(String zuoraBillingAccountId, String paymentMethodProvidedBy) {

        //This queries Zuora and looks for a CC on file for the Billing Account in ACTIVE status.

        //Edited logic for CCBOB-92:  Now we're also filtering the results based on values on the Payment Method object in Salesforce.
        //New parameter, 'paymentMethodProvidedBy' - contains either 'Sold By Partner' or 'Customer' for the filtering.

        //If at least one is found, easy path is FALSE.
        //Else, easy path is TRUE.

        //This was originally going to use the fancy-schmancy new REST interface, but since Zuora is horribly inconsistent
        //and they don't expose the payment method STATUS field with the REST interface we have to go old-school and bust out the SOAP action...

        creditCardsInZuora = new List<CreditCardObject>();
        List<CreditCardObject> filteredList = new List<CreditCardObject>();
        Map<String, Zuora__PaymentMethod__c> paymentMethodMap = new Map<String, Zuora__PaymentMethod__c>();
        paymentMethodsFound = new List<Zuora.zObject>();
        Set<String> allPaymentMethodIds = new Set<String>();

        String  zoql = 'SELECT AccountId, ';
                //zoql += 'Active, ';
                zoql += 'CreditCardExpirationMonth, ';
                zoql += 'CreditCardExpirationYear, ';
                zoql += 'CreditCardHolderName, ';
                zoql += 'CreditCardMaskNumber, ';
                zoql += 'CreditCardType, ';
                zoql += 'Id, ';
                zoql += 'PaymentMethodStatus, ';
                zoql += 'Type ';
            zoql += 'from PaymentMethod ';
            zoql += 'where AccountId = \'' + zuoraBillingAccountId + '\' and PaymentMethodStatus = \'Active\' and Type = \'CreditCard\'';
        
        try {
            if (!test.isRunningTest()) {
                Zuora.zApi.LoginResult loginResult = api.zLogin();
                paymentMethodsFound = api.zquery(zoql);
            }
            else {
                Zuora.zObject zob = new Zuora.zObject('PaymentMethod');
                zob.setValue('Id', '12345678901234567890123456789012');
                zob.setValue('CreditCardType', 'Discover');
                zob.setValue('CreditCardMaskNumber', '************1234');
                zob.setValue('CreditCardExpirationYear', 2028);
                zob.setValue('CreditCardExpirationMonth', 12);
                zob.setValue('PaymentMethodStatus', 'Active');
                zob.setValue('CreditCardHolderName', 'James Franco');
                paymentMethodsFound.add(zob);
            }
        }
        catch (Zuora.zAPIException e) {
            system.debug('### - Error: ' + e);
            throw e;
        }

        for (Zuora.zObject zob : paymentMethodsFound) {

            CreditCardObject cco = new CreditCardObject();

            cco.id                      = (String)zob.getValue('Id');
            cco.cardType                = (String)zob.getValue('CreditCardType');
            cco.cardNumber              = (String)zob.getValue('CreditCardMaskNumber');
            cco.expirationYear          = (Integer)zob.getValue('CreditCardExpirationYear');
            cco.expirationMonth         = (Integer)zob.getValue('CreditCardExpirationMonth');
            cco.status                  = (String)zob.getValue('PaymentMethodStatus');
            cco.cardholderName          = (String)zob.getValue('CreditCardHolderName');

            creditCardsInZuora.add(cco);

            allPaymentMethodIds.add(cco.id);
        }

        if (paymentMethodProvidedBy == null || paymentMethodProvidedBy == '') return;    //If paymentMethodProvidedBy is null or empty, return before the filtering.

        //Get the map for filtering...
        for (Zuora__PaymentMethod__c pm : [SELECT Id, Provided_By__c, Zuora__BillingAccount__c, Zuora__External_Id__c FROM Zuora__PaymentMethod__c WHERE Zuora__External_Id__c IN :allPaymentMethodIds]) {
            paymentMethodMap.put(pm.Zuora__External_Id__c, pm);
        }

        //Now actually loop and filter based on provided by value and the passed in parameter, 'paymentMethodProvidedBy'
        for (CreditCardObject cco : creditCardsInZuora) {
            if (paymentMethodMap.containsKey(cco.id)) {
                if (paymentMethodMap.get(cco.id).Provided_By__c != null) {
                    if (paymentMethodMap.get(cco.id).Provided_By__c.equalsIgnoreCase(paymentMethodProvidedBy)) filteredList.add(cco);  
                    else { /* do NOT add it! */ }
                }
                else {
                    //Else provided by on the payment Method is null - include it for now
                    filteredList.add(cco);
                }
            }
            else {
                //If the payment method exists in Zuora but not yet in salesforce... (hasn't synced back, etc.)
                //That means we don't know who provided it so do we will include it for now...
                filteredList.add(cco);
            }
        }
        creditCardsInZuora = filteredList;
    }

    private void SettheClientIPAddress() {

        String result = '';

        Map<String, String> mapHeaders = ApexPages.currentPage().getHeaders();
        if (mapHeaders != null) {
            result = mapHeaders.get('True-Client-IP');
            if (result == null) result = mapHeaders.get('X-Salesforce-SIP');
        }

        ipAddress = result;
    }

    public static HMACReturnClass GetHMACToken(String thisZuoraBillingAccountId, String uri) {
        //First, get the HMAC token from the server
        //HMACToken = null;
        //HMACSignature = null;

        HMACReturnClass result = new HMACReturnClass();

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
 
        req.setEndpoint(Label.RemittanceLinkZuoraHMACURL);
        req.setMethod('POST');
  
        Blob headerValue = Blob.valueOf(Label.RemittanceLinkZuoraUser + ':' + Label.RemittanceLinkZuoraPass);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);

        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json');

        JSONGenerator js = JSON.createGenerator(true);
        js.writeStartObject();
        js.writeStringField('uri', uri);
        js.writeStringField('method', 'POST');
        if (thisZuoraBillingAccountId != null) js.writeStringField('accountKey', thisZuoraBillingAccountId);
        js.writeEndObject();

        req.setBody(js.getAsString());

        try {
            
            if (!test.isRunningTest()) res = http.send(req);

            if (res.getStatusCode() == 200) {

                JSONParser jp = JSON.createParser(res.getBody());

                while (jp.nextToken() != null) {
                    if ((jp.getCurrentToken() == JSONToken.FIELD_NAME)) {
                        String fieldName = jp.getText();
                        jp.nextToken();

                        //if (fieldName == 'success') System.debug('###### - ' + fieldName + ' : ' + jp.getBooleanValue());

                        if (fieldName == 'token') result.HMACToken = jp.getText();

                        //if (fieldName == 'processId') System.debug('###### - ' + fieldName + ' : ' + jp.getText());

                        if (fieldName == 'signature') result.HMACSignature = jp.getText();
                    }
                }
            }
            else result.errors.add('Unable to authenticate.  Please try again later.' + res.getStatusCode() + ':' + res.getBody());

        } catch (System.CalloutException e) {
            result.errors.add('ERROR: (Exception:)' + e + '  ::  (Response:)' + res.toString());
            result.errors.add('Unable to authenticate.  Please try again later.');
        }

        //system.debug('### - HMAC Result Class: ' + result);

        return result;
    }

    public class CreditCardObject {

        public String id {get; set;}
        public String cardType {get; set;}
        public String cardNumber {get; set;}
        public Integer expirationYear {get; set;}
        public Integer expirationMonth {get; set;}       
        public String expirationMonthShortAndLongForm {

            get {

                if (expirationMonth != null) {
                    if (expirationMonth == 1) return '01 - January';
                    else if (expirationMonth == 2) return '02 - February';
                    else if (expirationMonth == 3) return '03 - March';
                    else if (expirationMonth == 4) return '04 - April';
                    else if (expirationMonth == 5) return '05 - May';
                    else if (expirationMonth == 6) return '06 - June';
                    else if (expirationMonth == 7) return '07 - July';
                    else if (expirationMonth == 8) return '08 - August';
                    else if (expirationMonth == 9) return '09 - September';
                    else if (expirationMonth == 10) return '10 - October';
                    else if (expirationMonth == 11) return '11 - November';
                    else if (expirationMonth == 12) return '12 - December';
                    else return 'Error Determining Month';
                }
                else return 'NULL';

            }
        } 

        public String expirationMonthTwoDigit {

            get {

                if (expirationMonth == null) return null;

                if (expirationMonth > 9) return String.valueOf(expirationMonth);
                else return '0' + String.valueOf(expirationMonth);

            }
        }

        public Boolean defaultPaymentMethod {get; set;}
        public String status {get; set;}
        public String cardholderName {get; set;}        
        public String notes {get; set;}

        public Boolean isCardExpired {
            get {

                Date lastDayofThisMonth = Date.newInstance(System.today().year(), System.today().month(), 1);
                Date lastDayofCCMonth = Date.newInstance(expirationYear, expirationMonth, 1);

                lastDayofThisMonth.addMonths(1).addDays(-1);
                lastDayofCCMonth.addMonths(1).addDays(-1);

                if (lastDayofCCMonth >= lastDayofThisMonth) return false;
                return true;
            } 
        }

        public String headerLabel {
            get {

                String result = '';

                if (isCardExpired) return 'expired on ' + expirationMonthPurdy + ' of ' + expirationYear;
                else return 'expiring in ' + expirationMonthPurdy + ' of ' + expirationYear;
            } 
        }

        public String expirationMonthPurdy {
            get{
                if (expirationMonth != null) {
                    if (expirationMonth == 1) return 'January';
                    else if (expirationMonth == 2) return 'February';
                    else if (expirationMonth == 3) return 'March';
                    else if (expirationMonth == 4) return 'April';
                    else if (expirationMonth == 5) return 'May';
                    else if (expirationMonth == 6) return 'June';
                    else if (expirationMonth == 7) return 'July';
                    else if (expirationMonth == 8) return 'August';
                    else if (expirationMonth == 9) return 'September';
                    else if (expirationMonth == 10) return 'October';
                    else if (expirationMonth == 11) return 'November';
                    else if (expirationMonth == 12) return 'December';
                    else return 'Error Determining Month';
                }
                else return 'NULL';
            }
        }

        public String ccImageName {
            get {
                if (cardType != null) {
                    if (cardType.toLowerCase() == 'visa') return 'visa.png';
                    else if (cardType.toLowerCase() == 'mastercard') return 'mc.png';
                    else if (cardType.toLowerCase() == 'americanexpress') return 'amex.png';
                    else if (cardType.toLowerCase() == 'discover') return 'discover.png';                    
                }
                return 'cc_blank.png';
            }
        }

        public CreditCardObject() {

        }
    }

    public class HMACReturnClass {
        public String HMACToken {get; set;}
        public String HMACSignature {get; set;}
        public List<String> errors {get; set;}

        public HMACReturnClass() {
            HMACToken = null;
            HMACSignature = null;
            errors = new List<String>();
        }
    }
}