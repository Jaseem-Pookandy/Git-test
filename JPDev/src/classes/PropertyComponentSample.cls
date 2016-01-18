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


public with sharing class PropertyComponentSample extends zqu.PropertyComponentController.ParentController {

    ApexPages.StandardController controller;
    public zqu__Quote__c quote {
        get;
        set;
    }
    public zqu.PropertyComponentOptions theOptions {
        get;
        set;
    }
    public Opportunity opp {
        get;
        set;
    }
  
    public String billingAccountId {get; set;}
  
    public String existSubscriptionId {get; set;}
  
    private final Zuora.zApi api = new Zuora.zApi();
  
    public PropertyComponentSample(ApexPages.StandardController stdController) {

        this.controller = stdController;

        this.quote = (zqu__Quote__c) this.controller.getRecord();

        // Get current opportunity
        String oppId = ApexPages.currentPage().getParameters().get('oppId');
        List < Opportunity > opportunitys = [Select Id, Name From Opportunity Where Id=: oppId limit 1];
    
        if (opportunitys == null || opportunitys.size() == 0) {
            // Insert Opportunity record
            Opportunity opp = new Opportunity();
            opp.Name = 'test opportunity';
            opp.StageName = 'Prospecting';
            opp.CloseDate = Date.today();
            insert opp;
            opportunitys = new List < Opportunity > ();
            opportunitys.add(opp);
        }

        setOpportunity(opportunitys.get(0).Id);
    
        // Initialize property component options
        theOptions = new zqu.PropertyComponentOptions();
        theOptions.objectName = 'zqu__Quote__c';
        theOptions.objectId = this.quote.Id != null ? this.quote.Id : null;
        theOptions.viewType = zqu.ViewConfigurationManager.VIEW_CONFIGURATION_VIEW_TYPE_CREATE;
        theOptions.isEditMode = true;

        // Set to detail mode
        String mode = ApexPages.currentPage().getParameters().get('mode');
        if (this.quote.Id != null && mode == 'detail')	theOptions.isEditMode = false;

        theOptions.renderButtonBar = theOptions.isEditMode;
        theOptions.parentController = this;
        theOptions.instanceName = 'sampleProperty';
        Schema.SObjectType objectType = zqu__Quote__c.sObjectType;
        Map < String, Schema.RecordTypeInfo > recordTypeInfoMap = objectType.getDescribe().getRecordTypeInfosByName();
        theOptions.recordTypeId = recordTypeInfoMap.get('Default').getRecordTypeId();
    
        theOptions.customRenderingFields.add('zqu__RenewalTerm__c');
        theOptions.customRenderingFields.add('zqu__AutoRenew__c');
    
        theOptions.readonlyFields.add('zqu__Opportunity__c');
        
        theOptions.renderBackButton = true;
        
        theOptions.hiddenFields.add('zqu__RenewalTerm__c');
        theOptions.hiddenFields.add('zqu__AutoRenew__c');
    
        theOptions.populateValuePlugin = 'PropertyComponentSample.PopulateDefaultFieldValuePlugin';
        theOptions.relatedObjectPlugin = 'PropertyComponentSample.PopulateRelatedObjectFieldPlugin';
        
        theOptions.updatePlugin = 'PropertyComponentSample.PopulateUpdatePlugin';
        theOptions.goBackPlugin = 'PropertyComponentSample.PopulateGoBackPlugin';
        theOptions.cancelPlugin = 'PropertyComponentSample.PopulateCancelPlugin'; 
    }
  
    // Set field default value
    public class PopulateDefaultFieldValuePlugin implements IPopulateValuePlugin {
        public void populateDefaultFieldValue(SObject record, zqu.PropertyComponentController.ParentController pcc) {
    
            // Get PropertyComponentSample instance
            PropertyComponentSample parentController = (PropertyComponentSample) pcc;
            Opportunity opportunity = parentController.opp;
    
            // Set default field values when creating new quote
            if (parentController.quote.Id == null && opportunity != null) {
    
	            // Set default opportunity
	            record.put('zqu__Opportunity__c', opportunity.Id);
	                    
	            // Set default renewal term as 0
	            parentController.quote = (zqu__Quote__c) record;        
	            record.put('zqu__RenewalTerm__c', 0);
	            
	            // Set default Invoice Delivery Method, Payment Term & Currency based on Zuora Config settings
	            Map<String,Object> zuoraConfigInfo = zqu.zQuoteUtil.getZuoraConfigInformation();
	            String invDelivPref = (String)zuoraConfigInfo.get('invoice_delivery_preferences__c');
	            String paymentTerm = (String)zuoraConfigInfo.get('payment_term__c');
	            String currncy = (String)zuoraConfigInfo.get('currency__c');
	            record.put('zqu__BillingMethod__c', invDelivPref);
	            record.put('zqu__PaymentTerm__c', paymentTerm);
	            record.put('zqu__Currency__c', currncy);
	            
	            parentController.quote.zqu__Opportunity__r = opportunity;
	            parentController.quote.zqu__Opportunity__c = opportunity.Id;
	        
	            Schema.DescribeSObjectResult dsr = Schema.SObjectType.zqu__Quote__c;
	            
	            // For Testing:
	            if(Test.isRunningTest()){
	                if(parentController.quote.zqu__SubscriptionType__c == 'New Subscription'){
	                    record.put('zqu__SubscriptionType__c', 'New Subscription');                 
	                    parentController.billingAccountID = 'testBillingAccId';
	                    if ('' != parentController.billingAccountId) {
	                        parentController.quote.zqu__ZuoraAccountId__c = parentController.billingAccountId;
	                        record.put('zqu__ZuoraAccountId__c', parentController.billingAccountId);
	                    }
	                }
	                else if (parentController.quote.zqu__SubscriptionType__c == 'Amend Subscription') {
	                    parentController.billingAccountID = 'testBillAccntId';
	                
	                    if ('' != parentController.billingAccountId) {
	                        parentController.quote.zqu__ZuoraAccountId__c = parentController.billingAccountId;
	                        record.put('zqu__ZuoraAccountId__c', parentController.billingAccountId);
	                    } else	System.Debug('Need to specify the billingaccountid.');
	                
	                    parentController.existSubscriptionID = 'testExistingSubId';
	                    if ('' != parentController.existSubscriptionId) {
	                        parentController.quote.zqu__existSubscriptionID__c = parentController.existSubscriptionId;
	                        record.put('zqu__existSubscriptionID__c', parentController.existSubscriptionId);
	                        
	                    } else	System.Debug('Need to specify the existsubscriptionid.');
	                                    
                        Zuora.zObject acczobj = parentController.getBillingAccount(parentController.billingAccountID);
                        
                        if (acczobj != null) {
                            parentController.quote.zqu__Currency__c = 'USD';
                            record.put('zqu__Currency__c', parentController.quote.zqu__Currency__c);
                        }
                        final Zuora.zObject subzobj = parentController.getSubscription(parentController.existSubscriptionId);
                        
                        if (null != subzobj) {
                            parentController.quote.BrandTag__c = 'ClearanceJobs';
                            record.put('BrandTag__c', parentController.quote.BrandTag__c);                        
                            parentController.quote.zqu__StartDate__c = date.newinstance(2014, 1, 1);
                            record.put('zqu__StartDate__c', parentController.quote.zqu__StartDate__c);                        
                            parentController.quote.zqu__Hidden_Subscription_Name__c = 'test sub name';
                            record.put('zqu__Hidden_Subscription_Name__c', parentController.quote.zqu__Hidden_Subscription_Name__c);
                            parentController.quote.zqu__SubscriptionVersion__c = 1;
                            record.put('zqu__SubscriptionVersion__c', parentController.quote.zqu__SubscriptionVersion__c);
                            parentController.quote.zqu__SubscriptionTermStartDate__c = date.newinstance(2014, 1, 1);
                            record.put('zqu__SubscriptionTermStartDate__c', parentController.quote.zqu__SubscriptionTermStartDate__c);
                            parentController.quote.zqu__SubscriptionTermEndDate__c = date.newinstance(2015, 1, 1);
                            record.put('zqu__SubscriptionTermEndDate__c', parentController.quote.zqu__SubscriptionTermEndDate__c);                                                  
                        }
	                
	                    parentController.quote.zqu__SubscriptionType__c = 'Amend Subscription';
	                    record.put('zqu__SubscriptionType__c', parentController.quote.zqu__SubscriptionType__c);
	                    parentController.quote.zqu__Amendment_Name__c =  opportunity.Name;
	                    record.put('zqu__Amendment_Name__c', parentController.quote.zqu__Amendment_Name__c);                    
	                }         
	            }// End of Test
	            else if (!Test.isRunningTest()){
	                if(ApexPages.currentPage().getParameters().get('quoteType') == 'Subscription'){
	                    record.put('zqu__SubscriptionType__c', 'New Subscription');
	                    
	                    parentController.billingAccountID = ApexPages.currentPage().getParameters().get('billingAccountId');
	                    if ('' != parentController.billingAccountId) {
	                        parentController.quote.zqu__ZuoraAccountId__c = parentController.billingAccountId;
	                        record.put('zqu__ZuoraAccountId__c', parentController.billingAccountId);
	                    }
	                }
	                else if (ApexPages.currentPage().getParameters().get('quoteType') == 'Amendment') {
	                    parentController.billingAccountID = ApexPages.currentPage().getParameters().get('billingAccountId');
	                    
	                    if ('' != parentController.billingAccountId) {
	                        parentController.quote.zqu__ZuoraAccountId__c = parentController.billingAccountId;
	                        record.put('zqu__ZuoraAccountId__c', parentController.billingAccountId);
	                    } else	throw new zqu.ZQException('Need to specify the billingaccountid in the url.');
	                    
	                    parentController.existSubscriptionID = ApexPages.currentPage().getParameters().get('subscriptionId');
	                    if ('' != parentController.existSubscriptionId) {
	                        parentController.quote.zqu__existSubscriptionID__c = parentController.existSubscriptionId;
	                        record.put('zqu__existSubscriptionID__c', parentController.existSubscriptionId);
	                        
	                    } else	throw new zqu.ZQException('Need to specify the existsubscriptionid in the url.');
	                          
	                    try {
	                        parentController.api.zlogin();
	                        Zuora.zObject acczobj = parentController.getBillingAccount(parentController.billingAccountID);
	                        if (acczobj != null) {
	                            parentController.quote.zqu__Currency__c = (String)acczobj.getValue('Currency');
	                            record.put('zqu__Currency__c', parentController.quote.zqu__Currency__c);
	                        }
	                        final Zuora.zObject subzobj = parentController.getSubscription(parentController.existSubscriptionId);
	                        
	                        if (null != subzobj) {
	                            parentController.quote.BrandTag__c = (String)subzobj.getValue('BrandTag__c');
	                            record.put('BrandTag__c', parentController.quote.BrandTag__c);                        
	                            parentController.quote.zqu__StartDate__c = ((Datetime)subzobj.getValue('TermStartDate')).date();
	                            record.put('zqu__StartDate__c', parentController.quote.zqu__StartDate__c);                        
	                            parentController.quote.zqu__Hidden_Subscription_Name__c = (String)subzobj.getValue('Name');
	                            record.put('zqu__Hidden_Subscription_Name__c', parentController.quote.zqu__Hidden_Subscription_Name__c);
	                            parentController.quote.zqu__SubscriptionVersion__c = (Integer)subzobj.getValue('Version');
	                            record.put('zqu__SubscriptionVersion__c', parentController.quote.zqu__SubscriptionVersion__c);
	                            parentController.quote.zqu__SubscriptionTermStartDate__c = ((Datetime)subzobj.getValue('TermStartDate')).date();
	                            record.put('zqu__SubscriptionTermStartDate__c', parentController.quote.zqu__SubscriptionTermStartDate__c);
	                            parentController.quote.zqu__SubscriptionTermEndDate__c = ((Datetime)subzobj.getValue('TermEndDate')).date();
	                            record.put('zqu__SubscriptionTermEndDate__c', parentController.quote.zqu__SubscriptionTermEndDate__c);                                                  
	                        }
	                    } catch(Exception e) { throw new zqu.ZQException(e.getMessage()); }
	                    
	                    parentController.quote.zqu__SubscriptionType__c = 'Amend Subscription';
	                    record.put('zqu__SubscriptionType__c', parentController.quote.zqu__SubscriptionType__c);
	                    parentController.quote.zqu__Amendment_Name__c =  opportunity.Name;
	                    record.put('zqu__Amendment_Name__c', parentController.quote.zqu__Amendment_Name__c);                    
	                }    
	            }
	          
	            // For edit / detail mode, make sure the quote is from record of property component
	            if (parentController.quote.Id != null)	parentController.quote = (zqu__Quote__c) record;
          	}
        }
    }

    public class PopulateRelatedObjectFieldPlugin implements IRelatedObjectPlugin {
        public Map < String, SObject > getRelatedObject(zqu.PropertyComponentController.ParentController pcc) {

            // Get PropertyComponentSample instance
            PropertyComponentSample parentController = (PropertyComponentSample) pcc;
    
            Map < String, SObject > relatedObjectMap = new Map < String, SObject > ();

            // Set value for related object field : Opportunity__r.AccountId
            relatedObjectMap.put('Opportunity__r', parentController.opp);      

            return relatedObjectMap;
        }
    }
  
    public class PopulateUpdatePlugin implements IUpdatePlugin{
        public PageReference doUpdate(SObject record, zqu.PropertyComponentController.ParentController pcc){        
                
            PropertyComponentSample parentController = (PropertyComponentSample) pcc;
        
            Opportunity opportunity = parentController.opp;
        
            // Set default field values when creating new quote
            if (parentController.quote.Id == null && opportunity != null)	record.put('zqu__Opportunity__c', opportunity.Id); // Set default opportunity                      

            // For edit / detail mode, make sure the quote is from record of property component
            if (parentController.quote.Id != null)	parentController.quote = (zqu__Quote__c) record;                        
            else{
                parentController.quote = (zqu__Quote__c) record;
                if(!Test.isRunningTest())	Database.upsert(parentController.quote);
            }
        
            // Navigate to the next step of the quote wizard:       
            PageReference nextPage;
            if (!Test.isRunningTest())	nextPage = zqu.QuoteWizardManager.navigateNext(New Map<String, String> {'Id' => parentController.quote.Id}, ApexPages.currentPage().getParameters().get('quoteType'));
            else	nextPage = new ApexPages.Standardcontroller(parentController.quote).view();
            
            return nextPage;   
                        
        }
    }
  
    public class PopulateGoBackPlugin implements IGoBackPlugin{
        public PageReference goBack(SObject record, zqu.PropertyComponentController.ParentController pcc){ 
            PropertyComponentSample parentController = (PropertyComponentSample) pcc;
            Opportunity opportunity = parentController.opp;
    
            // Set default field values when creating new quote
            if (parentController.quote.Id == null && opportunity != null)	record.put('zqu__Opportunity__c', opportunity.Id); // Set default opportunity
                    
            // Navigate to the previous quote wizard step
            Pagereference prevPage = zqu.QuoteWizardManager.navigateBack(New Map<String, String>{'oppId' => opportunity.Id});
            
            return prevPage;    
        }
    }
    
    public class PopulateCancelPlugin implements ICancelPlugin{
        public PageReference doCancel(SObject record, zqu.PropertyComponentController.ParentController pcc){        
            PropertyComponentSample parentController = (PropertyComponentSample) pcc;
            Opportunity opportunity = parentController.opp; 
                    
            PageReference oppPage = new ApexPages.Standardcontroller(opportunity).view();
            oppPage.setRedirect(true);
            return oppPage;
        }
    }  

    public void setOpportunity(Id oppId) {

        String opp_query;
        if (UserInfo.isMultiCurrencyOrganization())	opp_query = 'SELECT Id, Name,CurrencyISOCode, Account.Id, Account.Name FROM Opportunity WHERE Id = \'' + oppId + '\'';
        else	opp_query = 'SELECT Id, Name, Account.Id, Account.Name FROM Opportunity WHERE Id = \'' + oppId + '\'';

        this.opp = Database.query(opp_query);
    }
  
    private Zuora.zObject getBillingAccount(String billingaccountId){
        final Zuora.zObject acczobj;
        final String zoqlacc = 'SELECT BillToId,SoldToId,Currency from Account where Id=\'' + billingaccountId  + '\'';
        if (!Test.isRunningTest()){
	        final List <Zuora.zObject> acczobjs = api.zquery(zoqlacc);
	        if(acczobjs.size() == 1)	acczobj = acczobjs[0];
        }else{
        	// when test is running:
        	acczobj = new Zuora.zObject('Account');
        	acczobj.setValue('BillToId', 'testBillToId');
        	acczobj.setValue('SoldToId', 'testSoldToId');
        	acczobj.setValue('Currency', 'USD');
        	acczobj.setValue('Id', billingaccountId);        	
        }
        return acczobj;
    }
  
    private Zuora.zObject getSubscription(String subscriptionId){
        final Zuora.zObject subzobj;
        final String zoqlsubscription = 'Select Id, Name, Version, AccountId, OriginalId, BrandTag__c, ContractEffectiveDate, TermStartDate, TermEndDate, RenewalTerm from Subscription where Id = \'' + subscriptionId + '\'';
        if(!Test.isRunningTest()){
	        final List <Zuora.zObject> subzobjs = api.zquery(zoqlsubscription);
	        if(subzobjs.size() == 1)	subzobj = subzobjs[0];
        }else{
        	//when test is running:
        	subzobj = new Zuora.zObject('Subscription');
        	subzobj.setValue('Id', subscriptionId);
        	subzobj.setValue('Name', 'testSubName');
        	subzobj.setValue('Version', '1');
        	subzobj.setValue('AccountId', 'testAccId');
        	subzobj.setValue('OriginalId', 'testOrigId');
        	subzobj.setValue('BrandTag__c', 'ClearanceJobs');
        	subzobj.setValue('ContractEffectiveDate', date.newinstance(2014, 1, 1));
        	subzobj.setValue('TermStartDate', date.newinstance(2014, 1, 1));
        	subzobj.setValue('TermEndDate', date.newinstance(2015, 1, 1));
        	subzobj.setvalue('RenewalTerm', '12');
        }
        return subzobj;
    }
}