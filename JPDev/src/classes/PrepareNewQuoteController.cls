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

 
//Shawn Xuereb - Deprecated with the Release 2.
public with sharing class PrepareNewQuoteController{
   
    private Zuora.zApi api = new Zuora.zApi();
    private final Opportunity opp;
    private final String CRMId;
    private final Map <String,List<SelectOption>> cachedSubOptions = new Map <String,List<SelectOption>>();
   
    public Boolean initFailed                          {get; private set;}
    public String  selectedAccountType                 {get;set;}
    public String  selectedAccount                     {get;set;}
    public String  selectedSubscription                {get;set;}
    public String  selectedSubscriptionType            {get;set;}
    public String  selectedAmendmentType               {get;set;}
    public List<SelectOption> billingAccountList       {get;set;}
    public List<SelectOption> subscriptionList         {get;set;}
    
    public PrepareNewQuoteController(ApexPages.StandardController controller) {}
    /*public PrepareNewQuoteController(ApexPages.StandardController controller) {
        this.initFailed = true;
        final String oppId = controller.getId();
        if (null == oppId || '' == oppId) {
            appendErrorMessage('Need to specify the id of opportunity to create a quote.');
            return;
        }      
       
        final List<Opportunity> oppList = [SELECT Id, Account.Id FROM Opportunity WHERE Id = :oppId limit 1];
        if (oppList.size() != 1) {
            appendErrorMessage('Invalid opportunity specified to create a quote.');
            return;
        }      
        this.opp = oppList[0];
        this.CRMId = this.opp.Account.Id;
       
        if(!Test.isRunningTest())
	    {
	        try { api.zlogin(); } 
	        catch (Zuora.zAPIException e) { appendErrorMessage(e.getMessage()); return; }
	    }
        this.initFailed = false;
    }
   
    public PageReference onload() {
        try {
            this.loadBillingAccountList();
        } catch (Zuora.zAPIException e) {
            appendErrorMessage(e.getMessage());
            return null;
        }
        
        if(this.billingAccountList.size() == 0)
        {
        	return goNewQuote();
        }
        else
        {
        	selectedAccountType = 'existing';
       		onSelectAccountType();
       		
       		try{
       			this.loadSubscriptionList();
       		}catch(Zuora.zAPIException e){
       			appendErrorMessage(e.getMessage());
           		return null;
       		}
       		
       		//if(this.subscriptionList.size() == 0)
       		//{
       			this.selectedSubscriptionType = 'new';
       		//}
       		//else
       		//{
       		//	selectedSubscriptionType = 'existing';
      		//	onSelectSubscriptionType();
       		//}
        }
        
        return null;
    }
   
    public PageReference onSelectAccount() {
                try {
                    this.loadSubscriptionList();
                } catch (Zuora.zAPIException e) {
                    appendErrorMessage(e.getMessage());
                    return null;
            }
            return null;
    }
   
    public PageReference goNewQuote() {
        PageReference  newQuotePage = Page.NewQuote;
        String quoteType = 'New';        
        if(this.selectedSubscriptionType == 'new') {
        	quoteType = 'New';
        } else if ('amend' == selectedAmendmentType ) {
            quoteType = 'Amend';
        } else if ('renew' == selectedAmendmentType) {
                    quoteType = 'Renew';
        } 
        
        newQuotePage.getParameters().put('quoteType', quoteType);
        newQuotePage.getParameters().put('oppid', String.valueOf(this.opp.Id).substring(0,15));
      
       //Additional logic
       if(selectedAccountType == 'existing' && selectedSubscriptionType == 'new'){
       		newQuotePage.getParameters().put('billingaccountid', this.selectedAccount);
       }
       else if(quoteType != 'New')
       {
        	newQuotePage.getParameters().put('billingaccountid', this.selectedAccount);
        	newQuotePage.getParameters().put('existsubscriptionid', this.selectedSubscription);
        }
        
        newQuotePage.setRedirect(true);      

        return newQuotePage;
    }

    public PageReference onSelectAccountType() {
        if ('new' == this.selectedAccountType) {
            this.selectedSubscriptionType = 'new';
            
            this.selectedAmendmentType = ''; 
        } else {
            try {
            this.loadBillingAccountList();
            } 
            catch (Zuora.zAPIException e) { appendErrorMessage(e.getMessage());  return null; }
            this.selectDefaultAccount();
            
            try{
       			this.loadSubscriptionList();
       		}
       		catch(Zuora.zAPIException e){ appendErrorMessage(e.getMessage()); return null; }
       		
       		if(this.subscriptionList.size() == 0)
       		{
       			this.selectedSubscriptionType = 'new';
       		}
       		else
       		{
       			selectedSubscriptionType = 'existing';
      			onSelectSubscriptionType();
       		}
        }      
        return null;
    }
   
    private void selectDefaultAccount() {
        if (this.billingAccountList != null && this.billingAccountList.size() > 0) {
            this.selectedAccount = this.billingAccountList[0].getValue();
        }
        this.onSelectAccount();
    }
   
    public PageReference onSelectSubscriptionType() {
        if ('existing' == this.selectedSubscriptionType) {
            try {
            	this.loadSubscriptionList();
            } 
            catch (Zuora.zAPIException e) { appendErrorMessage(e.getMessage()); return null; }
            this.selectDefaultSubscription();
        } 
        else {
			this.selectedAmendmentType = '';
		}     
        return null;          
    }    
    private void selectDefaultSubscription() {
        if (this.subscriptionList.size() > 0) {
            this.selectedAmendmentType = 'amend';
            this.selectedSubscription = this.subscriptionList[0].getValue();
        }
    }    
    private void loadBillingAccountList() {
        if (this.CRMId == null) return;
        //already queried from Zuora, no need to query again
        if (this.billingAccountList != null)
            return;
        else{
            //query from Zuora and build the billing account picklist
            this.billingAccountList = new List<SelectOption> ();
            String acczoql = 'SELECT Id, AccountNumber, Name, BillToId, SoldToId, Currency, DefaultPaymentMethodId, InvoiceTemplateName__c FROM Account WHERE Status = \'Active\' AND CrmId LIKE \'' + this.CRMId.substring(0, 15) + '%\'';
            List <Zuora.zObject> acclist;
            
            if(!Test.isRunningTest())
	        {
	            try { acclist = api.zquery(acczoql); }
	            catch (Zuora.zAPIException e) { throw e; }
	        }
	        else
	        {
	        	acclist = new List<Zuora.zObject>();
	        		
	        		Zuora.zObject acc = new Zuora.zObject('Account');
	        		acc.setValue('Id', '123456789');
	        		acc.setValue('Name', 'test');
	        		acc.setValue('AccountNumber', '123456');
	        		acclist.add(acc);
	        }
	        
           	String billTozoql = 'SELECT Id, FirstName, LastName FROM Contact WHERE Id =\'';
           	String soldTozoql = 'SELECT Id, FirstName, LastName FROM Contact WHERE Id =\'';
           	String paymentMethodzoql = 'SELECT Id, CreditCardMaskNumber, Type FROM PaymentMethod WHERE Id =\'';
           	
            for(Integer i = 0; i < acclist.size(); i++) {
            	
            	if(i == acclist.size() - 1)
            	{
            		billTozoql += (String)acclist[i].getValue('BillToId') + '\'';
            	}
            	else
            	{
            		billTozoql += (String)acclist[i].getValue('BillToId') + '\' OR Id = \'';
            	}
		        
		        if(i == acclist.size() - 1)
            	{
            		soldTozoql += (String)acclist[i].getValue('SoldToId') + '\'';
            	}
            	else
            	{
            		soldTozoql += (String)acclist[i].getValue('SoldToId') + '\' OR Id = \'';
            	}		        
		        
		         if(i == acclist.size() - 1)
		         {
					paymentMethodzoql  += (String)acclist[i].getValue('DefaultPaymentMethodId') + '\'';
		         }
		         else
		         {
					paymentMethodzoql  += (String)acclist[i].getValue('DefaultPaymentMethodId') + '\' OR Id = \'';
		         }
            }
            
            List <Zuora.zObject> billToContacts = new List <Zuora.zObject>();
            List <Zuora.zObject> soldToContacts = new List <Zuora.zObject>();
            List <Zuora.zObject> paymentMethods = new List <Zuora.zObject>();
            
            if(acclist.size() != 0)
            {
	            if(!Test.isRunningTest())
	        	{
			        try { billToContacts = api.zquery(billTozoql); } 
			        catch (Zuora.zAPIException e) { throw e; }
			        
			        try { soldToContacts = api.zquery(soldTozoql);} 
			        catch (Zuora.zAPIException e) { throw e; }
			        
			        try { paymentMethods = api.zquery(paymentMethodzoql); }
			        catch (Zuora.zAPIException e) { throw e; }
	        	}
	        	else
	        	{
	        		Zuora.zObject billToContact = new Zuora.zObject('Contact');
	        		billToContact.setValue('Id', '123456789');
	        		billToContact.setValue('FirstName', 'Jim');
	        		billToContact.setValue('LastName', 'Bob');
	        		billToContacts.add(billToContact);
	        		
	        		Zuora.zObject soldToContact = new Zuora.zObject('Contact');
	        		soldToContact.setValue('Id', '123452789');
	        		soldToContact.setValue('FirstName', 'Joe');
	        		soldToContact.setValue('LastName', 'Bob');
	        		soldToContacts.add(soldToContact);
	        			        		
	        		Zuora.zObject paymentMethod = new Zuora.zObject('PaymentMethod');
	        		paymentMethod.setValue('Id', '123452789');
	        		paymentMethod.setValue('CreditCardMaskNumber', '1234567');
	        		paymentMethod.setValue('Type', 'CreditCard');
	        		paymentMethods.add(paymentMethod);
	        		
	        	}
            }
	        
	        for(Zuora.zObject acc: acclist)
	        {
		        String accvalue = (String)acc.getValue('Id');                  
	            String acclabel = acc.getValue('Name') +  ', Acct#:' + acc.getValue('AccountNumber');
	            
	            String extraInfo = ', Invoice Template Name: ' + (String)acc.getValue('InvoiceTemplateName__c') + ', Currency: ' + acc.getValue('Currency');
	            
	            String billToContactlabel;
	            for(Zuora.zObject billToContact : billToContacts)
	            {
	            	if((String)billToContact.getValue('Id') == (String)acc.getValue('BillToId'))
	            	{
	            		billToContactlabel = ', Bill to: ' + (String)billToContact.getValue('FirstName') + ' ' + (String)billToContact.getValue('LastName');
	            		break;
	            	}
	            }
	            
	            String soldToContactlabel;
	            for(Zuora.zObject soldToContact : soldToContacts)
	            {
	            	if((String)soldToContact.getValue('Id') == (String)acc.getValue('SoldToId'))
	            	{
	            		soldToContactlabel = ', Bill to: ' + (String)soldToContact.getValue('FirstName') + ' ' + (String)soldToContact.getValue('LastName');
	            		break;
	            	}
	            }
	            
	            SelectOption accso;
				if(paymentMethods.size() != 0)
                {
                	String paymentInfo;
                	
                	for(Zuora.zObject paymentMethod : paymentMethods)
                	{
                	
                		if(paymentMethod.getValue('Id') == (String)acc.getValue('DefaultPaymentMethodId'))
                		{
		                	if((String)paymentMethod.getValue('Type') == 'CreditCard')
		                	{
		                		paymentInfo = ', Payment Method: ' + (String)paymentMethod.getValue('Type') + ', Credit Card: ' + (String)paymentMethod.getValue('CreditCardMaskNumber');
		                	}
		                	else if((String)paymentMethod.getValue('Type') == 'DebitCard')
		                	{
		                		paymentInfo = ', Payment Method: ' + (String)paymentMethod.getValue('Type') + ', Debit Card: ' + (String)paymentMethod.getValue('CreditCardMaskNumber');
		                	}
		                	else if((String)paymentMethod.getValue('Type') != null)
		                	{
		                		paymentInfo = ', Payment Method: ' + (String)paymentMethod.getValue('Type');	
		                	}
                		}
                	}
                	
                	if(paymentInfo != null)
                	{
                		accso = new SelectOption (accvalue, acclabel + billToContactlabel + soldToContactlabel + paymentInfo + extraInfo);
                	}
                	else
                	{
                		accso = new SelectOption (accvalue, acclabel + billToContactlabel + soldToContactlabel + extraInfo);
                	}
                }
                else
                { 
               	 	accso = new SelectOption (accvalue, acclabel + billToContactlabel + soldToContactlabel + extraInfo);
                }
	            
	            this.billingAccountList.add(accso);
	        }
        }
    }    
    //query the subscription from zuora and build the picklist
    private void loadSubscriptionList() {
        this.subscriptionList = new  List<SelectOption>();      
        if (this.selectedAccount == null) return;
        List<SelectOption> suboptionlist = this.cachedSubOptions.get(this.selectedAccount);
        if (suboptionlist != null) this.subscriptionList = suboptionlist;
        else{
            suboptionlist = new List<SelectOption> ();
            String subzoql = 'SELECT Id, Name, ContractEffectiveDate, TermType, Status FROM Subscription WHERE Status = \'Active\' AND AccountId = \'' + this.selectedAccount + '\'';
            List<Zuora.zObject> subscriptionList;
            
            if(!Test.isRunningTest())
	        {
	            try { subscriptionList = api.zquery(subzoql); }
	            catch (Zuora.zAPIException e) { throw e; }
	        }
	        else
        	{
        		subscriptionList = new List<Zuora.zObject>();
        		Zuora.zObject sub = new Zuora.zObject('Subscription');
        		sub.setValue('Id', '123456789');
        		sub.setValue('Name', 'test');
        		sub.setValue('TermType', 'Evergreen');
        		sub.setValue('Status', 'Active');
        		subscriptionList.add(sub);
        	}                    
           
            for(Zuora.zObject sub : subscriptionList) {
                String subvalue = (String)sub.getValue('Id');
                DateTime cedatetime = (DateTime)sub.getValue('ContractEffectiveDate');      
                String sublabel;
                if(!Test.isRunningTest())
				{        
                	sublabel = (String)sub.getValue('Name') +  ', Status: ' + (String)sub.getValue('Status') +  ', Contract Effective Date: ' +  cedatetime.date().format();
				}
				else
				{
					sublabel = 'test';
				}
                SelectOption subso = new SelectOption (subvalue,sublabel);
                suboptionlist.add(subso);
            }
       
            if (suboptionlist.size() > 0){
                this.cachedSubOptions.put(this.selectedAccount, suboptionlist);
                this.subscriptionList = suboptionlist;
            }
        }
    }
   
    static private void appendErrorMessage(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }*/
}