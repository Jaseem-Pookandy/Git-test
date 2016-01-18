@isTest
private class CCCaptureUtilities_Test {

	static testMethod void scenario1_test() {
        
		CCCaptureUtilities ccu = new CCCaptureUtilities();	//constructor

		final String cryptoKey = '123045678901515487952361dfergtdf';
		final String plainText = 'Plain text to encrypt';

		String encryptedResult = CCCaptureUtilities.EncryptText(cryptoKey, plainText);
		System.assertNotEquals(encryptedResult, plainText);
		System.assertNotEquals(encryptedResult, null);

		String decryptedResult = CCCaptureUtilities.DecryptText(cryptoKey, encryptedResult);
		System.assertEquals(decryptedResult, plainText);

		//Bad scenarios
		encryptedResult = CCCaptureUtilities.EncryptText(null, plainText);
		System.assertNotEquals(encryptedResult, plainText);
		System.assertEquals(encryptedResult, null);

		decryptedResult = CCCaptureUtilities.DecryptText(null, 'garbage');
		System.assertEquals(decryptedResult, null);
     }

    static testMethod void scenario2_test() {

        //Create Account
        Account account = TestUtils.createAccount();
        insert account;
        
        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        insert contactList;

        Zuora__Subscription__c newSub = new Zuora__Subscription__c();
        newSub.Zuora__Zuora_Id__c = '12345678901234567890123456789012';
        newSub.Name = 'Fake Sub';
        newSub.Zuora__Account__c = account.Id;
        insert newSub;
        
        //Create Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;
        for(integer i=0; i<2; i++) {
            opp = TestUtils.createOpportunity('Opp_'+i, account);
            opp.Contact__c = contactList.get(i).id;
            opp.ZuoraSubscription__c = newSub.Id;
            oppList.add(opp);           
        }
        insert oppList;

		List<Payment_Link__c> listoLinks = new List<Payment_Link__c>();

        Payment_Link__c pl = new Payment_Link__c();
        pl.Opportunity__c = oppList[0].Id;
        pl.Contact__c = opp.Contact__c;
        pl.Reason__c = 'Docusign Generated';

        listoLinks.add(pl);
        insert pl;

		EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName =:Label.Payment_Link_Email_Template_Manual];
		Messaging.SingleEmailMessage sem = CCCaptureUtilities.CreatePaymentEmail(pl.Id, pl.Contact__c, et.Id);
        String result = CCCaptureUtilities.SendPaymentEmail(pl.Id, pl.Contact__c, et.Id);

        CCCaptureUtilities.ProcessExpiredPaymentLinks(listoLinks);

        CCCaptureUtilities.PostProcessRemittanceLink(   '************1234',
                                                        pl.Opportunity__c,
                                                        pl.Id,
                                                        '127.0.0.1',
                                                        'Homer Simpson',
                                                        '04',
                                                        '2020',
                                                        'Visa',
                                                        'Notes',
                                                        false,
                                                        'paymentech',
                                                        new CCCaptureController.CreditCardObject(),
                                                        false,
                                                        false,
                                                        false,
                                                        '',
                                                        true,
                                                        new List<String>(),
                                                        '1234567890123456789012345678901a'
                                                        );
    }

    static testMethod void scenario3_test() {

        //Create Account
        Account account = TestUtils.createAccount();
        insert account;
        
        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        insert contactList;

        Zuora__Subscription__c newSub = new Zuora__Subscription__c();
        newSub.Zuora__Zuora_Id__c = '12345678901234567890123456789012';
        newSub.Name = 'Fake Sub';
        newSub.Zuora__Account__c = account.Id;
        insert newSub;
        
        //Create Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;
        for(integer i=0; i<2; i++) {
            opp = TestUtils.createOpportunity('Opp_'+i, account);
            opp.Contact__c = contactList.get(i).id;
            opp.ZuoraSubscription__c = newSub.Id;
            oppList.add(opp);           
        }
        insert oppList;

        List<Payment_Link__c> listoLinks = new List<Payment_Link__c>();

        Payment_Link__c pl = new Payment_Link__c();
        pl.Opportunity__c = oppList[0].Id;
        pl.Contact__c = opp.Contact__c;
        pl.Reason__c = 'For Entry on Behalf of Customer';

        listoLinks.add(pl);
        insert pl;

        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName =:Label.Payment_Link_Email_Template_Manual];
        Messaging.SingleEmailMessage sem = CCCaptureUtilities.CreatePaymentEmail(pl.Id, pl.Contact__c, et.Id);
        String result = CCCaptureUtilities.SendPaymentEmail(pl.Id, pl.Contact__c, et.Id);

        CCCaptureUtilities.ProcessExpiredPaymentLinks(listoLinks);

        CCCaptureUtilities.PostProcessRemittanceLink(   '************1234',
                                                        pl.Opportunity__c,
                                                        pl.Id,
                                                        '127.0.0.1',
                                                        'Homer Simpson',
                                                        '04',
                                                        '2020',
                                                        'Discover',
                                                        'Notes',
                                                        false,
                                                        'paymentech',
                                                        new CCCaptureController.CreditCardObject(),
                                                        false,
                                                        false,
                                                        false,
                                                        '',
                                                        true,
                                                        new List<String>(),
                                                        '1234567890123456789012345678901a'
                                                        );

        Boolean bResult = CCCaptureUtilities.IsValidId('03r');
        System.assertEquals(false, bResult);

        bResult = CCCaptureUtilities.IsValidId(pl.Id);
        System.assertEquals(true, bResult);
    }
}