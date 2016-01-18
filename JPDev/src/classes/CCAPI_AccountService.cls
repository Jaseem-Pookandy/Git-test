@RestResource(UrlMapping='/ccapi/accounts/*')
global with sharing class CCAPI_AccountService {

    public static string CONTACT_TYPE_BY_BRAND ='Product User/Main Sales Contact';
    @HttpPost
    global static AccountPostResponse createOrUpdate(
        string brand,
        string companyName,
        string phoneNumber,
        string faxNumber,
        string websiteUrl,
        ContactInfo contact,
        Address physicalAddress,
        string currencyCode
    ) {
        // cleanup incoming parameters
        if (currencyCode != null) currencyCode = currencyCode.toUpperCase();

		Account a = new Account();

        a.Customer_Segment__c = 'Direct Hire';
        a.Validation_Status__c = 'Validated';
		a.Name = companyName;
        a.CurrencyIsoCode = currencyCode;
        a.BillingCity = physicalAddress.city;
        a.BillingState = physicalAddress.state;
        a.BillingCountry = physicalAddress.country;
        a.BillingPostalCode = physicalAddress.postalCode;
        a.BillingStreet = physicalAddress.street;
        a.Phone = phoneNumber;
        a.Fax = faxNumber;
        a.Website = websiteUrl;

        
        Utils_AccountContactCreation.ReturnClass accountSaveResult = Utils_AccountContactCreation.fetchDuplicateAccounts(a); 
        if(accountSaveResult.MatchType == 'Error Encountered')
        {
        	throw new EndUserMessageException(accountSaveResult.Remark);
        }
        
       	if(accountSaveResult.MatchType == 'Existing Account')
       	{
        	// setup response
			AccountPostResponse resp = new AccountPostResponse();
			resp.AccountId = accountSaveResult.MatchedAccount.Id;
	        resp.AccountCreated = false;
	        resp.ContactCreated = false;        
	        return resp;
       	}
		

        //use the account, or the mailing address details provided on the ContactInfo object
        Contact c = buildContact(physicalAddress, contact, a.Id);
        
        Utils_AccountContactCreation.ReturnContact contactSaveResult = Utils_AccountContactCreation.fetchDuplicateContacts(c);
        if(contactSaveResult.MatchType == 'Error Encountered')
        	throw new EndUserMessageException(contactSaveResult.Remark);

        if(contactSaveResult.MatchType == 'Existing Contact')
        	c = contactSaveResult.MatchedContact;

		// assign owners to the account brand record.  this needs to be done after account created 
		// since the account brand records are created by an insert trigger on account
        Account_Brand__c accountBrand = assignAccountBrandOwnership(a.Id, brand, a.BillingCountry);

		// query to get the account number since generated on account create
        string accountNumber = [
			SELECT Account_Number__c 
			FROM Account 
			WHERE Id = :a.Id 
			LIMIT 1].Account_Number__c;
		
		// create new user group if needed 
		User_Group__c userGroup = createUserGroup(a.Id, a.Name, accountNumber, physicalAddress);
		
        // create a new product user
        Product_User__c productUser = createProductUser(a, c, userGroup, accountBrand, currencyCode);
        
        //update the contact type with the correct type
        updateContactType(c.Id, brand);
        
		// setup response
		AccountPostResponse resp = new AccountPostResponse();
		resp.AccountId = a.Id;
        resp.AccountCreated = (accountSaveResult.MatchType == 'New Account');
        resp.ContactId = c.Id;
        resp.ContactCreated = (contactSaveResult.MatchType == 'New Contact');
        resp.AccountBrandStatus = accountBrand.Status__c;
        resp.AccountNumber = accountNumber;
        resp.ProductUserGroupId = userGroup.Id;
        resp.ProductUserId = productUser.Id;
        
        return resp;
    }
    
    global class Address {
        public string street { get; set; }
        public string city { get; set; }
        public string state { get; set; }
        public string postalCode { get; set; }
        public string country { get; set; }
    }

    global class ContactInfo {
        public string firstName { get; set; }
        public string lastName { get; set; }
        public string emailAddress { get; set; }
        public string phoneNumber { get; set; }
        public Address mailingAddress {get; set;}
    }

   	global class AccountPostResponse {
        public string AccountId { get; set; }
        public Boolean AccountCreated { get; set; }
        public string ContactId { get; set; }
        public Boolean ContactCreated { get; set; }
        public string AccountBrandStatus { get; set; }
        public string AccountNumber { get; set; }
        public string ProductUserGroupId { get; set; }
        public string ProductUserId { get; set; }
    } 
	private static Contact buildContact(Address physicalAddress, ContactInfo contactInfo, string accountID)
	{
		Contact contact = new Contact();
        contact.FirstName = contactInfo.firstName;
        contact.LastName = contactInfo.lastName;        
        contact.Email = contactInfo.emailAddress;
        contact.Phone = contactInfo.phoneNumber;
        contact.AccountId = accountID;
        //Start with the billing addres on the account.
        contact.MailingStreet = physicalAddress.street;
        contact.MailingCity = physicalAddress.city;
        contact.MailingState = physicalAddress.state;
        contact.MailingPostalCode = physicalAddress.postalCode;
        contact.MailingCountry = physicalAddress.country;
        
        //If the contact info has the optional mailingAddress properties completed, use them for the contact
        if(contactInfo.mailingAddress != null 
        	&& String.isNotBlank(contactInfo.mailingAddress.street)
        	&& String.isNotBlank(contactInfo.mailingAddress.city)
        	&& String.isNotBlank(contactInfo.mailingAddress.state)
        	&& String.isNotBlank(contactInfo.mailingAddress.postalCode)
        	&& String.isNotBlank(contactInfo.mailingAddress.country))
        	{
	        	contact.MailingStreet = contactInfo.mailingAddress.street;
	        	contact.MailingCity = contactInfo.mailingAddress.city;
	        	contact.MailingState = contactInfo.mailingAddress.state;
	        	contact.MailingPostalCode = contactInfo.mailingAddress.postalCode;
	        	contact.MailingCountry = contactInfo.mailingAddress.country;
        	}
		
		return contact;		
	}
	private static void updateContactType(string contactId, string brandName)
	{
		Contact_Type__c contactType = (Contact_Type__c)[SELECT c.Type__c, c.Name, c.Id, c.Contact__c, c.Brand_Name__c, c.Account_Brand__c 
		FROM Contact_Type__c c
		WHERE c.Contact__c = :contactId
		AND Brand_Name__c = :brandName
		LIMIT 1];
		
		//set the contact type type
		contactType.Type__c = CONTACT_TYPE_BY_BRAND;
		
		update contactType;
	}
	
    private static Account_Brand__c findAccountBrand(string accountId, string brandName) {
        List<Account_Brand__c> queryResults = [
            SELECT Id, Primary_Owner__c, CS__c, Status__c
            FROM Account_Brand__c
            WHERE Account__c = :accountId
            AND Brand__r.Name = :brandName
            LIMIT 1
        ];

        for (Account_Brand__c accountBrand : queryResults) {
            return accountBrand;
        }

        return null;
    }

    public static Account_Brand__c assignAccountBrandOwnership(string accountId, string brandName, string country) {
        Account_Brand__c accountBrand = findAccountBrand(accountId, brandName);

        if (accountBrand == null) {
            throw new QueryException('Account brand not found for account ID ' + accountId + ' and brand name ' + brandName);
        }

        if (accountBrand.Primary_Owner__c != null && accountBrand.CS__c != null) {
            return accountBrand;
        }

        Map<string, string> params = new Map<string, string>();

        params.put('Brand', brandName);

        if (country.length() > 3) {
            params.put('CountryName', country);
        } else {
            params.put('CountryISO', country);
        }

        RESTOwnershipAssignment.ReturnClass ownershipAssignment = RESTOwnershipAssignment.OperationHandler(params);

        if (ownershipAssignment == null ||
            string.isBlank(ownershipAssignment.primaryOwnerId) ||
            string.isBlank(ownershipAssignment.supportOwnerId)) {
            throw new QueryException('Ownership assignment not found for brand name ' + brandName + ' and country ' + country);
        }

        if (accountBrand.Primary_Owner__c == null) {
            accountBrand.Primary_Owner__c = ownershipAssignment.primaryOwnerId;
        }

        if (accountBrand.CS__c == null) {
            accountBrand.CS__c = ownershipAssignment.supportOwnerId;
        }

        upsert accountBrand;
        
        return accountBrand;
    }

	private static User_Group__c createUserGroup(string accountId, string accountName, string accountNumber, Address physicalAddress)
	{
	    // query to see if we already have a user group created
		List<User_Group__c> queryResults = [
			SELECT Id 
			FROM User_Group__c 
			WHERE Account__c = :accountId 
			AND Group_Id_Assigned__c = :accountNumber
			LIMIT 1
		];
		
		for (User_Group__c userGroup : queryResults) {
			return userGroup;
		}
		
        // create new user group 
		String userGroupDescription = String.format('{0}: {1}: {2}: {3}', new List<String>{
			accountName,
			physicalAddress.city,
			physicalAddress.state,
			accountNumber
		});
        User_Group__c newUserGroup = new User_Group__c();
		newUserGroup.Group_Id_Assigned__c = accountNumber;
        newUserGroup.Name = accountNumber;
        newUserGroup.Account__c = accountId;
		newUserGroup.Description__c = userGroupDescription;
        insert newUserGroup;	
		
		return newUserGroup;
	}
	
	private static Product_User__c createProductUser(Account account, Contact contact, User_Group__c userGroup, Account_Brand__c accountBrand, string currencyCode)
	{
	    // query to see if we already have a product user created
		List<Product_User__c> queryResults = [
			SELECT Id 
			FROM Product_User__c 
			WHERE User_Group__c = :userGroup.Id  
			AND Contact__c = :contact.Id
			AND Account__c = :account.Id
			LIMIT 1
		];
		
		for (Product_User__c productUser : queryResults) {
			return productUser;
		}
		
		// create a new product user
        Product_User__c newProductUser = new Product_User__c();
        newProductUser.CurrencyIsoCode = currencyCode;
        newProductUser.Role__c = 'Team Administrator';
        newProductUser.Status__c = 'Active';
        newProductUser.Account__c = account.Id;
        newProductUser.Account_Brand__c = accountBrand.Id;
        newProductUser.Contact__c = contact.Id;
        newProductUser.User_Group__c = userGroup.id;
		newProductUser.Username__c = contact.Email;
        newProductUser.Start_Date__c = Date.today();
        newProductUser.End_Date__c = Date.today().addYears(1);
		// productUser.Brand__c = brand;  - TODO:  listed in resource mapping but cant compile.  Error:Field is not writeable: Product_User__c.Brand__c
		// productUser.Country__c = physicalAddress.country;  - TODO:  listed in resource mapping but cant compile.  Error:Field is not writeable: Product_User__c.Country__c
        insert newProductUser;
	
		return newProductUser;
	}
	
    global class EndUserMessageException extends Exception {}
}