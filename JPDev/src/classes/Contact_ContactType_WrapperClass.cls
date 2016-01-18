public with sharing class Contact_ContactType_WrapperClass {

	public Contact ContactRecord {get; set;}
	public List<Contact_Type__c> ContactTypes {get; set;}
	
	public Contact_ContactType_WrapperClass() {
		ContactRecord = new Contact();
		ContactTypes = new List<Contact_Type__c>();
	}
	
	public Contact_ContactType_WrapperClass(Contact C) {
		ContactRecord = C;
		ContactTypes = new List<Contact_Type__c>();
	}
}