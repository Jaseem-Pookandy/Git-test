@isTest
public class AccountManagerTest {
    @isTest static void testgetaccount(){
        Account acc = new Account();
        acc.name = 'Test account';
        insert acc;
        Contact con = new Contact();
        con.lastname = 'Test Contact';
        con.AccountId = acc.Id;
        insert con;
        
        RestRequest request = new Restrequest();
        request.requestURI = 'jaseem-dev-ed.my.salesforce.com/services/apexrest/Accounts/'+acc.id+'/Contacts';
        request.httpMethod = 'GET';
        Restcontext.request = request;
        Account accc = AccountManager.getAccount();
        
        system.assert(accc!=null);
    }
}