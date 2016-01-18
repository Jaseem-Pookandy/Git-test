/*******************************************************************************
Name        : EmailMessageTriggerHandler_Test
Description : Test Class for EmailMessageTriggerHandler.
Author      : Naresh Kr. Ojha (Appirio Offshore)
Date        : Apr 11th, 2013
*******************************************************************************/
@isTest
private class EmailMessageTriggerHandler_Test {

    static testMethod void allScenario_Test() {
    	
    	TestUtils.CreateCustomSettingsRecords();
    	TestUtils.createEmailHandlerRecords('Blahblah', 'EmailTgrHandler');
    	
      TestUtils.createBrands();

      TestUtils.createDomaintoBrandMap();

	    Account testAccount = TestUtils.createAccount();
//	    List<Case> caseList = new List<Case>();
	    insert testAccount;

	    //Contact
	    List<Contact> contactList = TestUtils.createContacts(testAccount, 1);
      contactList.get(0).Email = 'bussys@dice.com';
      contactList.get(0).Alternate_Email__c = 'test_emmsg0002@abc.com';
	    insert contactList;
      
      Case newCase = new Case();
      // do not add a contact - so that we fall through the build a dummy contact code.
      newCase.AccountId = testAccount.ID;
      newCase.Subject = 'Test subject 00001';
      newCase.Origin = Constants.CASEORIGIN_CUSTOMER;
      newCase.SuppliedEmail = 'chris.andrews@dice.com';
      insert newCase;
      
      EmailMessage[] newEmail = new List<EmailMessage>();
      newEmail.add(new EmailMessage(FromAddress = 'sample.user@metacube.com', 
                                    Incoming = True, 
                                    ToAddress= 'support@dice.com', 
                                    Subject = 'Test email-to-case 001001', 
                                    TextBody = '23456 ', ParentId = newCase.Id)); 

      Test.startTest();
      insert newEmail;
      
      Case assertCase = [SELECT Assign_to_CSR__c, Brand__c, Domain__c, Recipient__c FROM Case WHERE ID =: newCase.ID];
      System.assertEquals(assertCase.Assign_to_CSR__c, true);
      System.assertEquals(assertCase.Brand__c, Constants.BRAND_DICE);
      System.assertEquals(assertCase.Domain__c,'dice.com');
      System.assertEquals(assertCase.Recipient__c,'support');
      
      newCase = new Case();
      newCase.AccountId = testAccount.ID;
      newCase.ContactId = contactList.get(0).ID;
      newCase.Subject = 'Test subject 00002';
      newCase.Brand__c = Constants.BRAND_CJ;
      newCase.Origin = Constants.CASEORIGIN_CUSTOMER;
      newCase.SuppliedEmail = 'no@thanks.dice.com';
      insert newCase;
 
	    EmailMessage[] newEmail2 = new List<EmailMessage>();
	    newEmail2.add(new EmailMessage(FromAddress = 'test_emmsg0002@dice.com', 
	                                   Incoming = True, 
	                                   ToAddress= 'DoNotSent@clearancejobs.com', 
	                                   Subject = 'Test email-to-case 001002', 
	                                   TextBody = '23456222 ', 
	                                   ParentId = newCase.Id)); 
	    insert newEmail2;

      Test.stopTest();
    }
}