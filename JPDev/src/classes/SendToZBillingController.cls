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

public with sharing class SendToZBillingController {
   
    public final List<zqu.ZChargeGroup> chargeGroupList {get; set;}
    private final ApexPages.StandardController controller;
    public zqu__Quote__c quote {get;set;} 
    public String quoteId {get;set;}
    
    //Shawn Xuereb: Removed in Release 2 Will be handled in QuotePreviewSample   
    /*public boolean buttonCheck {
            get
            {
                if(buttonCheck == null) buttonCheck = false;
                return ButtonCheck;
            }
        
            set;
        }
    */   
        
    public SendToZBillingController(ApexPages.StandardController controller) {
        this.controller = controller;
        quoteId = this.controller.getRecord().Id;
        
        this.quote = [SELECT Id, zqu__ZuoraAccountID__c, zqu__ZuoraSubscriptionID__c, zqu__Opportunity__c, zqu__Opportunity__r.Account.Id, zqu__SubscriptionType__c, zqu__Status__c, zqu__Currency__c, zqu__Customer_Acceptance_Date__c, zqu__StartDate__c FROM zqu__Quote__c WHERE id = :quoteId LIMIT 1];
         
        if (this.validate()) 
        {
            try
            {
                zqu.GlobalCustomFieldDefinition.QUOTE_FIELDS = new Set<String> { 'PO_Number__c', 'IO_Number__c', 'Service_End_Date__c', 'ContractChannel__c', 'Global_Deal__c'};
                zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Country__c', 'Notes__c', 'Event__c', 'ServiceStart__c', 'ServiceEnd__c', 'ItalianChargeName__c', 'GermanChargeName__c', 'EnglishChargeName__c', 'FrenchChargeName__c', 'SpanishChargeName__c', 'SimplifiedChineseChargeName__c', 'RussianChargeName__c', 'DutchChargeName__c', 'Sales_Representative__c', 'Region__c', 'EnergyRegion__c', 'SubRegion1__c', 'SubRegion2__c'};
                chargeGroupList = zqu.zQuoteUtil.getChargeGroups(quoteId);    
            } 
            catch(Exception e) 
            {
                appendMessage(ApexPages.Severity.ERROR, e.getMessage());
            }
        }
    }

//Shawn Xuereb: Removed in Release 2 Will be handled in QuotePreviewSample   
 /*   public void onload()
    {
        if(this.quote.zqu__Status__c == 'Sent To Z-Billing')
        {
            buttonCheck = false;
        }
        else
        {
            buttonCheck = true;
        }
    }
   
   public PageReference send() {
    
        zqu.GlobalCustomFieldDefinition.QUOTE_FIELDS = new Set<String> { 'PO_Number__c', 'IO_Number__c', 'Service_End_Date__c', 'ContractChannel__c', 'Global_Deal__c'};
        zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Country__c', 'Notes__c', 'Event__c', 'EventID__c', 'ServiceStart__c', 'ServiceEnd__c', 'ItalianChargeName__c', 'GermanChargeName__c', 'EnglishChargeName__c', 'FrenchChargeName__c', 'SpanishChargeName__c', 'SimplifiedChineseChargeName__c', 'RussianChargeName__c', 'DutchChargeName__c', 'Sales_Representative__c', 'Region__c', 'EnergyRegion__c', 'SubRegion1__c', 'SubRegion2__c'};
        
        List<zqu.zQuoteUtil.ZBillingQuoteCollection> quotes = new List<zqu.zQuoteUtil.ZBillingQuoteCollection>();
        zqu.zQuoteUtil.ZBillingQuoteCollection quoteCol = new zqu.zQuoteUtil.ZBillingQuoteCollection();
            
        if(quote.zqu__Opportunity__r.Account.Id != null)
        {
            // SFDC CRM Account ID
            quoteCol.sfdcAccountId = quote.zqu__Opportunity__r.Account.Id;
        }   
        
        if(quote.zqu__ZuoraAccountID__c != null)            
        {
            // Zuora Billing Account ID
            quoteCol.zAccountId = quote.zqu__ZuoraAccountID__c;
            
            Zuora.zApi zApiInstance = new Zuora.zApi();
        
            try {
                if(!Test.isRunningTest())
                { 
                    zApiInstance.zlogin(); 
                }
            }
            catch (Exception ex) { ex.getMessage(); }
            
            // zApiInstance should be instantiated and the login() method must
            // have been invoked prior to invoking any other method on the
            // object
            try {
                String zoql = 'SELECT Id, Currency from Account Where ID =\'' + quote.zqu__ZuoraAccountID__c + '\'';
                
                if(!Test.isRunningTest())
                {
                    List<Zuora.zObject> zobjs = zApiInstance.zquery(zoql);
                    String accCurrency = (String)zobjs[0].getValue('Currency');
                    if(accCurrency != quote.zqu__Currency__c)
                    {
                        appendMessage(ApexPages.Severity.ERROR, 'The Currency of the Billing Account doesn\'t match the Quote Currency. Please create a new Billing Account.');
                        return null;
                    }
                }
            } 
            catch (Exception ex) { ex.getMessage(); }
        }
        //new account z acc is null on quote its new
        else
        {
            quoteCol.zAccountId = 'new';
        }   

        quoteCol.quoteRequests = new List<zqu.zQuoteUtil.ZBillingQuoteRequest>();
        zqu.zQuoteUtil.ZBillingQuoteRequest req = new zqu.zQuoteUtil.ZBillingQuoteRequest();
        
        req.sfdcQuoteId = quote.Id; // SFDC Quote ID
        quoteCol.quoteRequests.add(req);
        quotes.add(quoteCol);
        
        List<zqu.zQuoteUtil.zBillingResult> results;
        
        if(!Test.isRunningTest())
        {
            results = zqu.zQuoteUtil.sendToZBilling(quotes);
        }
        else
        {
            results = new List<zqu.zQuoteUtil.zBillingResult>();
            zqu.zQuoteUtil.zBillingResult result = new zqu.zQuoteUtil.zBillingResult();
            result.sfdcQuoteId = this.quoteId;
            result.success = true;
            
            results.add(result);
        }
        
        for(zqu.zQuoteUtil.zBillingResult result : results ) 
        {
            if(result.success)
            {
                System.debug('SX: Result ' + result);
                buttonCheck = false;
                if(quote.zqu__SubscriptionType__c == 'New Subscription')
                {
                    updateQuote(this.quoteId);
                    if(quote.zqu__ZuoraAccountID__c == null)
                    	updateAccount(this.quoteId);
                    updateSubscription(this.quoteId);
                    
                    zqu__Quote__c tempQuote = [
                        Select  Id, zqu__ZuoraSubscriptionID__c, zqu__Subscription_Name__c
                        From zqu__Quote__c
                        WHERE Id =: this.quoteId
                    ];
                    appendMessage(ApexPages.Severity.CONFIRM, 'Subscription ' + tempQuote.zqu__ZuoraSubscriptionID__c + ' created successfully in Zuora.');
                }
                else if(quote.zqu__SubscriptionType__c == 'Amend Subscription')
                {
                    zqu__Quote__c tempQuote = [
                        Select Id, zqu__Subscription_Name__c
                        From zqu__Quote__c
                        WHERE Id =: this.quoteId
                    ];
                    appendMessage(ApexPages.Severity.CONFIRM, 'Successfully Amended Subscription ' + tempQuote.zqu__Subscription_Name__c + '.');                    
                }
            }
            else
            {
                 appendMessage(ApexPages.Severity.INFO, 'Result: QuoteId = ' + result.sfdcQuoteId + ', Success = ' + result.success + ', message = ' + result.message);
            }
        }
        
        return null;    
    }
    
    @future (callout=true)
    public static void updateQuote(String quoteId)
    {
        
        zqu__Quote__c updateQuote = [
            SELECT Id, zqu__ZuoraSubscriptionID__c
            FROM zqu__Quote__c 
            WHERE Id =:quoteId LIMIT 1
        ];
        
        Zuora.zApi zApiInstance = new Zuora.zApi();
        
        try {
            if(!Test.isRunningTest())
            { 
                zApiInstance.zlogin(); 
            }
        } catch (Exception ex) { ex.getMessage(); }
        
        // zApiInstance should be instantiated and the login() method must
        // have been invoked prior to invoking any other method on the
        // object
        try {
            String zoql = 'SELECT Id, Name from Subscription Where ID =\'' + updateQuote.zqu__ZuoraSubscriptionID__c + '\'';
            
            if(!Test.isRunningTest())
            {
                List<Zuora.zObject> zobjs = zApiInstance.zquery(zoql);
                String subName = (String)zobjs[0].getValue('Name');
                
                updateQuote.Zuora_Subscription_Name__c = subName;
                update updateQuote;
            }
        } catch (Exception ex) { ex.getMessage(); }
    }
    
    @future (callout=true)
    public static void updateSubscription(String quoteId)
    {
        zqu__Quote__c updateQuote = [
            SELECT Id, zqu__ZuoraSubscriptionID__c, AR_Special_Notes__c, Owner.Name
            FROM zqu__Quote__c 
            WHERE Id =:quoteId LIMIT 1
        ];
        Zuora.zApi zApiInstance = new Zuora.zApi();
        
        try {
            if(!Test.isRunningTest())
            { 
                zApiInstance.zlogin(); 
            }
        } 
        catch (Exception ex) { ex.getMessage(); }

        // zApiInstance should be instantiated and the login() method must
        // have been invoked prior to invoking any other method on the
        // object       
        try {           
            Zuora.zObject sub = new Zuora.zObject('Subscription');
            sub.setValue('Id', updateQuote.zqu__ZuoraSubscriptionID__c);
            
            if(updateQuote.AR_Special_Notes__c != null)
            {
                sub.setValue('Notes', updateQuote.AR_Special_Notes__c);
            }
            
            if(updateQuote.Owner.Name != null)
            {
                sub.setValue('ContractOwner__c', updateQuote.Owner.Name);
            }
            
            List<Zuora.zObject> objs = new List<Zuora.zObject> {sub};
            List<Zuora.zApi.SaveResult> results;
            
            if(!Test.isRunningTest())
            {
                results = zApiInstance.zupdate(objs);
            }
            else
            {
                results = new List<Zuora.zApi.SaveResult>();
                Zuora.zApi.SaveResult result = new Zuora.zApi.SaveResult();
                result.Success = false;
                results.add(result);
            }
            
            for (Zuora.zApi.SaveResult result : results) {
                if (result.Success){
                    //get the updated id
                    String updatedId = result.Id;
                } 
                else 
                {
                    Zuora.zObject[] errors = result.errors;
                    
                    for (Zuora.zObject error : errors) 
                    { 
                        String errorCode = (String)error.getValue('Code'); 
                        String message = (String)error.getValue('Message');
                        System.debug('SX: error Subscription Update ' + errorCode + ' ' + message);
                    }
                }
            }
        } catch (Exception ex) { ex.getMessage(); }
    }
    
    //SalesTax was default Zuora Tax Id TaxExemptCertificateId__c
    //isTax_Exempt__c to Account in Zuora (SF Account)
    //InvoiceTemplateId = template Id quey Zuora?
    @future (callout=true)
    public static void updateAccount(String quoteId)
    {
        zqu__Quote__c updateQuote = [
            SELECT Id, zqu__ZuoraAccountID__c, zqu__ZuoraSubscriptionID__c, zqu__Opportunity__c, zqu__Opportunity__r.Account.Id, zqu__SubscriptionType__c, PO_Number__c, IO_Number__c, InvoiceTemplateName__c, BrandTag__c, Payment_Gateway__c, AR_Special_Handling__c, zqu__StartDate__c, Deferred_Bill_Date__c
            FROM zqu__Quote__c 
            WHERE Id =:quoteId LIMIT 1
        ];
        
        Account salesforceAccount;
        if(updateQuote.zqu__Opportunity__r.Account.Id != null)
        {
            salesforceAccount = [SELECT Account_Number__c, Name, Tax_Number__c, isTax_Exempt__c FROM Account WHERE Id =:updateQuote.zqu__Opportunity__r.Account.Id];
        }
        
        Zuora.zApi zApiInstance = new Zuora.zApi();
        
        try {
            if(!Test.isRunningTest())
            { 
                zApiInstance.zlogin(); 
            }
        } 
        catch (Exception ex) { ex.getMessage(); }

        // zApiInstance should be instantiated and the login() method must
        // have been invoked prior to invoking any other method on the
        // object       
        try {           
            Zuora.zObject acc = new Zuora.zObject('Account');
            acc.setValue('Id', updateQuote.zqu__ZuoraAccountID__c);
            
            if(updateQuote.InvoiceTemplateName__c != null)
            {
                acc.setValue('InvoiceTemplateName__c', updateQuote.InvoiceTemplateName__c);
            }
            
            if(updateQuote.BrandTag__c != null)
            {
                acc.setValue('BrandTag__c', updateQuote.BrandTag__c);
            }
            
            if(updateQuote.Payment_Gateway__c != null)
            {
                acc.setValue('PaymentGateway', updateQuote.Payment_Gateway__c);
            }
            
            if(updateQuote.zqu__Opportunity__r.Account.Id != null && salesforceAccount.Account_Number__c != null)
            {
                acc.setValue('CRMAccountNumber__c', salesforceAccount.Account_Number__c);
            }
            
            if(updateQuote.zqu__Opportunity__r.Account.Id != null && salesforceAccount.Name != null)
            {
                acc.setValue('CRMAccountName__c', salesforceAccount.Name);
            }
            
            if(updateQuote.zqu__Opportunity__r.Account.Id != null && salesforceAccount.Tax_Number__c != null)
            {
                acc.setValue('TaxNumber__c', salesforceAccount.Tax_Number__c);
            }
            
            if(updateQuote.AR_Special_Handling__c)
            {
                acc.setValue('Batch', 'Batch2');
            }
            
            if(updateQuote.zqu__StartDate__c != updateQuote.Deferred_Bill_Date__c) 
            {
                acc.setValue('Batch', 'Batch5');
            }
            
            //if(updateQuote.zqu__Opportunity__r.Account.Id != null && salesforceAccount.isTax_Exempt__c != null)
            //{
            //    if(salesforceAccount.isTax_Exempt__c)
            //    {
            //        acc.setValue('TaxExemptStatus', 'Yes');
            //    }
            //    else
            //    {
            //        acc.setValue('TaxExemptStatus', 'No');
            //    }
            //}
            
           List<Zuora.zObject> objs = new List<Zuora.zObject> {acc};
            List<Zuora.zApi.SaveResult> results;
            
            if(!Test.isRunningTest())
            {
                results = zApiInstance.zupdate(objs);
            }
            else
            {
                results = new List<Zuora.zApi.SaveResult>();
                Zuora.zApi.SaveResult result = new Zuora.zApi.SaveResult();
                result.Success = false;
                results.add(result);
            }
            
            for (Zuora.zApi.SaveResult result : results) {
                if (result.Success){
                    //get the updated id
                    String updatedId = result.Id;
                } 
                else 
                {
                    Zuora.zObject[] errors = result.errors;
                    
                    for (Zuora.zObject error : errors) 
                    { 
                        String errorCode = (String)error.getValue('Code'); 
                        String message = (String)error.getValue('Message');
                        System.debug('SX: error Account Update ' + errorCode + ' ' + message);
                    }
                }
            }
        } catch (Exception ex) { ex.getMessage(); }
    }
    
    public PageReference cancel()
    {
        return new PageReference('/'+this.quoteId);
    }
*/
    private Boolean validate() {
        if (null == this.controller.getRecord() || null == this.controller.getRecord().Id) {
            appendMessage(ApexPages.Severity.ERROR, 'Need to specify the id of quote for creating subscription.');
            return false;
        }
        return true;
    }
       
    private static void appendMessage(ApexPages.Severity messageType, String message) 
    {   
        ApexPages.addMessage(new ApexPages.Message(messageType, message));
    }  
}