public class NewContactController {
    private PageReference pgReturnPage {get; set;}
    private String accountID {get; set;}
    private String retURL {get; set;}
    
    public NewContactController(ApexPages.StandardController controller) {
        
        //Nothing needed here, 'RedirectUser' is called from the 'action' on page load of the visualforce page.
            
    }
        
    public PageReference RedirectUser() {    
    	String sRecType = null;
    	
        //set the accountID if we came from the Account page...
        accountID = ApexPages.currentPage().getParameters().get('accid');
        retURL = ApexPages.currentPage().getParameters().get('retURL');

        //strip on the id= from the URL.  It is not needed and creates an error
        String stripChars = ('&id=' + accountID);
        retURL = retURL.replace(stripChars, '');
        
        //Get the RecordType ID for the 'Standard' RecordType to eliminate hardcoding
        ID conRecordType;
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'Standard' LIMIT 1]) {
           if (rt != null && rt.DeveloperName == 'Standard') conRecordType = rt.Id;
        } 
        
        //Use default RecordType from PROD if this code did not find anything, so this always works in PROD
        if (conRecordType == null) sRecType = '012d0000000wy41';
        else sRecType = conRecordType;
        
        //build the URL string to override the selection of the RecordType - always default to Standard
        String urlResult = '/003/e?RecordType=' + sRecType + '&nooverride=1';
        
        if (accountID != null) urlResult += '&accid=' + accountID;
        if (retURL != null) urlResult += '&retURL=' + retURL;
                    
        return pgReturnPage = new PageReference(urlResult);     
    }
}