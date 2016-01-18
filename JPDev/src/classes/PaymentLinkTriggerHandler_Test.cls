@isTest
private class PaymentLinkTriggerHandler_Test {
	
    static testMethod void senario1_test() {
        
        //Create Account
        Account account = TestUtils.createAccount();
        insert account;
        
        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        insert contactList;
        
        //Create Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;
        for(integer i=0; i<2; i++) {
            opp = TestUtils.createOpportunity('Opp_'+i, account);
            opp.Contact__c = contactList.get(i).id;
            oppList.add(opp);           
        }
        insert oppList;

        Payment_Link__c pl = new Payment_Link__c();
        pl.Opportunity__c = oppList[0].Id;
        pl.Reason__c = 'Docusign Generated';

        insert pl;

        //Without a crypto-key, this should be null

        Payment_Link__c thisPL = [SELECT Token__c, Id, Opportunity__c FROM Payment_Link__c WHERE Id = :pl.Id LIMIT 1];
        System.assertEquals(null, thisPL.Token__c);

        delete thisPL;

        //Now insert a crypto-key and do another...

        PaymentLinkCryptoKey__c thisKey = new PaymentLinkCryptoKey__c();
        thisKey.Name = 'CCCapture - AES 256';
        thisKey.Key__c = '123045678901515487952361dfergtdf';
        insert thisKey;

        pl = new Payment_Link__c();
        pl.Opportunity__c = oppList[0].Id;
        pl.Reason__c = 'Docusign Generated';

        insert pl;

        //Without a crypto-key, this should be null

        thisPL = [SELECT Token__c, Id, Opportunity__c FROM Payment_Link__c WHERE Id = :pl.Id LIMIT 1];
        System.assertNotEquals(null, thisPL.Token__c);

        delete thisPL;

     }
}