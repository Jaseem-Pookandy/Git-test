/*******************************************************************
Name            : MassUpdateAccountBrandsController
Author          : Byrnes
Date            : June 17, 2014
Related Task	: CC-2549
*************************************************************************/

public with sharing class MassUpdateAccountBrandsController {

	//public stuff...  (referenced on the .page file)
	public List<String> errors {get; set;}
	public List<Account_Brand__c> accountBrands {get; set;}
	public Account thisAccount {get; set;}


	//private stuff...  (referenced internally only)
	private PageReference pgReturnPage {get; set;}
	private String accountID {get; set;}

	public MassUpdateAccountBrandsController(ApexPages.StandardController controller) {
		
    	PrepPage();
    }

    private void PrepPage() {

		errors = new List<String>();
		accountBrands = new List<Account_Brand__c>();

		if (ApexPages.currentPage().getParameters().get('retURL') != null) pgReturnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
		else pgReturnPage = new PageReference('/home/home.jsp');

		if (ApexPages.currentPage().getParameters().get('accID') != null) accountID = ApexPages.currentPage().getParameters().get('accid');
		else {
			errors.add('Unable to initialize page as the \'accid\' querystring parameter is missing.');
			return;
		}

		List<Account> foundAccs = [SELECT Name, Id, Account_Number__c, (SELECT Id,CS__c,Primary_Owner__c, Name, Brand_Name__c FROM Account_Brands__r) FROM Account WHERE Id = :accountID];

		if (foundAccs.size() > 0) thisAccount = foundAccs[0];

		if (thisAccount != null) {

			for (Account_Brand__c ab : thisAccount.Account_Brands__r) {
				accountBrands.add(ab);
			}
		}

    }

    public PageReference Cancel() {
    	return pgReturnPage;
    }    

    public void SaveAccountBrands() {

    	update accountBrands;
    }

    public PageReference SaveItAll() {

    	//Boolean GoodToGo = Validate();		//validation, if/when necessary will go here...
    	Boolean GoodToGo = true;
    	
    	if (GoodToGo) { 	
    		
    		SaveAccountBrands();

			//This will redirect the user to the retURL
    		return pgReturnPage;
    	}
    	else return null;
    }    
}