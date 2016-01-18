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
 
public with sharing class SubscribePreviewController {
	
	public  final List<zqu.ZChargeGroup> chargeGroupList {get; set;}
    private final ApexPages.StandardController controller;
    
    //Checks to see if an account exists
    public boolean initFailed {get;set;}
    public String initFailure {get;set;}
    
    //Quote Id
    public String quoteId {get;set;} 
    
    //Quote
    public zqu__Quote__c quote {get;set;}
    
    //ZConfig
    Map<String, Object> ZConfig;
    
    //Account Information
    public boolean InvoiceDeliveryPrefsEmail{get;set;}
  
    public boolean submitQuote{get;set;}
    
    //Subscribe message variables
    public String subscribeStatus {get;set;}
    public String subscribeMessage {get;set;}
    public String subscribeRequest {get;set;}
    public String subscribeResponse {get;set;}
     
    public Decimal invoiceTotal {get;set;} 
    
    public Decimal DiscountTotal {get;set;}
    
    transient Map<String, zqu__ProductRatePlanCharge__c> tempprpcMap;
    //public Map<String, zqu__ProductRatePlanCharge__c> tempprpcMap;
    
    //bulkafy the query
	transient List<zqu__ProductRatePlanCharge__c> prpclist = [select id, zqu__ProductRatePlan__c 
		from zqu__ProductRatePlanCharge__c WHERE zqu__Deleted__c = false];
	//List<zqu__ProductRatePlanCharge__c> prpclist = [select id, zqu__ProductRatePlan__c from zqu__ProductRatePlanCharge__c];	
	
	//make a set with the list
	transient Set<zqu__ProductRatePlanCharge__c> tempprpcset = new Set<zqu__ProductRatePlanCharge__c>(prpclist);
	//Set<zqu__ProductRatePlanCharge__c> tempprpcset = new Set<zqu__ProductRatePlanCharge__c>(prpclist);
        
    public SubscribePreviewController(ApexPages.StandardController controller) {
		
		this.controller = controller;
		
		//Get the quote id
		this.quoteId = this.controller.getRecord().Id;
		
		//make a map with the set the key is the id
    	tempprpcMap = new Map<String, zqu__ProductRatePlanCharge__c>([select id, zqu__ProductRatePlan__c 
    		from zqu__ProductRatePlanCharge__c where id in : tempprpcset ]);

		//Gets the quote 
		this.quote = [
			SELECT zqu__BillToContact__c,zqu__SoldToContact__c, zqu__StartDate__c, zqu__PaymentTerm__c, zqu__Currency__c, zqu__Opportunity__c, zqu__Subscription_Term_Type__c, 
				zqu__PaymentMethod__c, zqu__InitialTerm__c, zqu__RenewalTerm__c, zqu__AutoRenew__c, zqu__Service_Activation_Date__c,zqu__Customer_Acceptance_Date__c, zqu__Status__c, 
				zqu__ZuoraAccountID__c, OwnerId, zqu__BillingMethod__c, Charge_Total__c, zqu__Total__c, Discount__c, zqu__Opportunity__r.Account.Name, zqu__Opportunity__r.Owner.Name
			FROM zqu__Quote__c 
			WHERE Id=:this.quoteId LIMIT 1];
		
        if (this.validate()) {
           try {
               chargeGroupList = zqu.zQuoteUtil.getChargeGroups(this.controller.getRecord().Id);    
           } catch(Exception e) {
               appendMessage(ApexPages.Severity.ERROR, e.getMessage());
           }
        }
        
        ZConfig = zqu.zQuoteUtil.getZuoraConfigInformation();  
	}
	
	public void onload()
    {
    	subscribe();
    }
	
	//get the SFDC product rate plan id based on the SFDC charge id
   	public string getProductRatePlan(String id){
            String ratePlanId;
    	//product rate plan charge            
    	try
    	{
    		ratePlanId = tempprpcMap.get(id).zqu__ProductRatePlan__c;
    	}catch(Exception e)
    	{
    		System.Debug('error' + e.getMessage());
    	}
                                                                                 
        if(ratePlanId != null)
        {                        
    		//set the email on the invoice custom field                                                
			return ratePlanId;                        
		}
           
        return null;
  	}
	
	public PageReference done()
    {
    	return new PageReference('/'+this.quoteId);
    }
	
	public void subscribe()
	{
		System.debug('SX:');
		subscribeRequest = '---';
        subscribeResponse = '---';
	        
        Zuora.zApi zApiInstance = new Zuora.zApi();
	        
        try {
        	if(!Test.isRunningTest())
        	{ 
        		zApiInstance.zlogin(); 
        	}
        } 
        catch (Exception ex) 
        { 
        	subscribeMessage = ex.getMessage(); 
        } 	
			
		try {

			//subscription options
            Zuora.zApi.SubscribeOptions so = new Zuora.zApi.SubscribeOptions(); 
            so.GenerateInvoice = true;
            so.ProcessPayments = false;

            //Set up preview options
            Zuora.zApi.PreviewOptions previewOpt = new Zuora.zApi.PreviewOptions(); 
            previewOpt.EnablePreviewMode = true;
            									
            //Setting the values for account
            Zuora.zObject acc = new Zuora.zObject('Account');
	        if(this.quote.zqu__ZuoraAccountID__c == null || previewOpt.EnablePreviewMode)
	        {
	        	//acc.setValue('Name', this.quote.zqu__Opportunity__r.Account.Name); 
	        	acc.setValue('Name', 'Discount Calculation');
	            acc.setValue('Currency',this.quote.zqu__Currency__c); 
	            	
            	Object mCED = ZConfig.get('match_contract_effective_date__c');
				if(String.valueOf(mCED) == 'true')
				{
					acc.setValue('BillCycleDay', this.quote.zqu__StartDate__c.day());
				}
		 		else
		 		{
		 			Object BCD = ZConfig.get('billingaccount_billcycleday__c');
		 			acc.setValue('BillCycleDay', Integer.valueOf(BCD));
		 		}
			 		
            	acc.setValue('CrmId', account.Id); 
            	acc.setValue('PaymentTerm', this.quote.zqu__PaymentTerm__c); 
            	
            	Object BatchNum = ZConfig.get('billingaccount_batch__c');
            	acc.setValue('Batch', String.valueOf(BatchNum));
			 			
		 		if(quote.zqu__BillingMethod__c == 'Print' || quote.zqu__BillingMethod__c == 'Both')
		 		{
		 			acc.setValue('InvoiceDeliveryPrefsPrint', true);
		 		}
		 		
            	acc.setValue('SalesRepName', this.quote.zqu__Opportunity__r.Owner.Name);
            }
            else 
            {
            	acc.setValue('Id', this.quote.zqu__ZuoraAccountID__c);
            }
	            

			Contact billToContact = [
				SELECT c.MailingStreet, c.MailingState, c.MailingPostalCode, c.Email, c.MailingCountry, c.MailingCity, c.LastName, c.HomePhone, c.FirstName, c.Phone, c.MobilePhone, c.OtherStreet, c.OtherPhone 
				FROM Contact c 
				WHERE Id=:this.quote.zqu__BillToContact__c LIMIT 1];
				
			//Setting the values for bill to contact
            Zuora.zObject zBillToContact = new Zuora.zObject('Contact'); 
            zBillToContact.setValue('FirstName', billToContact.FirstName); 
            zBillToContact.setValue('LastName', billToContact.LastName); 
            zBillToContact.setValue('WorkEmail', billToContact.Email); 
            zBillToContact.setValue('Country', billToContact.MailingCountry); 
            zBillToContact.setValue('State', billToContact.MailingState);
            zBillToContact.setValue('Address1', billToContact.MailingStreet); 
            zBillToContact.setValue('Address2', billToContact.OtherStreet); 
            zBillToContact.setValue('City', billToContact.MailingCity);
            zBillToContact.setValue('PostalCode', billToContact.MailingPostalCode); 
            zBillToContact.setValue('HomePhone', billToContact.HomePhone); 
            zBillToContact.setValue('MobilePhone', billToContact.MobilePhone); 
            zBillToContact.setValue('OtherPhone', billToContact.OtherPhone); 
            zBillToContact.setValue('WorkPhone', billToContact.Phone);
	            
          	//Setting the values for sold to contact
            Zuora.zObject zSoldToContact = new Zuora.zObject('Contact');
            if(this.quote.zqu__SoldToContact__c != this.quote.zqu__BillToContact__c)
            {
            	Contact soldToContact = [
	            	Select c.MailingStreet, c.MailingState, c.MailingPostalCode, c.Email, c.MailingCountry, c.MailingCity, c.LastName, c.HomePhone, c.FirstName, c.Phone, c.MobilePhone, c.OtherStreet, c.OtherPhone 
	            	From Contact c 
	            	WHERE Id=:this.quote.zqu__SoldToContact__c];
	            	
            	zSoldToContact.setValue('FirstName', soldToContact.FirstName); 
             	zSoldToContact.setValue('LastName', soldToContact.LastName); 
             	zSoldToContact.setValue('WorkEmail', soldToContact.Email); 
             	zSoldToContact.setValue('Country', soldToContact.MailingCountry); 
             	zSoldToContact.setValue('State', soldToContact.MailingState); 
             	zSoldToContact.setValue('Address1', soldToContact.MailingStreet); 
             	zSoldToContact.setValue('Address2', soldToContact.OtherStreet); 
             	zSoldToContact.setValue('City', soldToContact.MailingCity); 
             	zSoldToContact.setValue('PostalCode', soldToContact.MailingPostalCode); 
             	zSoldToContact.setValue('HomePhone', soldToContact.HomePhone); 
             	zSoldToContact.setValue('MobilePhone', soldToContact.MobilePhone); 
             	zSoldToContact.setValue('OtherPhone', soldToContact.OtherPhone); 
             	zSoldToContact.setValue('WorkPhone', soldToContact.Phone);
            }
 
            //subscription
            Zuora.zObject sub = new Zuora.zObject('Subscription'); 
            if(this.quote.zqu__StartDate__c != null)
            {
            	//sub.setValue('ContractEffectiveDate', Zuora.zUtil.getZuoraDate(this.quote.zqu__StartDate__c));
            	sub.setValue('ContractEffectiveDate', Zuora.zUtil.getZuoraDate(System.today()));
            }
            
            if(this.quote.zqu__Service_Activation_Date__c != null)
            { 
            	//sub.setValue('ServiceActivationDate', Zuora.zUtil.getZuoraDate(this.quote.zqu__Service_Activation_Date__c));
            	sub.setValue('ServiceActivationDate', Zuora.zUtil.getZuoraDate(System.today()));
            }
            
            if(this.quote.zqu__Customer_Acceptance_Date__c != null)
            { 
            	//sub.setValue('ContractAcceptanceDate', Zuora.zUtil.getZuoraDate(this.quote.zqu__Customer_Acceptance_Date__c));
            	sub.setValue('ContractAcceptanceDate', Zuora.zUtil.getZuoraDate(System.today()));
            } 
            
            sub.setValue('TermType', this.quote.zqu__Subscription_Term_Type__c.toUpperCase());
            
            if(this.quote.zqu__Subscription_Term_Type__c.toUpperCase() != 'EVERGREEN')
            { 
            	sub.setValue('InitialTerm', this.quote.zqu__InitialTerm__c); 
            	sub.setValue('RenewalTerm', this.quote.zqu__RenewalTerm__c); 
            	sub.setValue('AutoRenew', this.quote.zqu__AutoRenew__c); 
            }            
            
            for(zqu.zChargeGroup ratePlan: chargeGroupList)
            {
            	for(zqu.zCharge charge : ratePlan.zCharges)
            	{
            		if(charge.MODEL != 'Discount-Fixed Amount' && charge.MODEL != 'Discount-Percentage' && charge.CHARGE_TYPE == 'Recurring')
            		{
            			if(this.quote.zqu__Subscription_Term_Type__c == 'TERMED')
            			{
	            			if(charge.PERIOD == 'Annual' && this.quote.zqu__InitialTerm__c != 12)
	            			{
	            				 previewOpt.NumberOfPeriods = (Integer)this.quote.zqu__InitialTerm__c / 12;
	            			}
	            			else if(charge.PERIOD == 'Month' || charge.PERIOD == 'Quarter')
	            			{
	            				previewOpt.NumberOfPeriods = (Integer)this.quote.zqu__InitialTerm__c;
	            			}
	            			else if(charge.PERIOD == 'Semi-Annual')
	            			{
	            				previewOpt.NumberOfPeriods = 2;
	            			}
	            			else 
	            			{
	            				previewOpt.NumberOfPeriods = 1;
	            			}
            			}
            			else if(this.quote.zqu__Subscription_Term_Type__c == 'EVERGREEN')
            			{
            				if(charge.PERIOD == 'Month')
            				{
            					previewOpt.NumberOfPeriods = 1;
            				}
            			}
            		}	
            	}
            }    
                   
            //subscription data
            Zuora.zApi.SubscriptionData sd = new Zuora.zApi.SubscriptionData(); 
            sd.Subscription = sub;    
	            
            //Set up rate plan datas
            List<Zuora.zObject> ratePlanDatas = new List<Zuora.zObject>();
            List<zqu__ProductRatePlan__c> prps= [ SELECT Id, zqu__ZuoraId__c FROM zqu__ProductRatePlan__c WHERE zqu__Deleted__c = false];
            for(zqu.zChargeGroup ratePlan: chargeGroupList)
            {
            	//Rate Plan
            	Zuora.zObject rp = new Zuora.zObject('RatePlan');
				
            	//rp.setValue('ProductRatePlanId', ratePlan.productRateplanZuoraID);	     
            	
            	//Make Rate plan Data
                Zuora.zObject rpd = new Zuora.zObject('RatePlanData');       	
            	
            	List<Zuora.zObject> rpcds = new List<Zuora.zObject>();
            	for(zqu.zCharge charge : ratePlan.zCharges)
            	{
            		//Rate Plan Charge
            		Zuora.zObject rpc = new Zuora.zObject('RatePlanCharge'); 
            		
            		rpc.setValue('ProductRatePlanChargeId', charge.PRODUCT_RATE_PLAN_CHARGE_ZUORA_ID);
            		
            		if(charge.QUANTITY != '-')
               		{ 
                		rpc.setValue('Quantity', charge.QUANTITY); 
                	}
                	
                	if(charge.MODEL == 'Discount-Fixed Amount' && charge.EFFECTIVE_PRICE != '-')
                    {
                        rpc.setValue('DiscountAmount', charge.EFFECTIVE_PRICE);
                    }
                    
                    if(charge.MODEL == 'Discount-Percentage' && charge.EFFECTIVE_PRICE != '-')
                    {
                        rpc.setValue('DiscountPercentage', charge.EFFECTIVE_PRICE);
                    }
                    
                    if(charge.LIST_PRICE != '-')
                    {
                    	rpc.setValue('Price', charge.EFFECTIVE_PRICE);
                    }
            		
            		Zuora.zObject rpcd = new Zuora.zObject('RatePlanChargeData');
                    rpcd.setValue('RatePlanCharge', rpc); 
	                    
	                    
                    //Sets the rate plan Id
					try{
						String sfId = getProductRatePlan(charge.PRODUCT_RATE_PLAN_CHARGE_SFDC_ID);
						//zqu__ProductRatePlan__c prp= [ SELECT zqu__ZuoraId__c FROM zqu__ProductRatePlan__c WHERE Id=:sfId LIMIT 1];
						for(zqu__ProductRatePlan__c prp : prps)
						{
							if(prp.Id == sfId)
							{
								rp.setValue('ProductRatePlanId', prp.zqu__ZuoraId__c);
							}
						}
					}
					catch(Exception e)
					{
						System.Debug(e.getMessage() );
					}
					
                    rpcds.add(rpcd);
            	}
            	
            	//Attach Rateplan to rateplan data
                rpd.setValue('RatePlan', rp);
                //Attach Rateplan to rateplan data 
                rpd.setValue('RatePlanChargeData', rpcds); 
                ratePlanDatas.add(rpd);
            }
	            
            sd.RatePlanData = ratePlanDatas;

            //subscribe request
            Zuora.zApi.SubscribeRequest subsRequest = new
            Zuora.zApi.SubscribeRequest();
                        
            subsRequest.ZAccount = acc; 
            subsRequest.BillToContact = zBillToContact; 
	            
	        if(this.quote.zqu__SoldToContact__c != this.quote.zqu__BillToContact__c)
	        {
	           	subsRequest.SoldToContact = zSoldToContact;
	        }

            subsRequest.SubscribeOptions = so; 
            subsRequest.SubscriptionData = sd;
            subsRequest.PreviewOptions = previewOpt;
	        
            List<Zuora.zApi.SubscribeRequest> subsRequestLists = new List<Zuora.zApi.SubscribeRequest>{subsRequest};
            List<Zuora.zApi.SubscribeResult> subscribeResults;
            if(!Test.isRunningTest())
            {
            	subscribeResults = zApiInstance.zsubscribe(subsRequestLists); 
            	subscribeRequest = Zuora.zApi.currentLogger.request; 
            	subscribeResponse = Zuora.zApi.currentLogger.response;
            }
            else
            {
            	subscribeResults = new List<Zuora.zApi.SubscribeResult> {}; 
            	Zuora.zApi.SubscribeResult subRes = new Zuora.zApi.SubscribeResult(); 
            	subRes.Success = true;
            	subscribeResults.add(subRes);
            }
	        System.debug('SX: subscribeResults inside DC ' + subscribeResults);
            for (Zuora.zApi.SubscribeResult result : subscribeResults) 
            {
                if (result.Success) 
                {			            
		            if (result.InvoiceDatas != null) {
						for (Zuora.zObject invData: result.InvoiceDatas) {
					    	//in Preview mode, handle with the invoice data					    						
							Zuora.zObject invoice = (Zuora.zObject) invData.getValue('Invoice');
							invoiceTotal = ( Decimal ) invoice.getValue('AmountWithoutTax');
							discountTotal = this.quote.Charge_Total__c - invoiceTotal;
							this.quote.Discount__c = this.quote.Charge_Total__c - invoiceTotal;
							System.debug('SX: quote.Discount__c ' + this.quote.Discount__c);
							update this.quote;
							
							List<Object> invoiceItems = invData.getArrayValue('InvoiceItem');
						      	
					      	if( invoiceItems != null ){
						        for( Object invoiceItem : invoiceItems ){						        	
						        	Zuora.zObject zInvoiceItem = ( Zuora.zObject ) invoiceItem;
						        }
					      	}
					   }
  					} 
                } else {
                    Zuora.zObject[] errors = result.errors;
                    for (Zuora.zObject error : errors) { subscribeStatus = 'Failure'; subscribeMessage = 'Subscribe failed: ' + (String)error.getValue('Message'); ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, subscribeMessage)); }
                }
        	}      
        } catch (Zuora.zRemoteException ex) {
			if ('INVALID_FIELD' == ex.code) {
				subscribeStatus = 'Failure.'; subscribeMessage = 'Remote Exception Valid Code: ' + ex.getMessage() + ' Code: ' + ex.code;
			} else {
				subscribeStatus = 'Failure.'; subscribeMessage = 'Remote Exception: ' + ex.getMessage() + ' Code: ' + ex.code;
			}
		} catch (Zuora.zAPIException ex) {
			subscribeStatus = 'Failure.'; subscribeMessage = 'API Exception: ' + ex.getMessage();
		} catch (Zuora.zForceException ex) {
			subscribeStatus = 'Failure.'; subscribeMessage = 'zForce Exception: ' + ex.getMessage();
		} 
        catch (Exception ex ) { subscribeStatus = 'Failure.'; subscribeMessage = 'Unhandled Exception: ' + ex.getMessage(); }
	}

    private Boolean validate() {
        if (null == this.controller.getRecord() || null == this.controller.getRecord().Id) {
            appendMessage(ApexPages.Severity.ERROR, 'Need to specify the id of quote for creating subscription.');
            return false;
        }
        return true;
    }
   
    private static void appendMessage(ApexPages.Severity messageType, String message) {
        ApexPages.addMessage(new ApexPages.Message(messageType, message));
    }
}