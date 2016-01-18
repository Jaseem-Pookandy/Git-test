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

public with sharing class PropertyComponentForEditQuoteDetails extends zqu.PropertyComponentController.ParentController {

	ApexPages.StandardController controller;
  	public zqu__Quote__c quote {
    	get;
   	 	set;
  	}
  	public zqu.PropertyComponentOptions theOptions {
    	get;
    	set;
  	}
  
  	public String billingAccountId {get; set;}
  
  	public String existSubscriptionId {get; set;}
  
  	private final Zuora.zApi api = new Zuora.zApi();
  	//public Boolean initFailed {get; private set;}
  
  	public PropertyComponentForEditQuoteDetails(ApexPages.StandardController stdController) {
    	System.debug('PropertyComponentForEditQuoteDetails(stdCtrl) executed!');

    	this.controller = stdController;

    	this.quote = (zqu__Quote__c) this.controller.getRecord();

    	// Initialize property component options
    	theOptions = new zqu.PropertyComponentOptions();
    	theOptions.objectName = 'zqu__Quote__c';
    	theOptions.objectId = this.quote.Id != null ? this.quote.Id : null;
    	theOptions.viewType = zqu.ViewConfigurationManager.VIEW_CONFIGURATION_VIEW_TYPE_EDIT;
    	//theOptions.propertyPageTitle = 'Property Component Sample';
    	theOptions.isEditMode = true;

    	// Set to detail mode
    	String mode = ApexPages.currentPage().getParameters().get('mode');
    	if (this.quote.Id != null && mode == 'detail')
      	theOptions.isEditMode = false;

    	theOptions.renderButtonBar = theOptions.isEditMode;
    	theOptions.parentController = this;
    	theOptions.instanceName = 'sampleProperty';

    	Schema.SObjectType objectType = zqu__Quote__c.sObjectType;
    	Map < String, Schema.RecordTypeInfo > recordTypeInfoMap = objectType.getDescribe().getRecordTypeInfosByName();
    	theOptions.recordTypeId = recordTypeInfoMap.get('Default').getRecordTypeId();

    	theOptions.customRenderingFields.add('zqu__RenewalTerm__c');
    	theOptions.customRenderingFields.add('zqu__AutoRenew__c');

    	theOptions.readonlyFields.add('zqu__Opportunity__c');
	    
    	theOptions.hiddenFields.add('zqu__RenewalTerm__c');
    	theOptions.hiddenFields.add('zqu__AutoRenew__c');

    	theOptions.populateValuePlugin = 'PropertyComponentForEditQuoteDetails.PopulateDefaultFieldValuePlugin';
    
    	theOptions.updatePlugin = 'PropertyComponentForEditQuoteDetails.PopulateUpdatePlugin';
    
    	theOptions.cancelPlugin = 'PropertyComponentForEditQuoteDetails.PopulateCancelPlugin';

   
	}

  	public String selectedCustomPicklistValue {
    	get;
    	set;
  	}
  
  	// Set field default value
  	public class PopulateDefaultFieldValuePlugin implements IPopulateValuePlugin {
    	public void populateDefaultFieldValue(SObject record, zqu.PropertyComponentController.ParentController pcc) {

      		// Get PropertyComponentForEditQuoteDetails instance
      		PropertyComponentForEditQuoteDetails parentController = (PropertyComponentForEditQuoteDetails) pcc;
            
      		// For edit / detail mode, make sure the quote is from record of property component
      		if (parentController.quote.Id != null) {
      			parentController.quote = (zqu__Quote__c) record;
      		}
    	}
  	}

  
  	public class PopulateUpdatePlugin implements IUpdatePlugin{
  		public PageReference doUpdate(SObject record, zqu.PropertyComponentController.ParentController pcc){ 		
  		 		
  			PropertyComponentForEditQuoteDetails parentController = (PropertyComponentForEditQuoteDetails) pcc;
  	
      		// For edit / detail mode, make sure the quote is from record of property component
      		if (parentController.quote.Id != null) {
        		parentController.quote = (zqu__Quote__c) record;
        		update parentController.quote;       	       	      	
      		}      	
      		else{
      			parentController.quote = (zqu__Quote__c) record;      	      		
      			Database.upsert(parentController.quote);      		
      		}
      	      	      	     	      	
      		PageReference savedQuotePage = new ApexPages.Standardcontroller(parentController.quote).view();
	  		savedQuotePage.setRedirect(true);
			return savedQuotePage;
		        		
  		}
  	}

	public class PopulateCancelPlugin implements ICancelPlugin{
	  	public PageReference doCancel(SObject record, zqu.PropertyComponentController.ParentController pcc){ 		
	  		PropertyComponentForEditQuoteDetails parentController = (PropertyComponentForEditQuoteDetails) pcc;
	  		  		  		
	  		PageReference quoteDetailPage = new ApexPages.Standardcontroller(parentController.quote).view();
	  		quoteDetailPage.setRedirect(true);
			return quoteDetailPage;
	  	}
	}
  

}