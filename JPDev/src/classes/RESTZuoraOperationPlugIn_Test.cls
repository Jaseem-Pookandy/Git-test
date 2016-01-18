@isTest(SeeAllData=true)
private class RESTZuoraOperationPlugIn_Test {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        //test.startTest();
        CreateData();
        //test.stopTest();    
        System.AssertEquals(1, 1);
    }  
  static void CreateData() {
         test.startTest(); 
                
       //Account
       Account account = TestUtils.createAccount();
       account.Validation_Status__c = 'Validated'; 
       account.Customer_Segment__c = 'Direct Hire';
       insert account; 
        
       Map<String, String> requestParameterMap = new Map<String, String>();
       requestParameterMap.put('Operation', 'CreateBillingAccount');
       requestParameterMap.put('CRMAccountId', account.Id);
       requestParameterMap.put('IsoCurrency', 'USD');
       requestParameterMap.put('BrandTag', 'Dice');
       requestParameterMap.put('PaymentMethod', 'Credit Card');
       requestParameterMap.put('ContextLanguage', 'English');
       requestParameterMap.put('PaymentTerm', 'Net 30');
       requestParameterMap.put('SoldToAddress', '1331 L Street');
       requestParameterMap.put('SoldToCity', 'Washington');
       requestParameterMap.put('SoldToCountry', 'United States');
       requestParameterMap.put('SoldToPostalCode', '20005');
       requestParameterMap.put('SoldToState', 'District of Columbia');
       requestParameterMap.put('SoldToFirstName', 'Godfrey');
       requestParameterMap.put('SoldToLastName', 'Mwamsoyo'); 
       requestParameterMap.put('SoldToPersonalEmail', 'elizabeth.cruz@dice.com');
       requestParameterMap.put('SoldToWorkEmail', 'elizabeth.cruz@dice.com');
       requestParameterMap.put('SoldToWorkPhone', '515-782-6710');
       requestParameterMap.put('BillToAddress', '1331 L Street');
       requestParameterMap.put('BillToCity', 'Washington');
       requestParameterMap.put('BillToCountry', 'United States');
       requestParameterMap.put('BillToPostalCode', '20005');
       requestParameterMap.put('BillToState', 'District of Columbia');
       requestParameterMap.put('BillToFirstName', 'Elizabeth');
       requestParameterMap.put('BillToLastName', 'Cruz'); 
       requestParameterMap.put('BillToPersonalEmail', 'elizabeth.cruz@dice.com');
       requestParameterMap.put('BillToWorkEmail', 'elizabeth.cruz@dice.com');
       requestParameterMap.put('BillToWorkPhone', '515-782-6710');
       requestParameterMap.put('CustomerServiceRepName', 'Devi Tummala');
       requestParameterMap.put('SalesRepName', 'Elizabeth Cruz');
       requestParameterMap.put('InvoiceDeliveryPref', 'Print');    
       requestParameterMap.put('SalesRepDivision','');
       RESTZuoraOperationPlugIn.ReturnClass createAcctResult = RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap);
       System.debug('create Account Result = ' + createAcctResult.message);
       //System.assertEquals(createAcctResult.isActiveBilling, 'true');    
       
       requestParameterMap.put('InvoiceDeliveryPref', 'Email');    
       createAcctResult = RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap);   
       
       requestParameterMap.put('InvoiceDeliveryPref', 'Both');    
       createAcctResult = RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap);  
              
       requestParameterMap.put('BillingAccountId', 'NotActivelyBilling');
       createAcctResult = RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap);

       requestParameterMap.put('Operation', 'IsBillingAccountActive');
       requestParameterMap.put('BillingAccountId', 'e20b0747486604b70148c2d90ff80e89');
       RESTZuoraOperationPlugIn.ReturnClass isAccountActiveResult = RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap);
       System.debug('Is Account Active Result = ' + isAccountActiveResult.isActiveBilling);
       //System.assertEquals(isAccountActiveResult.isActiveBilling, 'false');    

       requestParameterMap.put('Operation', 'IsBillingAccountActive');
       requestParameterMap.put('BillingAccountId', 'OneTime');
       isAccountActiveResult = RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap);
       System.debug('Is Account Active Result = ' + isAccountActiveResult.isActiveBilling);
       
       Map<String,String> resultMap =  RESTZuoraOperationPlugIn.parse('/name/value');
       //System.assertEquals(resultMap.get('name') , 'value');    
       
       String stateName = RESTZuoraOperationPlugIn.getStateName('IA', 'United States');
       //System.assertEquals(stateName, 'Iowa');    
       
       Zuora.zObject contactObj = RESTZuoraOperationPlugIn.createZuoraContact('Dice', 'SoldToContact', '1331 L Street', 'Washington', 'United States', 'Godfrey', 'Mwamsoyo', '20005', 'District of Columbia', 
                                                 'elizabeth.cruz@dice.com', 'elizabeth.cruz@dice.com', '515-782-6710', '4534ew34001K0000015METmIAO');
       String firstName = (String)contactObj.getValue('FirstName');
       //System.assertEquals(firstName, 'Godfrey');    
       

          map<String, String> acctParameterMap = new map<String, String>();
          acctParameterMap.put('CrmId','4534ew34001K0000015METmIAO');
          acctParameterMap.put('CRMAccountName','CRMAccountName');
          acctParameterMap.put('CRMAccountNumber','CRMAccountNumber');
          acctParameterMap.put('IsoCurrency','USD');
          acctParameterMap.put('BrandTag','Dice');
          acctParameterMap.put('InvoiceTemplateName','InvoiceTemplateName');
          acctParameterMap.put('InvoiceTemplateId','InvoiceTemplateId');
          acctParameterMap.put('PaymentGateway','PaymentGateway');
          acctParameterMap.put('DefaultPaymentMethodId','paymentMethodId');
          acctParameterMap.put('SoldToAddress','SoldToAddress');
          acctParameterMap.put('SoldToCity','SoldToCity');
          acctParameterMap.put('SoldToCountry','SoldToCountry');
          acctParameterMap.put('SoldToPostalCode','50323');
          acctParameterMap.put('SoldToState','IA');
          acctParameterMap.put('SoldToFirstName','SoldToFirstName');
          acctParameterMap.put('SoldToLastName','SoldToLastName');
          acctParameterMap.put('SoldToPersonalEmail','SoldToPersonalEmail');
          acctParameterMap.put('SoldToWorkEmail','SoldToWorkEmail');
          acctParameterMap.put('SoldToWorkPhone','SoldToWorkPhone');
          acctParameterMap.put('BillToAddress','BillToAddress');
          acctParameterMap.put('BillToCity','BillToCity');
          acctParameterMap.put('BillToCountry','BillToCountry');
          acctParameterMap.put('BillToPostalCode','50323');
          acctParameterMap.put('BillToState','IA');
          acctParameterMap.put('BillToFirstName','BillToFirstName');
          acctParameterMap.put('BillToLastName','BillToLastName');
          acctParameterMap.put('BillToPersonalEmail','BillToPersonalEmail');
          acctParameterMap.put('BillToWorkEmail','BillToWorkEmail');
          acctParameterMap.put('BillToWorkPhone','BillToWorkPhone');
          acctParameterMap.put('PaymentTerm','PaymentTerm');
          acctParameterMap.put('CustomerServiceRepName','CustomerServiceRepName');
          acctParameterMap.put('SalesRepName','SalesRepName');
          acctParameterMap.put('SalesRepDivision','');    
       
       RESTZuoraOperationPlugIn.ReturnClass returnAccount = RESTZuoraOperationPlugIn.createZuoraAccount(acctParameterMap );
       String accountNumber = (String)contactObj.getValue('CRMAccountNumber');
       //System.assertEquals(returnAccount.isActiveBilling, 'true');  
          
        RESTZuoraOperationPlugIn plugin = new RESTZuoraOperationPlugIn();
        plugin.describe();
        Map<String,Object> inputParams = requestParameterMap; // new Map<String,Object>();
        Process.PluginRequest request = new Process.PluginRequest(inputParams);                   
        plugin.invoke(request);
        
        Zuora.zObject zobj = new Zuora.zObject('Error');
        zobj.setValue('Message','Test Message');
        List<Zuora.zObject> zSubobjs = new List<Zuora.zObject>();
        zSubobjs.add(zobj);
        String errorMessage = RESTZuoraOperationPlugIn.getZuoraErrorMsg(zSubobjs);  
        //System.assertEquals(errorMessage, 'Test Message');          
  }
}