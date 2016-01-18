global class WebstoreOrderSendToZBilling {
    public static Zuora.zApi zApiInstance = new Zuora.zApi();    
    public static Map<Id, Zuora.zObject> wsozAcctMap;
    public static Map<Id, Zuora.zObject> wsozContMap;
    private static List<Webstore_Order__c> webstoreLst;
    private static List<String> zProductNameLst = new List<String>();
    private static Opportunity sOpportunity;
    private static Contact sContact;
    private static String InvoiceTemplateId;
    private static String InvoiceTemplateName;
    private static String PaymentGateway;
    public  static String paymentMethodId;
    public  static String defaultPaymentMethodId;
    private static String opportunityLineDesc = 'Auto Generated Webstore Order';
    private static String taskPriority = 'High';
    private static String taskStatus = 'Not Started';
    private static String zProductName = 'Webstore (DI)';
    private static String taskOwnerType = 'Webstore Upsell';
    private static String taskCSRType = 'Account Reviewed';
    public static zqu__ProductRatePlanCharge__c sProductRatePlanCharge;
    public static zqu__ProductRatePlanChargeTier__c sProductRatePlanChargeTier;
    private static String accountName;
    private static String accountNumberAssigned;  
    private static String zProductRatePlanId;
    private static String zChargeId;
    private static String returnMessage = ''; 
    private static boolean hasDefaultPayment = false;
    // variables compatible with unit test
    public static Zuora.zObject zPaymentMethod;  
    public static Zuora.zObject zAccount;
    public static List<Zuora.zApi.SubscribeResult> SubscribeResultLst;
    public static String zoql;
    private static RESTZuoraOperationPlugIn.ReturnClass billingAcctWSResult;
  
    //=====================================================================================//
    // Method that creates objects related to webstore order after the order is verified
    //=====================================================================================//  
    webservice static List<String> createWebstoreReferenceObjects(String webstoreOrderId) { 
       List<String> webstoreOrderIdLst = new List<String>{webstoreOrderId};
       Webstore_Order__c singleWebstore = null;
       String approvalSource = 'Electronic' ;
       boolean hasConfirmedOwnerAssignments = true;
       String renewalFeedback = 'Declined - Webstore';
       String stageName = 'Closed Won';
       String provisioningOwnerId = UserInfo.getUserId();
       boolean hasOpportunity = false;
       String brandName = null;
       String brandId = null;
       String primaryOwnerId = null;
       String customerServicesId = null;
       String opportunityId = null;
       opportunityLineDesc = 'Auto Generated Webstore Order';
       taskPriority = 'High';
       taskStatus = 'Not Started';
       zProductName = 'Webstore (DI)';
       taskOwnerType = 'Webstore Upsell';
       taskCSRType = 'Account Reviewed';
       accountName = null;
       accountNumberAssigned = null;
       List<Opportunity> newOpportunityLst = new List<Opportunity>();
       boolean isTherePendingOrder = false;
       
       if (singleWebstore == null) singleWebstore = getWebstoreOrder(webstoreOrderId);       
       if (sProductRatePlanChargeTier == null) sProductRatePlanChargeTier = getProductRatePlanChargeTier(singleWebstore); 
       if (sProductRatePlanChargeTier == null) return returnRejectReason(singleWebstore, 'The product was not found in the product catalog');                          
       if (!singleWebstore.Status__c.equals('Pending')) return returnRejectReason(singleWebstore, 'Only Pending Order can be Processed');
       if (singleWebstore.Webstore_Order_Lines__r.size() == 0) return returnRejectReason(singleWebstore, 'Webstore Order Line is required');
       
       if (singleWebstore.Account_Brand__r.Primary_Owner__c == null || singleWebstore.Account_Brand__r.Primary_Owner__r.IsActive == false ||singleWebstore.Account_Brand__r.CS__c == null || singleWebstore.Account_Brand__r.CS__r.IsActive == false) return returnRejectReason(singleWebstore, 'Active Owner(s) Required in Account Brand');
       if (singleWebstore.Account_Brand__r.Primary_Owner__r.DefaultBrand__c == null) return returnRejectReason(singleWebstore, 'Default Brand is Required for Primary Owner');
       if (singleWebstore.Account_Brand__r.Primary_Owner__r.Default_BrandTag__c == null) return returnRejectReason(singleWebstore, 'Default BrandTag is Required for Primary Owner');
       if (!singleWebstore.Account_Brand__r.Primary_Owner__r.Default_BrandTag__c.equals(sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c)) return returnRejectReason(singleWebstore, 'Primary Owner Default BrandTag does not match Product BrandTag');
       if (singleWebstore.Account__c == null || singleWebstore.Account_Brand__c == null ||singleWebstore.Contact__c == null || singleWebstore.User_Group__c == null || !'Ready to Process'.equals(singleWebstore.Data_Integrity__c)) return returnRejectReason(singleWebstore, 'All Reference Objects are Required');
       if (!'Validated'.equals(singleWebstore.Account__r.Validation_Status__c)) return returnRejectReason(singleWebstore, 'Account needs to be Validated');
       else { 
        isTherePendingOrder = true;
        //Start population new Opportunity list
        hasOpportunity = singleWebstore.Opportunities__r.size() > 0;
        hasConfirmedOwnerAssignments = true;                 
        // Mark the order to receive intro email
        singleWebstore.Send_Intro_Email__c = true; 
        if (!hasOpportunity) {
          sOpportunity = createOpportunity(singleWebstore);
          newOpportunityLst.add(sOpportunity);
        }   //End Opportunity collection                     
       }
       
       //Populate Product catalog collection 
       if (sProductRatePlanChargeTier == null) sProductRatePlanChargeTier = getProductRatePlanChargeTier(singleWebstore);
                          
        //Existing Product User collection                 
        List<Product_User__c> productUserLst = [SELECT Account_Brand__c, Id, End_Date__c, Start_Date__c, Status__c, User_Group__c, Username__c, Contact__c 
            FROM Product_User__c WHERE Username__c = :singleWebstore.Email__c AND User_Group__c = :singleWebstore.User_Group__c AND Account_Brand__c = :singleWebstore.Account_Brand__c]; 
        List<Product_User__c> productUserUpsertLst = new List<Product_User__c>();
        
        //Existing tasks collection          
        List<Task> existingTaskLst = [SELECT Id, WhatId FROM Task WHERE WhatId = :singleWebstore.Id AND Status = :taskStatus];                                      
        List<Task> taskUpsertLst = new List<Task>(); 
        
        boolean hasProductUser = false;  
            for (Product_User__c productUser : productUserLst) {
              if ((singleWebstore.Account_Brand__c.equals(productUser.Account_Brand__c) && singleWebstore.Email__c.equals(productUser.Username__c) && singleWebstore.User_Group__c.equals(productUser.User_Group__c))) {                     
                  //CC-3491 Check whether a product user has contact       
                  if (productUser.Contact__c == null) {
                     singleWebstore.Status__c = 'Failed';
                     singleWebstore.Reason__c = 'Product User must have a contact'; 
                  }
                  hasProductUser = true;
                  if (productUser.Status__c.equals('Inactive')) {
                     productUser.Status__c = 'Active';
                     productUser.Start_Date__c = singleWebstore.Purchase_Date__c.date();
                     productUser.End_Date__c = singleWebstore.Purchase_Date__c.date().addMonths(singleWebstore.Initial_Term__c.intValue());
                     productUserUpsertLst.add(productUser);
                  }
              }
            }
            if (!hasProductUser) {
               productUserUpsertLst.add(new Product_User__c(Account__c = singleWebstore.Account__c, Account_Brand__c = singleWebstore.Account_Brand__c, 
                    Contact__c = singleWebstore.Contact__c, CurrencyIsoCode = singleWebstore.CurrencyIsoCode, Start_Date__c = singleWebstore.Purchase_Date__c.date(),
                    End_Date__c = singleWebstore.Purchase_Date__c.date().addMonths(singleWebstore.Initial_Term__c.intValue()), 
                    isContact_on_Different_Account__c = false, No_Contact_Ref__c = false, Role__c = 'Job Poster',                     
                    Status__c = 'Active', User_Group__c = singleWebstore.User_Group__c, Username__c = singleWebstore.Email__c));
            }   
            //Check for existing task otherwise create one each for sales and customer service
            boolean hasTask = false;
            for (Task task : existingTaskLst) { 
               if (task.WhatId.equals(singleWebstore.Id)) {
                  hasTask = true;
                  //if(nwso.Status__c.equals('Pending')) nwso.Status__c = 'Processed';
                  break;
               }
            }
            if (!hasTask) {
                 boolean hasProductCatalog = false; 
                 if (sProductRatePlanChargeTier == null) sProductRatePlanChargeTier = getProductRatePlanChargeTier(singleWebstore);
                 String taskSubject = 'Webstore order for account ' + singleWebstore.Account_Brand__r.Account__r.Account_Number_Assigned__c; 
                 taskSubject +=  ' (' + singleWebstore.Account_Brand__r.Account__r.Name + ')' ;
                 String taskDescription = 'A webstore order ' + singleWebstore.Name + ' was posted on ' + singleWebstore.Purchase_Date__c.format('MM-dd-yyyy') + '.\n';
                 taskDescription += 'Contract value is ' + singleWebstore.CurrencyIsoCode + ' ' + singleWebstore.Contract_Value__c + '.\n'; 
                 taskDescription += 'Product purchased is ' + sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.Name;
                 taskDescription += ' (' + sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__SKU__c + ').\n';
                 taskDescription += ' Rate Plan is ' + sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Name + '.\n'; 
                 taskDescription += ' Charge name is ' + sProductRatePlanChargeTier.Name + '.';
                 if (singleWebstore.Website__c != null) taskDescription += '\n Customer website URL is ' + singleWebstore.Website__c; 
                 //Task for Sales
                 taskUpsertLst.add(new Task(ActivityDate = System.Today(), Brand__c = singleWebstore.account_Brand__r.Brand_Name__c, Description = taskDescription, Due_Date__c = System.Today(), 
                       OwnerId = singleWebstore.account_Brand__r.Primary_Owner__c, Priority = taskPriority, Status = taskStatus , Subject = taskSubject, Type__c = taskOwnerType, 
                       WhatId = singleWebstore.Id, WhoId = singleWebstore.Contact__c)); 
                 //Task for CS
                 if (sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.CSNotificationofOrderTask__c != null) {
                       if (sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.CSNotificationofOrderTask__c.tolowercase() == 'y' ) {
                             taskUpsertLst.add(new Task(ActivityDate = System.Today(), Brand__c = singleWebstore.Account_Brand__r.Brand_Name__c, Description = taskDescription, Due_Date__c = System.Today(), 
                                   OwnerId = singleWebstore.Account_Brand__r.CS__c, Priority = taskPriority, Status = taskStatus , Subject = taskSubject, Type__c = taskCSRType, 
                                   WhatId = singleWebstore.Id, WhoId = singleWebstore.Contact__c));
                       }
                 }
                 hasProductCatalog = true;
                         
                if (!hasProductCatalog) {
                   singleWebstore.Status__c = 'Failed';
                   singleWebstore.Reason__c = 'Product not found in product catalog'; 
                }
            }
       //Old loop end for webstoreorderlst
       //Make sure to capture status of each upsert below. Error happening will cause not to return appropriate... add exception handling if neccessary
       if (productUserUpsertLst.size() > 0) upsert productUserUpsertLst;
       if (taskUpsertLst.size() > 0) upsert taskUpsertLst;
       update singleWebstore;
       List<String> returnLst = new List<String>();
       returnLst.add((singleWebstore.Status__c.equals('Pending') ? 'Success:' : 'Failure:') + singleWebstore.Id);
       
       return returnLst;
    } // End of createWebstoreReferenceObjects()
         
   //=====================================================================================//
   // Method that populate reference objects
   //=====================================================================================//  
   public static boolean populateWebstoreReferenceObjects(ID wsoId) {
        webstoreLst = [SELECT Id, Name, Account__c, Country__c, Contract_Value__c, CurrencyIsoCode, Purchase_Date__c, Initial_Term__c,
              Email__c, User_Group__c, Contact__r.MailingStreet, Contact__r.MailingCity, Invoice_TemplateId__c, Invoice_TemplateName__c, Payment_Gateway__c,
              Contact__r.MailingCountry, Contact__r.Fax, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email, Contact__r.MailingPostalCode,
              Contact__r.MailingState, Contact__r.Phone, Account_Brand__r.Account__r.Name, Account_Brand__r.Account__r.Account_Number_Assigned__c,  
              Account_Brand__r.Primary_Owner__r.Name, Account_Brand__r.Primary_Owner__r.Division, Account_Brand__r.Primary_Owner__c, Account_Brand__r.CS__r.Name,Account_Brand__r.Brand_Name__c, 
              (SELECT BrandTag__c, Name, CloseDate, Owner.Area__c FROM Opportunities__r) 
              FROM Webstore_Order__c WHERE Id = :wsoId Limit 1]; 
           
       return true;
   }
     
   //=====================================================================================//
   // Method that create subscription in Zuora. Called from a button on the WSO page
   //=====================================================================================//  
   webservice static List<String> createZuoraSubscription(String webstoreOrderId){
       List<ID> wsoIdLst = new List<ID>();
       wsoIdLst.add(Id.valueOf(webstoreOrderId));
       List<String> zSubIdsLst = new List<String>();
       String billToId;
       String soldToId;
       Zuora.zObject paymentMethodObj;
       populateWebstoreReferenceObjects(Id.valueOf(webstoreOrderId));
       try {                                
              List<Zuora.zApi.SubscribeRequest> subscribeRequestLst = new List<Zuora.zApi.SubscribeRequest>();
              //zAccount = createZuoraAccount();               
              if (!Test.isRunningTest()) zApiInstance.zlogin(); 
              for (Webstore_Order__c wso : webstoreLst) {        
                  List<Opportunity> opportunityList = wso.Opportunities__r;        
                  if(sProductRatePlanChargeTier == null) sProductRatePlanChargeTier = getProductRatePlanChargeTier(wso); 

                  if (sProductRatePlanChargeTier != null && sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r != null && sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r != null) zProductRatePlanId = sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZuoraId__c; 
                  else {
                    zSubIdsLst.add('Failure:' + webstoreOrderId + ':' + 'Product catalog data hierarchy missing');
                    return zSubIdsLst;
                  }

                  zChargeId = sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c ; 
                  List<pw_ccpro__CountryObject__c> pwCountryLst = [SELECT Id, Name, Region__c, Region_Energy__c, Sub_Region1__c, Sub_Region2__c 
                         FROM pw_ccpro__CountryObject__c WHERE pw_ccpro__IsoCode_2__c = :wso.Country__c.toUpperCase() LIMIT 1];
                  pw_ccpro__CountryObject__c country = pwCountryLst.get(0);
                  Webstore_Order_line__c wsol = [SELECT Id, Quantity__c FROM Webstore_Order_line__c WHERE Webstore_Order__c = :wso.Id LIMIT 1];    
                  system.debug('###zProductRatePlanId:'+zProductRatePlanId);
                  system.debug('###zChargeId :'+zChargeId );                                      
                  Zuora.zObject[] zRatePlanDataArry = createRatePlanDataArray(zProductRatePlanId, zChargeId, country.Name, 
                        wso.Account_Brand__r.Primary_Owner__r.Name, country.Region__c, country.Sub_Region1__c, 
                        country.Sub_Region2__c, country.Region_Energy__c, wso.Account_Brand__r.Primary_Owner__c, (Integer)wsol.Quantity__c); 
                          
                  // Create Zuora ZuoraSubscription
                  Zuora.zObject zSubscription = createZuoraSubscription(wso);
                          
                  //subscription data
                  Zuora.zApi.SubscriptionData subscriptionData = new Zuora.zApi.SubscriptionData();
                  subscriptionData.Subscription = zSubscription;
                  subscriptionData.RatePlanData = zRatePlanDataArry;
      
                  // SubscribeInvoiceProcessingOptions - Need to find out how to set subscription level invoicing
                  //Zuora.zApi.SubscribeInvoiceProcessingOptions invoiceProcessingOptions = new Zuora.zApi.SubscribeInvoiceProcessingOptions();
                  //Zuora.zObject invoiceProcessingOptions = new Zuora.zObject('SubscribeInvoiceProcessingOptions');
                  //invoiceProcessingOptions.setValue('InvoiceProcessingScope', 'Subscription');
                  
                  //subscription options - Need to add SubscribeInvoiceProcessingOptions 
                  Zuora.zApi.SubscribeOptions subscribeOptions = new Zuora.zApi.SubscribeOptions();
                  subscribeOptions.GenerateInvoice = true;
                  subscribeOptions.ProcessPayments = false;                  
                  //subscribeOptions.SubscribeInvoiceProcessingOptions =  invoiceProcessingOptions;
                  //subscribe request
                  Zuora.zApi.SubscribeRequest subscribeRequest = new Zuora.zApi.SubscribeRequest();
                  billingAcctWSResult = getZuoraAccountContact(wso);
                  defaultPaymentMethodId = billingAcctWSResult.defaultPaymentMethodId;
                  if(Test.isrunningtest())
                  {
                      billingAcctWSResult.billingAccountId = '123';
                  }
                  if(billingAcctWSResult.billingAccountId == null || '' == billingAcctWSResult.billingAccountId)
                  {                      
                      zSubIdsLst.add('Failure:' + webstoreOrderId + ':' + 'processZuoraSubscription - Create Billing Account Failed, ' + billingAcctWSResult.message);
                  }
                  else
                  {                            
                      Zuora.zObject billingAccount = new Zuora.zObject('Account'); 
                      billingAccount.setValue('Id', billingAcctWSResult.billingAccountId);
                      subscribeRequest.ZAccount = billingAccount;
                      paymentMethodObj = getPaymentMethod();
                       if(Test.isrunningtest())
                      {
                          billingAcctWSResult.matchType = 'Existing Billing Account Found – Not Actively Billing';
                      }
                      //If existing Billing Account does not currently billing reset info to match Quote Process - JIRA CC-3182
                      if(billingAcctWSResult.matchType == 'Existing Billing Account Found – Not Actively Billing')
                      {
                          Zuora.zObject billToContact = new Zuora.zObject('Contact'); 
                          billToContact.setValue('Address1', wso.Contact__r.MailingStreet);
                          billToContact.setValue('City', wso.Contact__r.MailingCity);
                          billToContact.setValue('Country', wso.Contact__r.MailingCountry);
                          billToContact.setValue('FirstName', wso.Contact__r.FirstName);
                          billToContact.setValue('LastName', wso.Contact__r.LastName);
                          billToContact.setValue('PostalCode', wso.Contact__r.MailingPostalCode);
                          billToContact.setValue('State', wso.Contact__r.MailingState);
                          billToContact.setValue('PersonalEmail', wso.Contact__r.Email);
                          billToContact.setValue('WorkEmail', wso.Contact__r.Email);
                          billToContact.setValue('WorkPhone', wso.Contact__r.Phone);
                          billToContact.setValue('AccountId', billingAcctWSResult.billingAccountId);
                          billToContact.setValue('Id', billingAcctWSResult.billedToContactId); 
                          Zuora.zObject[] contactObjs;
                          if(Test.isrunningtest())
                          {
                               billingAcctWSResult.billedToContactId = '123';
                          }
                          if(billingAcctWSResult.billedToContactId == billingAcctWSResult.soldToContactId)
                          {
                              contactObjs = new Zuora.zObject[1];
                              contactObjs[0] = billToContact;
                          }
                          else
                          {
                              contactObjs = new Zuora.zObject[2];
                              contactObjs[0] = billToContact;
                              Zuora.zObject soldToContact = new Zuora.zObject('Contact'); 
                              soldToContact.setValue('Address1', wso.Contact__r.MailingStreet);
                              soldToContact.setValue('City', wso.Contact__r.MailingCity);
                              soldToContact.setValue('Country', wso.Contact__r.MailingCountry);
                              soldToContact.setValue('FirstName', wso.Contact__r.FirstName);
                              soldToContact.setValue('LastName', wso.Contact__r.LastName);
                              soldToContact.setValue('PostalCode', wso.Contact__r.MailingPostalCode);
                              soldToContact.setValue('State', wso.Contact__r.MailingState);
                              soldToContact.setValue('PersonalEmail', wso.Contact__r.Email);
                              soldToContact.setValue('WorkEmail', wso.Contact__r.Email);
                              soldToContact.setValue('WorkPhone', wso.Contact__r.Phone);
                              soldToContact.setValue('AccountId', billingAcctWSResult.billingAccountId);
                              soldToContact.setValue('Id', billingAcctWSResult.soldToContactId); 
                              contactObjs[1] = soldToContact;
                          }
                          List<Zuora.zApi.SaveResult> contactResults;
                          
                          if(!Test.isRunningTest())
                          {
                              contactResults = zApiInstance.zupdate(contactObjs);
                              if (contactResults[0].Success){
                                  billToId = billingAcctWSResult.billedToContactId; 
                                  soldToId = billingAcctWSResult.soldToContactId;
                              }
                          }
                          else
                          {
                            billToId = '0123456789';
                            soldToId = '0123456789';
                          }
                      }
                      else
                      {
                          //billToContact.setValue('Id', billingAcctWSResult.billedToContactId);                        
                      }
                      //subscribeRequest.BillToContact = billToContact; /* Bill to not required when account already exists */
                      subscribeRequest.SubscriptionData = subscriptionData;
                      subscribeRequest.PaymentMethod = paymentMethodObj;
                      subscribeRequest.SubscribeOptions = subscribeOptions; 
                      subscribeRequestLst.add(subscribeRequest);
                  }
          }
          List<Zuora.zObject> updAccountLst = new List<Zuora.zObject>();
          List<Zuora.zObject> accountPaymentList = new List<Zuora.zObject>();
          if (subscribeRequestLst.size() > 0) {  
              if (!Test.isRunningTest()) SubscribeResultLst = zApiInstance.zsubscribe(subscribeRequestLst);
              if(SubscribeResultLst != null) {        
                for (integer i = 0; i < SubscribeResultLst.size(); i++) {
                      Zuora.zApi.SubscribeResult result = SubscribeResultLst[i];
                      Webstore_Order__c wso = webstoreLst[i];
                      returnMessage = '';
                      if (result.Success) {
                         if (defaultPaymentMethodId == null) defaultPaymentMethodId = paymentMethodId;
                      
                         Zuora.zObject updAccount = new Zuora.zObject('Account'); 
                         updAccount.setValue('Id', result.AccountId);
                         //If existing Billing Account does not currently billing reset info to match Quote Process - JIRA CC-3182
                         //if(billingAcctWSResult.matchType == 'Existing Billing Account Found – Not Actively Billing')
                         if(billingAcctWSResult.isActiveBilling == 'false')
                         {
                            if('false' == billingAcctWSResult.isAutoPay) defaultPaymentMethodId = (String)paymentMethodObj.getValue('Id');                          
                            updAccount.setValue('PaymentTerm', 'Due Upon Receipt');
                            updAccount.setValue('PaymentGateway', wso.Payment_Gateway__c);
                            updAccount.setValue('InvoiceDeliveryPrefsEmail', 'TRUE');
                            updAccount.setValue('InvoiceDeliveryPrefsPrint', 'FALSE');
                            updAccount.setValue('InvoiceTemplateName__c', wso.Invoice_TemplateName__c);
                            updAccount.setValue('InvoiceTemplateId', wso.Invoice_TemplateId__c);
                            updAccount.setValue('BillToId', billToId);
                            updAccount.setValue('SoldToId', soldToId);
                            updAccount.setValue('Status', 'Active');
                            if(billingAcctWSResult.batch != 'Batch2')
                            {
                               updAccount.setValue('Batch', 'Batch10');
                            }
                         }
                         else if(billingAcctWSResult.matchType == 'New Billing Account Created')
                         {
                            updAccount.setValue('Batch', 'Batch10');                          
                         }
                         else
                         {
                            updAccount.setValue('Batch', 'Batch2');                          
                         }
                         updAccount.setValue('DefaultPaymentMethodId', defaultPaymentMethodId);
                         updAccountLst.add(updAccount);
                         
                         Zuora.zObject accountPayment = new Zuora.zObject('Payment');
                         accountPayment.setValue('AccountId', result.AccountId);
                         accountPayment.setValue('PaymentMethodId', PaymentMethodId);
                         accountPayment.setValue('Type', 'External');
                         // Check whether purchase date is last month. In with case use today's date
                         if (isAccountingPeriodOpen(wso.Purchase_Date__c)) accountPayment.setValue('EffectiveDate', wso.Purchase_Date__c.format('yyyy-MM-dd\'T\'HH:mm:ss'));
                         else accountPayment.setValue('EffectiveDate', Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss'));
                         accountPayment.setValue('Status', 'Processed');
                         accountPayment.setValue('Amount', wso.Contract_Value__c);
                         accountPayment.setValue('AppliedInvoiceAmount', wso.Contract_Value__c);
                         accountPayment.setValue('InvoiceId', result.InvoiceId);
                         accountPaymentList.add(accountPayment);                                          
                         accountPayment.setValue('ReferenceId', wso.Email__c);
                         accountPayment.setValue('AccountingCode', '110-1102-000-00');
                         accountPayment.setValue('BankName__c', 'BOA');
                         accountPayment.setValue('BankAcctNbr__c', 'BOA_DI_Webstore'); //--- Not in prod yet
                                 
                         if (updAccountLst.size() > 0) {
                            List<Zuora.zApi.SaveResult> updateResults = zApiInstance.zupdate(updAccountLst);
                            if (!updateResults[0].Success) {
                              Zuora.zObject[] errors = updateResults[0].errors;
                              for (Zuora.zObject error : errors) {
                                 returnMessage  += (String)error.getValue('Message');
                                 returnMessage  += ', ';
                              }
                            }
                            updAccountLst = new List<Zuora.zObject>();
                         }
                         if (accountPaymentList.size() > 0) {
                           List<Zuora.zApi.SaveResult> createResults = zApiInstance.zcreate(accountPaymentList);
                           if (!createResults[0].Success) {
                              Zuora.zObject[] errors = createResults[0].errors;
                              for (Zuora.zObject error : errors) {
                                 returnMessage  += (String)error.getValue('Message');
                                 returnMessage  += ', ';
                              }
                           }
                           returnMessage = returnMessage.replace(':', '-');                                                      
                           accountPaymentList = new List<Zuora.zObject>();
                         }
                         zSubIdsLst.add('Success:' + wso.Id + ':' + result.SubscriptionId + ':' + returnMessage);
                      } else {   //failure - get the errors
                        returnMessage = '';
                        Zuora.zObject[] errors = result.errors;
                        for (Zuora.zObject error : errors) {
                            returnMessage  += (String)error.getValue('Message');
                        }
                       system.debug(returnMessage);
                       zSubIdsLst.add('Failure:' + wso.Id + ':' + returnMessage);
                      } 
                    }
                }
           }
       }  catch (Zuora.zRemoteException ex) {
             system.debug('processZuoraSubscription - zRemoteException ' + ex.getMessage()); 
             zSubIdsLst.add('Failure:' + webstoreOrderId + ':' + 'processZuoraSubscription - zRemoteException ' + ex.getMessage());
          }
          catch (Zuora.zAPIException ex) {
            system.debug('processZuoraSubscription - zAPIException ' + ex.getMessage()); 
             zSubIdsLst.add('Failure:' + webstoreOrderId + ':' + 'processZuoraSubscription - zAPIException ' + ex.getMessage());
          } 
          catch (Zuora.zForceException ex) {
             system.debug('processZuoraSubscription - zForceException ' + ex.getMessage());
             zSubIdsLst.add('Failure:' + webstoreOrderId + ':' + 'processZuoraSubscription - zForceException ' + ex.getMessage());
          }
       
       return zSubIdsLst;
   }    
      
    public static RESTZuoraOperationPlugIn.ReturnClass getZuoraAccountContact(Webstore_Order__c wso)
    {
       Map<String, String> requestParameterMap = new Map<String, String>();
       requestParameterMap.put('Operation', 'CreateBillingAccount');
       requestParameterMap.put('CRMAccountId', wso.Account__c);
       requestParameterMap.put('IsoCurrency', wso.CurrencyIsoCode);
       requestParameterMap.put('BrandTag', 'Dice');
       requestParameterMap.put('PaymentMethod', 'CC Reference Transaction');
       requestParameterMap.put('ContextLanguage', 'English');
       requestParameterMap.put('PaymentTerm', 'Due Upon Receipt');
       requestParameterMap.put('SoldToAddress', wso.Contact__r.MailingStreet);
       requestParameterMap.put('SoldToCity', wso.Contact__r.MailingCity);
       requestParameterMap.put('SoldToCountry', wso.Contact__r.MailingCountry);
       requestParameterMap.put('SoldToPostalCode', wso.Contact__r.MailingPostalCode);
       requestParameterMap.put('SoldToState', wso.Contact__r.MailingState);
       requestParameterMap.put('SoldToFirstName', wso.Contact__r.FirstName);
       requestParameterMap.put('SoldToLastName', wso.Contact__r.LastName); 
       requestParameterMap.put('SoldToPersonalEmail', wso.Contact__r.Email);
       requestParameterMap.put('SoldToWorkEmail', wso.Contact__r.Email);
       requestParameterMap.put('SoldToWorkPhone', wso.Contact__r.Phone);
       requestParameterMap.put('BillToAddress', wso.Contact__r.MailingStreet);
       requestParameterMap.put('BillToCity', wso.Contact__r.MailingCity);
       requestParameterMap.put('BillToCountry', wso.Contact__r.MailingCountry);
       requestParameterMap.put('BillToPostalCode', wso.Contact__r.MailingPostalCode);
       requestParameterMap.put('BillToState', wso.Contact__r.MailingState);
       requestParameterMap.put('BillToFirstName', wso.Contact__r.FirstName);
       requestParameterMap.put('BillToLastName', wso.Contact__r.LastName); 
       requestParameterMap.put('BillToPersonalEmail', wso.Contact__r.Email);
       requestParameterMap.put('BillToWorkEmail', wso.Contact__r.Email);
       requestParameterMap.put('BillToWorkPhone', wso.Contact__r.Phone);
       requestParameterMap.put('CustomerServiceRepName', wso.Account_Brand__r.CS__r.Name);
       requestParameterMap.put('SalesRepName', wso.Account_Brand__r.Primary_Owner__r.Name);
       requestParameterMap.put('SalesRepDivision', wso.Account_Brand__r.Primary_Owner__r.Division);
       requestParameterMap.put('InvoiceDeliveryPref', 'Email');  
       requestParameterMap.put('ProcessName', 'Webstore'); 
       //We don't know the batch number yet. Don't assing Batch10
       //requestParameterMap.put('BillingBatchNo', 'Batch10'); 
       
       return RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap);
    }
    
    private static Zuora.zObject getPaymentMethod() {   
            zPaymentMethod = new Zuora.zObject('PaymentMethod');                  
            zoql = 'SELECT Id FROM PaymentMethod WHERE Name= \'CC Reference Transaction\' LIMIT 1';
            if (!Test.isRunningTest()) {
               zApiInstance.zlogin();
               List<Zuora.zObject> zobjs = zApiInstance.zquery(zoql);
               for (Zuora.zObject zobj : zobjs) {
                  zPaymentMethod.setValue('Id', (String)zobj.getValue('Id'));
                  zPaymentMethod.setValue('Type','CreditCardReferenceTransaction');
                  zPaymentMethod.setValue('Active','TRUE');
                  paymentMethodId = (String)zobj.getValue('Id');
               }
            } 
        return zPaymentMethod;
    }
    
    private static Zuora.zObject createZuoraSubscription(Webstore_Order__c wso) {
                  Zuora.zObject zSubscription = new Zuora.zObject('Subscription'); 
                  zSubscription.setValue('TermStartDate', wso.Purchase_Date__c.format('yyyy-MM-dd\'T\'HH:mm:ss'));
                  zSubscription.setValue('ContractEffectiveDate', wso.Purchase_Date__c.format('yyyy-MM-dd\'T\'HH:mm:ss'));
                  zSubscription.setValue('ContractAcceptanceDate', wso.Purchase_Date__c.format('yyyy-MM-dd\'T\'HH:mm:ss'));
                  zSubscription.setValue('ServiceActivationDate', wso.Purchase_Date__c.format('yyyy-MM-dd\'T\'HH:mm:ss'));
                  zSubscription.setValue('Service_End_Date__c', wso.Purchase_Date__c.AddMonths(wso.Initial_Term__c.intValue()).AddDays(-1).format('yyyy-MM-dd'));
                  zSubscription.setValue('OrginalSubscriptionEndDate__c', wso.Purchase_Date__c.AddMonths(wso.Initial_Term__c.intValue()).AddDays(-1).format('yyyy-MM-dd'));
                  zSubscription.setValue('InitialTerm', wso.Initial_Term__c);
                  zSubscription.setValue('RenewalTerm', 0);
                  zSubscription.setValue('Notes', 'Webstore ZContract auto-generated by the middleware for Order ' + wso.Name);
                  zSubscription.setValue('Status', 'Active');
                  zSubscription.setValue('IsInvoiceSeparate', 'TRUE');
                  zSubscription.setValue('BrandTag__c', wso.Opportunities__r[0].BrandTag__c);  
                  zSubscription.setValue('Name', wso.Opportunities__r[0].Name);       
                  zSubscription.setValue('ContractOwner__c', wso.Account_Brand__r.Primary_Owner__r.Name);
                  zSubscription.setValue('ContractChannel__c', wso.Opportunities__r[0].Owner.Area__c);
                  zSubscription.setValue('Global_Deal__c', 'false');
                  zSubscription.setValue('Deferred_Bill_Date__c', (datetime.newInstance(wso.Opportunities__r[0].CloseDate.year(), wso.Opportunities__r[0].CloseDate.month(),wso.Opportunities__r[0].CloseDate.day())).format('yyyy-MM-dd')); 
                  //cc-3010 - Quote Billing Frequency - Pull into Zuora Subscription Record
                  zSubscription.setValue('Billing_Frequency__c', 'One-Time');
                  return zSubscription;
    }
    
    //Accounting Period
    public static boolean isAccountingPeriodOpen(Datetime purchaseDate) {
        boolean isOpen = false;
        Zuora.zObject zAccountingPeriod = new Zuora.zObject('AccountingPeriod');                  
        zoql = 'SELECT StartDate, EndDate FROM AccountingPeriod Where Status = \'Open\' AND FiscalYear = ' + Datetime.now().format('yyyy');
        if (!Test.isRunningTest()) {
           zApiInstance.zlogin();
           List<Zuora.zObject> zobjs = zApiInstance.zquery(zoql);
           for (Zuora.zObject zobj : zobjs) {
                Datetime startDate = (Datetime)zobj.getValue('StartDate');
                Datetime endDate = (Datetime)zobj.getValue('EndDate');
                if(startDate <= purchaseDate && purchaseDate <= endDate ) {
                   isOpen = true;
                   break;
                }
           }
        }
        return isOpen;
    }    
    
    private static List<Zuora.zObject> createRatePlanDataArray(String productRatePlanId, String chargeId, String country,
                 String salesRep, String region, String subRegion1, String subRegion2, String energyRegion, String salesRepId, Integer quantity) { 
            Zuora.zObject zRatePlanCharge = new Zuora.zObject('RatePlanCharge');
            zRatePlanCharge.setValue('ProductRatePlanChargeId', chargeId);
            zRatePlanCharge.setValue('TriggerEvent', 'ServiceActivation');
            zRatePlanCharge.setValue('IsPrimarySalesRepOwner__c', 'TRUE');
            zRatePlanCharge.setValue('Sales_Representative__c', salesRep);
            zRatePlanCharge.setValue('SalesRepId__c', salesRepId);
            zRatePlanCharge.setValue('Country__c', country);
            zRatePlanCharge.setValue('Region__c', region);
            zRatePlanCharge.setValue('SubRegion1__c', subRegion1);
            zRatePlanCharge.setValue('SubRegion2__c', subRegion2);
            zRatePlanCharge.setValue('EnergyRegion__c', energyRegion);
            zRatePlanCharge.setValue('Sale_Type__c', 'Standard');
            zRatePlanCharge.setValue('Quantity', quantity);
                        
            Zuora.zObject zRatePlanChargeData = new Zuora.zObject('RatePlanChargeData');
            zRatePlanChargeData.setValue('RatePlanCharge', zRatePlanCharge);
            
            Zuora.zObject zRatePlan = new Zuora.zObject('RatePlan');
            zRatePlan.setValue('ProductRatePlanId', productRatePlanId);
            
            Zuora.zObject zRatePlanData = new Zuora.zObject('RatePlanData');
            zRatePlanData.setValue('RatePlan', zRatePlan);
            zRatePlanData.setValue('RatePlanChargeData', new List<Zuora.zObject> { zRatePlanChargeData });
            return new List<Zuora.zObject> { zRatePlanData }; 
        }
        
        public static Webstore_Order__c getWebstoreOrder(String WebstoreOrderId) {                 
            List<Webstore_Order__c> webstoreOrderLst = [SELECT Account__c, Account__r.Validation_Status__c, Account_Brand__c, Account_Brand__r.Brand__c, Account_Brand__r.Brand_Name__c,
                     Address_Line_1__c, Address_Line_2__c, Account_Brand__r.Primary_Owner__c, Account_Brand__r.Primary_Owner__r.IsActive, Account_Brand__r.Primary_Owner__r.Default_BrandTag__c,
                     Account_Brand__r.CS__c, Account_Brand__r.CS__r.IsActive, account_Brand__r.Account__r.Account_Number_Assigned__c, Account_Brand__r.Primary_Owner__r.Division,
                     Account_Brand__r.Primary_Owner__r.DefaultBrand__c, account_Brand__r.Account__r.Name, (SELECT Id, Name, BrandTag__c FROM Opportunities__r), Reason__c, Account_Validation_Status__c,
                     Billing_Account__c, Billing_Accounts__c, City__c, City_HQ__c, Company__c, Contact__c, Contract_Value__c, Country__c, Country_HQ__c,
                     CurrencyIsoCode, Customer_Segment__c, Data_Integrity__c, Email__c, External_Account_ID__c, Fax__c, First_Name__c, Id, Initial_Term__c,
                     IsVerified__c, Last_Name__c, Name, Order_ID__c, OwnerId, Phone__c, Postal_Code__c, Product_User__c, Purchase_Date__c, State__c, Status__c,
                     User_Group__c, Verification_Status__c, Website__c, Zuora_Subscription_ID__c, Invoice_TemplateId__c, Invoice_TemplateName__c, Payment_Gateway__c,
                     (SELECT Id FROM Webstore_Order_Lines__r)
                     FROM Webstore_Order__c WHERE Id = :Id.valueOf(webstoreOrderId) Limit 1];   
            return  webstoreOrderLst.get(0);
        }
        
        public static List<String> returnRejectReason(Webstore_Order__c rejectedWSO, String reason) {
            rejectedWSO.Status__c = 'Rejected';
            rejectedWSO.Reason__c = reason;
            update rejectedWSO;
            return new List<String>(); //'Failed business rules validation';
        }
        
       /* public static zqu__ProductRatePlanCharge__c getProductRatePlanCharge(Webstore_Order__c varifiedWebstoreOrder) {                              
            List<zqu__ProductRatePlanCharge__c> pRPChargeLst = [SELECT Name, zqu__ProductRatePlan__r.Name, zqu__ListPrice__c,zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c,
              zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c, zqu__ProductRatePlan__r.zqu__ZProduct__r.Name, zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__SKU__c,
              zqu__ProductRatePlan__r.zqu__ZProduct__r.BuildOppty__c, zqu__ProductRatePlan__r.zqu__ZProduct__r.CSNotificationofOrderTask__c, zqu__ProductRatePlan__r.zqu__ZProduct__r.UploadLogo__c,  
              zqu__ProductRatePlan__c, CurrencyIsoCode, zqu__ProductRatePlan__r.Brand__c, zqu__ZuoraId__c, zqu__ProductRatePlan__r.zqu__ZuoraId__c, zqu__ProductRatePlan__r.BrandTag__c
              FROM zqu__ProductRatePlanCharge__c 
              WHERE zqu__ProductRatePlan__r.Brand__c = :varifiedWebstoreOrder.Account_Brand__r.Brand_Name__c AND zqu__Deleted__c = false 
              AND zqu__ProductRatePlan__r.zqu__ZProduct__r.Name = 'Webstore (DI)' AND CurrencyIsoCode = :varifiedWebstoreOrder.CurrencyIsoCode
              AND zqu__ListPrice__c = :varifiedWebstoreOrder.Contract_Value__c AND zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c >= :System.Today() LIMIT 1];
              if(pRPChargeLst.size() <= 0) return null;
            return pRPChargeLst.get(0);
        }*/
        
        public static zqu__ProductRatePlanChargeTier__c getProductRatePlanChargeTier(Webstore_Order__c varifiedWebstoreOrder) {  
            List<Webstore_Order_Line__c> WSOrderLineList = [select id,SKU__c,Quantity__c from Webstore_Order_Line__c where Webstore_Order__c=:varifiedWebstoreOrder.Id];
            List<zqu__ProductRatePlanChargeTier__c> pRPChargeTierLst = [SELECT zqu__ZuoraId__c, zqu__Price__c, zqu__StartingUnit__c, zqu__EndingUnit__c, zqu__Tier__c,zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c,zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZuoraId__c,
            zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__ZuoraId__c,zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c,zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.Name,
            zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__SKU__c,zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c,zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c,            
            zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Name,zqu__ProductRatePlanChargeTier__c.Name,zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.CSNotificationofOrderTask__c            
                         FROM zqu__ProductRatePlanChargeTier__c 
            WHERE zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c = 'Webstore' AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c = :varifiedWebstoreOrder.Account_Brand__r.Brand_Name__c
            AND zqu__Deleted__c = false AND zqu__ProductRatePlanCharge__r.zqu__Deleted__c = false AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Deleted__c = false
            AND  zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__Deleted__c = false AND  zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__SKU__c =: WSOrderLineList[0].SKU__c
            and zqu__StartingUnit__c <= :WSOrderLineList[0].Quantity__c AND zqu__EndingUnit__c >= :WSOrderLineList[0].Quantity__c AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c >= :System.Today()];

            if (pRPChargeTierLst == null || pRPChargeTierLst.isEmpty()) return null;
            return pRPChargeTierLst.get(0);
            
        }
        
        public static Opportunity createOpportunity(Webstore_Order__c varifiedWebstoreOrder) { 
           String pricebook2Id;
           List<Pricebook2> pricebook2Lst = [SELECT Id FROM Pricebook2 LIMIT 1]; 
           if (pricebook2Lst.size() > 0) pricebook2Id = pricebook2Lst[0].Id;   
           String recordTypeId;           
           List<RecordType> recordTypeLst = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity'  AND DeveloperName = 'Webstore' LIMIT 1];   
           if (recordTypeLst.size() > 0) recordTypeId = recordTypeLst[0].Id;             
 
           double randomName = Math.floor(Math.random()*10000);
           if (randomName < 1000) randomName += 1000;
           String opportunityName = varifiedWebstoreOrder.Company__c == null ? varifiedWebstoreOrder.Last_Name__c 
                                    + ' ' + varifiedWebstoreOrder.First_Name__c : varifiedWebstoreOrder.Company__c; 
           opportunityName += ' ' + DateTime.now().format('MMddyyyy') + randomName.intValue();
           Opportunity newOpportunity = new Opportunity(Account_Brand__c = varifiedWebstoreOrder.Account_Brand__c, AccountId = varifiedWebstoreOrder.Account__c, 
                                           Amount = varifiedWebstoreOrder.Contract_Value__c, Approval_Source__c = 'Electronic',
                                           Brands__c = varifiedWebstoreOrder.account_Brand__r.Brand_Name__c, CloseDate = System.today(),
                                           Contact__c = varifiedWebstoreOrder.Contact__c, CurrencyIsoCode = varifiedWebstoreOrder.CurrencyIsoCode, 
                                           hasConfirmed_Owner_Assignments__c = true, Name = opportunityName,
                                           Pricebook2Id = pricebook2Id , OwnerId = varifiedWebstoreOrder.account_Brand__r.Primary_Owner__c,
                                           Provisioning_Owner__c = UserInfo.getUserId(), Provisioning_Status__c = Constants.STATUS_SENT_TO_BILLING,
                                           RecordTypeId = recordTypeId, Renewal_Date_Assigned__c = (varifiedWebstoreOrder.Purchase_Date__c.date() + 32),
                                           Renewal_Feedback__c = 'Declined - Webstore', StageName = 'Closed Won', Webstore_Order__c = varifiedWebstoreOrder.Id,
                                           BrandTag__c = varifiedWebstoreOrder.Account_Brand__r.Primary_Owner__r.Default_BrandTag__c, 
                                           Primary_Brand__c = varifiedWebstoreOrder.Account_Brand__r.Primary_Owner__r.DefaultBrand__c);
           insert newOpportunity;
           newOpportunity.Provisioning_Status__c = Constants.STATUS_SENT_TO_BILLING;
           update newOpportunity;
           List<pw_ccpro__CountryObject__c> pwCountryList = [SELECT Id  FROM pw_ccpro__CountryObject__c WHERE pw_ccpro__IsoCode_2__c = :varifiedWebstoreOrder.Country__c.toUpperCase() LIMIT 1];
           List<PricebookEntry> priceBookEntryLst = [SELECT Id, Name, CurrencyIsoCode FROM PricebookEntry WHERE Name = :varifiedWebstoreOrder.Account_Brand__r.Brand_Name__c
                     AND CurrencyIsoCode = :varifiedWebstoreOrder.CurrencyIsoCode LIMIT 1 ];
           if (sProductRatePlanChargeTier == null) sProductRatePlanChargeTier = getProductRatePlanChargeTier(varifiedWebstoreOrder);                  
           OpportunityLineItem newOpportunityLineItem = new OpportunityLineItem(Brand__c = varifiedWebstoreOrder.Account_Brand__r.Brand__c, 
                 Country__c = pwCountryList.get(0).Id, Description = opportunityLineDesc, OpportunityId = newOpportunity.Id, 
                 PricebookEntryId = priceBookEntryLst.get(0).Id, Quantity = 1, ServiceDate = varifiedWebstoreOrder.Purchase_Date__c.date(), 
                 UnitPrice = varifiedWebstoreOrder.Contract_Value__c, BrandTag__c = varifiedWebstoreOrder.Account_Brand__r.Primary_Owner__r.Default_BrandTag__c, 
                 Product_Group__c = sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c, 
                 Sub_Category__c = sProductRatePlanChargeTier.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c,
                 Sale_Type__c = 'Standard');
           insert newOpportunityLineItem;                            
           return newOpportunity;
        }
 
}