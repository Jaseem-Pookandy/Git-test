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

public with sharing class QuotePreviewSample extends zqu.QuotePreviewController {

  /*CLASS VARIABLES*/
  public static final String BLANK_CONTACT_ERROR_MESSAGE = 'A quote must have a valid bill to contact and sold to contact to be sent to Zuora. Click Go Back to return to the quote\'s detail page';
  public static final String QUOTE_SUBMIT_SUCCESS = 'Quote was successfully submitted to Z-Billing!';
  /*INSTANCE VARIABLES*/

  // Configuration options for quote preview componenta
  public zqu.QuotePreviewOptions previewOptions {
    get;
    set;
  }

  // Configuration options for notification component within quote preview component
  public zqu.NotificationOptions notificationOptions {
    get;
    set;
  }

  // Handler to the quote object
  private zqu__Quote__c quote {
    get;
    set;
  }
  
  
  // Constructor
  public QuotePreviewSample(ApexPages.StandardController stdController) {
    
    // Ensure that the BillTo/SoldTo contacts are accessible
    if (!Test.isRunningTest()) stdController.addFields(new List < String > {
      'zqu__BillToContact__c', 'AR_Special_Handling__c', 'Deferred_Bill_Date__c', 'zqu__StartDate__c', 'zqu__ElectronicPaymentMethodId__c', 'zqu__Opportunity__r.AccountId', 'zqu__SoldToContact__c', 'zqu__ZuoraAccountID__c', 'zqu__SubscriptionType__c', 'zqu__PaymentMethod__c', 'zqu__SoldToContact__r.Language__c', 'InvoiceTemplateName__c', 'BrandTag__c', 'Payment_Gateway__c'
    });
    
    // Get quote object
    quote = (zqu__Quote__c) stdController.getRecord();
     
    System.Debug('quote: '+quote);
    //System.Debug('quoteId'+quoteId);
    
    // Initialize preview options
    previewOptions = new zqu.QuotePreviewOptions();

    // Pass quote id to the preview options
    previewOptions.quoteId = stdController.getId();

    // Set display options
    previewOptions.buttonBarLocation = 'top';
    previewOptions.quotePropertyTitle = 'Quote Details';
    previewOptions.selectedProductsTitle = 'Selected Products and Rate Plans';
    previewOptions.isSelectedProductsCollapsible = true;

    // Set preview controller and CreateOrderPlugin
    previewOptions.previewController = this;
    previewOptions.createOrderPlugin = 'QuotePreviewSample.CreateOrderPlugin';
        
    // Initialize the notification options
    notificationOptions = new zqu.NotificationOptions();
    
    List<zqu__Quote__c> quotes = [Select Id, InvoiceTemplateName__c, BrandTag__c from zqu__Quote__c where Id=: quote.Id];
    
    SET<String> validGateways = ZuoraGateways__c.getAll().keySet();
    
    //List<Invoice_Template__c> invTemp = [Select Id, Name from Invoice_Template__c where Name=: quotes[0].InvoiceTemplateName__c];
    
    // If the quote is missing a Bill To Contact or Sold To Contact, disable the create order button
    // and display a popup message for the error
    if (quote.zqu__BillToContact__c == null || quote.zqu__SoldToContact__c == null) {
      previewOptions.disableCreateButton = true;
      notificationOptions.failureBody = BLANK_CONTACT_ERROR_MESSAGE;
      notificationOptions.isPopup = true;
      notificationOptions.backAction = 'toQuoteDetail();';
    } else if (quote.zqu__PaymentMethod__c == 'Cash') { // CC-1040 Prevent quotes that are cash from being Sent to Z-Billing.
        previewOptions.disableCreateButton = true;
        notificationOptions.failureBody = 'Please update the payment method from cash.';
        notificationOptions.isPopup = true;
        notificationOptions.backAction = 'toQuoteDetail();';
    } else if (quote.zqu__SoldToContact__r.Language__c == null) { // CC-1634 Add Language Field validation, required for invoice template name.
        previewOptions.disableCreateButton = true;
        notificationOptions.failureBody = 'Please select a language for your SoldTo contact.';
        notificationOptions.isPopup = true;
        notificationOptions.backAction = 'toQuoteDetail();';
    } else if (quote.BrandTag__c == null) { // CC-2150 Check to prevent quotes from being submitted without a brand tag.
        previewOptions.disableCreateButton = true;
        notificationOptions.failureBody = 'Please select an brand tag on the quote.';
        notificationOptions.isPopup = true;
        notificationOptions.backAction = 'toQuoteDetail();';
    } else if (quote.InvoiceTemplateName__c == null) { // Check to prevent quotes from being submitted without an invoice template.
        previewOptions.disableCreateButton = true;
        notificationOptions.failureBody = 'Please select an invoice template on the quote.';
        notificationOptions.isPopup = true;
        notificationOptions.backAction = 'toQuoteDetail();';
    } else if (!validGateways.contains(quote.Payment_Gateway__c)) { // CC-1929 - Check to see if gateway selected is a valid gateway.
        previewOptions.disableCreateButton = true;
        notificationOptions.failureBody = 'Please contact your Zuora Administrator. The gateway selected is not a valid gateway.';
        notificationOptions.isPopup = true;
        notificationOptions.backAction = 'toQuoteDetail();';
    }
    
    // Set configuration options for notification component within quote preview component
    previewOptions.notificationOptions = notificationOptions;
  }

  // Method to return to quote's detail page from notification popup
  public PageReference toQuoteDetail() {
    return new PageReference('/' + quote.Id);    
  }
  
  // Plugin implementation of ICreateOrder interface
  public class CreateOrderPlugin implements ICreateOrderPlugin {
    public PageReference CreateOrder(zqu.QuotePreviewController qpc) {
      // Cast plugin instance
      QuotePreviewSample previewController = (QuotePreviewSample) qpc;
      //Retrieve quote object from outer controller
      zqu__Quote__c quote = previewController.quote;
      if (quote == null) return null;

      // Retrieve config information
      Map < String, Object > zqconfig = zqu.zQuoteUtil.getZuoraConfigInformation();
      List < zqu.zQuoteUtil.ZBillingQuoteCollection > quotes = new List < zqu.zQuoteUtil.ZBillingQuoteCollection > ();
      zqu.zQuoteUtil.ZBillingQuoteCollection quoteCol = new zqu.zQuoteUtil.ZBillingQuoteCollection();
          
      // Set Account ID on collection
      if (String.isNotEmpty(quote.zqu__Opportunity__r.AccountId)) quoteCol.sfdcAccountId = quote.zqu__Opportunity__r.AccountId;

      quoteCol.zAccountId = String.isEmpty(quote.zqu__ZuoraAccountId__c) ? 'new' : quote.zqu__ZuoraAccountId__c;

      quoteCol.quoteRequests = new List < zqu.zQuoteUtil.ZBillingQuoteRequest > ();
      zqu.zQuoteUtil.ZBillingQuoteRequest req = new zqu.zQuoteUtil.ZBillingQuoteRequest();
      req.sfdcQuoteId = quote.Id;
      
      //Set the payment method id on request from the quote if not null
      if (String.isNotBlank(quote.zqu__ElectronicPaymentMethodID__c)) req.paymentMethodId = quote.zqu__ElectronicPaymentMethodID__c;

      //Set generate invoice flag on request
      req.generateInvoice = (Boolean) zqconfig.get('Generate_Invoice__c');

      //Set process payments flag on the request
      Boolean processPayment = (Boolean) zqconfig.get('Process_Payments__c') == null ? false : (Boolean) zqconfig.get('Process_Payments__c');
      req.processPayment = processPayment && String.isNotBlank(quote.zqu__ZuoraAccountID__c);

      quoteCol.quoteRequests.add(req);
      quotes.add(quoteCol);

      //Begin byrnes edits, 2014.12.04
      //We now know if the account is actively billing or not.
      //If it IS actively billing OR AR Special Handling is checked, set to Batch2
      Map<String, String> requestParameterMap = new Map<String, String>();
      requestParameterMap.put('Operation', 'IsBillingAccountActive');
      requestParameterMap.put('BillingAccountId', quote.zqu__ZuoraAccountID__c);
      RESTZuoraOperationPlugIn.ReturnClass isAccountActiveResult = RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap);

      //CC-3401 Check Batch reassignment for the last time
      String batVal = '';
      //zqu__Quote__c updateBatchByAmount;
      //zqu__QuoteCharge__c quoteChargeBatch;
      Decimal QuoteTotal = 1.00;
      if(isAccountActiveResult.isActiveBilling == 'true' || quote.AR_Special_Handling__c) batVal = 'Batch2';
      else if(quote.zqu__StartDate__c != quote.Deferred_Bill_Date__c) batVal = 'Batch5';
      else
      {
        //updateBatchByAmount = [SELECT Quote_Total__c FROM zqu__Quote__c  WHERE Id =:quote.Id LIMIT 1];
        List<zqu__QuoteCharge__c> quoteChargeBatchLst = [select zqu__ProductRatePlanCharge__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SoldThrough__c, zqu__Quote__r.Quote_Total__c 
                                                         from zqu__QuoteCharge__c where zqu__Quote__c =:quote.Id];
        boolean isWebstore = false;
        for(zqu__QuoteCharge__c quoteChargeBatch : quoteChargeBatchLst)           
        {
          QuoteTotal =  quoteChargeBatch.zqu__Quote__r.Quote_Total__c;
          if (quoteChargeBatch.zqu__ProductRatePlanCharge__r != null && 
              quoteChargeBatch.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r != null && 
              quoteChargeBatch.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SoldThrough__c != null &&
              quoteChargeBatch.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SoldThrough__c.containsIgnoreCase('webstore')) {

              isWebstore = true;
              break;           
          }
        }                                         
        if(isAccountActiveResult.isActiveBilling == 'false')  batVal = RESTZuoraOperationPlugIn.getBillingAccountBatch(quote.zqu__ZuoraAccountID__c, isAccountActiveResult.Batch, (isWebstore ? 'Webstore' : 'CPQ'), quote.Payment_Gateway__c, quote.BrandTag__c, QuoteTotal); 
      } 
      
      //Send request
      List < zqu.zQuoteUtil.zBillingResult > results = Test.isRunningTest() ?
        new List < zqu.zQuoteUtil.zBillingResult > {
          QuotePreviewSample_Test.testZBillingResult
      } :
        zqu.zQuoteUtil.sendToZBilling(quotes);

      //Display results using popup notification component
      previewController.notificationOptions.isPopup = true;

      //If zBillingResult was successful, navigate to Subscription Confirmation page. If not, display error message on current page 
      for (zqu.zQuoteUtil.zBillingResult result: results) {
        if (result.success) {           
            
            // call the future methods when the subscription is new
            if(quote.zqu__SubscriptionType__c == 'New Subscription') {
                updateQuote((String)quote.Id);
                if(batVal != '') updateAccount((String)quote.Id, batVal);

                if (quote.zqu__ZuoraAccountID__c == null) { //Account level custom fields are set only on the initial account creation. - not anymore.  Byrnes, 2014.12.04.  Moved up, outside this if.
                    updateInvoiceTemplate((String)quote.Id); //CC-1930 Split validation of custom fields from invoice template.
                    updateGateway((String)quote.Id); //CC-1930 Split validation of custom fields from gateway.
                }   

                updateSubscription((String)quote.Id); //Needs to be executed after updateAccount due to CC-1597 and Batch 2 takes precedence over Batch 5
            }
            
            if (quote.zqu__SubscriptionType__c == 'Amend Subscription' ) updateSubscription((String)quote.Id);

            updateContact((String)quote.Id);  //CC-2312, 2014.05.30
          
          //Enable popup notification with OK button redirecting to quote detail page
          previewController.notificationOptions.continueAction = 'hidePopupNotification();displayStatusModal();toQuoteDetail();';
          previewController.notificationOptions.backAction = '';

          //Post confirmation message
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, QUOTE_SUBMIT_SUCCESS));
        }
        else {
          //Enable popup notification with cancel button only
          previewController.notificationOptions.continueAction = '';
          previewController.notificationOptions.backAction = 'hidePopupNotification();displayStatusModal();toQuoteDetail();';

          //Post error message
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, result.message));
          System.Debug('reached here with error');
        }
      }

      //Stay on current page
      return null;
    }
  }
  
  @future (callout=true)
    public static void updateQuote(String quoteId) {
        
        zqu__Quote__c updateQuote = [
            SELECT Id, zqu__ZuoraSubscriptionID__c, Zuora_Subscription_Name__c
            FROM zqu__Quote__c 
            WHERE Id =:quoteId LIMIT 1
        ];
        
        Zuora.zApi zApiInstance = new Zuora.zApi();
        
        try {
            if (!Test.isRunningTest())   zApiInstance.zlogin(); 
            
        } catch (Exception ex) { ex.getMessage(); }
        
        // zApiInstance should be instantiated and the login() method must
        // have been invoked prior to invoking any other method on the
        // object
        try {
            String zoql = 'SELECT Id, Name from Subscription Where ID =\'' + updateQuote.zqu__ZuoraSubscriptionID__c + '\'';
            
            if (!Test.isRunningTest()) {
                List<Zuora.zObject> zobjs = zApiInstance.zquery(zoql);
                String subName = (String)zobjs[0].getValue('Name');
                
                updateQuote.Zuora_Subscription_Name__c = subName;
                update updateQuote;
            }
            else {
                //When test is running
                updateQuote.Zuora_Subscription_Name__c = 'testSubName';
                update updateQuote;
            }
        } catch (Exception ex) { ex.getMessage(); }
    }
    
    @future (callout=true)
    public static void updateSubscription(String quoteId) {
        zqu__Quote__c updateQuote = [
            SELECT Id, zqu__ZuoraSubscriptionID__c, zqu__SubscriptionType__c, AR_Special_Notes__c, Owner.Name, Global_Deal__c, Billing_Frequency__c, zqu__ZuoraAccountID__c, Deferred_Bill_Date__c, zqu__StartDate__c, AR_Special_Handling__c, 
                   Payment_Gateway__c, BrandTag__c, Quote_Total__c, Service_End_Date__c
            FROM zqu__Quote__c 
            WHERE Id =:quoteId LIMIT 1
        ];
        Zuora.zApi zApiInstance = new Zuora.zApi();
        
        try {
            if (!Test.isRunningTest())   zApiInstance.zlogin(); 
        } 
        catch (Exception ex) { ex.getMessage(); }
        
        // Flag to indicate if we meet the condition to update the Account BCD
        boolean updateBCD = false;
        
        // Checks to see if this a new account or there is an existing account
        if (updateQuote.zqu__ZuoraAccountID__c != null) {
            // Query New Subscription
            List<Zuora.zObject> zobjs = new List<Zuora.zObject>();
            if (!Test.isRunningTest())   zobjs = zApiInstance.zquery('SELECT Id, Name, ContractEffectiveDate, SubscriptionEndDate, AccountId from Subscription Where Id =\'' + updateQuote.zqu__ZuoraSubscriptionID__c + '\'');
            else {
                // when test is running:                
                Zuora.zObject zo = new Zuora.zObject('Subscription');
                zo.setValue('Id', 'testId');
                zo.setValue('Name', 'testName');
                zo.setValue('ContractEffectiveDate', date.newinstance(2014, 1, 1));
                zo.setValue('SubscriptionEndDate', date.newinstance(2015, 1, 1));
                zo.setValue('AccountId', 'testAccntId');
                zobjs.add(zo);
            }
            DateTime contractEffDate = (DateTime)zobjs[0].getValue('ContractEffectiveDate');        
            String currSubId = (String)zobjs[0].getValue('Id');
            
            List<Zuora.zObject> zobjas = new List<Zuora.zObject>();
            if (!Test.isRunningTest())   zobjas = zApiInstance.zquery('SELECT Id, Name, SubscriptionEndDate, AccountId, OriginalId, Version from Subscription Where AccountId =\'' + updateQuote.zqu__ZuoraAccountID__c + '\' And Status = Active OR AccountId =\'' + updateQuote.zqu__ZuoraAccountID__c + '\' And Status = Cancelled OR AccountId =\'' + updateQuote.zqu__ZuoraAccountID__c + '\' And Status = Expired'); // Query for all subscriptions on the Zuora Account       
            else {
                // When test is running:
                Zuora.zObject zob = new Zuora.zObject('Subscription');
                zob.setValue('Id', 'newId');
                zob.setValue('Name', 'testSub');
                zob.setValue('SubscriptionEndDate', date.newinstance(2015, 1, 1));
                zob.setValue('AccountId', 'testAccnt');
                
                Zuora.zObject zob2 = new Zuora.zObject('Subscription');
                zob2.setValue('Id', 'newId2');
                zob2.setValue('Name', 'testSub2');
                zob2.setValue('SubscriptionEndDate', date.newinstance(2015, 1, 10));
                zob2.setValue('AccountId', 'testAccnt2');
                
                zobjas.add(zob);
                zobjas.add(zob2);          
            }
            
            // List to hold active subscriptions, minus the new subscription
            List<Zuora.zObject> zobjos = new List<Zuora.zObject>();
            
            //Create a subscriptions returned in zobjas
            Map<String, Zuora.zObject> mapSubscriptions = new Map<String, Zuora.zObject>();
            
            //If your contract is expired and is not the lastest version of the subscription ignore
            for(Zuora.zObject zobj : zobjas) {
                if (mapSubscriptions.get((String)zobj.getValue('OriginalId')) != null) {                 
                    if ((Decimal)mapSubscriptions.get((String)zobj.getValue('OriginalId')).getValue('Version') < (Decimal)zobj.getValue('Version')) {
                        mapSubscriptions.remove((String)zobj.getValue('OriginalId'));
                        mapSubscriptions.put((String)zobj.getValue('OriginalId'), zobj);
                    }
                }
                else   mapSubscriptions.put((String)zobj.getValue('OriginalId'), zobj);
            }
            
            //Remove the current subscription created from the list            
            for(Zuora.zObject zobj : mapSubscriptions.values()){
                if ((String)zobj.getValue('Id') != currSubId)    zobjos.add(zobj);
            }
            
            // If the subscription type on the quote is 'new subscription,' and active subscriptions are billed through, update the Account Bill Cycle Day 
            // to the new subscription's Contract Effective Day 
            if (updateQuote.zqu__SubscriptionType__c == 'New Subscription' && zobjos.size() > 0){
                
                // Query Rate Plans based on all existing, active subscriptions:
                String zoqlrp = 'SELECT Id, Name, SubscriptionId from RatePlan Where SubscriptionId =\'' + zobjos[0].getValue('Id') + '\'';
                
                // If there is more than one pre-existing, active subscription, add to the query string to get rate plans from all of these subscriptions
                if (zobjos.size() > 1) {
                    for (Integer i = 1; i < zobjos.size(); i++) zoqlrp = zoqlrp + ' Or SubscriptionId =\'' + zobjos[i].getValue('Id') +'\'';  
                }
                
                List<Zuora.zObject> zobjrps = new List<Zuora.zObject>();
                if (!Test.isRunningTest())   zobjrps = zApiInstance.zquery(zoqlrp); // Query for all rate plans and save in a list:
                else {
                    // When test is running:
                    Zuora.zObject rp = new Zuora.zObject('RatePlan');
                    rp.setValue('Id', 'testRatePlanId');
                    rp.setValue('Name', 'testName');
                    rp.setValue('SubscriptionId', zobjos[0].getValue('Id'));
                    
                    Zuora.zObject rp2 = new Zuora.zObject('RatePlan');
                    rp2.setValue('Id', 'testRatePlanId2');
                    rp2.setValue('Name', 'testName2');
                    rp2.setValue('SubscriptionId', zobjos[0].getValue('Id'));
                    
                    zobjrps.add(rp);
                    zobjrps.add(rp2);
                }
                
                // Used to determine if we need to iterate additional charges on the subscrtipion
                boolean breakOut = false;
            
                // Get rate plan charges from all of the above rate plans:
                String zoqlrpc = 'SELECT Id, Name, ChargedThroughDate, RatePlanId, ChargeType From RatePlanCharge Where RatePlanId =\'' + zobjrps[0].getValue('Id') + '\'';
                                
                // When there is more than one rate plan, add to the query string to get rate plan charges from all rate plans
                if (zobjrps.size() > 1){
                    for (Integer i = 1; i < zobjrps.size(); i++) {
                        zoqlrpc = zoqlrpc + ' Or RatePlanId =\'' + zobjrps[i].getValue('Id') +'\'';
                    }
                }
                
                List<Zuora.zObject> zobjrpcs = new List<Zuora.zObject>();
                if (!Test.isRunningTest())   zobjrpcs = zApiInstance.zquery(zoqlrpc); // Query for all rate plan charges and save in a list:                
                else {
                    // When test is running:
                    Zuora.zObject rpc = new Zuora.zObject('RatePlanCharge');
                    rpc.setValue('Id', 'rpcId');
                    rpc.setValue('Name', 'testName');
                    rpc.setValue('ChargedThroughDate', date.newinstance(2014, 1, 1));
                    rpc.setValue('RatePlanId', 'testRatePlanId');
                    zobjrpcs.add(rpc);
                }
                
                //Loop through all the rate plan charges to see if all charges have been charged through
                for (Zuora.zObject ratePlanCharge: zobjrpcs) { 
                    DateTime chrgdThruDate = (DateTime)ratePlanCharge.getValue('ChargedThroughDate');               

                    String currChrgRatePlanId = (String)ratePlanCharge.getValue('RatePlanId');
                    String currChrgSubscriptionId;
                    DateTime subEndDate;
                    
                    // Find the subscription end date for the current rate plan charge
                    for (Zuora.zObject ratePlan : zobjrps){
                        if ((String)ratePlan.getValue('Id') == currChrgRatePlanId){
                            currChrgSubscriptionId = (String)ratePlan.getValue('SubscriptionId');
                            for (Zuora.zObject sub : zobjos){
                                if ((String)sub.getValue('Id') == currChrgSubscriptionId){
                                    subEndDate = (DateTime)sub.getValue('SubscriptionEndDate');             
                                    break;
                                }
                            }
                            break;
                        }
                        break;
                    }                
                          
                    // Check if the charged through date is equal to the subscription end date, and set flag for bill cycle day
                    if (chrgdThruDate != null && subEndDate != null && zobjos.size() > 0){
                        if ((chrgdThruDate.year() != subEndDate.year() || chrgdThruDate.day() != subEndDate.day() || chrgdThruDate.month() != subEndDate.month()) && (String)ratePlanCharge.getValue('ChargeType') == 'Recurring'){                                    
                            updateBCD = false;      
                            breakOut = true;
                            break;
                        }
                        else    updateBCD = true; //Update BCD on Account to true
                    }
                    else if (chrgdThruDate == null && zobjos.size() > 0)    updateBCD = false;
                    
                    if (breakOut) break;
                }
        
                Zuora.zObject acc = new Zuora.zObject('Account');
                acc.setValue('Id', updateQuote.zqu__ZuoraAccountID__c);
                if (updateBCD)   acc.setValue('BillCycleDay', contractEffDate.day()); // Set bill cycle day on the account to be same as the contract effective day 
                
                if (!updateQuote.AR_Special_Handling__c) {
                    if (!updateBCD && zobjos.size() > 0)
                    {
                        //acc.setValue('Batch', 'Batch2'); // When there is actively billing subscription, set the Batch to Batch 2
                        
                        //CC-3401 Check Batch reassignment for the last time
                        List<zqu__QuoteCharge__c> quoteChargeBatchLst = [select zqu__ProductRatePlanCharge__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SoldThrough__c, zqu__Quote__r.Quote_Total__c 
                                                         from zqu__QuoteCharge__c where zqu__Quote__c =:updateQuote.Id];
                        boolean isWebstore = false;
                        for(zqu__QuoteCharge__c quoteChargeBatch : quoteChargeBatchLst)           
                        {
                            if((quoteChargeBatch.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SoldThrough__c).contains('Webstore'))
                            {
                                isWebstore = true;
                                break;
                            }
                        }                                 
                        String newBatch = RESTZuoraOperationPlugIn.getBillingAccountBatch(updateQuote.zqu__ZuoraAccountID__c, null, (isWebstore ? 'Webstore' : 'CPQ'), updateQuote.Payment_Gateway__c, updateQuote.BrandTag__c, updateQuote.Quote_Total__c);
                        acc.setValue('Batch', newBatch); // When there is actively billing subscription, set the Batch to Batch 2
                        
                    }
                    else if (updateQuote.zqu__StartDate__c != updateQuote.Deferred_Bill_Date__c) acc.setValue('Batch', 'Batch5'); //When the Deferred Bill Date is different then the service start date
                    
                } else  acc.setValue('Batch', 'Batch2'); // AR Special Handling is enable moved subscription to Batch 2
                
                // Update only after we have checked all subscriptions and charges
                try {
                    List<Zuora.zObject> objs = new List<Zuora.zObject> {acc};
                    List<Zuora.zApi.SaveResult> results;
    
                    if (!Test.isRunningTest())   results = zApiInstance.zupdate(objs);
                    else {
                        results = new List<Zuora.zApi.SaveResult>();
                        Zuora.zApi.SaveResult result = new Zuora.zApi.SaveResult();
                        result.Success = false;
                        results.add(result);
                    }
        
                    for (Zuora.zApi.SaveResult result : results) {
                        if (result.Success) String updatedId = result.Id; //get the updated id
                        else {
                          Zuora.zObject[] errors = result.errors;
                      
                          for (Zuora.zObject error : errors) { 
                              //String errorCode = (String)error.getValue('Code'); 
                              //String message = (String)error.getValue('Message');
                              //System.debug('SX: error Account Update ' + errorCode + ' ' + message);
                          }
                        }
                    }
                } catch (Exception ex) { ex.getMessage(); }
            }
        }
        
        // zApiInstance should be instantiated and the login() method must
        // have been invoked prior to invoking any other method on the object.
        try {
            // Assign Notes, ContracOwner, Global Deal and Invoice Sperate for all subscriptions       
            Zuora.zObject sub = new Zuora.zObject('Subscription');
            sub.setValue('Id', updateQuote.zqu__ZuoraSubscriptionID__c);
        
            if (updateQuote.AR_Special_Notes__c != null && updateBCD)    sub.setValue('Notes', updateQuote.AR_Special_Notes__c + ' Bill Cycle Day has been updated.');
            else if (updateQuote.AR_Special_Notes__c != null)    sub.setValue('Notes', updateQuote.AR_Special_Notes__c);
            else if (updateBCD)  sub.setValue('Notes', 'Bill Cycle Day has been updated.');
            
            sub.SetValue('IsInvoiceSeparate', true);    //CC-1647 Invoice All Subscriptions Separately      
        
            if (updateQuote.Owner.Name != null)  sub.setValue('ContractOwner__c', updateQuote.Owner.Name);
        
            if (updateQuote.Global_Deal__c != null)  sub.setValue('Global_Deal__c', updateQuote.Global_Deal__c);

            //MB - CC-3010 - Update Billing Frequency on Subscription     
            if (updateQuote.Billing_Frequency__c != null)  sub.setValue('Billing_Frequency__c', updateQuote.Billing_Frequency__c);    

            //CC-3413 Subscription Original SED Field Updated when Subscription Created  
            if (updateQuote.zqu__SubscriptionType__c == 'New Subscription') sub.setValue('OrginalSubscriptionEndDate__c', (''+updateQuote.Service_End_Date__c).substring(0,10)); 

            List<Zuora.zObject> objs = new List<Zuora.zObject> {sub};
            List<Zuora.zApi.SaveResult> results;
        
            if (!Test.isRunningTest())   results = zApiInstance.zupdate(objs);
            else {
                results = new List<Zuora.zApi.SaveResult>();
                Zuora.zApi.SaveResult result = new Zuora.zApi.SaveResult();
                result.Success = false;
                results.add(result);
            }
            
            
            for (Zuora.zApi.SaveResult result : results) {
                if (result.Success) String updatedId = result.Id; //get the updated id
                else  {
                    Zuora.zObject[] errors = result.errors;
                
                    for (Zuora.zObject error : errors) { 
                        String errorCode = (String)error.getValue('Code'); 
                        String message = (String)error.getValue('Message');
                        System.debug('### Error Subscription Update ' + errorCode + ' ' + message);
                    }
                }
            }
        } catch (Exception ex) { 
          system.debug('### - Error: ' + ex.getMessage());
          ex.getMessage(); 
        }
    }
    
    @future (callout=true)
    public static void updateInvoiceTemplate(String quoteId) {
        zqu__Quote__c updateQuote = [
            SELECT Id, zqu__ZuoraAccountID__c, InvoiceTemplateName__r.Name, InvoiceTemplateName__r.Invoice_Template_Id__c
            FROM zqu__Quote__c 
            WHERE Id =:quoteId LIMIT 1
        ];
        
        Zuora.zApi zApiInstance = new Zuora.zApi();
        
        try {
            if (!Test.isRunningTest())   zApiInstance.zlogin(); 
        } 
        catch (Exception ex) { ex.getMessage(); }

        // zApiInstance should be instantiated and the login() method must
        // have been invoked prior to invoking any other method on the
        // object       
        try {           
            Zuora.zObject acc = new Zuora.zObject('Account');
            acc.setValue('Id', updateQuote.zqu__ZuoraAccountID__c);
            
            if (updateQuote.InvoiceTemplateName__c != null) {
                acc.setValue('InvoiceTemplateName__c', updateQuote.InvoiceTemplateName__r.Name); //Sets the Account level custom field for the Invoice template name
                acc.setValue('InvoiceTemplateId', updateQuote.InvoiceTemplateName__r.Invoice_Template_Id__c); //Sets the Zuora template on the account
            }
                        
            List<Zuora.zObject> objs = new List<Zuora.zObject> {acc};
            List<Zuora.zApi.SaveResult> results;
            
            if (!Test.isRunningTest())   results = zApiInstance.zupdate(objs);
            else {
                results = new List<Zuora.zApi.SaveResult>();
                Zuora.zApi.SaveResult result = new Zuora.zApi.SaveResult();
                result.Success = false;
                results.add(result);
            }
            
            for (Zuora.zApi.SaveResult result : results) {
                if (result.Success) String updatedId = result.Id; //get the updated id
                else {
                    Zuora.zObject[] errors = result.errors;
                    
                    for (Zuora.zObject error : errors) { 
                        //String errorCode = (String)error.getValue('Code'); 
                        //String message = (String)error.getValue('Message');
                        //System.debug('SX: error Account Update ' + errorCode + ' ' + message);
                    }
                }
            }
        } catch (Exception ex) { ex.getMessage(); }
    }
    
    @future (callout=true)
    public static void updateGateway(String quoteId) {
        zqu__Quote__c updateQuote = [
            SELECT Id, zqu__ZuoraAccountID__c,  Payment_Gateway__c
            FROM zqu__Quote__c 
            WHERE Id =:quoteId LIMIT 1
        ];
        
        Zuora.zApi zApiInstance = new Zuora.zApi();
        
        try {
            if (!Test.isRunningTest())   zApiInstance.zlogin(); 
        } 
        catch (Exception ex) { ex.getMessage(); }

        // zApiInstance should be instantiated and the login() method must
        // have been invoked prior to invoking any other method on the
        // object       
        try {           
            Zuora.zObject acc = new Zuora.zObject('Account');
            acc.setValue('Id', updateQuote.zqu__ZuoraAccountID__c);
            
            if (updateQuote.Payment_Gateway__c != null)  acc.setValue('PaymentGateway', updateQuote.Payment_Gateway__c);
                        
            List<Zuora.zObject> objs = new List<Zuora.zObject> {acc};
            List<Zuora.zApi.SaveResult> results;
            
            if (!Test.isRunningTest())   results = zApiInstance.zupdate(objs);
            else {
                results = new List<Zuora.zApi.SaveResult>();
                Zuora.zApi.SaveResult result = new Zuora.zApi.SaveResult();
                result.Success = false;
                results.add(result);
            }
            
            for (Zuora.zApi.SaveResult result : results) {
                if (result.Success) String updatedId = result.Id; //get the updated id
                else {
                    Zuora.zObject[] errors = result.errors;
                    
                    for (Zuora.zObject error : errors) { 
                        //String errorCode = (String)error.getValue('Code'); 
                        //String message = (String)error.getValue('Message');
                        //System.debug('SX: error Account Update ' + errorCode + ' ' + message);
                    }
                }
            }
        } catch (Exception ex) { ex.getMessage(); }
    }
    

    @future (callout=true)
    public static void updateAccount(String quoteId, String batchValue) {

        system.debug('### 1 Batch: ' + batchValue);

        zqu__Quote__c updateQuote = [
            SELECT Id, zqu__ZuoraAccountID__c, zqu__ZuoraSubscriptionID__c, zqu__Opportunity__c, zqu__Opportunity__r.Account.Id, zqu__SubscriptionType__c, PO_Number__c, IO_Number__c, BrandTag__c, AR_Special_Handling__c, zqu__StartDate__c, Deferred_Bill_Date__c, zqu__BillToContact__r.Account.Id, zqu__Opportunity__r.Owner.Name
            FROM zqu__Quote__c 
            WHERE Id =:quoteId LIMIT 1
        ];
        
        Account salesforceAccount;
        if (updateQuote.zqu__Opportunity__r.Account.Id != null) {
            salesforceAccount = [
                SELECT Account_Number__c, Name, Tax_Number__c, isTax_Exempt__c, Tax_Exempt_Certificate_ID__c
                FROM Account 
                WHERE Id =:updateQuote.zqu__Opportunity__r.Account.Id
            ];
        }
        
        //Removed until further discussion with Karen
        /*Account agencyAccount; // CC-2025 Display Account Name of Bill To Contact on Account for Agency Contacts
        if(!Test.isRunningTest())
            if(updateQuote.zqu__Opportunity__r.Account.Id != null)
            {
                agencyAccount = [
                    SELECT Name 
                    FROM Account 
                    WHERE Id =:updateQuote.zqu__BillToContact__r.Account.Id
                ];
            }
        else 
        { 
            agencyAccount = new Account();  
        }*/
        
        
        Zuora.zApi zApiInstance = new Zuora.zApi();
        
        try {
            if(!Test.isRunningTest())   zApiInstance.zlogin(); 
        } 
        catch (Exception ex) { ex.getMessage(); }

        // zApiInstance should be instantiated and the login() method must
        // have been invoked prior to invoking any other method on the
        // object       
        try {      

            system.debug('### 2 Batch: ' + batchValue);

            Zuora.zObject acc = new Zuora.zObject('Account');
            acc.setValue('Id', updateQuote.zqu__ZuoraAccountID__c);
            
            if (updateQuote.BrandTag__c != null) acc.setValue('BrandTag__c', updateQuote.BrandTag__c);            
            if (updateQuote.zqu__Opportunity__r.Account.Id != null && salesforceAccount.Account_Number__c != null)   acc.setValue('CRMAccountNumber__c', salesforceAccount.Account_Number__c);           
            if (updateQuote.zqu__Opportunity__r.Account.Id != null && salesforceAccount.Name != null)    acc.setValue('CRMAccountName__c', salesforceAccount.Name);
            //CC-2749 - update sales rep on Zuora Account
            if (updateQuote.zqu__Opportunity__c != null) acc.setValue('SalesRepName', updateQuote.zqu__Opportunity__r.Owner.Name);    
            acc.setValue('Batch', batchValue);

 
            //if (updateQuote.zqu__Opportunity__r.Account.Id != null && salesforceAccount.isTax_Exempt__c != null && salesforceAccount.Tax_Number__c != null) {
            if (updateQuote.zqu__Opportunity__r.Account.Id != null) {    
                if (salesforceAccount.isTax_Exempt__c) acc.setValue('TaxExemptStatus', 'Yes'); // Flag on the Salesforce Account
                else acc.setValue('TaxExemptStatus', 'No'); // Flag on the Salesforce Account
            }
            //CC-3142 - send tax fields to Zuora even if null
            //if(updateQuote.zqu__Opportunity__r.Account.Id != null && salesforceAccount.Tax_Number__c != null) {
            if(updateQuote.zqu__Opportunity__r.Account.Id != null) {
                if (String.isNotBlank(salesforceAccount.Tax_Number__c)) acc.setValue('TaxNumber__c', salesforceAccount.Tax_Number__c); 
                else acc.setValue('TaxNumber__c', ''); 
                //acc.setValue('TaxNumber__c', salesforceAccount.Tax_Number__c); 
            }
            
            //CC-3142 - send tax fields to Zuora even if null
            //if(updateQuote.zqu__Opportunity__r.Account.Id != null && salesforceAccount.Tax_Exempt_Certificate_ID__c != null) {
            if(updateQuote.zqu__Opportunity__r.Account.Id != null) {
                if (String.isNotBlank(salesforceAccount.Tax_Exempt_Certificate_ID__c )) acc.setValue('TaxExemptCertificateID', salesforceAccount.Tax_Exempt_Certificate_ID__c); 
                else acc.setValue('TaxExemptCertificateID', '');                 
                //acc.setValue('TaxExemptCertificateID', salesforceAccount.Tax_Exempt_Certificate_ID__c); //TaxNumber is default Zuora TaxExemptCertificateID
            }
                                                
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
                
                for (Zuora.zObject error : errors) { 
                    String errorCode = (String)error.getValue('Code'); 
                    String message = (String)error.getValue('Message');

                    system.debug('### Error: ' + message);
                }
              }
            }          
        } 
        catch (Exception ex) { 
          ex.getMessage(); 
          system.debug('&&&&&&&&&&&&&&&& - Error! ' + ex.getMessage());
        }
    }

    @future (callout=true)
    public static void updateContact(String quoteId) {
        zqu__Quote__c updateQuote = [
            SELECT 
                Id, 
                zqu__ZuoraAccountID__c, 
                zqu__ZuoraSubscriptionID__c, 
                zqu__Opportunity__c, 
                zqu__Opportunity__r.Account.Id, 
                zqu__SubscriptionType__c, 
                PO_Number__c, 
                IO_Number__c, 
                BrandTag__c, 
                AR_Special_Handling__c, 
                zqu__StartDate__c, 
                Deferred_Bill_Date__c, 
                zqu__BillToContact__r.Account.Id
            FROM zqu__Quote__c 
            WHERE Id =:quoteId LIMIT 1
        ];        

        //get the list of approved brandtags that should actually be sent to zuora.
        Map<String, BrandTagsToZQUTaxRegion__c> approvedBrandTagMap = BrandTagsToZQUTaxRegion__c.getAll();
        
        //see if this quote's brandTag is in the map - if so, continue.  If not, end.
        if (!approvedBrandTagMap.containsKey(updateQuote.BrandTag__c)) return;

        Zuora.zApi zApiInstance = new Zuora.zApi();
        
        try {
            if(!Test.isRunningTest())   zApiInstance.zlogin(); 
        } 
        catch (Exception ex) { ex.getMessage(); }

        // zApiInstance should be instantiated and the login() method must
        // have been invoked prior to invoking any other method on the
        // object       
        try {                      
            List<Zuora.zApi.SaveResult> results;
            
            //Begin updating the Sold To contact with the Quote's BrandTag details now...
            if (updateQuote.BrandTag__c != null) {

              results = new List<Zuora.zApi.SaveResult>();

              List<Zuora.zObject> selectList = new List<Zuora.zObject>();
              List<Zuora.zObject> updateList = new List<Zuora.zObject>();
              String soldToContactID;                          

              String accountZoql = 'select Id, SoldToId from Account where Id = \'' + updateQuote.zqu__ZuoraAccountID__c + '\'';

              if (!Test.isRunningTest()) selectList = zApiInstance.zquery(accountZoql);      

              for (Zuora.zObject o : selectList) {

                //get the soldToContact's Id now...
                soldToContactID = (String)o.getValue('SoldToId');

                //create the update and push the update
                Zuora.zObject soldToContact = new Zuora.zObject('Contact');
                soldToContact.setValue('Id', soldToContactID);
                soldToContact.setValue('TaxRegion', updateQuote.BrandTag__c);

                updateList.add(soldToContact);                
              }

              if (!Test.isRunningTest()) results = zApiInstance.zupdate(updateList);
              else {
                    results = new List<Zuora.zApi.SaveResult>();
                    Zuora.zApi.SaveResult result = new Zuora.zApi.SaveResult();
                    result.Success = false;
                    results.add(result);
                }
              
              for (Zuora.zApi.SaveResult result : results) {
                if (result.Success) String updatedId = result.Id;                
                else {
                  Zuora.zObject[] errors = result.errors;
                  
                  for (Zuora.zObject error : errors) { 
                      //String errorCode = (String)error.getValue('Code'); 
                      //String message = (String)error.getValue('Message');
                      //System.debug('SX: error Account Update ' + errorCode + ' ' + message);
                  }
                }
              }
              //Done with contact stuff...
            }
        } catch (Exception ex) { ex.getMessage(); }
    }    
}