@RestResource(urlMapping='/ZuoraWSOperation/*')
  global with sharing class RESTZuoraOperationPlugIn implements Process.Plugin {
  /* Try to use getLevenshteinDistance for fuzzy matching */
  public static Zuora.zApi zApiInstance = new Zuora.zApi();  
  static String InvoiceDeliveryPref;
  static String BillingBatchNo;
  global Process.PluginResult invoke(Process.PluginRequest request) { 
            
        Map<String, String> requestParameterMap = new Map<String, String>();
        requestParameterMap.put('Operation', (String) request.inputParameters.get('Operation'));
        requestParameterMap.put('BillToAddress', (String) request.inputParameters.get('BillToAddress'));
        requestParameterMap.put('BillToCity', (String) request.inputParameters.get('BillToCity'));
        requestParameterMap.put('BillToCountry', (String) request.inputParameters.get('BillToCountry'));
        requestParameterMap.put('BillToFirstName', (String) request.inputParameters.get('BillToFirstName'));
        requestParameterMap.put('BillToLastName', (String) request.inputParameters.get('BillToLastName'));
        requestParameterMap.put('BillToPostalCode', (String) request.inputParameters.get('BillToPostalCode'));
        requestParameterMap.put('BillToState', (String) request.inputParameters.get('BillToState'));
        requestParameterMap.put('BillToPersonalEmail', (String) request.inputParameters.get('BillToPersonalEmail'));
        requestParameterMap.put('BillToWorkEmail', (String) request.inputParameters.get('BillToWorkEmail'));
        requestParameterMap.put('BillToWorkPhone', (String) request.inputParameters.get('BillToWorkPhone'));
        requestParameterMap.put('BrandTag', (String) request.inputParameters.get('BrandTag'));
        requestParameterMap.put('CRMAccountId', (String) request.inputParameters.get('CRMAccountId'));
        requestParameterMap.put('IsoCurrency', (String) request.inputParameters.get('IsoCurrency'));
        requestParameterMap.put('PaymentMethod', (String) request.inputParameters.get('PaymentMethod'));
        requestParameterMap.put('SoldToAddress', (String) request.inputParameters.get('SoldToAddress'));
        requestParameterMap.put('SoldToCity', (String) request.inputParameters.get('SoldToCity'));
        requestParameterMap.put('SoldToCountry', (String) request.inputParameters.get('SoldToCountry'));
        requestParameterMap.put('SoldToFirstName', (String) request.inputParameters.get('SoldToFirstName'));
        requestParameterMap.put('SoldToLastName', (String) request.inputParameters.get('SoldToLastName'));
        requestParameterMap.put('SoldToPostalCode', (String) request.inputParameters.get('SoldToPostalCode'));
        requestParameterMap.put('SoldToState', (String) request.inputParameters.get('SoldToState'));        
        requestParameterMap.put('SoldToPersonalEmail', (String) request.inputParameters.get('SoldToPersonalEmail'));
        requestParameterMap.put('SoldToWorkEmail', (String) request.inputParameters.get('SoldToWorkEmail'));
        requestParameterMap.put('SoldToWorkPhone', (String) request.inputParameters.get('SoldToWorkPhone'));
        requestParameterMap.put('ContextLanguage', (String) request.inputParameters.get('ContextLanguage')); 
        requestParameterMap.put('PaymentTerm', (String) request.inputParameters.get('PaymentTerm'));
        requestParameterMap.put('InvoiceTemplateName', (String) request.inputParameters.get('InvoiceTemplateName'));
        requestParameterMap.put('InvoiceDeliveryPref', (String) request.inputParameters.get('InvoiceDeliveryPref'));
        requestParameterMap.put('CustomerServiceRepName', (String) request.inputParameters.get('CustomerServiceRepName'));
        requestParameterMap.put('SalesRepName', (String) request.inputParameters.get('SalesRepName'));
        requestParameterMap.put('SalesRepDivision', (String) request.inputParameters.get('SalesRepDivision'));
        requestParameterMap.put('BillingBatchNo', (String) request.inputParameters.get('BillingBatchNo'));
        requestParameterMap.put('ProcessName', (String) request.inputParameters.get('ProcessName'));

        ReturnClass returnClass =  ZuoraOperationHandler(requestParameterMap);
        
        Map<String,Object> result = new Map<String,Object>();  
        result.put('billingAccountId', returnClass.billingAccountId);   
        result.put('billedToContactId', returnClass.billedToContactId); 
        result.put('soldToContactId', returnClass.soldToContactId);
        result.put('billingAccountNumber', returnClass.billingAccountNumber); 
        result.put('isActiveBilling', returnClass.isActiveBilling); 
        result.put('matchType', returnClass.matchType); 
        result.put('defaultPaymentMethodId', returnClass.defaultPaymentMethodId);
        result.put('message', returnClass.message);
        return new Process.PluginResult(result); 
  }
  
    global Process.PluginDescribeResult describe() {
        Process.PluginDescribeResult result = new Process.PluginDescribeResult();
        result.description = 'Check whether a billing account exists and it is actively billing. When no account is found a new one is created.';
        result.tag = 'Billing Account Management';
        
        result.inputParameters = new 
            List<Process.PluginDescribeResult.InputParameter>{
                 new Process.PluginDescribeResult.InputParameter('Operation', Process.PluginDescribeResult.ParameterType.STRING, true),
                 new Process.PluginDescribeResult.InputParameter('BillingAccountId', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillToAddress', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillToCity', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillToCountry', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillToFirstName', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillToLastName', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillToPostalCode', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillToState', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillToPersonalEmail', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillToWorkEmail', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillToWorkPhone', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BrandTag', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('CRMAccountId', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('IsoCurrency', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('PaymentMethod', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SoldToAddress', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SoldToCity', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SoldToCountry', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SoldToFirstName', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SoldToLastName', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SoldToPostalCode', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SoldToState', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SoldToPersonalEmail', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SoldToWorkEmail', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SoldToWorkPhone', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('ContextLanguage', Process.PluginDescribeResult.ParameterType.STRING, false) ,
                 new Process.PluginDescribeResult.InputParameter('PaymentTerm', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('InvoiceTemplateName', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('InvoiceDeliveryPref', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('CustomerServiceRepName', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SalesRepName', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('SalesRepDivision', Process.PluginDescribeResult.ParameterType.STRING, false),
                 new Process.PluginDescribeResult.InputParameter('BillingBatchNo', Process.PluginDescribeResult.ParameterType.STRING, false) ,
                 new Process.PluginDescribeResult.InputParameter('ProcessName', Process.PluginDescribeResult.ParameterType.STRING, false)                                                                                 
        };
        result.outputParameters = new List<Process.PluginDescribeResult.OutputParameter>{
                 new Process.PluginDescribeResult.OutputParameter('billingAccountId', Process.PluginDescribeResult.ParameterType.STRING),
                 new Process.PluginDescribeResult.OutputParameter('billingAccountNumber', Process.PluginDescribeResult.ParameterType.STRING),
                 new Process.PluginDescribeResult.OutputParameter('isActiveBilling', Process.PluginDescribeResult.ParameterType.STRING),
                 new Process.PluginDescribeResult.OutputParameter('matchType', Process.PluginDescribeResult.ParameterType.STRING),
                 new Process.PluginDescribeResult.OutputParameter('message', Process.PluginDescribeResult.ParameterType.STRING)                      
        };

        return result;
    }
            
  global class ReturnClass {
      global String billingAccountId;
      global String billedToContactId;
      global String soldToContactId;
      global String billingAccountNumber;
      global String isActiveBilling;
      global String defaultPaymentMethodId;
      global String matchType;
      global String message;
      global Double balance;
      global String isAutoPay;
      global String batch;

      // Backward compatibility with QuoteUtilities. This will need to be removed and have null parameter constructors to avoid reuse of inner classes
      global ReturnClass(String billingAccountId, String billingAccountNo, String isActiveBilling, String matchType, String message) {
       this.billingAccountId = billingAccountId;
       this.billingAccountNumber = billingAccountNo;
       this.isActiveBilling = isActiveBilling;
       this.matchType = matchType;
       this.message = message;
       }

      global ReturnClass(String billingAccountId, String billedToContactId, String soldToContactId, String billingAccountNo, String isActiveBilling, String defaultPaymentMethodId, String matchType, String message) {
       this.billingAccountId = billingAccountId;
       this.billedToContactId = billedToContactId;
       this.soldToContactId = soldToContactId;
       this.billingAccountNumber = billingAccountNo;
       this.defaultPaymentMethodId = defaultPaymentMethodId;
       this.isActiveBilling = isActiveBilling;
       this.matchType = matchType;
       this.message = message;
       }       
    }
  
  public static Map<String,String> parse( String req )
  {
        // URL pattern of '/name/value/name/value ...' This can be moved to a help class and shared by other classes in the org
        List<String> tokens = req.split('/');
        Map<String,String> tokensMap = new Map<String,String>();
        for( integer i = 1 ; i < tokens.size() ; i++ )
        {
            tokensMap.put( tokens.get( i ), tokens.get( ++i ) );
        }
        return tokensMap;
  } 
  
  public static ReturnClass ZuoraOperationHandler(Map<String, String> requestParameterMap)
  {
      String PaymentGateway;            
      Boolean InvoiceDeliveryPrefsEmail;
      Boolean InvoiceDeliveryPrefsPrint;
      String BillingAccountId = requestParameterMap.get('BillingAccountId');
      String BillToAddress = requestParameterMap.get('BillToAddress');
      String BillToCity = requestParameterMap.get('BillToCity');
      String BillToCountry = requestParameterMap.get('BillToCountry');
      String BillToFirstName = requestParameterMap.get('BillToFirstName');
      String BillToLastName = requestParameterMap.get('BillToLastName');
      String BillToPostalCode = requestParameterMap.get('BillToPostalCode');
      String BillToState = requestParameterMap.get('BillToState');
      String BillToPersonalEmail = requestParameterMap.get('BillToPersonalEmail');
      String BillToWorkEmail = requestParameterMap.get('BillToWorkEmail');
      String BillToWorkPhone = requestParameterMap.get('BillToWorkPhone');
      String BrandTag = requestParameterMap.get('BrandTag');
      String CRMAccountId = requestParameterMap.get('CRMAccountId');
      String IsoCurrency = requestParameterMap.get('IsoCurrency');
      String PaymentMethod = requestParameterMap.get('PaymentMethod');
      String SoldToAddress = requestParameterMap.get('SoldToAddress');
      String SoldToCity = requestParameterMap.get('SoldToCity');
      String SoldToCountry = requestParameterMap.get('SoldToCountry');
      String SoldToFirstName = requestParameterMap.get('SoldToFirstName');
      String SoldToLastName = requestParameterMap.get('SoldToLastName');
      String SoldToPostalCode = requestParameterMap.get('SoldToPostalCode');
      String SoldToState = requestParameterMap.get('SoldToState');       
      String SoldToPersonalEmail = requestParameterMap.get('SoldToPersonalEmail');
      String SoldToWorkEmail = requestParameterMap.get('SoldToWorkEmail');
      String SoldToWorkPhone = requestParameterMap.get('SoldToWorkPhone');
      String Operation = requestParameterMap.get('Operation');
      String ContextLanguage = requestParameterMap.get('ContextLanguage');  
      String PaymentTerm = requestParameterMap.get('PaymentTerm');
      String InvoiceTemplateName = requestParameterMap.get('InvoiceTemplateName');
      String CustomerServiceRepName = requestParameterMap.get('CustomerServiceRepName');
      String SalesRepName = requestParameterMap.get('SalesRepName');
      String SalesRepDivision = requestParameterMap.get('SalesRepDivision');
      String ProcessName = requestParameterMap.get('ProcessName');
      BillingBatchNo = requestParameterMap.get('BillingBatchNo');

      Boolean newAutoPay;
      Double acctBalance;
      String newBatch;

      List<Zuora.zApi.SaveResult> updateResults;
      Boolean isAcctUpdateSuccess;

      InvoiceDeliveryPref = requestParameterMap.get('InvoiceDeliveryPref');
     try
     {  
       String isSuccess = 'false';
       String zoql = '';
       DateTime todayDt = DateTime.now();
       String AccountNumber = '';
       String formattedTodayDt = todayDt.format('yyyy-MM-dd') + 'T00:00:00';
       if(!Test.isRunningTest()) zApiInstance.zlogin(); 
       if('IsBillingAccountActive'.equals(Operation))
       {
          return IsBillingAccountActive(BillingAccountId);
       }
       else if('CreateBillingAccount'.equals(Operation))
       {
         if('Print' == InvoiceDeliveryPref)
         {
           InvoiceDeliveryPrefsPrint = TRUE;
           InvoiceDeliveryPrefsEmail = FALSE;
         }
         else if('Both' == InvoiceDeliveryPref)
         {
           InvoiceDeliveryPrefsPrint = TRUE;
           InvoiceDeliveryPrefsEmail = TRUE;
         }
         else
         {
           InvoiceDeliveryPrefsPrint = FALSE;
           InvoiceDeliveryPrefsEmail = TRUE;
         }    
         if(InvoiceDeliveryPrefsEmail && IsParameterNull(BillToWorkEmail))
         {
            return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'Missing Bill To Contact Email Address for Email Invoice Delivery');
         }
         if(IsParameterNull(BrandTag)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'BrandTag Missing');
         //BrandTag = BrandTag.ToUpperCase();
         if(IsParameterNull(IsoCurrency)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'IsoCurrency Missing');
         //IsoCurrency = IsoCurrency.ToUpperCase();
         if(IsParameterNull(PaymentMethod)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'PaymentMethod Missing');
         if(IsParameterNull(ContextLanguage)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'ContextLanguage Missing');
         //ContextLanguage = ContextLanguage.ToUpperCase();
         if(IsParameterNull(CRMAccountId)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'CRMAccountId Missing');
         if(IsParameterNull(BillToFirstName)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'BillToFirstName Missing');
         if(IsParameterNull(BillToLastName)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'BillToLastName Missing');
         if(IsParameterNull(BillToAddress)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'BillToAddress Missing');
         if(IsParameterNull(BillToCity)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'BillToCity Missing');
         if(IsParameterNull(BillToCountry)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'BillToCountry Missing');
         if('United States' == BillToCountry || 'Canada' == BillToCountry)
         {
             if(IsParameterNull(BillToState))
             {
                return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'BillToState Missing');
             }
             else
             {
               if(BillToState.length() == 2) BillToState = getStateName(BillToState, BillToCountry);
             }
         }
         if(IsParameterNull(SoldToFirstName)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'SoldToFirstName Missing');
         if(IsParameterNull(SoldToLastName)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'SoldToLastName Missing');
         if(IsParameterNull(SoldToAddress)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'SoldToAddress Missing');
         if(IsParameterNull(SoldToCity)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'SoldToCity Missing');
         if(IsParameterNull(SoldToCountry)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'SoldToCountry Missing');
         List<pw_ccpro__CountryObject__c> CountryObjectLst = [SELECT Id, Name, Region__c, Region_Energy__c, Sub_Region1__c, Sub_Region2__c
                                                       FROM pw_ccpro__CountryObject__c WHERE Name = :SoldToCountry LIMIT 1];
         if(CountryObjectLst.size() == 0)  return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'SoldToCountry is Incorrect');
         pw_ccpro__CountryObject__c CountryObject = CountryObjectLst[0];
         if('United States' == SoldToCountry || 'Canada' == SoldToCountry)
         {
             if(IsParameterNull(SoldToState)) 
             {
                 return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'SoldToState Missing'); 
             }
             else
             {
               if(SoldToState.length() == 2) SoldToState = getStateName(SoldToState, SoldToCountry);
             }
         }
         if(IsParameterNull(PaymentTerm)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'PaymentTerm Missing');
         Map<String, PaymentGateway__c> PaymentGatewayMap = PaymentGateway__c.getAll();  
         String paymentGatewayKey = BrandTag + '_' + IsoCurrency;
         for(String paymentGatewayName : PaymentGatewayMap.keySet())
         {
            if(paymentGatewayKey == paymentGatewayName)
            {
               PaymentGateway = PaymentGatewayMap.get(paymentGatewayName).PaymentGatewayName__c;
               break;
            }
         }
         if(IsParameterNull(PaymentGateway)) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'A PaymentGateway corresponding to Brand Tag and Currency not found');

         Account salesforceAccount = [SELECT Name, Account_Number_Assigned__c from Account where Id = :CRMAccountId];
         if(salesforceAccount == null) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'CRMAccount Id does not exists');
         String CRMAccountName = salesforceAccount.Name;
         String CRMAccountNumber = salesforceAccount.Account_Number_Assigned__c;

         if(IsParameterNull(BillingBatchNo)) BillingBatchNo = label.Billing_Batch_Number; 
      
         if(IsParameterNull(InvoiceTemplateName)) 
         {
             if(BrandTag.startsWith('eFC') && CountryObject.Sub_Region1__c == 'Middle East')
             {
                 InvoiceTemplateName = 'eFC-MiddleEast_' + ContextLanguage + '_' + IsoCurrency; 
             }
             else if(BrandTag == 'Rigzone' && CountryObject.Region_Energy__c != 'AMERICAS')
             {
                 InvoiceTemplateName = 'RigZone-Row_' + ContextLanguage + '_' + IsoCurrency; 
             }
             else
             {
                 InvoiceTemplateName = BrandTag + '_' + ContextLanguage + '_' + IsoCurrency;
             }
         }
         List<Invoice_Template__c> InvoiceTemplateLst = [SELECT Invoice_Template_Id__c, Name FROM Invoice_Template__c WHERE Name = :InvoiceTemplateName LIMIT 1];         
         if(InvoiceTemplateLst.size() <= 0) return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'Invoice Template does not exists');         
         InvoiceTemplateName = InvoiceTemplateLst[0].Name; 
         String InvoiceTemplateId = InvoiceTemplateLst[0].Invoice_Template_Id__c;
                       
         zoql = 'SELECT Id FROM PaymentMethod WHERE Name = \'' + PaymentMethod  + '\'';  
         List<Zuora.zObject> zPtmObjs = new List<Zuora.zObject>();
         if(!Test.isRunningTest())
         {
           zPtmObjs = zApiInstance.zquery(zoql);          
         }
         else
         {
             Zuora.zObject zobj = new Zuora.zObject('Contact');
             zobj.setValue('Id','0123456789');
             zPtmObjs.add(zobj);
         }
         if(zPtmObjs.size() <= 0)  return new ReturnClass('', '', '', '', '', 'false', 'FAILED', 'Invalid Payment Method - ' + PaymentMethod );
         String paymentMethodId = (String)zPtmObjs[0].getValue('Id');               
                    
         zoql = 'SELECT Id, Name, Batch, AccountNumber, BillToId, SoldToId, DefaultPaymentMethodId, PaymentGateway, InvoiceTemplateId, ';
         zoql += ' InvoiceTemplateName__c, PaymentTerm, InvoiceDeliveryPrefsEmail, InvoiceDeliveryPrefsPrint, Batch, Balance, AutoPay ';
         zoql += ' FROM Account WHERE Status = \'Active\' AND CrmId = \'' + CRMAccountId + '\' AND Currency = \'' + IsoCurrency + '\' AND BrandTag__c = \'' + BrandTag + '\'';
         zoql += ' AND Batch != \'Batch4\'';    //CC-3513 - Billing Account Selection - Exclude Batch 4
         List<Zuora.zObject> zActObjs = new List<Zuora.zObject>();      
         if(!Test.isRunningTest())
         {
           zActObjs = zApiInstance.zquery(zoql);
         }
         else
         {
             Zuora.zObject zaobj = new Zuora.zObject('Account');
             zaobj.setValue('Id',BillingAccountId);
             zaobj.setValue('AutoPay',true);
             zaobj.setValue('Balance',0);
             zaobj.setValue('Batch','Batch2');
             zaobj.setValue('InvoiceTemplateName__c',InvoiceTemplateName);
             zaobj.setValue('InvoiceTemplateId',InvoiceTemplateId);
             zaobj.setValue('PaymentGateway',PaymentGateway);
             zaobj.setValue('DefaultPaymentMethodId',paymentMethodId);
             zaobj.setValue('InvoiceDeliveryPrefsEmail',true);
             zaobj.setValue('InvoiceDeliveryPrefsPrint',true);
             zaobj.setValue('PaymentTerm',PaymentTerm);
             zActObjs.add(zaobj);
         }   
          map<String, String> acctParameterMap = new map<String, String>();
          acctParameterMap.put('CrmId',CRMAccountId);
          acctParameterMap.put('CRMAccountName',CRMAccountName);
          acctParameterMap.put('CRMAccountNumber',CRMAccountNumber);
          acctParameterMap.put('IsoCurrency',IsoCurrency);
          acctParameterMap.put('BrandTag',BrandTag);
          acctParameterMap.put('InvoiceTemplateName',InvoiceTemplateName);
          acctParameterMap.put('InvoiceTemplateId',InvoiceTemplateId);
          acctParameterMap.put('PaymentGateway',PaymentGateway);
          acctParameterMap.put('DefaultPaymentMethodId',paymentMethodId);
          acctParameterMap.put('SoldToAddress',SoldToAddress);
          acctParameterMap.put('SoldToCity',SoldToCity);
          acctParameterMap.put('SoldToCountry',SoldToCountry);
          acctParameterMap.put('SoldToPostalCode',SoldToPostalCode);
          acctParameterMap.put('SoldToState',SoldToState);
          acctParameterMap.put('SoldToFirstName',SoldToFirstName);
          acctParameterMap.put('SoldToLastName',SoldToLastName);
          acctParameterMap.put('SoldToPersonalEmail',SoldToPersonalEmail);
          acctParameterMap.put('SoldToWorkEmail',SoldToWorkEmail);
          acctParameterMap.put('SoldToWorkPhone',SoldToWorkPhone);
          acctParameterMap.put('BillToAddress',BillToAddress);
          acctParameterMap.put('BillToCity',BillToCity);
          acctParameterMap.put('BillToCountry',BillToCountry);
          acctParameterMap.put('BillToPostalCode',BillToPostalCode);
          acctParameterMap.put('BillToState',BillToState);
          acctParameterMap.put('BillToFirstName',BillToFirstName);
          acctParameterMap.put('BillToLastName',BillToLastName);
          acctParameterMap.put('BillToPersonalEmail',BillToPersonalEmail);
          acctParameterMap.put('BillToWorkEmail',BillToWorkEmail);
          acctParameterMap.put('BillToWorkPhone',BillToWorkPhone);
          acctParameterMap.put('PaymentTerm',PaymentTerm);
          acctParameterMap.put('CustomerServiceRepName',CustomerServiceRepName);
          acctParameterMap.put('SalesRepName',SalesRepName);
          acctParameterMap.put('SalesRepDivision',SalesRepDivision);
          acctParameterMap.put('ProcessName',ProcessName);

          if(zActObjs.size() <= 0) return createZuoraAccount(acctParameterMap);

         //Account matched by CRMId, Currency and BrandTag 
         List<String> billToLst = new List<String>();
         List<String> soldToLst = new List<String>();

         Map<String, String> AcctNumberIdMap = new Map<String, String>();
         Map<String, String> billingAcctMap = new Map<String, String>();
         Map<String, String> defaultpaymentMethodMap = new Map<String, String>();
         //Map<String, Boolean> acctAutoPayMap = new Map<String, Boolean>();
         //Map<String, Double> acctBalanceMap = new Map<String, Double>();
         ReturnClass activeAcct = null; 

         List<Zuora.zObject> updAccountLst;
         Zuora.zObject updAccount;
                  
         for(Zuora.zObject zAcct : zActObjs)
         {
             newAutoPay = (Boolean)zAcct.getValue('AutoPay');
             acctBalance = (Double)zAcct.getValue('Balance');
             newBatch = (String)zAcct.getValue('Batch');
             activeAcct = IsBillingAccountActive((String)zAcct.getValue('Id'));
             //Godfrey: CCBOB-93 - Unpaid invoices are treated the same as actively billing
             if(('false' == activeAcct.isActiveBilling) && ((Double)zAcct.getValue('Balance') == 0.0))
             {                               
                //Godfrey: Stop setting new batch for not actively billing when it is Batch2
                updAccountLst = new List<Zuora.zObject>();
                updAccount = new Zuora.zObject('Account'); 
                updAccount.setValue('Id', (String)zAcct.getValue('Id'));
                updAccountLst.add(updAccount); 
                if('Print' == InvoiceDeliveryPref)
                {
                    updAccount.setValue('InvoiceDeliveryPrefsPrint', 'TRUE');
                    updAccount.setValue('InvoiceDeliveryPrefsEmail', 'FALSE');
                }
                else if('Both' == InvoiceDeliveryPref)
                {
                    updAccount.setValue('InvoiceDeliveryPrefsEmail', 'TRUE');
                    updAccount.setValue('InvoiceDeliveryPrefsPrint', 'TRUE');
                }
                else
                {
                    updAccount.setValue('InvoiceDeliveryPrefsEmail', 'TRUE');
                    updAccount.setValue('InvoiceDeliveryPrefsPrint', 'FALSE');
                } 
                if((Boolean)zAcct.getValue('AutoPay'))
                {
                    if((Double)zAcct.getValue('Balance') == 0.0)
                    {
                       updAccount.setValue('AutoPay', 'FALSE');
                       newAutoPay = false;
                    }         
                }
                //Moved to the begining of the function for multiple use
                //List<Zuora.zApi.SaveResult> updateResults; 
                //Boolean isAcctUpdateSuccess;
                if(!Test.isRunningTest())
                {
                   updateResults = zApiInstance.zupdate(updAccountLst);
                   isAcctUpdateSuccess = updateResults[0].Success;
                }
                else
                {
                   isAcctUpdateSuccess = true;
                }         
                ReturnClass rtnClass = new ReturnClass((String)zAcct.getValue('Id'), (String)zAcct.getValue('BillToId'), (String)zAcct.getValue('SoldToId'), 
                                       (String)zAcct.getValue('AccountNumber'), 'false', (String)zAcct.getValue('DefaultPaymentMethodId'), 
                                       'Existing Billing Account Found – Not Actively Billing', isAcctUpdateSuccess ? 'Successful' : getZuoraErrorMsg(updateResults[0].errors));
                rtnClass.balance = acctBalance;
                rtnClass.isAutoPay = newAutoPay ? 'true' : 'false';   
                rtnClass.batch = newBatch;  
                if(rtnClass.balance != 0) rtnClass.matchType += ' and has Outstanding Balance';                                   
                return rtnClass;
             }
             else
             {         
                AcctNumberIdMap.put((String)zAcct.getValue('Id'), (String)zAcct.getValue('AccountNumber'));
                if((paymentMethodId.equals((String)zAcct.getValue('DefaultPaymentMethodId'))) && (InvoiceTemplateName == (String)zAcct.getValue('InvoiceTemplateName__c'))
                 && (InvoiceTemplateId.equals((String)zAcct.getValue('InvoiceTemplateId'))) && (PaymentGateway == (String)zAcct.getValue('PaymentGateway'))
                 && (PaymentTerm == (String)zAcct.getValue('PaymentTerm'))
                 && InvoiceDeliveryPrefsPrint == (Boolean)zAcct.getValue('InvoiceDeliveryPrefsPrint') && InvoiceDeliveryPrefsEmail == (Boolean)zAcct.getValue('InvoiceDeliveryPrefsEmail')
                ) 
                {
                    billToLst.add((String)zAcct.getValue('BillToId')); 
                    soldToLst.add((String)zAcct.getValue('SoldToId'));
                }
             }
         }

         if(billToLst.size() == 0 || soldToLst.size() == 0)
         {
            acctParameterMap = new map<String, String>();
            acctParameterMap.put('CrmId',CRMAccountId);
            acctParameterMap.put('CRMAccountName',CRMAccountName);
            acctParameterMap.put('CRMAccountNumber',CRMAccountNumber);
            acctParameterMap.put('IsoCurrency',IsoCurrency);
            acctParameterMap.put('BrandTag',BrandTag);
            acctParameterMap.put('InvoiceTemplateName',InvoiceTemplateName);
            acctParameterMap.put('InvoiceTemplateId',InvoiceTemplateId);
            acctParameterMap.put('PaymentGateway',PaymentGateway);
            acctParameterMap.put('DefaultPaymentMethodId',paymentMethodId);
            acctParameterMap.put('SoldToAddress',SoldToAddress);
            acctParameterMap.put('SoldToCity',SoldToCity);
            acctParameterMap.put('SoldToCountry',SoldToCountry);
            acctParameterMap.put('SoldToPostalCode',SoldToPostalCode);
            acctParameterMap.put('SoldToState',SoldToState);
            acctParameterMap.put('SoldToFirstName',SoldToFirstName);
            acctParameterMap.put('SoldToLastName',SoldToLastName);
            acctParameterMap.put('SoldToPersonalEmail',SoldToPersonalEmail);
            acctParameterMap.put('SoldToWorkEmail',SoldToWorkEmail);
            acctParameterMap.put('SoldToWorkPhone',SoldToWorkPhone);
            acctParameterMap.put('BillToAddress',BillToAddress);
            acctParameterMap.put('BillToCity',BillToCity);
            acctParameterMap.put('BillToCountry',BillToCountry);
            acctParameterMap.put('BillToPostalCode',BillToPostalCode);
            acctParameterMap.put('BillToState',BillToState);
            acctParameterMap.put('BillToFirstName',BillToFirstName);
            acctParameterMap.put('BillToLastName',BillToLastName);
            acctParameterMap.put('BillToPersonalEmail',BillToPersonalEmail);
            acctParameterMap.put('BillToWorkEmail',BillToWorkEmail);
            acctParameterMap.put('BillToWorkPhone',BillToWorkPhone);
            acctParameterMap.put('PaymentTerm',PaymentTerm);
            acctParameterMap.put('CustomerServiceRepName',CustomerServiceRepName);
            acctParameterMap.put('SalesRepName',SalesRepName);
            acctParameterMap.put('SalesRepDivision',SalesRepDivision);
            acctParameterMap.put('ProcessName',ProcessName);
            return createZuoraAccount(acctParameterMap);
          }
                            
          String whereBillTo = '';
          String whereSoldTo = '';
          for(String billTo : billToLst)
          {
             whereBillTo = whereBillTo + ' Id = \'' + billTo + '\' OR';
          }
          for(String soldTo : soldToLst)
          {
             whereSoldTo = whereSoldTo + ' Id = \'' + soldTo + '\' OR';
          }
          whereBillTo = whereBillTo.substring(0, whereBillTo.length() - 2);
          whereSoldTo = whereSoldTo.substring(0, whereSoldTo.length() - 2);
          zoql = 'SELECT AccountId, Address1, City, Country, FirstName, Id, LastName, PostalCode, State FROM Contact WHERE ' + whereBillTo;
          List<Zuora.zObject> zbillToObjs = new List<Zuora.zObject>();
          if(!Test.isRunningTest())
          {
             zbillToObjs = zApiInstance.zquery(zoql);
          }
          else
          {            
             Zuora.zObject zobj = new Zuora.zObject('Contact');
             zobj.setValue('Id','0123456789');
             zobj.setValue('Address1',BillToAddress);
             zobj.setValue('City',BillToCity);
             zobj.setValue('FirstName',BillToFirstName);
             zobj.setValue('LastName',BillToLastName);
             zobj.setValue('PostalCode',BillToPostalCode);
             zobj.setValue('State',BillToState);
             zobj.setValue('Country',BillToCountry);
             zobj.setValue('AccountId',BillingAccountId);
             zbillToObjs.add(zobj);
          }
          Map<String, String> matchedBillActMap = new Map<String, String>();
          for(Zuora.zObject zbillToObj : zbillToObjs )
          {
             if(BillToAddress == (String)zbillToObj.getValue('Address1') && BillToCity == (String)zbillToObj.getValue('City') 
               && BillToFirstName == (String)zbillToObj.getValue('FirstName') && BillToLastName == (String)zbillToObj.getValue('LastName')
               && BillToPostalCode == (String)zbillToObj.getValue('PostalCode') && BillToState == (String)zbillToObj.getValue('State')
               && BillToCountry == (String)zbillToObj.getValue('Country')
             )
             {                       
                 matchedBillActMap.put((String)zbillToObj.getValue('AccountId'),(String)zbillToObj.getValue('AccountId'));
                 billingAcctMap.put((String)zbillToObj.getValue('AccountId'), (String)zbillToObj.getValue('Id'));
                 defaultpaymentMethodMap.put((String)zbillToObj.getValue('AccountId'),(String)zbillToObj.getValue('DefaultPaymentMethodId'));
             }
          }
          
          String accountIdStr = '';
          for (String key : matchedBillActMap.keySet()) {
            accountIdStr = accountIdStr + key+ ',';
          }
          
          zoql = 'SELECT AccountId, Address1, City, Country, FirstName, Id, LastName, PostalCode, State FROM Contact WHERE ' + whereSoldTo;
          List<Zuora.zObject> zsoldToObjs = new List<Zuora.zObject>();
          if(!Test.isRunningTest())
          {
             zsoldToObjs = zApiInstance.zquery(zoql);  
          }
          else
          {            
             Zuora.zObject zobj = new Zuora.zObject('Contact');
             zobj.setValue('Id','0123456789');
             zobj.setValue('Address1',SoldToAddress);
             zobj.setValue('City',SoldToCity);
             zobj.setValue('FirstName',SoldToFirstName);
             zobj.setValue('LastName',SoldToLastName);
             zobj.setValue('PostalCode',SoldToPostalCode);
             zobj.setValue('State',SoldToState);
             zobj.setValue('Country','SoldToCountry');
             zobj.setValue('AccountId',BillingAccountId);
             zsoldToObjs.add(zobj);
          }
          for(Zuora.zObject zsoldToObj : zsoldToObjs )
          {
             if(SoldToAddress == (String)zsoldToObj.getValue('Address1') && SoldToCity == (String)zsoldToObj.getValue('City') 
               && SoldToFirstName == (String)zsoldToObj.getValue('FirstName') && SoldToLastName == (String)zsoldToObj.getValue('LastName')
               && SoldToPostalCode == (String)zsoldToObj.getValue('PostalCode') && SoldToState == (String)zsoldToObj.getValue('State')
               && SoldToCountry == (String)zsoldToObj.getValue('Country') && matchedBillActMap.get((String)zsoldToObj.getValue('AccountId')) == (String)zsoldToObj.getValue('AccountId')
             )             
             {
              /*
               * Jira has been recalled for future implementation with creditcard capture
                if(acctAutoPayMap.get((String)zsoldToObj.getValue('AccountId')))
                {
                    if(acctBalanceMap.get((String)zsoldToObj.getValue('AccountId')) == 0.0)
                    {
                       updAccountLst = new List<Zuora.zObject>();
                       updAccount = new Zuora.zObject('Account'); 
                       updAccount.setValue('Id', (String)zsoldToObj.getValue('AccountId'));
                       updAccountLst.add(updAccount);
                       updAccount.setValue('AutoPay', 'FALSE');
                       newAutoPay = false;

                       if(!Test.isRunningTest())
                       {
                          updateResults = zApiInstance.zupdate(updAccountLst);
                          isAcctUpdateSuccess = updateResults[0].Success;
                       } 
                    }         
                }  
                */
                return new ReturnClass((String)zsoldToObj.getValue('AccountId'), billingAcctMap.get((String)zsoldToObj.getValue('AccountId')), (String)zsoldToObj.getValue('Id'), AcctNumberIdMap.get((String)zsoldToObj.getValue('AccountId')), 'true', defaultpaymentMethodMap.get((String)zsoldToObj.getValue('AccountId')), 'Existing Billing Account Found – All Matched', 'Successful');
             }
          }   
         acctParameterMap = new map<String, String>();
         acctParameterMap.put('CrmId',CRMAccountId);
         acctParameterMap.put('CRMAccountName',CRMAccountName);
         acctParameterMap.put('CRMAccountNumber',CRMAccountNumber);
         acctParameterMap.put('IsoCurrency',IsoCurrency);
         acctParameterMap.put('BrandTag',BrandTag);
         acctParameterMap.put('InvoiceTemplateName',InvoiceTemplateName);
         acctParameterMap.put('InvoiceTemplateId',InvoiceTemplateId);
         acctParameterMap.put('PaymentGateway',PaymentGateway);
         acctParameterMap.put('DefaultPaymentMethodId',paymentMethodId);
         acctParameterMap.put('SoldToAddress',SoldToAddress);
         acctParameterMap.put('SoldToCity',SoldToCity);
         acctParameterMap.put('SoldToCountry',SoldToCountry);
         acctParameterMap.put('SoldToPostalCode',SoldToPostalCode);
         acctParameterMap.put('SoldToState',SoldToState);
         acctParameterMap.put('SoldToFirstName',SoldToFirstName);
         acctParameterMap.put('SoldToLastName',SoldToLastName);
         acctParameterMap.put('SoldToPersonalEmail',SoldToPersonalEmail);
         acctParameterMap.put('SoldToWorkEmail',SoldToWorkEmail);
         acctParameterMap.put('SoldToWorkPhone',SoldToWorkPhone);
         acctParameterMap.put('BillToAddress',BillToAddress);
         acctParameterMap.put('BillToCity',BillToCity);
         acctParameterMap.put('BillToCountry',BillToCountry);
         acctParameterMap.put('BillToPostalCode',BillToPostalCode);
         acctParameterMap.put('BillToState',BillToState);
         acctParameterMap.put('BillToFirstName',BillToFirstName);
         acctParameterMap.put('BillToLastName',BillToLastName);
         acctParameterMap.put('BillToPersonalEmail',BillToPersonalEmail);
         acctParameterMap.put('BillToWorkEmail',BillToWorkEmail);
         acctParameterMap.put('BillToWorkPhone',BillToWorkPhone);
         acctParameterMap.put('PaymentTerm',PaymentTerm);
         acctParameterMap.put('CustomerServiceRepName',CustomerServiceRepName);
         acctParameterMap.put('SalesRepName',SalesRepName);
         acctParameterMap.put('SalesRepDivision',SalesRepDivision);
         acctParameterMap.put('ProcessName',ProcessName);
         return createZuoraAccount(acctParameterMap);                          
       }
       
       return new ReturnClass(BillingAccountId, '', '', '', 'false', '', Operation, 'Incorrect Operation');
       
     } catch (Exception e) {
      return new ReturnClass('', '', '', '', 'false', '', 'FAILED', e.getMessage());
    }   
      return null;
  }

  @HttpGet
  global static ReturnClass doGet() { 
       RestRequest req = RestContext.request; 
       Map<String,String> tokenMap = parse(EncodingUtil.urlDecode(req.requestURI,'UTF-8'));
       Map<String, String> parameterMap = RestContext.request.Params;
       parameterMap.put('Operation', tokenMap.get('ZuoraWSOperation')); 
       return ZuoraOperationHandler(parameterMap);
  }
  
  public static Zuora.zObject createZuoraContact(String BrandTag, String ContactType, String Address1, String City, String Country, String FirstName, String LastName, String PostalCode, String State, 
                                                 String PersonalEmail, String WorkEmail, String WorkPhone, String AccountId){
       Zuora.zObject zContact = new Zuora.zObject('Contact'); 
       zContact.setValue('Address1', Address1);
       zContact.setValue('City', City);
       zContact.setValue('Country', Country);
       zContact.setValue('FirstName', FirstName);
       zContact.setValue('LastName', LastName);
       zContact.setValue('PostalCode', PostalCode);
       zContact.setValue('State', State);
       if(!IsParameterNull(PersonalEmail)) zContact.setValue('PersonalEmail', PersonalEmail);
       if(!IsParameterNull(WorkEmail)) zContact.setValue('WorkEmail', WorkEmail);
       if(!IsParameterNull(WorkPhone)) zContact.setValue('WorkPhone', WorkPhone);
       if(ContactType == 'SoldToContact') 
       {
          Map<String, BrandTagsToZQUTaxRegion__c> approvedBrandTagMap = BrandTagsToZQUTaxRegion__c.getAll();
          if(approvedBrandTagMap.containsKey(BrandTag)) zContact.setValue('TaxRegion', BrandTag);
       }
       zContact.setValue('AccountId', AccountId);
       return zContact;
  }
    
  public static boolean IsParameterNull(String param) {
    return param == null || ''.equals(param);
  }

  public static String getCreditController(String BrandTag, String SoldToCountry, String SalesRepName, String SalesRepDivision)
  {
    String allSalesRepDivision = NULL;
    String allCountry = NULL;
    List<Credit_Controller__c> creditControllerLst = [SELECT Country__r.Name, Sales_Rep_Division__c, Collector__c 
                                                      FROM Credit_Controller__c WHERE BrandTag__c = :BrandTag];
    if(creditControllerLst.size() == 0) return NULL;
    for(Credit_Controller__c ccontroller : creditControllerLst)
    {
      if(SoldToCountry != NULL && ccontroller.Country__r.Name == SoldToCountry) 
      {
        if(SalesRepDivision != NULL && ccontroller.Sales_Rep_Division__c == SalesRepDivision) return ccontroller.Collector__c;
        if(ccontroller.Sales_Rep_Division__c == NULL) 
        {
          allSalesRepDivision = ccontroller.Collector__c;
          continue;
        }
      }
      else if(SalesRepDivision != NULL && ccontroller.Sales_Rep_Division__c == SalesRepDivision)
      {
        if(ccontroller.Country__r.Name == NULL) return ccontroller.Collector__c;        
      }
      if(ccontroller.Country__r.Name == NULL && ccontroller.Sales_Rep_Division__c == NULL) 
      {
          allSalesRepDivision = allSalesRepDivision == NULL ? ccontroller.Collector__c : allSalesRepDivision;
          allCountry = allCountry == NULL ? ccontroller.Collector__c : allCountry;
      }
    }
    return allSalesRepDivision == null ? allCountry : allSalesRepDivision;
  }
 
  public static ReturnClass createZuoraAccount(Map<String, String> acctParameterMap){
        String CrmId = acctParameterMap.get('CrmId');
        String CRMAccountName = acctParameterMap.get('CRMAccountName');
        String CRMAccountNumber = acctParameterMap.get('CRMAccountNumber');
        String IsoCurrency = acctParameterMap.get('IsoCurrency');
        String BrandTag = acctParameterMap.get('BrandTag');
        String InvoiceTemplateName = acctParameterMap.get('InvoiceTemplateName');
        String InvoiceTemplateId = acctParameterMap.get('InvoiceTemplateId');
        String PaymentGateway = acctParameterMap.get('PaymentGateway');
        String DefaultPaymentMethodId = acctParameterMap.get('DefaultPaymentMethodId');
        String SoldToAddress = acctParameterMap.get('SoldToAddress');
        String SoldToCity = acctParameterMap.get('SoldToCity');
        String SoldToCountry = acctParameterMap.get('SoldToCountry');
        String SoldToPostalCode = acctParameterMap.get('SoldToPostalCode');
        String SoldToState = acctParameterMap.get('SoldToState');
        String SoldToFirstName = acctParameterMap.get('SoldToFirstName');
        String SoldToLastName = acctParameterMap.get('SoldToLastName');
        String SoldToPersonalEmail = acctParameterMap.get('SoldToPersonalEmail');
        String SoldToWorkEmail = acctParameterMap.get('SoldToWorkEmail');
        String SoldToWorkPhone = acctParameterMap.get('SoldToWorkPhone');
        String BillToAddress = acctParameterMap.get('BillToAddress');
        String BillToCity = acctParameterMap.get('BillToCity');
        String BillToCountry = acctParameterMap.get('BillToCountry');
        String BillToPostalCode = acctParameterMap.get('BillToPostalCode');
        String BillToState = acctParameterMap.get('BillToState');
        String BillToFirstName = acctParameterMap.get('BillToFirstName');
        String BillToLastName = acctParameterMap.get('BillToLastName');
        String BillToPersonalEmail = acctParameterMap.get('BillToPersonalEmail');
        String BillToWorkEmail = acctParameterMap.get('BillToWorkEmail');
        String BillToWorkPhone = acctParameterMap.get('BillToWorkPhone');
        String PaymentTerm = acctParameterMap.get('PaymentTerm');
        String CustomerServiceRepName = acctParameterMap.get('CustomerServiceRepName');
        String SalesRepName = acctParameterMap.get('SalesRepName');
        String SalesRepDivision = acctParameterMap.get('SalesRepDivision');
        String ProcessName = acctParameterMap.get('ProcessName');

        Zuora.zObject zacct = new Zuora.zObject('Account');        
        zacct.setValue('CrmId', CrmId);             
        zacct.setValue('Name', CRMAccountName);     
        zacct.setValue('CRMAccountName__c', CRMAccountName);
        zacct.setValue('CRMAccountNumber__c', CRMAccountNumber);
        zacct.setValue('Currency', IsoCurrency);
        zacct.setValue('PaymentTerm', PaymentTerm);
        BillingBatchNo = getBillingAccountBatch(null, BillingBatchNo, ProcessName, PaymentGateway, BrandTag, null);
        zacct.setValue('Batch', BillingBatchNo);
        zacct.setValue('BillCycleDay', 1);
        zacct.setValue('Status', 'Draft');
        zacct.setValue('AutoPay', 'FALSE');
        zacct.setValue('Notes', 'Account generated by a Webservice');                          
        zacct.setValue('BrandTag__c',BrandTag);
        zacct.setValue('InvoiceTemplateName__c', InvoiceTemplateName);
        zacct.setValue('InvoiceTemplateId', InvoiceTemplateId);
        zacct.setValue('PaymentGateway', PaymentGateway);
        zacct.setValue('DefaultPaymentMethodId', DefaultPaymentMethodId);   
        String collectorName = getCreditController(BrandTag, SoldToCountry, SalesRepName, SalesRepDivision);
        if(!IsParameterNull(collectorName))  zacct.setValue('Collector__c', collectorName); 
        if('Print' == InvoiceDeliveryPref)
        {
            zacct.setValue('InvoiceDeliveryPrefsPrint', 'TRUE');
        }
        else if('Both' == InvoiceDeliveryPref)
        {
            zacct.setValue('InvoiceDeliveryPrefsEmail', 'TRUE');
            zacct.setValue('InvoiceDeliveryPrefsPrint', 'TRUE');
        }
        else
        {
            zacct.setValue('InvoiceDeliveryPrefsEmail', 'TRUE');
        } 
        if(!IsParameterNull(CustomerServiceRepName)) zacct.setValue('CustomerServiceRepName', CustomerServiceRepName);
        if(!IsParameterNull(SalesRepName)) zacct.setValue('SalesRepName', SalesRepName);
        Zuora.zObject[] objs = new Zuora.zObject[1];
        objs[0] = zacct;
        try{
             List<Zuora.zApi.SaveResult> results;
             Zuora.zApi.SaveResult result;
             Boolean isSuccess;
             String AccountId;
             if(!Test.isRunningTest())
             {
               results = zApiInstance.zcreate(objs);
               result = results[0];
               isSuccess = result.Success;
               if(isSuccess) AccountId = result.Id;
             }
             else
             {
                AccountId = '0123456789';
                isSuccess = true;
             }
             if (isSuccess){
                Zuora.zObject billToContact = createZuoraContact(BrandTag, 'BillToContact', BillToAddress, BillToCity, BillToCountry, BillToFirstName, BillToLastName, BillToPostalCode, BillToState, 
                                                                 BillToPersonalEmail, BillToWorkEmail, BillToWorkPhone, AccountId);              
                Zuora.zObject soldToContact = createZuoraContact(BrandTag, 'SoldToContact', SoldToAddress, SoldToCity, SoldToCountry, SoldToFirstName, SoldToLastName, SoldToPostalCode, SoldToState, 
                                                                 SoldToPersonalEmail, SoldToWorkEmail, SoldToWorkPhone, AccountId);
                Zuora.zObject[] contactObjs = new Zuora.zObject[2];
                contactObjs[0] = billToContact;
                contactObjs[1] = soldToContact;
                String billToId;
                String soldToId;
                List<Zuora.zApi.SaveResult> contactResults;
                if(!Test.isRunningTest())
                {
                  contactResults = zApiInstance.zcreate(contactObjs);
                   if (contactResults[0].Success){
                      billToId = contactResults[0].Id; 
                   } 
                   else
                   {   
                      return new ReturnClass('', '', '', '', 'false', '', 'FAILED' , getZuoraErrorMsg(contactResults[0].errors));    
                   }
                   if (contactResults[1].Success){
                      soldToId = contactResults[1].Id; 
                   } 
                   else
                   {
                      return new ReturnClass('', '', '', '', 'false', '', 'FAILED', getZuoraErrorMsg(contactResults[1].errors));    
                   }
                }
                else
                {
                  billToId = '0123456789';
                  soldToId = '0123456789';
                }
                List<Zuora.zObject> updAccountLst = new List<Zuora.zObject>();
                Zuora.zObject updAccount = new Zuora.zObject('Account'); 
                updAccount.setValue('Id', accountId);
                updAccount.setValue('BillToId', billToId);
                updAccount.setValue('SoldToId', soldToId);
                updAccount.setValue('Status', 'Active');
                updAccountLst.add(updAccount); 
                List<Zuora.zApi.SaveResult> updateResults;
                Boolean isAcctUpdateSuccess;
                if(!Test.isRunningTest())
                {
                   updateResults = zApiInstance.zupdate(updAccountLst);
                   isAcctUpdateSuccess = updateResults[0].Success;
                }
                else
                {
                   isAcctUpdateSuccess = true;
                }
                if(!isAcctUpdateSuccess) {
                    return new ReturnClass('', '', '', '', 'false', '', 'Account Update Failed' , getZuoraErrorMsg(updateResults[0].errors));
                }
                                                
                string zoql = 'SELECT Name, AccountNumber FROM Account WHERE Id = \'' + accountId + '\'';
                integer zObjectSize;
                string AccountNumber;
                if(!Test.isRunningTest())
                {
                   List<Zuora.zObject> zSubobjs = zApiInstance.zquery(zoql);
                   zObjectSize = zSubobjs.size();
                   if(zObjectSize > 0) AccountNumber = (String)zSubobjs[0].getValue('AccountNumber');
                }
                else
                {
                   zObjectSize = 1;
                   AccountNumber = '';
                }
                if(zObjectSize == 0) 
                {
                   return new ReturnClass('', '', '', '', 'false', '', 'INVALID ACCOUNT', 'Account Does Not Exists');
                }                
                ReturnClass newAccount = new ReturnClass(accountId, billToId, soldToId, AccountNumber, 'true', DefaultPaymentMethodId, 'New Billing Account Created', 'Successful');
                newAccount.balance = 0.00;
                newAccount.isAutoPay = 'false';
                newAccount.batch = BillingBatchNo;
                return new ReturnClass(accountId, billToId, soldToId, AccountNumber, 'true', DefaultPaymentMethodId, 'New Billing Account Created', 'Successful');
             } else {
                return new ReturnClass('', '', '', '', 'false', '', 'FAILED', getZuoraErrorMsg(result.errors));
             } 
         } catch (Exception e) {
           return new ReturnClass('', '', '', '', 'false', '', 'FAILED', e.getMessage());
         } 
    }
             
  public static String getZuoraErrorMsg(Zuora.zObject[] errors)
  {
     String message = '';
     for(Zuora.zObject error : errors) {
        message += (String)error.getValue('Message');
     }
     return message;
  }
  
  public static String getStateName(String StateCode, String CountryName)
  {
      List<pw_ccpro__state__c> stateLst = [SELECT Name FROM pw_ccpro__state__c WHERE pw_ccpro__IsoCode__c  = :StateCode AND pw_ccpro__Country__r.Name = :CountryName LIMIT 1];
      if(stateLst.size() >= 1) return stateLst[0].Name;
      return StateCode;
  }

  public static String getBillingAccountBatch(String zuoraAccountId, String currentBatch, String processName, String gateway, String brandTag, Decimal quoteAmount)
  {
    //system.debug('AccountBatch###: ' + zuoraAccountId+'-'+currentBatch+'-'+processName+'-'+gateway+'-'+brandTag+'-'+quoteAmount);
    if(gateway == null) gateway = '';
    if((currentBatch == null || currentBatch == '') && zuoraAccountId != null && zuoraAccountId != '')
    {
      String zoql = 'SELECT Batch  FROM Account WHERE Id = \'' + zuoraAccountId + '\'';
       if(!Test.isRunningTest())
       {
          List<Zuora.zObject> zSubobjs = zApiInstance.zquery(zoql);
          if(zSubobjs.size() > 0)
          {
             currentBatch = (String)zSubobjs[0].getValue('Batch');
          }
       }
    }
    if(currentBatch == 'Batch2') return currentBatch;
    //Godfrey - CCBOB-141 : Remove WorldPay Gateway from Batch 10 --  || gateway.contains('WorldPay_Gateway')
    if(processName == 'Webstore' || brandTag == 'eFC-China' || brandTag == 'eFC-Asia' || brandTag == 'RZ-APAC' || quoteAmount == 0.00) return 'Batch10';
    
    return label.Billing_Batch_Number;
  }
  
  public static ReturnClass IsBillingAccountActive(String BillingAccountId)
  {
       String zoql, AccountNumber, BillToId, SoldToId, AutoPay, Batch, DefaultPaymentMethodId;
       Double Balance;
       Integer zObjectSize = 0, whereCount = 0, pageSize = 199;
       List<Zuora.zObject> zSubobjs = new List<Zuora.zObject>();
       zoql = 'SELECT Name, AccountNumber, Batch, BillToId, SoldToId, Balance, AutoPay, DefaultPaymentMethodId FROM Account WHERE Status = \'Active\' AND Id = \'' + BillingAccountId + '\'';
       String isSuccess = 'false';
       ReturnClass rtnClass;
       if(!Test.isRunningTest())
       {
            zSubobjs = zApiInstance.zquery(zoql);
       }
       else
       {
          if('NotActivelyBilling'.equals(BillingAccountId)) return new ReturnClass('', '', 'false', '', '');
          zSubobjs = new Zuora.zObject[] { new Zuora.zObject('Account')};
          zSubobjs[0].setValue('AccountNumber', 'A000001');
          zSubobjs[0].setValue('Batch', 'Batch1');
          zSubobjs[0].setValue('SoldToId', '00000000000');
          zSubobjs[0].setValue('BillToId', '00000000000');
          zSubobjs[0].setValue('Balance', 0);
          zSubobjs[0].setValue('AutoPay', true);
          zSubobjs[0].setValue('DefaultPaymentMethodId', '00000000000');
       }
       //zObjectSize = zSubobjs.size();
       if(zSubobjs.size() > 0)
       {
          AccountNumber = (String)zSubobjs[0].getValue('AccountNumber');
          Batch = (String)zSubobjs[0].getValue('Batch');
          BillToId = (String)zSubobjs[0].getValue('BillToId');
          SoldToId = (String)zSubobjs[0].getValue('SoldToId');
          Balance = (Double)zSubobjs[0].getValue('Balance');
          AutoPay = (Boolean)zSubobjs[0].getValue('AutoPay') ? 'true' : 'false';
          DefaultPaymentMethodId = (String)zSubobjs[0].getValue('DefaultPaymentMethodId');
       }
       else
       {
           return new ReturnClass(BillingAccountId, '', '', '', 'false',  '', 'INVALID ACCOUNT', 'Account Is Not Active or Does Not Exists');
       }
       
      zoql = 'SELECT Id, AccountId, SubscriptionEndDate, Status, TermStartDate, TermType, OriginalId, Version';
      zoql += ' FROM Subscription WHERE Status = \'Active\' AND AccountId = \'';
      zoql += BillingAccountId;
      zoql += '\''; 
      if(!Test.isRunningTest())
      {
         zSubobjs = zApiInstance.zquery(zoql);
      }
      else
      {
        zSubobjs = new Zuora.zObject[] { new Zuora.zObject('Subscription'),  new Zuora.zObject('Subscription'),  new Zuora.zObject('Subscription')};
        zSubobjs[0].setValue('Id', '00000000000');
        zSubobjs[0].setValue('AccountId', '00000000000');
        zSubobjs[0].setValue('SubscriptionEndDate', '00000000000');
        zSubobjs[0].setValue('Status', 'Active');
        zSubobjs[0].setValue('TermStartDate', '00000000000');
        zSubobjs[0].setValue('TermType', 'OneTime'.equals(BillingAccountId) ? 'OneTime' :'EVERGREEN');
        zSubobjs[0].setValue('OriginalId', '00000000000');  
        zSubobjs[0].setValue('Version', 0);      

        zSubobjs[2].setValue('Id', '00000000000');
        zSubobjs[2].setValue('AccountId', '00000000000');
        zSubobjs[2].setValue('SubscriptionEndDate', '00000000000');
        zSubobjs[2].setValue('Status', 'Active');
        zSubobjs[2].setValue('TermStartDate', '00000000000');
        zSubobjs[2].setValue('TermType', 'OneTime'.equals(BillingAccountId) ? 'OneTime' :'EVERGREEN');
        zSubobjs[2].setValue('OriginalId', '00000000000');  
        zSubobjs[2].setValue('Version', 1);      

        zSubobjs[1].setValue('Id', '00000000001');
        zSubobjs[1].setValue('AccountId', '00000000000');
        zSubobjs[1].setValue('SubscriptionEndDate', '00000000000');
        zSubobjs[1].setValue('Status', 'Active');
        zSubobjs[1].setValue('TermStartDate', '00000000000');
        zSubobjs[1].setValue('TermType', 'OneTime');
        zSubobjs[1].setValue('OriginalId', '00000000000');  
        zSubobjs[1].setValue('Version', 0);      
      }
      rtnClass = new ReturnClass(BillingAccountId, BillToId, SoldToId, AccountNumber, isSuccess, '', 'NOT BILLING', 'Successful');
      rtnClass.Balance = Balance;
      rtnClass.batch = Batch;
      rtnClass.isAutoPay = AutoPay;
      rtnClass.DefaultPaymentMethodId = DefaultPaymentMethodId;
      if(rtnClass.Balance != 0) rtnClass.matchType += ' AND HAS OUTSTANDING BALANCE';
      if(zSubobjs.size() <= 0) return rtnClass; 
      
      //Create a map for latest subscription version
      Map<String, Zuora.zObject> latestSubscriptionMap = new Map<String, Zuora.zObject>();
      for(Zuora.zObject zobj : zSubobjs)
      {
         if(latestSubscriptionMap.get((String)zobj.getValue('OriginalId')) == null)
         {
             latestSubscriptionMap.put((String)zobj.getValue('OriginalId'), zobj);
         }
         else
         {
            if(((Decimal)latestSubscriptionMap.get((String)zobj.getValue('OriginalId')).getValue('Version')) < ((Decimal)zobj.getValue('Version')))
            {
                latestSubscriptionMap.put((String)zobj.getValue('OriginalId'), zobj);
            }
         }
      }
      //Find Rateplan corresponding to the subscriptions and Replace the key OriginalId on subscription map with Id
      List<Zuora.zObject> latestSubscriptionLst = latestSubscriptionMap.values();
      latestSubscriptionMap.clear();
      for(Integer i = 0; i < latestSubscriptionLst.size(); i++)
      {
         latestSubscriptionMap.put((String)latestSubscriptionLst[i].getValue('Id'), latestSubscriptionLst[i]);
      }
      if('EVERGREEN' == (String)latestSubscriptionLst[0].getValue('TermType') && 'Active' == (String)latestSubscriptionLst[0].getValue('Status')) 
      {        
          rtnClass = new ReturnClass(BillingAccountId, '', '', AccountNumber, 'true', '', 'EVERGREEN', 'Successful');
          rtnClass.Balance = Balance;
          rtnClass.isAutoPay = AutoPay;
          rtnClass.batch = Batch;
          rtnClass.DefaultPaymentMethodId = DefaultPaymentMethodId;
          return rtnClass;
      }

      whereCount = 0;  
      List<Zuora.zObject> zRatePlanObjs = new List<Zuora.zObject>();
      while(whereCount < latestSubscriptionLst.size())
      {
        zoql = 'SELECT Id, Name, SubscriptionId from RatePlan Where SubscriptionId =\'' + latestSubscriptionLst[whereCount++].getValue('Id') + '\'';
        if (latestSubscriptionLst.size() - whereCount > 1) {
           for (; whereCount < latestSubscriptionLst.size() && (whereCount < pageSize || Math.mod(whereCount, pageSize) != 0); whereCount++)
           {
              if('EVERGREEN' == (String)latestSubscriptionLst[whereCount].getValue('TermType') && 'Active' == (String)latestSubscriptionLst[whereCount].getValue('Status')) 
              {        
                  rtnClass = new ReturnClass(BillingAccountId, '', '', AccountNumber, 'true', '', 'EVERGREEN', 'Successful');
                  rtnClass.Balance = Balance;
                  rtnClass.isAutoPay = AutoPay;
                  rtnClass.batch = Batch;
                  rtnClass.DefaultPaymentMethodId = DefaultPaymentMethodId;
                  return rtnClass;
              }
              latestSubscriptionMap.put((String)latestSubscriptionLst[whereCount].getValue('Id'), latestSubscriptionLst[whereCount]);
              zoql += ' Or SubscriptionId =\'' + latestSubscriptionLst[whereCount].getValue('Id') +'\'';  
           }
        }                    
      
        if(!Test.isRunningTest())
        {
          List<Zuora.zObject> zRatePlanObjsBatches = zApiInstance.zquery(zoql);
          zRatePlanObjs.addAll(zRatePlanObjsBatches);
        } 
      }
      if(zRatePlanObjs.size() <= 0)
      {        
          rtnClass = new ReturnClass(BillingAccountId, BillToId, SoldToId, AccountNumber, isSuccess, '', 'NOT BILLING', 'Successful');
          rtnClass.Balance = Balance;
          if(rtnClass.Balance != 0) rtnClass.matchType += ' AND HAS OUTSTANDING BALANCE';
          rtnClass.isAutoPay = AutoPay;
          rtnClass.batch = Batch;
          rtnClass.DefaultPaymentMethodId = DefaultPaymentMethodId;
          return rtnClass;
      }
      
      whereCount = 0;
      List<Zuora.zObject> zRatePlanChargeObjs = new List<Zuora.zObject>();
      while(whereCount < zRatePlanObjs.size())
      {
        //Find Charges corresponding to the rateplans
        zoql = 'SELECT Id, Name, ChargedThroughDate, RatePlanId, ChargeType, ApplyDiscountTo, ChargeModel From RatePlanCharge Where RatePlanId =\'' + zRatePlanObjs[whereCount++].getValue('Id') + '\'';
        if (zRatePlanObjs.size() - whereCount > 1)
        {
            //for (Integer i = 1; i < zRatePlanObjs.size() && whereCount++ < 10; i++) 
            for (; whereCount < zRatePlanObjs.size() && (whereCount < pageSize || Math.mod(whereCount, pageSize) != 0); whereCount++) 
            {
                zoql += ' Or RatePlanId =\'' + zRatePlanObjs[whereCount].getValue('Id') +'\'';
            }
        }         
        if(!Test.isRunningTest())
        {
          List<Zuora.zObject> zRatePlanChargeObjsBatch = zApiInstance.zquery(zoql);  
          zRatePlanChargeObjs.addAll(zRatePlanChargeObjsBatch);
        }  
      }

      if(zRatePlanChargeObjs.size() <= 0) 
      {
        rtnClass = new ReturnClass(BillingAccountId, BillToId, SoldToId, AccountNumber, isSuccess, '', 'NOT BILLING', 'Successful');
          rtnClass.Balance = Balance;
          if(rtnClass.Balance != 0) rtnClass.matchType += ' AND HAS OUTSTANDING BALANCE';
          rtnClass.isAutoPay = AutoPay;
          rtnClass.batch = Batch;
          rtnClass.DefaultPaymentMethodId = DefaultPaymentMethodId;
          return rtnClass;
        //return new ReturnClass(BillingAccountId, BillToId, SoldToId, AccountNumber, isSuccess, '','NOT BILLING', 'Successful');
      }
      //Determine whether all charges have been charged through
      for (Zuora.zObject zRatePlanCharge : zRatePlanChargeObjs)
      { 
          // Skip discount
          if(((String)zRatePlanCharge.getValue('ChargeModel')).contains('Discount')) continue; 
          DateTime chargedThroughDate = (DateTime)zRatePlanCharge.getValue('ChargedThroughDate');           
          String currentChrgRatePlanId = (String)zRatePlanCharge.getValue('RatePlanId');
          String currentChrgSubscriptionId;
          DateTime subscriptionEndDate;
          //Find subscription Id for this particular charge
          for (Zuora.zObject zratePlan : zRatePlanObjs){ 
              if ((String)zratePlan.getValue('Id') == currentChrgRatePlanId){
                  currentChrgSubscriptionId = (String)zratePlan.getValue('SubscriptionId');
                  // Get Subscription Object from the map 
                  subscriptionEndDate = (DateTime)latestSubscriptionMap.get(currentChrgSubscriptionId).getValue('SubscriptionEndDate');  
                  break;
              }
          } 
           
          //Check whether all recurring charges have been billed through
          if (chargedThroughDate != null && subscriptionEndDate != null && zSubobjs.size() > 0){
              if (
                   (
                     (!(chargedThroughDate.year() == subscriptionEndDate.year() && chargedThroughDate.day() == subscriptionEndDate.day() && chargedThroughDate.month() == subscriptionEndDate.month())) 
                      && (chargedThroughDate < subscriptionEndDate) 
                   )
                   && (String)zRatePlanCharge.getValue('ChargeType') == 'Recurring'
                 )
              {         
                  rtnClass = new ReturnClass(BillingAccountId, BillToId, SoldToId, AccountNumber, 'true', '', 'ACTIVE SUBSCRIPTION', 'Successful');
                  rtnClass.Balance = Balance;
                  rtnClass.isAutoPay = AutoPay;
                  rtnClass.batch = Batch;
                  rtnClass.DefaultPaymentMethodId = DefaultPaymentMethodId;
                  return rtnClass;
              }
          } 
          else if(chargedThroughDate == null && zSubobjs.size() > 0)
          {
             rtnClass = new ReturnClass(BillingAccountId, BillToId, SoldToId, AccountNumber, 'true', '', 'ACTIVE SUBSCRIPTION', 'Successful');
             rtnClass.Balance = Balance;
             rtnClass.isAutoPay = AutoPay;
             rtnClass.batch = Batch;
             rtnClass.DefaultPaymentMethodId = DefaultPaymentMethodId;
             return rtnClass;
          }
      }
      rtnClass = new ReturnClass(BillingAccountId, BillToId, SoldToId, AccountNumber, isSuccess, '', 'NOT BILLING', 'Successful');
      rtnClass.Balance = Balance;
      if(rtnClass.Balance != 0) rtnClass.matchType += ' AND HAS OUTSTANDING BALANCE';
      rtnClass.isAutoPay = AutoPay;
      rtnClass.batch = Batch;
      rtnClass.DefaultPaymentMethodId = DefaultPaymentMethodId;
      return rtnClass;
  }
  
}