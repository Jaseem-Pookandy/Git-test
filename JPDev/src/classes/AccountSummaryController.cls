/*******************************************************************
Name            : AccountSummaryController
Author          : Byrnes
Date            : December 17, 2013
Related Task	: CC-1697
*************************************************************************/

public with sharing class AccountSummaryController {

	//Public stuff...  (referenced on the .page file)
	public Account account {get; set;}
	
	
	//Private stuff... (reference internally only)
	private PageReference pgReturnPage {get; set;}
	private User currentUser {get; set;}
	private String accountID {get; set;}
	private List<Contact_ContactType_WrapperClass> wrappedContacts {get; set;}
	private List<Contact> productUsers {get; set;}

	public AccountSummaryController(ApexPages.StandardController controller) {
		
		accountID = ApexPages.currentPage().getParameters().get('id');
		if (accountID != null) PopulateThePage();
	}

	private void PopulateThePage() {
		
		account = [	SELECT 	Name, 
							Id,
							Account_Number__c,
							Status__c,
							Channel_Partner__c,
							Customer_Segment__c,
							Website,
							BillingStreet,
							BillingCity, 
							BillingState, 
							BillingPostalCode, 
							BillingCountry,
							Accounting_Flag__c,
							(SELECT 
								Name,
								Brand_Picklist__c,
								Status__c,
								Primary_Owner__c,
								CS__c,
								Rank__c,
								hasNeeds__c,
								Market_Segment__c,
								Valid_Thru__c, 
								Active_Users__c,
								At_Risk__c
							FROM Account_Brands__r ORDER BY Name ASC),
							
							(SELECT 
								Name,
								Brand__c,
								Zuora__TotalContractValue__c,
								Country__c,
								Zuora__EffectiveEndDate__c,
								Zuora__EffectiveStartDate__c,
								Zuora__Subscription__c,
								Product_Rate_Plan__c
							FROM Zuora__R00N40000001lGjTEAU__r),
							
							(SELECT 
								Id,
								Name,
								Zuora__BillToName__c,
								Zuora__BillToWorkEmail__c,
								Zuora__BillToWorkPhone__c,
								Full_Bill_To_Address__c,
								Zuora__SoldToName__c
							FROM Zuora__R00N40000001kyLcEAI__r)
							
					FROM Account 
					WHERE Id = :accountID LIMIT 1];
	}
	
	public List<Contact_ContactType_WrapperClass> getWrappedContacts() {
		
		wrappedContacts = new List<Contact_ContactType_WrapperClass>();
			
		for (Contact c : [SELECT	AccountId, 
									Name, 
									Full_Mailing_Address__c, 
									Email, 
									Title, 
									Contact_Full_Name__c, 
									Phone, 
									LastName,
									Contact_Preferences_Flag__c,
										(SELECT 
											Brand_Name__c,
											Type__c 
										FROM Contact_Types__r
										WHERE Type__c IN ('Main Sales Contact', 'Decision Maker') 
										ORDER BY Brand_Name__c ASC) 
									FROM Contact
									WHERE No_Longer_With_Company__c = false
									AND AccountId = :accountID
									ORDER BY LastName ASC]) {
						 	
			Contact_ContactType_WrapperClass cw = new Contact_ContactType_WrapperClass();	
			cw.ContactRecord = c;
						 	
			for (Contact_Type__c ct : c.Contact_Types__r) {
				cw.ContactTypes.add(ct);
			}
			
			if (cw.ContactTypes.size() > 0) wrappedContacts.add(cw);
		}		
		
		return wrappedContacts;
	}
	
	//This is a bit odd, yes.  Technically we're returning (and displaying on the page) Contacts in the product User section
	//It's done because the user doesn't care about any product user-specific details, other than the Contact stuff, so, yeah.
	public List<Contact> getProductUsers() {
		
		Set<Id> productUser_ContactIDs = new Set<Id>();
		productUsers = new List<Contact>();
			
		for (Product_User__c pu : [SELECT Contact__c FROM Product_User__c WHERE Contact__c != null AND Account__c = :accountID AND Status__c = 'Active']) {
			productUser_ContactIDs.add(pu.Contact__c);
		}	
				
		for (Contact c : [SELECT	
								AccountId, 
								Id,
								Name, 
								Full_Mailing_Address__c, 
								Email, 
								Title, 
								Phone,
								User_Allocations_Active__c
				 		   FROM Contact
				 		   WHERE Id IN :productUser_ContactIDs
				 		   ORDER BY LastName ASC]) {
						 	
			productUsers.add(c);
		}		
		
		return productUsers;
	}	
	
	public pageReference ReturnToAccount() {
		pgReturnPage = new ApexPages.StandardController(account).view();
		pgReturnPage.setRedirect(true);
		
		return pgReturnPage;
	}
}