/***************************************************************************
// (c) 2012 Appirio, Inc.
//
// Description    : Utility class to help on creation of objects for test classes.                  
//                  
// Dec 13th, 2012    Karun Gangwani(Appirio Off)
//  
-----------------------------Modifications Updates ------------------------------
*Author           @GMwamsoyo
*Story            CCBOB-
*Date             13/17/2015
*Description      Review creation of basic objects to match existing  validations and new functionalities

//***************************************************************************/

public class TestUtils {
	
  //================================================================//
  // Create a new Account (This method will not do any DML operation)
  //================================================================//
  public static Account createAccount(){
    Account account = new Account(Name = 'Test');
    account.Status__c = 'Active';
    account.Phone = '9829198291';
    account.BillingCity = 'Jaipur';
    account.BillingStreet = 'test street';
    account.BillingState = 'Rajasthan';
    account.BillingCountry = 'India';
    account.BillingPostalCode = '302022';
    return account;
  }

  //================================================================//
  // Create multiple new Accounts based on passed paramter (max 10)
  //================================================================//
  public static List<Account> createAccounts(integer counter){
  	if(counter == null || counter < 1) counter = 1;
  	if(counter > 10) counter = 10;
  	List<Account> acctLst = new List<Account>();
  	for(integer i = 1; i <= counter; i++)
  	{
  		acctLst.add( new Account(Name = 'Sample Account ' + i,
  								 BillingStreet = '101 Main Steet', 
                                 BillingCity = 'Urbandale', 
                                 BillingState = 'Iowa',  
                                 BillingPostalCode = '50322', 
                                 BillingCountry = 'United States', 
                                 Phone = '515-313-224' + i)
  		           );
  	}
    return acctLst;
  }

  public static void createEmailHandlerRecords(string accountName, string migrationID){
    Account account = new Account(Name = accountName);
    account.Status__c = 'Active';
    account.Phone = '9829198291';
    account.BillingCity = 'Jaipur';
    account.BillingStreet = 'test street';
    account.BillingState = 'Rajasthan';
    account.BillingCountry = 'India';
    account.BillingPostalCode = '302022';
    account.Migration_Id__c = migrationID;
    //insert account;
    
    Contact c = new Contact();
	c.AccountId = account.Id;
	c.Migration_Id__c = migrationID;
	c.FirstName = 'FirstName';
	c.LastName = 'LastName';
	c.MailingCity = 'Test';
	c.MailingState = 'Test State';
	c.MailingPostalCode = '110011';
	c.MailingCountry = 'India';			
	c.Language__c = 'English';
	c.Email = 'no@thanks.dice.com';
	//insert c;
	
	//Insert CaseAutoResponseRule now...
	CaseAutoResponseRule__c car = new CaseAutoResponseRule__c();
	car.CaseOrigin__c = 'Email - Customer';
	car.SenderEmail__c = 'support@dice.com';
	car.EmailTemplate__c = 'Dice_Email_Customer';
	car.ReplyToEmail__c = 'supportgroup@dice.com';
	car.Enabled__c = true;
	car.Brand__c = 'Dice';
	car.SenderName__c = 'Dice Customer Support';
	car.Name = 'Dice Customer Support';
	car.CurrencyIsoCode = 'USD';
	car.SortOrder__c = 1;
	insert car;
	car = new CaseAutoResponseRule__c();
	car.CaseOrigin__c = 'Email - Customer';
	car.SenderEmail__c = 'support@clearancejobs.com';
	car.EmailTemplate__c = 'ClearanceJobs_Email_Customer';
	car.ReplyToEmail__c = 'supportgroup@dice.com';
	car.Enabled__c = true;
	car.Brand__c = 'ClearanceJobs';
	car.SenderName__c = 'ClearanceJobs Customer Support';
	car.Name = 'ClearanceJobs Customer Support';
	car.SortOrder__c = 2;
    insert car;
  }    
  
  public static Profile usrProfile(){ return TestUtils.usrProfile('System Administrator'); }
  public static Profile usrProfile (String profileName){ return [SELECT Id, Name FROM Profile WHERE Name =: profileName LIMIT 1]; }
  
  //==========================================================//
  //Create a new User (It will not make any DML operation)
  //==========================================================//  
  public static User createUser (String lastName, String firstName , String email, String userName,
                                      String alias, String nickName, Id profileId, String adUsername){
     
     User pUsr = new User(LastName = lastName, FirstName = firstName, Email = email,
                            UserName = userName, Alias = alias, CommunityNickName = nickName, TimeZoneSidKey = 'America/New_York', 
                              LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', ProfileId = profileId, LanguageLocaleKey = 'en_US', 
                              AD_Username__c = adUsername, DefaultBrand__c = 'Dice', Default_BrandTag__c = 'Dice', IsActive = true);       
     return pUsr;
  }

  //=============================================================//
  //Returns a map of Name and ID of Brand__c
  //=============================================================//
  public static Map<String, Brand__c> getBrands() {
    Map<String, Brand__c> brID_BrandMap = new Map<String, Brand__c>();
     for(Brand__c br : [SELECT Name, ID FROM Brand__c]) {
      if(!brID_BrandMap.containsKey(br.Name)) {
        brID_BrandMap.put(br.Name, br);
      }
    }
    
    return brID_BrandMap;
  }
  /*****************************************************************************
    Method Name : createOpportunity  
    Description : Contain actions need to create an Opportunity
  *****************************************************************************/
	public static Opportunity createOpportunity(String name, Account acc){
		Opportunity opportunity = new Opportunity();
		opportunity.Name = name;
		opportunity.CloseDate = Date.today().addDays(5);
		opportunity.AccountId = acc.Id;
		opportunity.StageName = 'Working';
        opportunity.BrandTag__c = 'Dice';
        opportunity.Primary_Brand__c = 'Dice';
		return opportunity;
	}
	
	/*****************************************************************************
    Method Name : createContacts 
    Description : Contain actions need to create contacts
  *****************************************************************************/
	public static List<Contact> createContacts(Account account, Integer contactCount){
		List<Contact> contactList = new List<Contact>();
		Contact contact;		
		for(Integer i = 1; i <= contactCount; i++) {
			contact = new Contact();
			contact.AccountId = account.Id;
			contact.FirstName = 'FirstName_'+i;
			contact.LastName = 'LastName_'+i;
			contact.MailingCity = 'Test';
			contact.MailingState = 'Test State';
			contact.MailingPostalCode = '110011';
			contact.MailingCountry = 'India';			
			contact.Language__c = 'English';		//byrnes
			contact.Email = 'no' + i + '@thanks.dice.com';	//byrnes
			contactList.add(contact);
		}
		return contactList;
	}
	
	/*****************************************************************************
    Method Name : createTasks
    Description : Contain actions need to create tasks
  *****************************************************************************/
	public static List<Task> createTasks(Id whoID, Id whatID, String brandName, Integer taskCount){
		List<Task> taskList = new List<Task>();
		Task t;		
		Integer j = -1;
		for(Integer i =1 ; i <= taskCount; i++) {
			t = new Task();
			if (whoID != null) t.WhoId = whoID;
			if (whatID != null) t.WhatId = whatID;
			
        	t.Subject = 'Testing ' + i;
        	t.Status = 'Not Started';
        	t.Type = 'Complaint';
        	t.Brand__c = brandName;
        	t.ActivityDate = system.today().adddays(i);
        	taskList.add(t);
		}
		return taskList;
	}
	
	/****************************************************************************
	* Method to create Brands
	****************************************************************************/
	public static List<Brand__c> createBrands() {
		List<Brand__c> brandList = new List<Brand__c>();
		Brand__c brand = new Brand__c(isActive__c = true, Name = 'Dice', External_Id__c = 'DiceTest');
		brandList.add(brand);
		brand = new Brand__c(isActive__c = true, Name = 'ClearanceJobs', External_Id__c = 'CJTest');
		brandList.add(brand);
		brand = new Brand__c(isActive__c = true, Name = 'eFinancialCareers', External_Id__c = 'eFCTest');
		brandList.add(brand);
		brand = new Brand__c(isActive__c = true, Name = 'HealthCallings', External_Id__c = 'HCTest');
		brandList.add(brand);
		brand = new Brand__c(isActive__c = true, Name = 'Rigzone', External_Id__c = 'RZTest');
		brandList.add(brand);
		insert brandList;
		return brandList;
	}
	
	public static void CreateCustomSettingsRecords() {
		
		List<CreditCardPaymentSettings__c> ccps = new List<CreditCardPaymentSettings__c>();
		
		CreditCardPaymentSettings__c c = new CreditCardPaymentSettings__c();
		c.Name = Constants.BASE_PAYMENT_ADDRESS_URL;
		c.URL__c = 'https://payments.diceholdings.com/index.php?id=';
		ccps.add(c);
		
		CreditCardPaymentSettings__c c2 = new CreditCardPaymentSettings__c();
		c2.Name = Constants.ENCRYPTION_URL_NAME;
		c2.URL__c = 'https://payments.diceholdings.com/services.php?action=encrypt&id=';
		ccps.add(c2);
		
		insert ccps;
		
		List<CreditCardPaymentGateways__c> cpg = new List<CreditCardPaymentGateways__c>();
		CreditCardPaymentGateways__c cg = new CreditCardPaymentGateways__c();
		cg.Approved__c = true;
		cg.Gateway__c = '_Paymentech_Gateway';
		cg.Name = 'Paymentech';
		cpg.add(cg);
		
		CreditCardPaymentGateways__c cg2 = new CreditCardPaymentGateways__c();
		cg2.Approved__c = true;
		cg2.Gateway__c = '_WorldPay_Gateway';
		cg2.Name = 'Worldpay';
		cpg.add(cg2);
		
		insert cpg;
		
		List<GlobalFlags__c> flags = new List<GlobalFlags__c>();
		//global flag for deletion logic.
	    GlobalFlags__c gf = new GlobalFlags__c();
	    gf.Enabled__c = false;
	    gf.Name = 'AB Deletion - Admins Ignore Constraint';
	    flags.add(gf);
	    
	    gf = new GlobalFlags__c();
      	gf.Enabled__c = true;
      	gf.Name = 'Case Auto Response';
      	flags.add(gf);
      	
      	gf = new GlobalFlags__c();
      	gf.Enabled__c = true;
      	gf.Name = 'Sync Account Address Edits to Contacts';
      	flags.add(gf);

      	insert flags;

      	Training_Backup_User__c tu = new Training_Backup_User__c();
      	User backupUser = [SELECT Id, Name FROM User WHERE IsActive = true LIMIT 1];
      	tu.Name = backupUser.Name;
      	tu.UserID__c = backupUser.Id;      	
      	insert tu;
	}  	
	/****************************************************************************
	* Method to create Doimain_to_Brand_Map records
	****************************************************************************/
	public static void createDomaintoBrandMap() {
		List<Domain_to_Brand_Map__c> d2blist = new List<Domain_to_Brand_Map__c>();
		Map<String, ID> brandList = new Map<String, ID>();

		for (Brand__c brandrec: [Select Name, ID from Brand__c WHERE isActive__c = true]){
			if (!brandList.containsKey(brandrec.Name)) {
				brandList.put(brandrec.Name, brandrec.ID);
			}
		}

		Domain_to_Brand_Map__c d2b = new Domain_to_Brand_Map__c(is_Active__c = true, Domain_Name__c = 'dice.com', Brand__c = brandList.get('Dice'));
		d2blist.add(d2b);
		d2b = new Domain_to_Brand_Map__c(is_Active__c = true, Domain_Name__c = 'clearanceJobs', Brand__c = brandList.get('ClearanceJobs'));
		d2blist.add(d2b);
		d2b = new Domain_to_Brand_Map__c(is_Active__c = true, Domain_Name__c = 'efinancialcareers', Brand__c = brandList.get('eFinancialCareers'));
		d2blist.add(d2b);
		d2b = new Domain_to_Brand_Map__c(is_Active__c = true, Domain_Name__c = 'rigzone', Brand__c = brandList.get('Rigzone'));
		d2blist.add(d2b);
		insert d2blist;
	}		

	/****************************************************************************
	* Method to create User Group record
	****************************************************************************/
	public static User_Group__c createUserGroup(Account account) {
        User_Group__c userGroup = new User_Group__c(Account__c = account.Id, Company_Display_Name__c = 'FileWall USA Inc.', 
                                 CurrencyIsoCode = 'USD', Description__c = 'FileWall USA Inc.', Name = 'FileWall USA Inc.');
        insert userGroup;
        return userGroup;
     }	

	/****************************************************************************
	* Method to create Product User record
	****************************************************************************/
	public static Product_User__c createProductUser(User_Group__c userGroup, Account_Brand__c accountBrand, Contact contact) {

        Product_User__c productUser = new Product_User__c(Account__c = accountBrand.Account__c, Account_Brand__c = accountBrand.Id, 
                    Contact__c = contact.Id, Start_Date__c = System.today(), End_Date__c = System.today().addMonths(12), 
                    isContact_on_Different_Account__c = false, No_Contact_Ref__c = false, Role__c = 'Job Poster',                     
                    Status__c = 'Active', User_Group__c = userGroup.Id, Username__c = 'productUser1@example.dice.com',
                    Initial_Password__c = 'abcd1234', Send_Credentials__c = false);
        insert productUser;
        return productUser;
    }

	/****************************************************************************
	* Method to create Webstorerecord
	****************************************************************************/
	public static Webstore_Order__c createWebstoreOrder(User_Group__c userGroup, Account_Brand__c accountBrand, Contact contact) {

        Webstore_Order__c wso = new Webstore_Order__c(Account__c = accountBrand.Account__c, Account_Brand__c = accountBrand.Id, 
            Contact__c = contact.Id, User_Group__c = userGroup.Id, Address_Line_1__c = '10711 Main St', 
            Address_Line_2__c = 'Suite 250', City__c = 'Fishers', City_HQ__c = 'Fishers', Company__c = 'FileWall USA Inc.', 
            Contract_Value__c = 650.00, Country__c = 'US', Country_HQ__c = 'US', CurrencyIsoCode = 'USD',    
            Email__c = 'samsheinz@filewall.com', External_Account_ID__c = 'RTX0f97d1', First_Name__c = 'Sams', Initial_Term__c = 12,   
            Invoice_TemplateId__c = '2c92a0f943b129010143b1b63c907f7d', Invoice_TemplateName__c = 'Dice_English_USD', 
            IsVerified__c = false, Last_Name__c = 'Heinz', Order_ID__c = '135808135204-1', 
            Payment_Gateway__c = 'Dice_USD_Paymentech_Gateway',  Phone__c = '5151010202', Postal_Code__c = '50654', 
            Purchase_Date__c = System.Now(),  State__c  = 'IA', Status__c = 'Pending', Verification_Status__c = 'No Match', 
            Website__c  = 'www.newgroup.com');
        insert wso;
        return wso;
    }

	/****************************************************************************
	* Method to create Zuora Quote Product record
	****************************************************************************/
	public static zqu__ZProduct__c createZuoraQuoteProduct(String BrandName, String Name, String isCommissionable, String ProductGroup,
		                                                   String SubCategory, String Category, String SKU, String ZuoraId) {
		zqu__ZProduct__c zproduct = new zqu__ZProduct__c(Brand__c = BrandName, Name = Name, ProductforCommission__c = isCommissionable, 
		  	                                             ProductGroup__c = ProductGroup, zqu__Category__c = Category, 
		  	                                             ProductSubCategory__c = SubCategory, zqu__SKU__c = SKU, zqu__ZuoraId__c = ZuoraId);
		insert zproduct;
		return zproduct;
	}

	/****************************************************************************
	* Method to create Webstorerecord
	****************************************************************************/
	public static Webstore_Order_Line__c createWebstoreOrderLine(Webstore_Order__c wso, zqu__ZProduct__c product, integer quantity){
		Webstore_Order_Line__c wsol = new Webstore_Order_Line__c(End_Date__c = Date.today().AddMonths(12), Quantity__c = quantity,
                                                                 SKU__c  = product.zqu__SKU__c, Start_Date__c = Date.today(), Webstore_Order__c = wso.Id, 
                                                                 ZProduct__c = product.Id);
        insert wsol;
        return wsol;
	}
}