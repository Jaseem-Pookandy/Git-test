public with sharing class InsufficientPrivileges {

	ApexPages.StandardController controller;

	    
    public InsufficientPrivileges(ApexPages.StandardController stdController) {
    
    	this.controller = stdController;
    }
    
	// Navigate to step 1 of the quote wizard: 

	public pageReference goBack(){     	
      	PageReference prevPage;
      	      	     	      	
      	prevPage = zqu.QuoteWizardManager.navigateBack(New Map<String, String> {'oppId' => ApexPages.currentPage().getParameters().get('oppId')});
		return prevPage;
	}

}