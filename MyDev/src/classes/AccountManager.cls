@RestResource(urlmapping = '/Accounts/*')
global class AccountManager {
 
    @HttpGet
    global static Account getAccount(){
        Restrequest request = Restcontext.request;
        String accid = request.requestURI.Substring(request.requestURI.lastindexof('/')-18,request.requestURI.lastindexof('/'));
        system.debug('######### accountid '+accid);
        Account acc = [select id,name,(select id,name from Contacts) from Account where id =:accid];
        return acc;
    }
}