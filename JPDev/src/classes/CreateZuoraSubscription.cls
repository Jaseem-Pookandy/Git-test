// The Apex Plug-in for a flow must implement the Apex Process.Plugin Interface
global with sharing class CreateZuoraSubscription {
//global with sharing class CreateZuoraSubscription implements Process.Plugin {

/*    public String pluginStatus;
    public String pluginErrorMessage;
    public Zuora.zObject zuoraAccount;
    public Zuora.zObject zuoraBillToContact;
    
    public static final String SUCCESS = 'SUCCESS';
    public static final String ERROR = 'ERROR';
    public static final String SUCCESS_MESSAGE = 'Subscription Created Successfully';
    public  static Zuora.zApi zApiInstance = new Zuora.zApi();

 
    global Process.PluginResult invoke(Process.PluginRequest request) { 
                                       
            String accountId;
            String crmCurrency; 
            String accountName;  
            String accountNumberAssigned;  
            String address1;
            String city;
            String country;
            String fax;
            String firstName;
            String lastName;
            String personalEmail;
            String postalCode;
            String state;
            String workEmail;
            String workPhone;  
            String customerServiceRepName;
            String salesRepName;
            String region;
            String subRegion1;
            String subRegion2;
            String energyRegion;
            String salesRepId;
            
            // Contact, Account, Account Brand, Country input parameters 
            String contactId = (String) request.inputParameters.get('ContactId'); 
            String brandName = (String) request.inputParameters.get('BrandName');
            
            //Subscription input parameters
            String TermStartDate = (String)request.inputParameters.get('TermStartDate');
            String ContractEffectiveDate = (String)request.inputParameters.get('ContractEffectiveDate');
            String ContractAcceptanceDate = (String)request.inputParameters.get('ContractAcceptanceDate');
            String ServiceActivationDate = (String)request.inputParameters.get('ServiceActivationDate');
            String ServiceEndDate = (String)request.inputParameters.get('ServiceEndDate');
            Integer InitialTerm = (Integer)request.inputParameters.get('InitialTerm');
            Integer RenewalTerm = (Integer)request.inputParameters.get('RenewalTerm');
            String Notes = (String)request.inputParameters.get('Notes');
            String Status = (String)request.inputParameters.get('Status');
            String IsInvoiceSeparate = (String)request.inputParameters.get('IsInvoiceSeparate');
            String BrandTag = (String)request.inputParameters.get('BrandTag');
            String OpptyName = (String)request.inputParameters.get('OpptyName');
            String ContractChannel = (String)request.inputParameters.get('ContractChannel');
            String GlobalDeal = (String)request.inputParameters.get('GlobalDeal');
            String DeferredBillDate = (String)request.inputParameters.get('DeferredBillDate');
            
            //Rateplan input parameters
            String chargeId = (String)request.inputParameters.get('ChargeId');
            String productRatePlanId = (String)request.inputParameters.get('ProductRatePlanId ');
            
            //Invoice Template input parameters
            String invoiceTemplateName = (String)request.inputParameters.get('InvoiceTemplateName');
            String invoiceTemplateId = (String)request.inputParameters.get('InvoiceTemplateId');
            String paymentGateway = (String)request.inputParameters.get('PaymentGateway');
            
            List<contact> contactLst = [SELECT AccountId, Account.Name, Account.CurrencyIsoCode, Account.Account_Number_Assigned__c, Email, Fax, FirstName, HomePhone, Id, LastName, 
                                        MailingCity, MailingCountry, MailingPostalCode, MailingState, MailingStreet, MobilePhone, Name, Phone 
                                        FROM Contact WHERE Id = :contactId LIMIT 1];
            for(Contact aContact : contactLst)
            {                            
                accountId = aContact.AccountId;
                crmCurrency = aContact.Account.CurrencyIsoCode; 
                accountName = aContact.Account.Account_Number_Assigned__c;  
                accountNumberAssigned = aContact.Account.Account_Number_Assigned__c;  
                address1 = aContact.MailingStreet;
                city = aContact.MailingCity;
                country = aContact.MailingCountry;
                fax = aContact.Fax;
                firstName = aContact.FirstName;
                lastName = aContact.LastName;
                personalEmail = aContact.Email;
                postalCode = aContact.MailingPostalCode;
                state = aContact.MailingState;
                workEmail = aContact.Email;
                workPhone = aContact.Phone;   
            }            
            List<Account_Brand__c> accountBrandLst = [SELECT Id, Primary_Owner__r.Name, Primary_Owner__c, CS__r.Name FROM  Account_Brand__c WHERE Account__c = :accountId AND Brand_Name__c = :brandName Limit 1];
            for(Account_Brand__c accountBrand : accountBrandLst)
            {
                salesRepName = accountBrand.Primary_Owner__r.Name;
                salesRepId = accountBrand.Primary_Owner__c; //2668
                customerServiceRepName = accountBrand.CS__r.Name;
            }  
            for(pw_ccpro__CountryObject__c pwCountry : [SELECT Id, Name, Region__c, Region_Energy__c, Sub_Region1__c, Sub_Region2__c FROM pw_ccpro__CountryObject__c WHERE Name = :country Limit 1])
            { 
               region = pwCountry.Region__c; 
               subRegion1 = pwCountry.Sub_Region1__c;
               subRegion2 = pwCountry.Sub_Region2__c;
               energyRegion = pwCountry.Region_Energy__c; 
            }     
                         
            Map<String,Object> result = new Map<String,Object>();
            try {
            //Create Subscription Object
            Zuora.zObject zSubscription = new Zuora.zObject('Subscription'); 
            zSubscription.setValue('TermStartDate', TermStartDate);
            zSubscription.setValue('ContractEffectiveDate', ContractEffectiveDate);
            zSubscription.setValue('ContractAcceptanceDate', ContractAcceptanceDate);
            zSubscription.setValue('ServiceActivationDate', ServiceActivationDate);
            zSubscription.setValue('Service_End_Date__c', ServiceEndDate);
            zSubscription.setValue('InitialTerm', InitialTerm);
            zSubscription.setValue('RenewalTerm', RenewalTerm);
            zSubscription.setValue('Notes', Notes);
            zSubscription.setValue('Status', Status);
            zSubscription.setValue('IsInvoiceSeparate', IsInvoiceSeparate);
            zSubscription.setValue('BrandTag__c', BrandTag);
            zSubscription.setValue('Name', OpptyName);
            zSubscription.setValue('ContractOwner__c', salesRepName);
            zSubscription.setValue('ContractChannel__c', ContractChannel);
            zSubscription.setValue('Global_Deal__c', GlobalDeal);
            zSubscription.setValue('Deferred_Bill_Date__c', DeferredBillDate);
            
            //Create Rateplan collection
            List<Zuora.zObject> zRatePlanDataArry = new List<Zuora.zObject>();
            
            Zuora.zObject zRatePlanCharge = new Zuora.zObject('RatePlanCharge');
            zRatePlanCharge.setValue('ProductRatePlanChargeId', chargeId);
            zRatePlanCharge.setValue('TriggerEvent', 'ServiceActivation');
            zRatePlanCharge.setValue('IsPrimarySalesRepOwner__c', 'TRUE');
            zRatePlanCharge.setValue('Sales_Representative__c', salesRepName);
            zRatePlanCharge.setValue('SalesRepId__c', salesRepId);
            zRatePlanCharge.setValue('Country__c', country);
            zRatePlanCharge.setValue('Region__c', region);
            zRatePlanCharge.setValue('SubRegion1__c', subRegion1);
            zRatePlanCharge.setValue('SubRegion2__c', subRegion2);
            zRatePlanCharge.setValue('EnergyRegion__c', energyRegion);
            
            Zuora.zObject zRatePlanChargeData = new Zuora.zObject('RatePlanChargeData');
            zRatePlanChargeData.setValue('RatePlanCharge', zRatePlanCharge);
            
            Zuora.zObject zRatePlan = new Zuora.zObject('RatePlan');
            zRatePlan.setValue('ProductRatePlanId', productRatePlanId);
            
            Zuora.zObject zRatePlanData = new Zuora.zObject('RatePlanData');
            zRatePlanData.setValue('RatePlan', zRatePlan);
            zRatePlanData.setValue('RatePlanChargeData', new List<Zuora.zObject> { zRatePlanChargeData });
            zRatePlanDataArry.add(zRatePlanData); 
            
            //Create Billing Account
            createZuoraAccount(accountId, crmCurrency, accountName, accountNumberAssigned, customerServiceRepName, salesRepName, brandTag, invoiceTemplateName, 
                    invoiceTemplateId, PaymentGateway, address1, city, country, fax, firstName, lastName, personalEmail, postalCode, state, workEmail, workPhone);
        
            //subscription data
            Zuora.zApi.SubscriptionData subscriptionData = new Zuora.zApi.SubscriptionData();
            subscriptionData.Subscription = zSubscription;
            subscriptionData.RatePlanData = zRatePlanDataArry;
            
            //subscription options - Need to add SubscribeInvoiceProcessingOptions 
            Zuora.zApi.SubscribeOptions subscribeOptions = new Zuora.zApi.SubscribeOptions();
            subscribeOptions.GenerateInvoice = true;
            subscribeOptions.ProcessPayments = false;
            
            //subscribe request
            Zuora.zApi.SubscribeRequest subscribeRequest = new Zuora.zApi.SubscribeRequest();
            subscribeRequest.ZAccount = zuoraAccount;
            subscribeRequest.BillToContact = zuoraBillToContact;
            subscribeRequest.SubscriptionData = subscriptionData;
           // subscribeRequest.PaymentMethod = zPaymentMethod;
            subscribeRequest.SubscribeOptions = subscribeOptions; 
            List<Zuora.zApi.SubscribeRequest> subscribeRequestLst = new List<Zuora.zApi.SubscribeRequest>();
            subscribeRequestLst.add(subscribeRequest);

            String subscriptionId;
            String errorMessage = '';
            List<Zuora.zApi.SubscribeResult> SubscribeResultLst;
            if(subscribeRequestLst.size() > 0)
            {  
              if(!Test.isRunningTest()) SubscribeResultLst = zApiInstance.zsubscribe(subscribeRequestLst);            
              if(SubscribeResultLst != null)
              {        
                  for (integer i = 0; i < SubscribeResultLst.size(); i++)
                  {
                     Zuora.zApi.SubscribeResult createSubscriptionResult = SubscribeResultLst[i];
                     if(createSubscriptionResult.Success) {
                        subscriptionId = createSubscriptionResult.SubscriptionId;
                        errorMessage = 'Success' ;
                     }
                     else {
                        errorMessage = '';
                        Zuora.zObject[] errors = createSubscriptionResult.errors;
                        for (Zuora.zObject createSubscriptionError : errors) {
                            errorMessage += (String)createSubscriptionError.getValue('Message');
                        }
                      }
                  }
              }
          }                
         
        //CreateZuoraSubscription();
        result.put('SubscriptionId ', subscriptionId);
        result.put('SubscriptionError', errorMessage);
        result.put('Status', pluginStatus);
        result.put('ErrorMessage', pluginErrorMessage);
    }
    catch (Exception anException) {
        result.put('Status',ERROR);
        result.put('ErrorMessage', anException.getMessage());

    }
     
        return new Process.PluginResult(result); 
    }
    
    /**
     * Implementation of the CreateZuoraSubscriptionApex plug-in 
     */
    global void CreateZuoraSubscription(
    ) 
    {
    }

    /* This is the method the Cloud Flow Designer calls to show the Apex Plug-ins to the flow author
     * The implemnetation of this method drives how author of the flow interacts in the the Cloud Flow Designer 
     
    global Process.PluginDescribeResult describe() {
    
    Process.PluginDescribeResult result = new Process.PluginDescribeResult();
        //Shows the description visible in the Palette tab of the Cloud Flow Designer.    
        result.description = 'The CreateZuoraSubscription Flow Plug-in create a subscription in Zuora using a SOAP API';
        
        //Setting the 'tag' give the Apex Plug-in as its own section on the Cloud Flow Designer Palette tab.
        // Use this attribute to group related Apex Plug-ins together in the Cloud Flow Designer.        
        result.tag = 'Subscriptions';

        //All the Inputs needed, their data type and the requiredness        
        result.inputParameters = new List<Process.PluginDescribeResult.InputParameter>{
             new Process.PluginDescribeResult.InputParameter('Address1', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('City', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('Country', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('Fax', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('FirstName', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('LastName', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('PersonalEmail', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('PostalCode', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('State', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('WorkEmail', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('WorkPhone', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('TermStartDate', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('ContractEffectiveDate', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('ContractAcceptanceDate', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('ServiceActivationDate', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('ServiceEndDate', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('InitialTerm', 
                Process.PluginDescribeResult.ParameterType.INTEGER, true),
            new Process.PluginDescribeResult.InputParameter('RenewalTerm', 
                Process.PluginDescribeResult.ParameterType.INTEGER, true),
            new Process.PluginDescribeResult.InputParameter('Notes', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('Status', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('BrandTag', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('Name', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('ContractOwner', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('ContractChannel', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('GlobalDeal', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('DeferredBillDate', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('SalesRepName', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('Region', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('SubRegion1', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('SubRegion2', 
                Process.PluginDescribeResult.ParameterType.STRING, true),
            new Process.PluginDescribeResult.InputParameter('EnergyRegion', 
                Process.PluginDescribeResult.ParameterType.STRING, true)
            };

        //All the Outputs and their data type
        result.outputParameters = new List<Process.PluginDescribeResult.OutputParameter>{  
            new Process.PluginDescribeResult.OutputParameter('SubscriptionId ', 
                Process.PluginDescribeResult.ParameterType.STRING),
            new Process.PluginDescribeResult.OutputParameter('SubscriptionError', 
                Process.PluginDescribeResult.ParameterType.STRING),
            new Process.PluginDescribeResult.OutputParameter('Status', 
                Process.PluginDescribeResult.ParameterType.STRING),
            new Process.PluginDescribeResult.OutputParameter('ErrorMessage', 
                Process.PluginDescribeResult.ParameterType.STRING)                                    
                };        
        return result;
        }
 
        private void createZuoraContact(String address1, String city, String country, String fax, String firstName, 
                String lastName, String personalEmail, String postalCode, String state, String workEmail, String workPhone){
                  Zuora.zObject zuoraBillToContact = new Zuora.zObject('Contact'); 
                  zuoraBillToContact.setValue('Address1', address1);
                  zuoraBillToContact.setValue('City', city);
                  zuoraBillToContact.setValue('Country', country);
                  zuoraBillToContact.setValue('Fax', fax);
                  zuoraBillToContact.setValue('FirstName', firstName);
                  zuoraBillToContact.setValue('LastName', lastName);
                  zuoraBillToContact.setValue('PersonalEmail', personalEmail);
                  zuoraBillToContact.setValue('PostalCode', postalCode);
                  zuoraBillToContact.setValue('State', state);
                  zuoraBillToContact.setValue('WorkEmail', workEmail);
                  zuoraBillToContact.setValue('WorkPhone', workPhone);
        }
   
   private void createZuoraAccount(String accountId, String crmCurrency, String  accountName, String  accountNumberAssigned, 
                 String customerServiceRepName, String salesRepName, String  brandTag, String  invoiceTemplateName, String invoiceTemplateId, String  PaymentGateway,
                 String address1, String city, String country, String fax, String firstName, 
                 String lastName, String personalEmail, String postalCode, String state, String workEmail, String workPhone){ 
        String zuoraAccountId = '';
        String zuoraContactId;
        String zuoraCurrency; 
        String zoql = 'SELECT BrandTag__c, BillToId, CrmId, Currency, Id, DefaultPaymentMethodId, Name FROM Account  WHERE  CrmId = \'' + accountId + '\'';
        if(!Test.isRunningTest()) zApiInstance.zlogin(); 
        if(!Test.isRunningTest())
        {
          List<Zuora.zObject> zAcctobjs = zApiInstance.zquery(zoql);
          for(Zuora.zObject zAcct : zAcctobjs){ 
             zuoraAccountId = (String)zAcct.getValue('Id'); 
             zuoraCurrency= (String)zAcct.getValue('Currency'); 
             zuoraAccount = zAcct;
          }
        }

        if(!''.equals(zuoraAccountId) && zuoraCurrency.equals(crmCurrency) )
         {
            List<Zuora.zObject> billToobjs;
            zoql = 'SELECT Address1, Address2, City, Country, Fax, Id, PostalCode, State';
            zoql += '  FROM Contact WHERE Id = \'' + zuoraContactId + '\'';
            if(!Test.isRunningTest()) billToobjs = zApiInstance.zquery(zoql);
                for(Zuora.zObject billToobj : billToobjs){
                    if(address1.contains((String)billToobj.getValue('Address1')) 
                        && city.equals((String)billToobj.getValue('City'))
                        && country.equals((String)billToobj.getValue('Country')) 
                        && postalCode.equals((String)billToobj.getValue('PostalCode'))
                        // state.equals((String)billToobj.getValue('State')) // SFDC uses state code while Zuora use state names... translation is required
                        ){
                        zuoraContactId = (String)billToobj.getValue('Id');
                        zuoraBillToContact = billToobj;
                        break;
                    }
                }
         }
        
        if(zuoraAccount == null)
        {           
            zuoraAccount = new Zuora.zObject('Account');        
            zuoraAccount.setValue('CrmId', accountId);     
            zuoraAccount.setValue('CRMAccountName__c', accountName);
            zuoraAccount.setValue('CRMAccountNumber__c', accountNumberAssigned);
            zuoraAccount.setValue('Currency', crmCurrency);
            zuoraAccount.setValue('Name', accountName);
            zuoraAccount.setValue('PaymentTerm', 'Due Upon Receipt');
            zuoraAccount.setValue('Batch', 'Batch10');
            zuoraAccount.setValue('BillCycleDay', 1);
            zuoraAccount.setValue('Status' ,'Draft');
            zuoraAccount.setValue('AutoPay', 'FALSE');
            zuoraAccount.setValue('Notes', 'One Post Billing Account for ' + accountName);
            zuoraAccount.setValue('CustomerServiceRepName', customerServiceRepName);
            zuoraAccount.setValue('SalesRepName', salesRepName);     
            zuoraAccount.setValue('BrandTag__c', brandTag);
            zuoraAccount.setValue('InvoiceTemplateName__c', invoiceTemplateName);
            zuoraAccount.setValue('InvoiceTemplateId',invoiceTemplateId);
            zuoraAccount.setValue('PaymentGateway', PaymentGateway); 
            //Create Contact
            createZuoraContact(address1, city, country, fax, firstName, lastName, personalEmail, postalCode, state, workEmail, workPhone);
        } 
    } 
  */
    }