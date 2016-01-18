/****
*Class            Utils_AccountContactCreation_Test
*Author           @GMwamsoyo
*Story            CCBOB-88
*Date             11/04/2015
*Description      Unit Test class for Utils_AccountContactCreation 
-----------------------------Modifications Updates ------------------------------

***/
@isTest(SeeAllData=false)
private class Utils_AccountContactCreation_Test {
    static Id newAccountId;
    static testMethod void myUnitTest() {
        User testUser = [SELECT Id, Alias, Email, AD_Username__c, Lastname, UserName 
                   FROM User WHERE UserName='dhi_platform_api@dhigroupinc.com.partial'
                   OR UserName='dhi_platform_api@dhigroupinc.com.full'
                   OR UserName='dhi_platform_api@dhigroupinc.com'];

        test.startTest();
        System.runAs(testUser) {
           CreateAccount();
           CreateContact();
        }
        test.stopTest();   
    }  
  static void CreateAccount() {
         Account account1 = new Account(Name = 'Sample Account', 
                                  BillingStreet = '101 Main Steet', 
                                  BillingCity = 'Urbandale', 
                                  BillingState = 'Iowa',  
                                  BillingPostalCode = '50322', 
                                  BillingCountry = 'United States', 
                                  Phone = '515-313-2245');    
         Account account2 = new Account(Name = 'Sample Account', 
                                  BillingStreet = '101 Main Steet', 
                                  BillingCity = 'Urbandale', 
                                  BillingState = 'Iowa',  
                                  BillingPostalCode = '50322', 
                                  BillingCountry = 'United States', 
                                  Phone = '515-313-2245');          
         Account account3 = new Account(Name = 'Sample Account', 
                                  BillingStreet = '101 Main Steet', 
                                  BillingCity = 'Urbandale', 
                                  BillingState = 'Iowa3',  
                                  //BillingPostalCode = '50322',  //Cause error when not rovided
                                  BillingCountry = 'United States', 
                                  Phone = '515-313-2245');                                     
 
       Utils_AccountContactCreation.ReturnClass returnClass;
       returnClass = Utils_AccountContactCreation.fetchDuplicateAccounts(account1); 
       newAccountId =  ID.valueOf(returnClass.Id);
       System.AssertEquals(returnClass.MatchType, 'New Account');
       returnClass = Utils_AccountContactCreation.fetchDuplicateAccounts(account2); 
       System.AssertEquals(returnClass.MatchType, 'Existing Account');
      returnClass = Utils_AccountContactCreation.fetchDuplicateAccounts(account3); 
      System.AssertEquals(returnClass.MatchType, 'Error Encountered');
    }
    static void CreateContact()
    {
         Account account0 = new Account(Name = 'Sample Account', 
                                  BillingStreet = '101 Main Steet', 
                                  BillingCity = 'Urbandale', 
                                  BillingState = 'Iowa',  
                                  BillingPostalCode = '50322', 
                                  BillingCountry = 'United States', 
                                  Phone = '515-313-2245');  

        Contact contact1 = New Contact(email='saimogili066@gmail.com',
                        Firstname = 'John',
                        Lastname = 'Doe',
                        MailingStreet = '101 Main Street',
                        MailingCity = 'Urbandale',
                        MailingState ='Iowa',
                        MailingPostalCode = '50322',
                        MailingCountry ='United States',
                        Phone='515-313-2245',
                        AccountId = newAccountId);
        
        Contact contact2 = New Contact(email='saimogili066@gmail.com',
                        Firstname = 'John',
                        Lastname = 'Doe',
                        MailingStreet = '101 Main Street',
                        MailingCity='Urbandale',
                        MailingState='Iowa',
                        MailingPostalCode='50322',
                        MailingCountry='United States',
                        Phone='515-313-2245',
                        AccountId = newAccountId);
            
        Contact contact3 = New Contact(/*email='saimogili066@gmail.com', */
                        Firstname = 'John',
                        //Lastname = 'Doe',
                        MailingStreet='101 Main Street',
                        MailingCity='Urbandale',
                        MailingState='Iowa',
                        MailingPostalCode='50322',
                        MailingCountry='United States',
                        Phone='515-313-2245');
       Utils_AccountContactCreation.ReturnContact returnContact;
       returnContact = Utils_AccountContactCreation.fetchDuplicateContacts(contact1); 
       System.AssertEquals(returnContact.MatchType, 'New Contact');
      returnContact = Utils_AccountContactCreation.fetchDuplicateContacts(contact2); 
      System.AssertEquals(returnContact.MatchType, 'Existing Contact');
      returnContact = Utils_AccountContactCreation.fetchDuplicateContacts(contact3); 
      System.AssertEquals(returnContact.MatchType, 'Error Encountered');
    }
  }