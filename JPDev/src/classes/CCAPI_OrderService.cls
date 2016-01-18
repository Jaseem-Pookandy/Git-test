@RestResource(UrlMapping='/ccapi/orders/*')
global with sharing class CCAPI_OrderService {
    
    private static Zuora.zApi zuoraApi = new Zuora.zApi();
    
    @HttpPost
    global static void create(
        string accountId,
        string paymentMethodId,
        string currencyCode,
        string brand,
        string brandTag,
        BillTo billTo,
        List<LineItem> items
    ) {
        RestResponse response = RestContext.response;
        
        if (response == null) {
            response = new RestResponse();
            RestContext.response = response;
        }
        
        response.addHeader('Content-Type', 'application/json');
        
        try {
            string opportunityId = doCreate(accountId, paymentMethodId, currencyCode, brand, brandTag, billTo, items);
            
            response.responseBody = Blob.valueOf(JSON.serialize(opportunityId));
            response.statusCode = 200;
        } catch (Exception ex) {
            ErrorResponse error = new ErrorResponse();
            error.errorCode = 'POST_ORDER_FAILED';
            error.message = ex.getMessage() + '\n' + ex.getStackTraceString();
            
            List<ErrorResponse> errors =  new List<ErrorResponse> { error };
            
            response.responseBody = Blob.valueOf(JSON.serialize(errors));
            response.statusCode = 500;
        }
    }
    
    global static string doCreate(
        string accountId,
        string paymentMethodId,
        string currencyCode,
        string brand,
        string brandTag,
        BillTo billTo,
        List<LineItem> items
    ) {
        Account account = findAccount(accountId);
        Account_Brand__c accountBrand = findAccountBrand(account.Id, brand);
        pw_ccpro__CountryObject__c country = findCountry(billTo.country);
        
        RESTZuoraOperationPlugIn.ReturnClass accountInfo = getOrCreateZuoraAccountInfo(account, currencyCode, brandTag,
            billTo, accountBrand);
        
        string orderName = account.Name + ' ' + DateTime.now().format('ddMMyyyy') + ' ' + getRandomInt(1000, 9999);
        
        if (!Test.isRunningTest())
            zuoraApi.zlogin();
        
        Zuora.zApi.SubscribeResult subscribeResult = createZuoraSubscription(accountInfo.billingAccountId,
            accountInfo.billedToContactId, accountInfo.soldToContactId, paymentMethodId, brand, brandTag, items,
            orderName, accountBrand, country);
        
        Zuora.zObject invoice;
        if (Test.isRunningTest()) {
            invoice = new Zuora.zObject('Invoice');
            invoice.setValue('Amount', 1);
        } else {
            invoice = getZuoraObject('Invoice', subscribeResult.InvoiceId, 'Amount');
        }
        
        Decimal invoiceAmount = (Decimal)invoice.getValue('Amount');
        
        Zuora.zObject paymentMethod;
        if (Test.isRunningTest()) {
            paymentMethod = new Zuora.zObject('PaymentMethod');
            paymentMethod.setValue('CreditCardType', 'American Express');
        } else {
            paymentMethod = getZuoraObject('PaymentMethod', paymentMethodId, 'CreditCardType, Email');
        }
        
        string accountingCode = paymentMethod.getValue('CreditCardType') == 'American Express'
            ? '110-1100-000-00' : '110-1101-000-00';
        
        string emailAddress = paymentMethod.getValue('Email') == null
            ? billTo.emailAddress : (string)paymentMethod.getValue('Email');
        
        Zuora.zApi.SaveResult paymentResult = saveZuoraObject('Payment', ZuoraOperation.ZCREATE, new Map<string, object> {
            'AccountId' => accountInfo.billingAccountId,
            'Amount' => invoiceAmount,
            'AppliedInvoiceAmount' => invoiceAmount,
            'EffectiveDate' => DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss'),
            'InvoiceId' => subscribeResult.InvoiceId,
            'PaymentMethodId' => paymentMethodId,
            'Status' => 'Processed',
            'Type' => 'Electronic',
            'BankName__c' => 'BOA',
            'BankAcctNbr__c' => 'BOA_USD3542',
            'AccountingCode' => accountingCode,
            'Comment' => emailAddress
        });
        
        Zuora.zObject payment;
        if (Test.isRunningTest()) {
            payment = new Zuora.zObject('Payment');
            payment.setValue('GatewayResponse', 'Approved');
        } else {
            payment = getZuoraObject('Payment', paymentResult.Id, 'GatewayResponse, GatewayResponseCode');
        }
        
        Boolean paymentApproved = payment.getValue('GatewayResponse') == 'Approved'
            || payment.getValue('GatewayResponseCode') == 'approve';
        
        string subscriptionId = subscribeResult.SubscriptionId;
        
        Contact contact = upsertContact(account, billTo);
        
        Opportunity opportunity = createOpportunity(account, contact, paymentMethodId, currencyCode, brand, brandTag,
            billTo, orderName, invoiceAmount, subscribeResult.SubscriptionId, paymentResult.Id, paymentApproved);
        
        updateZuoraSubscriptionAsync(brand, opportunity.Id, subscribeResult.SubscriptionId,
            accountInfo.billingAccountId, paymentApproved, orderName);
        
        if (!paymentApproved)
            throw new EndUserMessageException('The Zuora payment was not approved');
        
        return opportunity.Id;
    }
    
    global class ErrorResponse {
        public string message { get; set; }
        public string errorCode { get; set; }
    }
    
    global class BillTo {
        public string firstName { get; set; }
        public string lastName { get; set; }
        public string emailAddress { get; set; }
        public string phoneNumber { get; set; }
        public string street { get; set; }
        public string city { get; set; }
        public string state { get; set; }
        public string country { get; set; }
        public string postalCode { get; set; }
    }
    
    global class LineItem {
        public string productSku { get; set; }
        public Integer quantity { get; set; }
    }
    
    global class EndUserMessageException extends Exception {}
    
    global enum ZuoraOperation {ZCREATE, ZUPDATE}
    
    private static RESTZuoraOperationPlugIn.ReturnClass getOrCreateZuoraAccountInfo(
        Account account,
        string currencyCode,
        string brandTag,
        BillTo billTo,
        Account_Brand__c accountBrand
    ) {
        Map<string, string> params = new Map<string, string>();
        
        params.put('CRMAccountId', account.Id);
        params.put('IsoCurrency', currencyCode);
        params.put('BrandTag', brandTag);
        params.put('Operation', 'CreateBillingAccount');
        params.put('ProcessName', 'Webstore');
        params.put('PaymentTerm', 'Due Upon Receipt');
        params.put('ContextLanguage', 'English');
        params.put('PaymentMethod', 'Credit Card');
        params.put('BillToFirstName', billTo.firstName);
        params.put('BillToLastName', billTo.lastName);
        params.put('BillToAddress', billTo.street);
        params.put('BillToCity', billTo.city);
        params.put('BillToState', billTo.state);
        params.put('BillToPostalCode', billTo.postalCode);
        params.put('BillToCountry', account.BillingCountry);
        params.put('BillToWorkEmail', billTo.emailAddress);
        params.put('BillToWorkPhone', billTo.phoneNumber);
        params.put('CustomerServiceRepName', accountBrand.CS__r.Name);
        params.put('SalesRepName', accountBrand.Primary_Owner__r.Name);
        params.put('SoldToFirstName', billTo.firstName);
        params.put('SoldToLastName', billTo.lastName);
        params.put('SoldToAddress', billTo.street);
        params.put('SoldToCity', billTo.city);
        params.put('SoldToState', billTo.state);
        params.put('SoldToPostalCode', billTo.postalCode);
        params.put('SoldToCountry', account.BillingCountry);
        params.put('SoldToWorkEmail', billTo.emailAddress);
        params.put('SoldToWorkPhone', billTo.phoneNumber);
        
        RESTZuoraOperationPlugIn.ReturnClass accountInfo;
        
        if (Test.isRunningTest())
            accountInfo = new RESTZuoraOperationPlugIn.ReturnClass('', '', '', '', 'Successful');
        else
            accountInfo = RESTZuoraOperationPlugIn.ZuoraOperationHandler(params);
        
        if (accountInfo == null)
            throw new EndUserMessageException('An error occurred getting or creating the Zuora account');
        
        if (accountInfo.message != 'Successful')
            throw new EndUserMessageException('An error occurred getting or creating the Zuora account: '
                + accountInfo.message);
        
        return accountInfo;
    }
    
    private static Zuora.zApi.SubscribeResult createZuoraSubscription(
        string billingAccountId,
        string billedToContactId,
        string soldToContactId,
        string paymentMethodId,
        string brandName,
        string brandTag,
        List<LineItem> lineItems,
        string orderName,
        Account_Brand__c accountBrand,
        pw_ccpro__CountryObject__c country
    ) {
        Zuora.zApi.SubscribeRequest subscribeRequest = new Zuora.zApi.SubscribeRequest();
        
        subscribeRequest.ZAccount = new Zuora.zObject('Account');
        subscribeRequest.ZAccount.setValue('Id', billingAccountId);
        
        subscribeRequest.BillToContact = new Zuora.zObject('Contact');
        subscribeRequest.BillToContact.setValue('Id', billedToContactId);
        
        subscribeRequest.SoldToContact = new Zuora.zObject('Contact');
        subscribeRequest.SoldToContact.setValue('Id', soldToContactId);
        
        subscribeRequest.PaymentMethod = new Zuora.zObject('PaymentMethod');
        subscribeRequest.PaymentMethod.setValue('Id', paymentMethodId);
        
        string now = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss');
        string endDate = DateTime.now().addYears(1).addDays(-1).format('yyyy-MM-dd');
        
        subscribeRequest.SubscriptionData = new Zuora.zApi.SubscriptionData();
        subscribeRequest.SubscriptionData.Subscription = new Zuora.zObject('Subscription');
        subscribeRequest.SubscriptionData.Subscription.setValue('BrandTag__c', brandTag);
        subscribeRequest.SubscriptionData.Subscription.setValue('Name', orderName);
        subscribeRequest.SubscriptionData.Subscription.setValue('TermType', 'TERMED');
        subscribeRequest.SubscriptionData.Subscription.setValue('InitialTerm', 12);
        subscribeRequest.SubscriptionData.Subscription.setValue('ContractEffectiveDate', now);
        subscribeRequest.SubscriptionData.Subscription.setValue('ServiceActivationDate', now);
        subscribeRequest.SubscriptionData.Subscription.setValue('ContractAcceptanceDate', now);
        subscribeRequest.SubscriptionData.Subscription.setValue('TermStartDate', now);
        subscribeRequest.SubscriptionData.Subscription.setValue('Service_End_Date__c', endDate);
        subscribeRequest.SubscriptionData.Subscription.setValue('Deferred_Bill_Date__c', DateTime.now().format('yyyy-MM-dd'));
        subscribeRequest.SubscriptionData.Subscription.setValue('OrginalSubscriptionEndDate__c', endDate);
        subscribeRequest.SubscriptionData.Subscription.setValue('Status', 'Active');
        subscribeRequest.SubscriptionData.Subscription.setValue('AutoRenew', 'false');
        subscribeRequest.SubscriptionData.Subscription.setValue('IsInvoiceSeparate', 'true');
        subscribeRequest.SubscriptionData.Subscription.setValue('RenewalTerm', '0');
        subscribeRequest.SubscriptionData.Subscription.setValue('Global_Deal__c', 'false');
        subscribeRequest.SubscriptionData.Subscription.setValue('ContractChannel__c', accountBrand.Primary_Owner__r.Area__c);
        subscribeRequest.SubscriptionData.Subscription.setValue('ContractOwner__c', accountBrand.Primary_Owner__r.Name);
        subscribeRequest.SubscriptionData.Subscription.setValue('Billing_Frequency__c', 'One-Time');
        
        subscribeRequest.SubscribeOptions = new Zuora.zApi.SubscribeOptions();
        subscribeRequest.SubscribeOptions.GenerateInvoice = true;
        subscribeRequest.SubscribeOptions.ProcessPayments = false;
        
        subscribeRequest.SubscriptionData.RatePlanData = new List<Zuora.zObject>();
        
        for (LineItem lineItem : lineItems) {
            Zuora.zObject ratePlanData = getRatePlanData(lineItem, brandTag, accountBrand, country);
            subscribeRequest.SubscriptionData.RatePlanData.add(ratePlanData);
        }
        
        Zuora.zApi.SubscribeResult subscribeResult;
        
        if (Test.isRunningTest()) {
            subscribeResult = new Zuora.zApi.SubscribeResult();
            subscribeResult.success = true;
            
            return subscribeResult;
        }
        
        List<Zuora.zApi.SubscribeResult> subscribeResults = zuoraApi.zsubscribe(new List<Zuora.zApi.SubscribeRequest> {
            subscribeRequest
        });
        
        System.debug('Zuora subscribe request: ' + Zuora.zApi.currentLogger.request);
        System.debug('Zuora subscribe response: ' + Zuora.zApi.currentLogger.response);
        
        if (subscribeResults == null || subscribeResults.isEmpty())
            throw new EndUserMessageException('An error occurred creating the Zuora subscription');
        
        subscribeResult = subscribeResults.get(0);
        
        if (!subscribeResult.success) {
            string message = '';
            
            for (Zuora.zObject error : subscribeResult.errors) {
                if (error.getValue('Field') != null) {
                    message += (string)error.getValue('Code') + ' on field ' + error.getValue('Field') + ' - '
                        + error.getValue('Message') + '\n';
                } else {
                    message += (string)error.getValue('Code') + ' - ' + error.getValue('Message') + '\n';
                }
            }
            
            throw new EndUserMessageException('An error occurred creating the Zuora subscription: ' + message);
        }
        
        return subscribeResult;
    }
    
    private static Zuora.zObject getRatePlanData(
        LineItem lineItem, 
        string brandTag,
        Account_Brand__c accountBrand,
        pw_ccpro__CountryObject__c country
    ) {
        CCAPI_ZuoraProductSkuQuery.ZuoraProduct zuoraProduct;
        
        if (Test.isRunningTest())
            zuoraProduct = new CCAPI_ZuoraProductSkuQuery.ZuoraProduct();
        else
            zuoraProduct = CCAPI_ZuoraProductSkuQuery.GetEFCWebstoreZuoraProduct(lineItem.productSku, brandTag);
        
        if (zuoraProduct == null)
            throw new EndUserMessageException('Zuora product not found for SKU ' + lineItem.productSku
                + ' and brand tag ' + brandTag);
        
        Zuora.zObject ratePlanCharge = new Zuora.zObject('RatePlanCharge');
        ratePlanCharge.setValue('ProductRatePlanChargeId', zuoraProduct.productRatePlanChargeID);
        ratePlanCharge.setValue('Quantity', lineItem.quantity);
        ratePlanCharge.setValue('IsPrimarySalesRepOwner__c', 'true');
        ratePlanCharge.setValue('Sales_Representative__c', accountBrand.Primary_Owner__r.Name);
        ratePlanCharge.setValue('SalesRepId__c', accountBrand.Primary_Owner__c);
        ratePlanCharge.setValue('Sale_Type__c', 'Standard');
        ratePlanCharge.setValue('Region__c', country.Region__c);
        ratePlanCharge.setValue('EnergyRegion__c', country.Region_Energy__c);
        ratePlanCharge.setValue('SubRegion1__c', country.Sub_Region1__c);
        ratePlanCharge.setValue('SubRegion2__c', country.Sub_Region2__c);
        // TODO: this field isn't specified in the mapping doc - do we need it?
        ratePlanCharge.setValue('TriggerEvent', 'ServiceActivation');
        
        Zuora.zObject ratePlanChargeData = new Zuora.zObject('RatePlanChargeData');
        ratePlanChargeData.setValue('RatePlanCharge', ratePlanCharge);
        
        Zuora.zObject ratePlan = new Zuora.zObject('RatePlan');
        ratePlan.setValue('ProductRatePlanId', zuoraProduct.productRatePlanID);
        
        Zuora.zObject ratePlanData = new Zuora.zObject('RatePlanData');
        ratePlanData.setValue('RatePlanChargeData', new List<Zuora.zObject> { ratePlanChargeData });
        ratePlanData.setValue('RatePlan', ratePlan);
        
        return ratePlanData;
    }
    
    private static Contact upsertContact(Account account, BillTo billTo) {
        Contact contact = new Contact();
        contact.FirstName = billTo.firstName;
        contact.LastName = billTo.lastName;
        contact.MailingStreet = billTo.street;
        contact.MailingCity = billTo.city;
        contact.MailingState = billTo.state;
        contact.MailingPostalCode = billTo.postalCode;
        contact.MailingCountry = billTo.country;
        contact.Email = billTo.emailAddress;
        contact.Phone = billTo.phoneNumber;
        contact.AccountId = account.Id;
        
        Utils_AccountContactCreation.ReturnContact contactSaveResult = Utils_AccountContactCreation.fetchDuplicateContacts(contact);
        
        if (contactSaveResult.MatchType == 'Error Encountered')
            throw new EndUserMessageException(contactSaveResult.Remark);
        
        if (contactSaveResult.MatchType == 'Existing Contact')
            contact = contactSaveResult.MatchedContact;
        
        System.debug('Contact  ' + billTo.firstName + ' ' + billTo.lastName
            + ' :' + billTo.emailAddress + ' was ' + contactSaveResult.MatchType
            + '. Contact ID:' + contact.Id);
        
        return contact;
    }
    
    private static Opportunity createOpportunity(
        Account account,
        Contact contact,
        string paymentMethodId,
        string currencyCode,
        string brandName,
        string brandTag,
        BillTo billTo,
        string orderName,
        Decimal invoiceAmount,
        string subscriptionId,
        string paymentId,
        Boolean paymentApproved
    ) {
        Brand__c brand = findBrand(brandName);
        Account_Brand__c accountBrand = findAccountBrand(account.Id, brandName);
        
        String pricebook2Id;
        List<Pricebook2> pricebook2Lst = [
            SELECT Id
            FROM Pricebook2
            LIMIT 1
        ];
        
        if (pricebook2Lst.size() > 0)
            pricebook2Id = pricebook2Lst[0].Id;
        
        String recordTypeId;
        List<RecordType> recordTypeLst = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType='Opportunity'
            AND DeveloperName = 'Webstore'
            LIMIT 1
        ];
        
        if (recordTypeLst.size() > 0)
            recordTypeId = recordTypeLst[0].Id;
        
        Opportunity newOpportunity = new Opportunity(
            AccountId = account.Id,
            Name = orderName,
            CloseDate = Date.today(),
            BrandTag__c = brandTag,
            Primary_Brand__c = brandName,
            Brands__c = brandName,
            Contact__c = contact.Id,
            Contract_Date__c = Date.today(),
            CurrencyIsoCode = currencyCode,
            Sent_to_Billing__c = DateTime.now(),
            Approval_Source__c = 'Electronic',
            hasConfirmed_Owner_Assignments__c = true,
            Pricebook2Id = pricebook2Id,
            OwnerId = accountBrand.Primary_Owner__c,
            Provisioning_Owner__c = UserInfo.getUserId(),
            RecordTypeId = recordTypeId,
            Renewal_Date_Assigned__c = Date.today().addDays(32),
            Renewal_Feedback__c = 'Declined - Webstore',
            ZuoraPaymentID__c = paymentId
        );
        
        if (paymentApproved) {
            newOpportunity.StageName = 'Closed Won';
        } else {
            newOpportunity.Closed_Lost_Reasons__c = 'Webstore - Failed';
            newOpportunity.StageName = 'Closed Lost';
        }
        
        insert newOpportunity;
        
        // We have to update this field after the trigger has run
        newOpportunity.Provisioning_Status__c = 'Sent to Billing';
        
        update newOpportunity;
        
        pw_ccpro__CountryObject__c country = findCountry(billTo.country);
        
        PricebookEntry priceBookEntry = [
            SELECT Id,
                Name,
                CurrencyIsoCode,
                UnitPrice
            FROM PricebookEntry
            WHERE Name = :brandName
            AND CurrencyIsoCode = :currencyCode
            LIMIT 1
        ];
        
        // TODO: why is this commented out? do we need this? can we delete it?
        //if (sProductRatePlanCharge == null)
        //    sProductRatePlanCharge = getProductRatePlanCharge(varifiedWebstoreOrder);
        
        OpportunityLineItem newOpportunityLineItem = new OpportunityLineItem(
            PricebookEntryId = priceBookEntry.Id,
            // TODO: mapping doc refers to this but get error saying field is not writable when compiling. think this is implied by pricebook entry?
            //CurrencyIsoCode = currencyCode,
            Quantity = 1,
            UnitPrice = invoiceAmount,
            Product_Group__c = 'Posting',
            Sub_Category__c = 'Webstore',
            Sale_Type__c = 'Standard',
            // TODO: mapping doc refers to date not service date - is this correct?
            ServiceDate = Date.today(),
            OpportunityId = newOpportunity.Id,
            BrandTag__c = brandTag,
            Brand__c = brand.Id,
            Country__c = country.Id
        );
        
        insert newOpportunityLineItem;
        
        return newOpportunity;
    }
    
    private static Account findAccount(string accountId) {
        List<Account> queryResults = [
            SELECT Id, Name, BillingCountry
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        
        if (queryResults.isEmpty())
            throw new QueryException('Account not found for account ID ' + accountId);
        
        return queryResults.get(0);
    }
    
    private static Account_Brand__c findAccountBrand(string accountId, string brandName) {
        List<Account_Brand__c> queryResults = [
            SELECT Primary_Owner__c, CS__c, Primary_Owner__r.Name, CS__r.Name, Primary_Owner__r.Area__c
            FROM Account_Brand__c
            WHERE Account__c = :accountId
            AND Brand__r.Name = :brandName
            LIMIT 1
        ];
        
        if (queryResults.isEmpty())
            throw new QueryException('Account brand not found for account ID ' + accountId + ' and brand name '
                + brandName);
        
        return queryResults.get(0);
    }
    
    private static Brand__c findBrand(string brandName) {
        List<Brand__c> queryResults = [
            SELECT Id
            FROM Brand__c
            WHERE Name = :brandName
            LIMIT 1
        ];
        
        if (queryResults.isEmpty())
            throw new QueryException('Brand not found for brand name ' + brandName);
        
        return queryResults.get(0);
    }
    
    private static pw_ccpro__CountryObject__c findCountry(string country) {
        List<pw_ccpro__CountryObject__c> queryResults = [
            SELECT Id, Region__c, Sub_Region1__c, Sub_Region2__c, Region_Energy__c
            FROM pw_ccpro__CountryObject__c
            WHERE (pw_ccpro__IsoCode_2__c = :country.toUpperCase() OR name = :country)
            LIMIT 1
        ];
        
        if (queryResults.isEmpty())
            throw new QueryException('Country not found for ' + country);
        
        return queryResults.get(0);
    }
    
    // Returns a random integer between min (inclusive) and max (inclusive)
    private static Integer getRandomInt(Integer min, Integer max) {
        double random = Math.floor(Math.random() * (max - min + 1)) + min;
        return random.intValue();
    }
    
    private static Zuora.zObject getZuoraObject(string objectType, string objectId, string fieldNames) {
        List<Zuora.zObject> queryResults = zuoraApi.zquery('SELECT ' + fieldNames + ' FROM ' + objectType
            + ' WHERE ID =\'' + objectId + '\'');
        
        System.debug('Zuora query request: ' + Zuora.zApi.currentLogger.request);
        System.debug('Zuora query response: ' + Zuora.zApi.currentLogger.response);
        
        if (queryResults == null || queryResults.isEmpty())
            throw new QueryException('Zuora object of type ' + objectType + ' not found with ID ' + objectId);
        
        return queryResults.get(0);
    }
    
    private static Zuora.zApi.SaveResult saveZuoraObject(string objectType, ZuoraOperation op, Map<string, object> params) {
        Zuora.zObject obj = new Zuora.zObject(objectType);
        
        for (string key : params.keySet())
            obj.setValue(key, params.get(key));
        
        Zuora.zApi.SaveResult saveResult;
        
        if (Test.isRunningTest()) {
            saveResult = new Zuora.zApi.SaveResult();
            saveResult.success = true;
            
            return saveResult;
        }
        
        List<Zuora.zApi.SaveResult> saveResults;
        
        if (op == ZuoraOperation.ZCREATE)
            saveResults = zuoraApi.zcreate(new List<Zuora.zObject> { obj });
        else if (op == ZuoraOperation.ZUPDATE)
            saveResults = zuoraApi.zupdate(new List<Zuora.zObject> { obj });
        
        System.debug('Zuora save request: ' + Zuora.zApi.currentLogger.request);
        System.debug('Zuora save response: ' + Zuora.zApi.currentLogger.response);
        
        if (saveResults == null || saveResults.isEmpty())
            throw new EndUserMessageException('An error occurred saving Zuora object of type ' + objectType
                + ' with ID ' + obj.getValue('Id'));
        
        saveResult = saveResults.get(0);
        
        if (!saveResult.success) {
            string message = '';
            
            for (Zuora.zObject error : saveResult.errors) {
                if (error.getValue('Field') != null) {
                    message += (string)error.getValue('Code') + ' on field ' + error.getValue('Field') + ' - '
                        + error.getValue('Message') + '\n';
                } else {
                    message += (string)error.getValue('Code') + ' - ' + error.getValue('Message') + '\n';
                }
            }
            
            throw new EndUserMessageException('An error occurred saving Zuora object of type ' + objectType
                + ' with ID ' + obj.getValue('Id') + ': ' + message);
        }
        
        return saveResult;
    }
    
    // Updates the Zuora subscription with properties from the newly created opportunity
    // This has to be done in a future annotated method because we can't call out to an external web service before
    // the transaction has been committed
    @future(callout=true)
    private static void updateZuoraSubscriptionAsync(
        string brandName,
        string opportunityId,
        string subscriptionId,
        string billingAccountId,
        Boolean paymentApproved,
        string orderName
    ) {
        Map<string, object> params = new Map<string, object> {
            'Id' => subscriptionId,
            'Notes' => 'Generated by ' + brandName + ' Webstore ZContract for Order ID ' + opportunityId,
            'Order_ID__c' => opportunityId
        };
        
        if (!paymentApproved)
            params.put('Service_End_Date__c', DateTime.now().format('yyyy-MM-dd'));
        
        if (!Test.isRunningTest())
            zuoraApi.zlogin();
        
        saveZuoraObject('Subscription', ZuoraOperation.ZUPDATE, params);
        
        if (!paymentApproved)
            cancelZuoraSubscription(orderName, subscriptionId);
        
        syncZuora(new Set<String> {
            billingAccountId
        });
    }
    
    private static void cancelZuoraSubscription(string orderName, string subscriptionId) {
        string now = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss');
        
        Zuora.zObject amendment = new Zuora.zObject('Amendment');
        amendment.setValue('ContractEffectiveDate', now);
        amendment.setValue('EffectiveDate', now);
        amendment.setValue('Name', orderName + ' Cancellation');
        amendment.setValue('Status', 'Completed');
        amendment.setValue('SubscriptionId', subscriptionId);
        amendment.setValue('Type', 'Cancellation');
        
        Zuora.zApi.AmendRequest amendRequest = new Zuora.zApi.AmendRequest();
        amendRequest.amendments = new List<Zuora.zObject> {
            amendment
        };
        
        if (Test.isRunningTest())
            return;
        
        zuoraApi.zamend(new List<Zuora.zApi.AmendRequest> {
            amendRequest
        });
        
        System.debug('Zuora amend request: ' + Zuora.zApi.currentLogger.request);
        System.debug('Zuora amend response: ' + Zuora.zApi.currentLogger.response);
    }
    
    private static void syncZuora(Set<String> idSet) {
        if (Test.isRunningTest())
            return;
        
        Zuora.OnDemandSyncManager syncManager = new Zuora.OnDemandSyncManager();
        syncManager.emailNotificationEnabled = false;
        syncManager.syncZuoraObjectIdSet = idSet;
        syncManager.sendRequest();
    }
    
}