/*******************************************************************
Name  : EnterpriseServicesController_Test
Author: Byrnes
Date  : 2014.03.05
*************************************************************************/
@isTest(seeAllData=true)
private class EnterpriseServicesController_Test {

    static testMethod void testMethod1() {
    
    	//CreateData();    

      EnterpriseServicesController controller = new EnterpriseServicesController();        
    
    	PageReference pg = controller.BeginTheAudit();
    }

	public static void CreateData() {

		//Creating brands
    TestUtils.createBrands();
    		        
    //Account
    Account testAccount = TestUtils.createAccount();
    insert testAccount;

    //Contact
    List<Contact> contactList = TestUtils.createContacts(testAccount, 1);
    insert contactList;

    //Fetching account brand for Oppty
    //List<Account_Brand__c> abList = [Select ID FROM Account_Brand__c WHERE Account__c =: testAccount.ID];
    List<Account_Brand__c> abList = createABList(testAccount);
    //Opportunity
    Opportunity testOppty = TestUtils.createOpportunity('Test Opty 001', testAccount);
    testOppty.Contact__c = contactList.get(0).ID;
    testOppty.Account_Brand__c = abList.get(0).ID;
    testOppty.Validation_Rule_Override__c = DateTime.now().addDays(4);
    testOppty.Renewal_Owner_Assigned__c = UserInfo.getUserId();
    insert testOppty;
    
    zqu__Quote__c quote = new zqu__Quote__c();
    quote.Name = 'Test Quote';
    quote.zqu__Opportunity__c = testOppty.ID;
    quote.IsSyncing__c = true;
    quote.zqu__BillToContact__c = contactList.get(0).ID;
    quote.zqu__SoldToContact__c = contactList.get(0).ID;
    quote.zqu__PaymentMethod__c = 'Credit Card';
    quote.zqu__PaymentTerm__c = 'Net 30';
    quote.zqu__InitialTerm__c = 3;
    quote.zqu__RenewalTerm__c = 3;
    quote.zqu__Status__c = 'Sent to Z-Billing';
    quote.zqu__ZuoraAccountID__c = '12345678901234567890123456789012';
    insert quote;
    
    testOppty.SyncedQuote__c = quote.ID;
    update testOppty;

    //Unfortunately history can't be used in a test class so this is moot...  
    Contact c = new Contact(ID=contactList[0].ID, MailingCity='Changed City', MailingStreet='123 Changed St.');
    update c;

	} 

	private static List<Account_Brand__c> createABList(Account testAccount) {
  		List<Account_Brand__c> accBrandList = new List<Account_Brand__c>();
  		testAccount = [SELECT Migration_Id__c From Account Where ID = :testAccount.Id];
  		Profile sysAdmin = TestUtils.usrProfile('System Administrator');
      	List<User> userList = new List<User>();      
      	User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                          'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
	    userList.add(adminUser);        
	    User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
	                      'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id,'testUser_adName2');
	    userList.add(adminUser2);
	    User adminUser3 = TestUtils.createUser('lname3','firstName3', 'email3@c.com',
	                      'tests3@b0.com', 'test3', 'nickName3', sysAdmin.Id,'testUser_adName3');
	    userList.add(adminUser3);
	            
	    insert userList;    
          Account_Brand__c abObj = new Account_Brand__c();
          abObj.Brand_Picklist__c = 'Dice';
          abObj.Account__c = testAccount.Id;
          abObj.Primary_Owner__c = userList.get(0).Id;
          abObj.CS__c = userList.get(1).Id;
          abObj.Status__c = 'Active';
          accBrandList.add(abObj);
       insert accBrandList;
    return accBrandList; 
  } 		
}