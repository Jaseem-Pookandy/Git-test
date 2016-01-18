/***
*Class          ---- zquQuoteTriggerHandler
*Author         ---- Naresh Ojha (Appirio Offshore)
*Story          ---- Initial implementation
*Created Date   ---- 2013.01.18
*Description    ---- Class that contains all of the functionality called by the zquQuoteTrigger. All contexts should be in this class.
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Tim Byrnes
*Story          ---- CCBOB-167
*Modified Date  ---- 2015.11.20
*Description    ---- Created (and called) SetQuoteValues to ensure 'InvoiceSeparately' is *always* true.
***/

public with sharing class zquQuoteTriggerHandler {
    private boolean m_isExecuting = false;  
    private integer BatchSize = 0;
  
    //Constructor
    public zquQuoteTriggerHandler(boolean isExecuting, integer size) {
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

    //On before insert trigger method
    public void OnBeforeInsert (List<zqu__Quote__c> newList) { 
        populateContractEndDate(newList);
        SetQuoteValues(newList);
        //populateServiceEndDate(newList);
        disableSyncForQuote(newList);
    }  

  // On before update trigger method
    public void OnBeforeUpdate (Map<Id, zqu__Quote__c> oldMap, List<zqu__Quote__c> newList) {
        populateContractEndDate(newList);
        SetQuoteValues(newList);
        RecalcInvoiceTemplate(oldMap, newList);             //byrnes, CC-2756.
        //RecalcServiceEndDateIfNecessary(oldMap, newList);   //byrnes, CC-2742.
        //HandlePaymentEmail(oldMap, newList);                //byrnes, CC-1636.
        FlagQuoteIfCurrencyChanged(oldMap, newList);        //byrnes, 2014.11.11 as part of CPQ2

        //Global deal logic.  This code used to exist in a stand-alone trigger named 'GlobalDealTriggerForQuote' but that has been moved here to eliminate the complication of debugging multiple triggers.
        ProcessGlobalDealLogic(oldMap, newList);
    }
  
    //On after insert trigger method
    public void OnAfterInsert (Map<Id, zqu__Quote__c> newMap) { 
        SynchQuoteWithOpportunity(newMap);
    }  

    // On after update trigger method
    public void OnAfterUpdate (Map<Id, zqu__Quote__c> oldMap, Map<Id, zqu__Quote__c> newMap) {
        SynchQuoteWithOpportunity(newMap);
        CommonUtil.OLIsOnOppty(newMap.values(), 'Quote', new Set<String>());
    
        //SendPaymentEmail(oldMap, newMap.values());
    }
  
  private void ProcessGlobalDealLogic(Map<Id, zqu__Quote__c> oldMap, List<zqu__Quote__c> newList) {

    if (System.isFuture()) return;
    
    Set<String> quoteIds = new Set<String>();
    
    for (zqu__Quote__c quote : newList) {      
      quoteIds.add(quote.Id);      
    }  
    
    Map<Id, List<zqu__QuoteCharge__c>> quoteChargeMap = new Map<Id, List<zqu__QuoteCharge__c>>();
    
    for (zqu__QuoteCharge__c qc : [ SELECT Id, Name, zqu__Quote__c, Sales_Representative__c, Country__c, zqu__Quote__r.Global_Deal__c, zqu__Quote__r.Discount__c, zqu__Quote__r.zqu__Previewed_Discount__c 
                                    FROM zqu__QuoteCharge__c WHERE zqu__Quote__c IN :quoteIds AND zqu__Quote__r.zqu__SubscriptionType__c = 'New Subscription']) {

      if (!quoteChargeMap.containsKey(qc.zqu__Quote__c)) quoteChargeMap.put(qc.zqu__Quote__c, new List<zqu__QuoteCharge__c>());
      quoteChargeMap.get(qc.zqu__Quote__c).add(qc);
    }

    Set<String> tagsToConsider = new Set<String>();
    for (GlobalDealBrandTags__c gdbt : [SELECT Name FROM GlobalDealBrandTags__c]) {
      tagsToConsider.add(gdbt.Name);
    }
              
    for (zqu__Quote__c myQuote : newList){  

      Set<String> uniqueReps = new Set<String>();
      Set<String> uniqueCountries = new Set<String>();
      
      // Update discount field on quote - just in case (Zuora had this code here, Byrnes can't take credit/blame)
      if (myQuote.zqu__Previewed_Discount__c != myQuote.Discount__c) myQuote.Discount__c = myQuote.zqu__Previewed_Discount__c;
      
      // Global Deal:
        //Rules are:  at least two charges  (covered in the next IF statement)  AND
        //BrandTag is either eFC-EMEA, eFC-Asia, eFC-Aus, eFC-Amer or Rigzone (covered in the next IF statement)   AND
        //quote charges have at least two unique Sales Reps                     AND
        //quote charges have at least two unique countries

      if ((tagsToConsider.contains(myQuote.BrandTag__c)) && (quoteChargeMap != null) && (quoteChargeMap.containsKey(myQuote.Id)) && (quoteChargeMap.get(myQuote.Id).size() > 1)) {
          
        for (zqu__QuoteCharge__c quoteChrg : quoteChargeMap.get(myQuote.Id)) {        

          if (quoteChrg.Sales_Representative__c != null) uniqueReps.add(quoteChrg.Sales_Representative__c);
          if (quoteChrg.Country__c != null) uniqueCountries.add(quoteChrg.Country__c);

          if ((uniqueReps.size() > 1) && (uniqueCountries.size() > 1)) {
            //Deal has been found - don't waste cycles iterating
            myQuote.Global_Deal__c = true;
            break;
          }
        }
      }
    }
  }

  //This is also called from the CreditCardPaymentController.
  //As the web service isn't bulkified (it's REST), neither is this.
  public static String GetEncryptedIDForEmail(String zuoraAccountID) {
    
    //https://payments.diceholdings.com/services.php?action=encrypt&id=STRING_TO_ENCRYPT
    
    String result;
    DateTime rightNow = DateTime.Now();
    String baseURL = [SELECT URL__c FROM CreditCardPaymentSettings__c WHERE Name = :Constants.ENCRYPTION_URL_NAME LIMIT 1].URL__c;
                        
    if (zuoraAccountID != null) {
                
        //loop through all quotes and build the web service call...
        String rawStringToEncrypt = zuoraAccountID;  // + '|' + rightNow;
        
        //call the rest service at baseURL now...   
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
 
        req.setEndpoint(baseURL + rawStringToEncrypt);
        req.setMethod('POST');
        try {
            if (test.isRunningTest()) return 'ERROR';
            res = http.send(req);
            result = res.getBody().trim();
            
            if (result.length() > 250) {
                //Then we got the HTML error...  append some stuff for debugging purposes...
                result += ' ::  RawStringToEncrypt: ' + rawStringToEncrypt;
                result += ' ::  Endpoint: ' + baseURL + rawStringToEncrypt;
            }
            return result;
            
        } catch (System.CalloutException e) {
            System.debug('&&&&&&&&&&&&&&&&&& - Callout error: ' + e);
            System.debug('&&&&&&&&&&&&&&&&&& - Response: ' + res.toString());
            result = 'ERROR: (Exception:)' + e + '  ::  (Response:)' + res.toString();
        }
    }   
    else result = 'ERROR';

    return result;
  }

  //CC-1636 - on update only as 'Sent to Z-Billing' is never a status upon insert...
  //this sub calls Dice's encrypt web service (that is bulkified) and updates
  //the opportunity.Payment_Address__c with the correct URL that will be sent out via the email template.
  // private void HandlePaymentEmail(Map<Id, zqu__Quote__c> oldMap, List<zqu__Quote__c> newList) {
    
  //   Boolean bProceed = false;

  //   for (zqu__Quote__c q : newList) {
  //     if ((q.zqu__Status__c == Constants.QUOTE_SENT) && (oldMap.containsKey(q.Id)) && (oldMap.get(q.Id).zqu__Status__c != Constants.QUOTE_SENT)) bProceed = true;
  //   }
    
  //   if (bProceed) {
  //     List<zqu__Quote__c> quotesToProcess = new List<zqu__Quote__c>();
  //     DateTime rightNow = DateTime.Now();
      
  //     String paymentURL;
  //     List<CreditCardPaymentSettings__c> ccpsList = [SELECT URL__c FROM CreditCardPaymentSettings__c WHERE Name = :Constants.BASE_PAYMENT_ADDRESS_URL LIMIT 1];
      
  //     if (ccpsList != null && ccpsList.size() > 0) paymentURL = ccpsList[0].URL__c;
  //     else return;
      
  //     //String paymentURL = [SELECT URL__c FROM CreditCardPaymentSettings__c WHERE Name = :Constants.BASE_PAYMENT_ADDRESS_URL LIMIT 1].URL__c;
      
  //     Set<Id> quoteSet = new Set<Id>();
  //     Map<Id, Boolean> quoteCCFlagMap = new Map<Id, Boolean>();
      
  //     for (zqu__Quote__c q : newList) {
  //         if (q.Do_Not_Send_Automated_Email__c != true) quoteSet.add(q.Id); 
  //     }
      
  //     for (Opportunity o : [SELECT Id, Credit_Card_Flag__c, SyncedQuote__c FROM Opportunity WHERE SyncedQuote__c IN :quoteSet]) {
  //         if (!quoteCCFlagMap.containsKey(o.SyncedQuote__c)) quoteCCFlagMap.put(o.SyncedQuote__c, o.Credit_Card_Flag__c);
  //     }
      
  //     //list of approved gateways.  The formula field, 'Payment_Gateway__c' on the Quote__c object will end with one here if it can be accepted in this manner.
  //     List<CreditCardPaymentGateways__c> listCCPG = [SELECT Gateway__c FROM CreditCardPaymentGateways__c WHERE Approved__c = true];
      
  //     for (zqu__Quote__c q : newList) {
          
  //         if ((q.Do_Not_Send_Automated_Email__c != true) && (quoteCCFlagMap.containsKey(q.Id)) && (quoteCCFlagMap.get(q.Id) == true)) {
  //             //If the updated quote is now equal to Sent to Z-Billing (where it wasn't before)...
  //             if ((q.zqu__Status__c == Constants.QUOTE_SENT) && (oldMap.containsKey(q.Id)) && (oldMap.get(q.Id).zqu__Status__c != Constants.QUOTE_SENT)) {
                  
  //                 if (q.zqu__ZuoraAccountID__c != null) {
                      
  //                     Boolean valid = false;
                      
  //                     for (CreditCardPaymentGateways__c ccpg : listCCPG) {
                          
  //                         if (q.Payment_Gateway__c.endsWith(ccpg.Gateway__c)) {
  //                             valid = true;
  //                             break;
  //                         }
  //                     }
                      
  //                     if (valid) CreditCardEncryption.EncryptAndSendNotificationEmail(q.Id);
      
  //                     //else it's not a valid gateway, null out the payment address...
  //                     else q.Payment_Address__c = null;
  //                 }
                  
  //                 else q.Payment_Address__c = null;
  //             }
  //         }
  //     }
  //   }
  // }

  //CC-1636 - on update only as 'Sent to Z-Billing' is never a status upon insert...
  //this is the automatic method....
  // private void SendPaymentEmail(Map<Id, zqu__Quote__c> oldMap, List<zqu__Quote__c> newList) {
  
  //   List<zqu__Quote__c> quotesToProcess = new List<zqu__Quote__c>();
    
  //   List<EmailTemplate> etList = new List<EmailTemplate>();
  //   EmailTemplate fakeET = new EmailTemplate(Id = '00XU0000000rRf6');   //Fake - for test class only.

  //   if (!Test.isRunningTest()) etList = [SELECT Id FROM EmailTemplate WHERE DeveloperName=:Constants.CREDITCARD_TEMPLATE_AUTOMATIC];
  //   else etList.add(fakeET);

  //   EmailTemplate et;
    
  //   if (etList != null && etList.size() > 0) et = etList[0];
  //   else return;
    
  //   //EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName=:Constants.CREDITCARD_TEMPLATE_AUTOMATIC];
       
  //   List<Messaging.SendEmailResult> listEmailResult = null;                                     //list of results 
  //   List<Messaging.Singleemailmessage> listEmails = new List<Messaging.Singleemailmessage>();   //list of emails that are going to be sent...
    
  //   for (zqu__Quote__c q : newList) {
  //       if (q.Do_Not_Send_Automated_Email__c != true) {
  //           //If the updated quote is now equal to Sent to Z-Billing (where it wasn't before)...
  //           if ((q.zqu__Status__c == Constants.QUOTE_SENT) && (oldMap.get(q.Id).Payment_Email_Automatically_Sent__c == false) && (q.Payment_Email_Automatically_Sent__c == true)) {
                
  //               if ((q.Payment_Address__c != null) || (Test.isRunningTest())) {
  //                   //send the email template out...
  //                   Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
  //                   mail.setWhatId(q.Id);
  //                   mail.setTargetObjectId(q.zqu__SoldToContact__c);
                            
  //                   if (et.Id != null) mail.setTemplateId(et.Id);
  //                   mail.setUseSignature(false);
  //                   mail.setBccSender(false);
  //                   mail.setSaveAsActivity(false);          
                    
  //                   listEmails.add(mail);
  //               }
  //           }
  //       }
  //   }
    
  //   if (listEmails.size() > 0)  listEmailResult = Messaging.sendEmail(listEmails);
  // }

  /*
  private void RecalcServiceEndDateIfNecessary(Map<Id, zqu__Quote__c> oldMap, List<zqu__Quote__c> newList) {
    List<zqu__Quote__c> listOfQuotes = new List<zqu__Quote__c>();

    for (zqu__Quote__c q : newList) {
      Boolean bAdd = false;
      if (oldMap.containsKey(q.Id) && (oldMap.get(q.Id).zqu__StartDate__c != q.zqu__StartDate__c || oldMap.get(q.Id).zqu__InitialTerm__c != q.zqu__InitialTerm__c)) bAdd = true;

      //if (oldMap.containsKey(q.Id) && oldMap.get(q.Id).Service_End_Date__c != q.Service_End_Date__c) { // if the service end date was manually changed, don't add.  Let it save.it}

      if (bAdd) listofQuotes.add(q);
    }

    if (listOfQuotes.size() > 0) populateServiceEndDate(listOfQuotes);
  }
  */

    //CC-526 - on insert only do we default service end date.
            //CC-2977 - Dice Holdings business wants to recognize the contract end date as one day less than 
            //the method used by Zuora. 
            //For example: Contract Start Date of Feb 22, 2014 for a 12 month contract. 
            //Zuora's calculated contract end date = Feb 22, 2015. 
            //DHI would like that contract end date to be = Feb 21, 2015
            //So, we are subtracting 1 day from the Contract End Date here
/*
  private void populateServiceEndDate (List<zqu__Quote__c> newList) {
    for (zqu__Quote__c quote : newList) {
        //if (quote.zqu__StartDate__c <> null && quote.zqu__InitialTerm__c <> null && quote.zqu__Subscription_Term_Type__c == 'Termed' && quote.DoNotCalculateServiceEndDate__c == false) quote.Service_End_Date__c = Date.valueOf(quote.zqu__StartDate__c).addMonths((Integer)quote.zqu__InitialTerm__c).addDays(-1);
        if (quote.zqu__StartDate__c <> null && quote.zqu__InitialTerm__c <> null && quote.zqu__Subscription_Term_Type__c == 'Termed') quote.Service_End_Date__c = Date.valueOf(quote.zqu__StartDate__c).addMonths((Integer)quote.zqu__InitialTerm__c).addDays(-1);
        else if (quote.zqu__Subscription_Term_Type__c == 'Evergreen') quote.Service_End_Date__c = null;
    }
  } 
  */

    //T-121728: Populate Contract_End_Date_Apex__c on zqu__Quote__c
    private void populateContractEndDate (List<zqu__Quote__c> newList) {
        for (zqu__Quote__c quote : newList) {
            if (quote.zqu__StartDate__c <> null && quote.zqu__InitialTerm__c <> null && quote.zqu__Subscription_Term_Type__c == 'Termed') quote.Contract_End_Date_Apex__c = Date.valueOf(quote.zqu__StartDate__c).addMonths((Integer)quote.zqu__InitialTerm__c);        
            else if (quote.zqu__Subscription_Term_Type__c == 'Evergreen') quote.Contract_End_Date_Apex__c = null;
        }
    }

    private void SetQuoteValues(List<zqu__Quote__c> newList) {

        //CCBOB-167
        for (zqu__Quote__c q : newList) {
            q.zqu__InvoiceSeparately__c = true;
        }

    }
  
    //I-53683: ENTITY_IS_LOCKED ERROR WHEN CREATING QUOTE ON OPPORTUNITY IN AN ACTIVE APPROVAL PROCESS /JH
    private void disableSyncForQuote (List<zqu__Quote__c> newList) {
        if (newList.size() == 1 ) {
            for (zqu__Quote__c quote : newList) {
                ProcessInstance[] PIs =  [select Id, TargetObjectId, Status from ProcessInstance where TargetObjectId = :quote.zqu__Opportunity__c and Status = 'Pending'];
                if (PIs.size() > 0) quote.IsSyncing__c = false;
            }    
        }
    }
 
    //To synch quote with opportunity
    //Also implements CC-904 regarding currency sync.  (Currency on the quote to consider is zqu__Currency__c - NOT CurrencyIsoCode)
    private void SynchQuoteWithOpportunity (Map<Id, zqu__Quote__c> newMap) { 

        if (PreventRecursiveExecution.isFirstRun == false) return;

        PreventRecursiveExecution.isFirstRun = false;

    Set<String> OpptyIDset = new Set<String>();
    Map<String, String> OptyID_QuoteIdMap = new Map<String, String>();
    List<Opportunity> optyListToUpdate = new List<Opportunity>();
    List<zqu__Quote__c> quoteListToUpdate = new List<zqu__Quote__c>(); 
    
    //904 setup
    List<OpportunityLineItem> oppLinesToDelete = new List<OpportunityLineItem>();
    Map<Id, String> oppCurrencyMap = new Map<Id, String>();
    List<OpportunityLineItem> oppLinesToInsert = new List<OpportunityLineItem>();
    Set<String> newCurrencies = new Set<String>();
    List<zqu__ProductRatePlanCharge__c> prpcToDelete = new List<zqu__ProductRatePlanCharge__c>();
    List<zqu__QuoteCharge__c> qcToDelete = new List<zqu__QuoteCharge__c>();
    Set<Id> quotesThatNeedLinesPurged = new Set<Id>();
    //end 904 setup
    
    for (zqu__Quote__c quote : newMap.values()) {
        if (quote.IsSyncing__c == true) {
            if (!OptyID_QuoteIdMap.containsKey(quote.zqu__Opportunity__c)) OptyID_QuoteIdMap.put(quote.zqu__Opportunity__c, quote.ID);
            OpptyIDset.add(quote.zqu__Opportunity__c);
        }
    }

    //Setting Synched Quote on Opportunity
    for (Opportunity opty : [SELECT ID, Validation_Rule_Override__c, CurrencyIsoCode,
                               SyncedQuote__c, (Select Id,  Name, IsSyncing__c, zqu__Currency__c
                                                 From zqu__Quotes__r 
                                                 WHERE ID NOT IN : (newMap.keySet())) 
                               FROM Opportunity WHERE ID IN : OpptyIDset]) {
      if (OptyID_QuoteIdMap.containsKey(opty.ID)) {
        opty.SyncedQuote__c = OptyID_QuoteIdMap.get(opty.ID);
        opty.Validation_Rule_Override__c = DateTime.now();

        //Set the Credit Card Flag on the Opportunity when the synced quote Payment
        if (newMap.get(OptyID_QuoteIdMap.get(opty.ID)).zqu__PaymentMethod__c == 'Credit Card') opty.Credit_Card_Flag__c = true;
        else opty.Credit_Card_Flag__c = false;        

        //if the currency on the quote does NOT match the currency on the Opportunity, make some adjustments to the opp.
        if (opty.CurrencyIsoCode != newMap.get(OptyID_QuoteIdMap.get(opty.ID)).zqu__Currency__c) {

          if (!oppCurrencyMap.containsKey(opty.Id)) oppCurrencyMap.put(opty.Id, newMap.get(OptyID_QuoteIdMap.get(opty.ID)).zqu__Currency__c); //map of opportunities and the NEW currency.
          
          opty.CurrencyIsoCode = newMap.get(OptyID_QuoteIdMap.get(opty.ID)).zqu__Currency__c;
          newCurrencies.add(opty.CurrencyIsoCode);
        }

        optyListToUpdate.add(opty);
      }
      
      for (zqu__Quote__c zQuote : opty.zqu__Quotes__r) {

        //updated prior existing Quotes
        zQuote.IsSyncing__c = false;
        zQuote.Validation_Rule_Override__c = DateTime.now();

        //correct the currency on any other quotes for this same opp...
        if (zQuote.zqu__Currency__c != opty.CurrencyIsoCode) {

          zQuote.zqu__Currency__c = opty.CurrencyIsoCode;
          quotesThatNeedLinesPurged.add(zQuote.Id);
        }

        quoteListToUpdate.add(zQuote);
      }
    }

    //To eliminate duplicate ID problem on deletion...
    Set<Id> prpcToDeleteSet = new Set<Id>();

    //Get the records that need purging from the other quote line items...
    for (zqu__QuoteCharge__c qc : [SELECT Id, zqu__ProductRatePlanCharge__c FROM zqu__QuoteCharge__c WHERE zqu__Quote__c IN :quotesThatNeedLinesPurged]) {
      if ((qc.zqu__ProductRatePlanCharge__c != null) && (!prpcToDeleteSet.contains(qc.zqu__ProductRatePlanCharge__c))) {
        prpcToDeleteSet.add(qc.zqu__ProductRatePlanCharge__c);
        prpcToDelete.add(new zqu__ProductRatePlanCharge__c(Id = qc.zqu__ProductRatePlanCharge__c));
      }

      qcToDelete.add(qc);
    }


    if (!prpcToDelete.isEmpty()) delete prpcToDelete;
    if (!qcToDelete.isEmpty()) delete qcToDelete;

    for (OpportunityLineItem oli : [SELECT Id, OpportunityId, Country__c, Quantity, UnitPrice, ServiceDate, CurrencyIsoCode, Description, PricebookEntryId, Product_Group__c, Sub_Category__c, Sale_Type__c, BrandTag__c, Brand__c, Brand__r.Name FROM OpportunityLineItem WHERE OpportunityId IN :oppCurrencyMap.keySet()]) {
      oppLinesToDelete.add(oli);
    }

    if (!oppLinesToDelete.isEmpty()) delete oppLinesToDelete;

    Map<String, Id> productBrandMap = new Map<String, Id>();
    if (!oppLinesToDelete.isEmpty()) {    //if we had to delete some records then we have to re-insert some as well...

      for (PricebookEntry pbe : [SELECT Id, Name, CurrencyIsoCode FROM PricebookEntry WHERE CurrencyIsoCode IN :newCurrencies ORDER BY Name ASC]) {
        if (!productBrandMap.containsKey(pbe.Name + '_' + pbe.CurrencyIsoCode)) productBrandMap.put(pbe.Name + '_' + pbe.CurrencyIsoCode, pbe.Id);                  
      }

      for (OpportunityLineItem oli : oppLinesToDelete) {

        OpportunityLineItem o = new OpportunityLineItem();
        o.Brand__c = oli.Brand__c;
        o.BrandTag__c = oli.BrandTag__c;
        o.Country__c = oli.Country__c;
        o.Description = oli.Description;
        o.OpportunityId = oli.OpportunityId;
        o.Product_Group__c = oli.Product_Group__c;
        o.Sub_Category__c = oli.Sub_Category__c;
        o.Quantity = oli.Quantity;
        o.UnitPrice = oli.UnitPrice;
        o.ServiceDate = oli.ServiceDate;
        o.Sale_Type__c = oli.Sale_Type__c;
        o.PricebookEntryId = productBrandMap.get(oli.Brand__r.Name + '_' + newMap.get(OptyID_QuoteIdMap.get(oli.OpportunityId)).zqu__Currency__c);

        oppLinesToInsert.add(o);
      }
    }

    if (!optyListToUpdate.isEmpty()) update optyListToUpdate;

    if (!oppLinesToInsert.isEmpty()) insert oppLinesToInsert;

    if (!quoteListToUpdate.isEmpty()) update quoteListToUpdate;
  }


  //CC-2756, part 1.  Part 2 is on the ContactTriggerHandler
  private void RecalcInvoiceTemplate(Map<Id, zqu__Quote__c> oldMap, List<zqu__Quote__c> newList) {

    //first check and see if either the country or the currency has changed.  If not, do nothing.
    //if one or both has changed, then recalculate so long as the invoicetemplate didn't also change.

    if (!PreventRecursiveExecution.invoiceTemplateRecalculated) {

      PreventRecursiveExecution.invoiceTemplateRecalculated = true;

      Map<Id, zqu__Quote__c> affectedQuotes = new Map<Id, zqu__Quote__c>();
      Set<Id> soldToContactIds = new Set<Id>();
      Set<Id> quoteIds = new Set<Id>();

      for (zqu__Quote__c zq : newList) {

        if ((oldMap.containsKey(zq.Id)) && ((zq.InvoiceTemplateName__c == null) || (zq.zqu__Currency__c != oldMap.get(zq.Id).zqu__Currency__c) || (zq.BrandTag__c != oldMap.get(zq.Id).BrandTag__c) || (zq.zqu__SoldToContact__c != oldMap.get(zq.Id).zqu__SoldToContact__c)) && (zq.InvoiceTemplateName__c == oldMap.get(zq.Id).InvoiceTemplateName__c)) {
          affectedQuotes.put(zq.Id, zq);
          quoteIds.add(zq.Id);
          soldToContactIds.add(zq.zqu__SoldToContact__c);
        }
      }

      if (!affectedQuotes.values().isEmpty()) {
        //recalc the invoice template then...

        List<Invoice_Template__c> invoiceTemplates = [SELECT Id, Name, Invoice_Template_Id__c FROM Invoice_Template__c];
          
        //Map of Invoice Templates
        Map<String, String> mapInvoiceTemplates = new Map<String, String>();
          
        for(Invoice_Template__c invoiceTemplate : invoiceTemplates) {
          mapInvoiceTemplates.put(invoiceTemplate.Name.toUpperCase(), invoiceTemplate.Id);
        }
          
        List<pw_ccpro__CountryObject__c> countries = [SELECT Id, Name, Sub_Region1__c, Region_Energy__c FROM pw_ccpro__CountryObject__c ];      
          
        Map<Id, Contact> mapContacts = new Map<Id, Contact>([
              SELECT Id, pw_ccpro__MailingCountryLookup__r.Sub_Region1__c, pw_ccpro__MailingCountryLookup__r.Region_Energy__c, Language__c
              FROM Contact
              Where Id IN: soldToContactIDs
          ]);

        for(zqu__Quote__c quote : newList) {
          if ((affectedQuotes.containsKey(quote.Id)) && (mapContacts.containsKey(quote.zqu__SoldToContact__c)) && (quote.BrandTag__c != null)) {
            if (((quote.zqu__SoldToContact__c != null) && (quote.BrandTag__c.startsWithIgnoreCase('efc')) && (mapContacts.get(quote.zqu__SoldToContact__c).pw_ccpro__MailingCountryLookup__c != null) && (mapContacts.get(quote.zqu__SoldToContact__c).pw_ccpro__MailingCountryLookup__r.Sub_Region1__c == 'Middle East')))     quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(('eFC-MiddleEast_'               + (String)mapContacts.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());
            else if ((quote.BrandTag__c.equalsIgnoreCase('rigzone')) && (mapContacts.get(quote.zqu__SoldToContact__c).pw_ccpro__MailingCountryLookup__r.Region_Energy__c != 'AMERICAS'))                                                                                                                                        quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(('Rigzone-ROW_'                  + (String)mapContacts.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());
            else if (mapInvoiceTemplates.get(((String)quote.BrandTag__c + '_' + (String)mapContacts.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase()) != null)                                                                                                                quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(((String)quote.BrandTag__c + '_' + (String)mapContacts.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());

            //Else set it to nothing if it's not found so it must be manually set before going to zBilling.
            else quote.InvoiceTemplateName__c = null;
          }
          else quote.InvoiceTemplateName__c = null;
        }
      }
    }
  }

  private void FlagQuoteIfCurrencyChanged(Map<Id, zqu__Quote__c> oldMap, List<zqu__Quote__c> newList) {
  
    for (zqu__Quote__c zq : newList) {

      if ((oldMap.containsKey(zq.Id)) && (zq.zqu__Currency__c != oldMap.get(zq.Id).zqu__Currency__c)) zq.Billing_Account_Selection_Response__c = Constants.QUOTE_CURRENCY_CHANGED;

    }
  }
  
}