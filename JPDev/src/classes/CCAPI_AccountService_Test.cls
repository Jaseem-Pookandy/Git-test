@isTest(SeeAllData=true)
private class CCAPI_AccountService_Test {

    static testMethod void testMethodValidAccountCreated() {
        CCAPI_AccountService.Address address = new CCAPI_AccountService.Address();
        CCAPI_AccountService.ContactInfo contactInfo = new CCAPI_AccountService.ContactInfo();

        contactInfo.firstName = 'Brian';
        contactInfo.lastName = 'Klinker';
        contactInfo.emailAddress = 'brian.klinker@dhigroupinc.com';
        contactInfo.phoneNumber = '1231231235';

        address.street = '22 Test Rd';
        address.city = 'Prosper';
        address.state = 'TX';
        address.postalCode = '75078';
        address.country = 'US';

        CCAPI_AccountService.AccountPostResponse response = CCAPI_AccountService.createOrUpdate(
            'eFinancialCareers',
            'Test company name',
            '1231231234',
            '9879879876',
            'www.dhigroupinc.com',
            contactInfo,
            address,
            'USD'
        );

        System.assert(response.AccountID != null, 'Account ID should not be null');
    }

    static testMethod void testMethodLowerCaseCurrencyCodeAccountCreated() {
        CCAPI_AccountService.Address address = new CCAPI_AccountService.Address();
        CCAPI_AccountService.ContactInfo contactInfo = new CCAPI_AccountService.ContactInfo();

        contactInfo.firstName = 'Brian';
        contactInfo.lastName = 'Klinker';
        contactInfo.emailAddress = 'brian.klinker@dhigroupinc.com';
        contactInfo.phoneNumber = '1231231235';

        address.street = '1234 a st';
        address.city = 'Prosper';
        address.state = 'TX';
        address.postalCode = '75078';
        address.country = 'US';

        CCAPI_AccountService.AccountPostResponse response = CCAPI_AccountService.createOrUpdate(
            'eFinancialCareers',
            'Test company name',
            '1231231234',
            '9879879876',
            'www.dhigroupinc.com',
            contactInfo,
            address,
            'usd'
        );

        System.assert(response.AccountID != null, 'Account ID should not be null');
    }

     static testMethod void testMethodInvalidEmailFails() {
        CCAPI_AccountService.Address address = new CCAPI_AccountService.Address();
        CCAPI_AccountService.ContactInfo contactInfo = new CCAPI_AccountService.ContactInfo();

        contactInfo.firstName = 'blahtestblah';
        contactInfo.lastName = 'blahtestblah';
        contactInfo.emailAddress = 'blahtestblah';
        contactInfo.phoneNumber = '1231231235';

        address.street = '1234 a st';
        address.city = 'Prosper';
        address.state = 'TX';
        address.postalCode = '75078';
        address.country = 'US';

        try {
            CCAPI_AccountService.AccountPostResponse response = CCAPI_AccountService.createOrUpdate(
                'eFinancialCareers',
                'Test company name',
                '1231231234',
                '9879879876',
                'www.dhigroupinc.com',
                contactInfo,
                address,
                'usd'
            );

            System.assert(false, 'An exception should have been thrown for the invalid email');
        } catch (Exception ex) {
            System.Assert(ex.getMessage().contains('email'), 'Account Validation Rule did not fire');
        }
    }

    static testMethod void testMethodInvalidBrand() {
        CCAPI_AccountService.Address address = new CCAPI_AccountService.Address();
        CCAPI_AccountService.ContactInfo contactInfo = new CCAPI_AccountService.ContactInfo();

        CCAPI_AccountService.AccountPostResponse response;

        contactInfo.firstName = 'Brn';
        contactInfo.lastName = 'Klr';
        contactInfo.emailAddress = 'brian.klinker@dhigroupinc.com';
        contactInfo.phoneNumber = '1231231235';

        address.street = '22 Test Rd';
        address.city = 'Props';
        address.state = 'CO';
        address.postalCode = '80111';
        address.country = 'US';

        try {
            response = CCAPI_AccountService.createOrUpdate(
                'eFinreers',
                'Test company name',
                '1231231234',
                '9879879876',
                'www.dhigroupinc.com',
                contactInfo,
                address,
                'usd'
            );}
        catch (QueryException e){
            //System.assert(response.AccountId == null, 'Account ID should be null');
            System.assert(e.getMessage().contains('Account brand not found'), e.getMessage());
        }
    }
    static testMethod void testValidateContactInfo() {
        CCAPI_AccountService.Address address = new CCAPI_AccountService.Address();
        CCAPI_AccountService.ContactInfo contactInfo = new CCAPI_AccountService.ContactInfo();

        CCAPI_AccountService.AccountPostResponse response;
		string validBrandName = 'eFinancialCareers';
        contactInfo.firstName = 'Fname';
        contactInfo.lastName = 'LName';
        contactInfo.emailAddress = 'unitTest@dhigroupinc.com';
        contactInfo.phoneNumber = '1231231235';
		contactInfo.mailingAddress =  new CCAPI_AccountService.Address();
        contactInfo.mailingAddress.street = '555 personal st.';
        contactInfo.mailingAddress.city = 'Paris';
        contactInfo.mailingAddress.state = 'TX';
        contactInfo.mailingAddress.postalCode = 'TX';
        contactInfo.mailingAddress.country = 'US';
        
        address.street = '22 Test Rd';
        address.city = 'Props';
        address.state = 'CO';
        address.postalCode = '80111';
        address.country = 'US';

        response = CCAPI_AccountService.createOrUpdate(
                validBrandName,
                'Test company name',
                '1231231234',
                '9879879876',
                'www.dhigroupinc.com',
                contactInfo,
                address,
                'usd'
            );
         System.assert(response.AccountID != null, 'Account ID should not be null');
         System.assert(response.ContactId != null, 'Contact ID should not be null');
        
          Contact contact = [
            SELECT c.MailingStreet, c.MailingCity, c.MailingState, c.MailingPostalCode, c.MailingCountry
            FROM Contact c
            WHERE Id = :response.ContactId
            LIMIT 1
        ];
        
        Contact_Type__c contactType = (Contact_Type__c)[
            Select c.Type__c
            From Contact_Type__c c
            where c.Brand_Name__c = :validBrandName
            and c.Contact__c = :response.ContactId
        ];
        
        System.assert(contactType.Type__c == CCAPI_AccountService.CONTACT_TYPE_BY_BRAND);
        System.assert(contactInfo.mailingAddress.street == contact.MailingStreet);
        System.assert(contactInfo.mailingAddress.city == contact.MailingCity);
        System.assert(contactInfo.mailingAddress.state == contact.MailingState);
        System.assert(contactInfo.mailingAddress.postalCode == contact.MailingPostalCode);
        System.assert('United States' == contact.MailingCountry);
        
    }

}