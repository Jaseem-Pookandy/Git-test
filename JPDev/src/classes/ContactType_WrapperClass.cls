public with sharing class ContactType_WrapperClass {

  public Contact_Type__c CTRecord {get; set;}
  public String Brand {get; set;}
    
  public ContactType_WrapperClass() {
    CTRecord = new Contact_Type__c();
  }
  
}