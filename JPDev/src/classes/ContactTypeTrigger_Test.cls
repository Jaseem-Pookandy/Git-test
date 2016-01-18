/*******************************************************************************
Name        : ContactTypeTrigger_Test
Description : Test Class for ContactTypeTriggerHandler.
Author      : Byrnes, Doextra Des Moines
Date        : 2013.08.02
*******************************************************************************/
@isTest
private class ContactTypeTrigger_Test 
{
    static List<Contact> contactList = new List<Contact>();
    static List<Brand__c> brandList = new List<Brand__c>();    
    
    public static testMethod void myUnitTest() {
        //Creating Test data
        createTestData();
        
        //Query newly inserted contacts
        List<Contact> newContacts = [SELECT Title, Job_Title__c FROM Contact 
                                     WHERE Id in :contactList];
          
        /*List<Contact_Type__c> CTList = [SELECT ID, Contact__c FROM Contact_Type__c
                                        WHERE Contact__c in :newContacts 
                                        ];
        System.assertEquals( 4, CTList.size() ); 
        
        //Update first contact's title
        newContacts.get(0).Title = 'testJobTitle2';
        update newContacts.get(0);
        
        //Verify that Job_Title__c also becomes same as Title.
        Contact updatedContact = [SELECT id, Title, Job_Title__c FROM Contact
                                  WHERE id = :newContacts.get(0).id];   
        System.assertEquals( updatedContact.Title, 
                             [SELECT Name FROM Job_Title__c 
                              WHERE Id = :updatedContact.Job_Title__c].Name); */      
                              
       	test.startTest();
       	
       	List<Contact_Type__c> cTypes = [SELECT Id, Never_Email__c, Contact__c FROM Contact_Type__c WHERE Contact__c IN : newContacts];
       	
       	List<Contact_Type__c> updatedCTs = new List<Contact_Type__c>();
       	
       	ContactTriggerHelper.isFirstRun = true;
       	Integer i = 0;
       	
       	for (Contact_Type__c ct : cTypes)
       	{
       		i++;
       		if (math.mod(i, 2) == 0)
       		{
       			ct.Never_Email__c = true;
       			updatedCTs.add(ct);
       		}
       	}
       	
       	update updatedCTs;
       	
       	test.stopTest();
       	
       	delete updatedCTs;                                                                                                        
    }
    
    private static void createTestData() 
    {             
        List<Job_Title__c> jobTitleList = new List<Job_Title__c>();
      
        Job_Title__c jobTitle = new Job_Title__c();
        jobTitle.Name = 'testJobTitle1';
        jobTitleList.add(jobTitle);
        
        jobTitle = new Job_Title__c();
        jobTitle.Name = 'testJobTitle2';
        jobTitleList.add(jobTitle);
        
        insert jobTitleList;
        
        //Create Brand__c       
        
        Brand__c brand = new Brand__c();
        brand.Name = 'Brand1';
        brand.External_Id__c = 'B001';
        brand.CurrencyIsoCode = 'USD';
        
        brandList.add(brand);
        
        brand = new Brand__c();
        brand.Name = 'Brand2';
        brand.External_Id__c = 'B002';
        brand.CurrencyIsoCode = 'USD';
        
        brandList.add(brand);
        
        insert brandList; 
        
        //Create Account 
        Account account = new Account();
        account.Name = 'testAccount';
        account.BillingStreet = 'TestStreet';
        account.BillingCity = 'TestCity';
        account.BillingState = 'TestState';
        account.BillingCountry = 'TestCountry';
        account.BillingPostalCode = '99999';
        
        insert account;
        
        //Create contacts
        Contact contact = new Contact();
        contact.AccountId = account.id;
        contact.LastName = 'LName1';
        contact.Title = 'testJobTitle1';    
        contact.No_Email__c = false;
        
        contactList.add(contact);
        
        contact = new Contact();
        contact.AccountId = account.id;
        contact.LastName = 'LName2';
        contact.Title = 'testJobTitle1';    
        
        contactList.add(contact);   
        
        insert contactList;
                                
    }
}