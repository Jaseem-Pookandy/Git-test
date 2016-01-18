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

public with sharing class NewQuoteController {
 
    public final zqu__Quote__c quote          {get;set;}
    public final Opportunity   opp            {get;set;}
    public final List<Contact> contacts       {get;set;}  //contacts for selection
    public final  String  billingAccountID    {get; set;}
    public final  String  existSubscriptionID {get; set;}
    public final  String  quoteType           {get; set;}
    public Boolean initFailed                 {get; private set;}
   
    private final ApexPages.StandardController controller;
    private final Zuora.zApi api = new Zuora.zApi();
    
    private final Map<String,Object> zQuoteConfig = zqu.zQuoteUtil.getZuoraConfigInformation();
   
   	public Boolean renderCustomerAcceptance {get;set;}
	public Boolean renderServiceActivation {get;set;}
   
    public NewQuoteController(ApexPages.StandardController stdcontroller) {
        this.initFailed = true;
        this.controller = stdcontroller;
        //get values parsed in zuora billingaccountId, subscriptionid, quotetype  
        //initialize and initial some value for your new quote page here
        this.quote = (zqu__Quote__c)stdcontroller.getRecord();
        
        if(!Test.isRunningTest())
        {
	        if (null != quote.id) {
	            throw new zqu.ZQException('Should Not specify id in the url.');
	        }
        }
        
        this.quoteType = this.getParameter('quotetype');
        if ('' == this.quoteType) {
            throw new zqu.ZQException('Need to specify the quotetype in the url.');
        }
               
        String testOppId = [select Id from Opportunity limit 1][0].Id;   
        final String oppId = Test.isRunningTest() ? testOppId : this.getParameter('oppid');
        if ('' == oppId) {
            throw new zqu.ZQException('Need to specify the oppid in the url.');
        }
        final List<Opportunity> oppIdList = [select Id, Name, Account.Id, Account.Name from Opportunity where Id =:oppId limit 1];
        if (oppIdList.size() != 1) {
            throw new zqu.ZQException('Invalid oppid.');
        }
        this.opp = oppIdList[0];
       
        this.quote.zqu__Opportunity__r = this.opp;
        this.quote.zqu__Opportunity__c = this.opp.Id;
        if ('Amend' == this.quoteType || 'Renew' == this.quoteType) {
            String testBillingAccountID = [select Id from Account limit 1][0].Id;
            this.billingAccountID = Test.isRunningTest() ? testBillingAccountID : this.getParameter('billingaccountid');
            if ('' != billingAccountId) {
                this.quote.zqu__ZuoraAccountId__c = this.billingAccountId;
            } else {
                throw new zqu.ZQException('Need to specify the billingaccountid for ' + this.quoteType + ' in the url.');
            }
           
            String testExistSubscriptionID = '2c92c0f939795d75013993a6b5885aa2';
            this.existSubscriptionID = Test.isRunningTest() ? testExistSubscriptionID : this.getParameter('existsubscriptionid');
            if ('' != existSubscriptionId) {
                this.quote.zqu__existSubscriptionID__c = existSubscriptionId;
            } else {
                throw new zqu.ZQException('Need to specify the existsubscriptionid for ' + this.quoteType + ' in the url.');
            }
                 
                try {
                    if(!Test.isRunningTest()){api.zlogin();}
                    Zuora.zObject acczobj = this.getBillingAccount(billingAccountID);
                if (acczobj != null) {
                        this.quote.zqu__Currency__c = (String)acczobj.getValue('Currency');
                    }
                    final Zuora.zObject subzobj = this.getSubscription(existSubscriptionId);
                    if (null != subzobj) {
                        if ('Amend' == this.quoteType) {
                           this.quote.zqu__StartDate__c = ((Datetime)subzobj.getValue('TermStartDate')).date();
                        } else {
                           this.quote.zqu__StartDate__c = ((Datetime)subzobj.getValue('TermEndDate')).date();
                        }
                        this.quote.zqu__Hidden_Subscription_Name__c = (String)subzobj.getValue('Name');
                        this.quote.zqu__SubscriptionVersion__c = (Integer)subzobj.getValue('Version');
                        this.quote.zqu__SubscriptionTermStartDate__c = ((Datetime)subzobj.getValue('TermStartDate')).date();
                        this.quote.zqu__SubscriptionTermEndDate__c = ((Datetime)subzobj.getValue('TermEndDate')).date();
                    }
            } catch(Exception e) {
                throw new zqu.ZQException(e.getMessage());
            }
        }
        else if(this.quoteType == 'New')
        {
        	this.billingAccountID = this.getParameter('billingaccountid');
        	if ('' != billingAccountId) {
                this.quote.zqu__ZuoraAccountId__c = this.billingAccountId;
            }
        	
        	this.quote.zqu__Subscription_Term_Type__c = (String) zQuoteConfig.get('default_subscription_term_type__c');
			this.quote.zqu__PaymentTerm__c = (String) zQuoteConfig.get('payment_term__c');
			this.quote.zqu__Currency__c = (String) zQuoteConfig.get('currency__c');
			this.quote.zqu__AutoRenew__c = (Boolean) zQuoteConfig.get('subscriptionautorenewdefault__c');
			this.quote.zqu__BillingMethod__c = (String) zQuoteConfig.get('invoice_delivery_preferences__c');
			this.quote.zqu__RenewalTerm__c = 0;
        }
        

        //must assign correct subscription type and record type base on quote type here           
        Schema.DescribeSObjectResult dsr = Schema.SObjectType.zqu__Quote__c;
        if('New' == this.quoteType){
        	this.quote.zqu__SubscriptionType__c = 'New Subscription';
            Schema.RecordTypeInfo defaultrtinfo = dsr.getRecordTypeInfosByName().get('Default');
            this.quote.RecordtypeId = defaultrtinfo.getRecordTypeId();
        }else if('Amend' == this.quoteType){
        	this.quote.zqu__SubscriptionType__c = 'Amend Subscription';
            Schema.RecordTypeInfo amdrtinfo = dsr.getRecordTypeInfosByName().get('Amendment');
            this.quote.RecordtypeId = amdrtinfo.getRecordTypeId();
            this.quote.zqu__Amendment_Name__c =  this.opp.Name;
        }else if('Renew' == this.quoteType){
            this.quote.zqu__SubscriptionType__c = 'Renew Subscription';
            Schema.RecordTypeInfo renewrtinfo = dsr.getRecordTypeInfosByName().get('Renewal');
            this.quote.RecordtypeId = renewrtinfo.getRecordTypeId();
            this.quote.zqu__Amendment_Name__c =  this.opp.Name;
        }
        
         renderServiceActivation = String.valueOf(zQuoteConfig.get('use_service_activation_date__c')) == 'true';
		 renderCustomerAcceptance = String.valueOf(zQuoteConfig.get('use_customer_acceptance_date__c')) == 'true';
        
        //get the list of contact that under the opportunity account for selection              
        this.contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE AccountId = :opp.Account.Id];        
        this.initFailed = false;
    }
   
    public PageReference save(){
        if('Renew' == this.quoteType){
                try{          
                    zqu.zQuoteUtil.renewQuote(this.quote);
                } catch(zqu.ZQException e){
                    appendErrorMessage(e.getMessage());
                    return null;
                }
        }

        final System.Savepoint quoteSavePoint = Database.setSavepoint();
        try {
                Database.upsert(this.quote);
            final PageReference quoteDetailPage = new ApexPages.Standardcontroller(this.quote).view();
            quoteDetailPage.setRedirect(true);
            return quoteDetailPage;
        } catch (DMLException e) {
            Database.rollback(quoteSavePoint);
            appendErrorMessage(e.getMessage());
            return null;
        }
    }
   
    private String getParameter(String paraname){
        if(ApexPages.currentPage().getParameters().get(paraname) != null){
                return String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(paraname));
        }else{
                return '';
        }
    }
   
    private Zuora.zObject getSubscription(String subscriptionId){
        final Zuora.zObject subzobj;
        final String zoqlsubscription = 'Select Id, Name, Version, AccountId, OriginalId,ContractEffectiveDate,TermStartDate,TermEndDate,RenewalTerm from Subscription where Id = \'' + subscriptionId + '\'';
        final List <Zuora.zObject> subzobjs;
        if(!Test.isRunningTest()) {subzobjs = api.zquery(zoqlsubscription);}
        else
        {
        	subzobjs = new List<Zuora.zObject>();
            Zuora.zObject testSub = new Zuora.zObject('Subscription');
            testSub.setValue('Id', '123');
            testSub.setValue('TermStartDate', datetime.newInstance(2020, 1, 1));
            testSub.setValue('TermEndDate', datetime.newInstance(2021, 1, 1));
            subzobjs.add(testSub);
        }
        if(subzobjs.size() == 1)
            subzobj = subzobjs[0];
        return subzobj;
    }
   
    private Zuora.zObject getBillingAccount(String billingaccountId){
        final Zuora.zObject acczobj;
        final String zoqlacc = 'SELECT BillToId,SoldToId,Currency from Account where Id=\'' + billingaccountId  + '\'';
      	final List <Zuora.zObject> acczobjs;
        if(!Test.isRunningTest()){acczobjs = api.zquery(zoqlacc);}
        else{
        	acczobjs = new List<Zuora.zObject>();
            Zuora.zObject acc = new Zuora.zObject('Account');
            acc.setValue('Id','123');
            acczobjs.add(acc);
        }
        if(acczobjs.size() == 1)
            acczobj = acczobjs[0];
        return acczobj;
    }
   
    private static void appendErrorMessage(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }
}