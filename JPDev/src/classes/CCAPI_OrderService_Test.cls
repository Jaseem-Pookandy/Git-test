@isTest(SeeAllData=true)
private class CCAPI_OrderService_Test {
    
    static testMethod void createValidRequestSucceeds() {
        string paymentMethodId = 'def234';
        string currencyCode = 'USD';
        string brand = 'eFinancialCareers';
        string brandTag = 'eFC-Amer';
        
        // setup test data
        Account account = (Account)TestFactory.createSObject(new Account(), false);
        insert account;
        
        Contact contact = (Contact)TestFactory.createSObject(new Contact(), false);
        contact.AccountId = account.Id;
        contact.FirstName = 'TestFirst';
        contact.LastName = 'TestLast';
        contact.Email = 'testemail@dhigroupinc.com';
        insert contact;
        
        CCAPI_AccountService.assignAccountBrandOwnership(account.Id, brand, account.BillingCountry);
        
        // build up request for service call
        CCAPI_OrderService.BillTo billTo = new CCAPI_OrderService.BillTo();
        billTo.firstName = contact.FirstName;
        billTo.lastName = contact.LastName;
        billTo.emailAddress = contact.Email;
        billTo.phoneNumber = contact.Phone;
        billTo.street = contact.MailingStreet;
        billTo.city = contact.MailingCity;
        billTo.state = contact.MailingState;
        billTo.country = contact.MailingCountry;
        billTo.postalCode = contact.MailingPostalCode;
        
        CCAPI_OrderService.LineItem lineItem = new CCAPI_OrderService.LineItem();
        lineItem.productSku = 'xyz789';
        lineItem.quantity = 1;
        
        List<CCAPI_OrderService.LineItem> lineItems = new List<CCAPI_OrderService.LineItem> {
            lineItem
        };
        
        Test.startTest();
        
        // execute the request
        string result = CCAPI_OrderService.doCreate(account.Id, paymentMethodId, currencyCode, brand, brandTag, billTo, lineItems);
        
        // make sure an opportunity was created
        Opportunity opp = [SELECT Id, Name, OwnerId FROM Opportunity WHERE Id = :result LIMIT 1];
        System.assert(!string.isBlank(opp.Name), 'Opportunity name not populated');
        
        // make sure a task was created
        //List<Task> oppTasks = [SELECT Id FROM Task WHERE whatid = :result];
        //System.assert(oppTasks.size() > 0, 'A task should have been created');
        
        System.assert(result != null);
        
        Test.stopTest();
    }
    
    static testMethod void createInvalidRequestFails() {
        CCAPI_OrderService.create('invalid', 'invalid', 'invalid', 'invalid', 'invalid',
            new CCAPI_OrderService.BillTo(), new List<CCAPI_OrderService.LineItem>());
        
        object response = JSON.deserialize(RestContext.response.responseBody.toString(),
        	List<CCAPI_OrderService.ErrorResponse>.class);
        List<CCAPI_OrderService.ErrorResponse> errorResponses = (List<CCAPI_OrderService.ErrorResponse>)response;
        
        System.assert(RestContext.response.statusCode == 500, 'This is all kinds of bad, should be a 500');
        System.assert(errorResponses.size() == 1, 'You should have a deserialized error response.');
    }
    
}