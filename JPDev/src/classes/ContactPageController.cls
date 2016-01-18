public class ContactPageController {

    public List<String> errors {get; set;}
    public Contact newCon {get; set;}
    public Contact_Type__c CTInsert {get; set;}
    public List<ContactType_WrapperClass> conTypes{get; set;}
    public String pgContext {get;set;}
    public Boolean isReqDelete {get;set;}
    public List<RecordType> recType {get;set;}
    
    private PageReference pgReturnPage {get; set;}
    private String accountID {get; set;}
    private Account currentAcct {get; set;}
    
    public ContactPageController(ApexPages.StandardController controller) {
 
        pgContext = ApexPages.currentPage().getParameters().get('Id');
        if (pgContext == null) PrepPageForNewContact();    
        else PrepPageForEdit();    
    }

    private void PrepPageForEdit(){
        pgReturnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
        conTypes = new List<ContactType_WrapperClass>();
        errors = new List<String>();
        
        newCon = [SELECT Id,Salutation,Phone,FirstName,MobilePhone,LastName,HomePhone,AccountId,
                    OtherPhone,Department,Fax,Title,Email,Language__c,Alternate_Email__c,Jigsaw,
                    No_Longer_With_Company__c,MailingStreet,MailingCity,MailingState,MailingPostalCode,
                    MailingCountry,No_Contact__c,No_Mail__c,No_Call__c,No_Gift__c,No_Email__c,No_Fax__c,
                    LeadSource,Description,Web_Message__c,Contact_Preferences__c,User_Allocations_Active__c,
                    User_Allocations_Inactive__c,Job_Title__c,
                    Reason_for_deletion__c, Delete_Requested_By__c, RecordTypeId
                    FROM Contact WHERE id=:pgContext];
    
        recType = [SELECT DeveloperName FROM RecordType WHERE Id=:newCon.RecordTypeId LIMIT 1];
        
        if (recType.size() > 0 && recType[0].DeveloperName == 'Requested_for_Deletion') {
            isReqDelete = true;
            newCOn.Delete_Requested_By__c = UserInfo.getUserId();
        }
        else isReqDelete = false;
         
        for (Contact_Type__c ctp : [select Name,Id,Type__c,Brand_Name__c,Authorized__c,Contact__c from Contact_Type__c where contact__c = :pgContext order by Brand_Name__c]) {
            ContactType_WrapperClass ct = new ContactType_WrapperClass();
            ct.Brand = ctp.Brand_Name__c;
            ct.CTRecord = ctp;
            //ct.Contact__c = newCon.Id;
            conTypes.add(ct);
            
        } 
    
    }
    
    private void PrepPageForNewContact(){

        
        pgReturnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
        newCon = new Contact();   
        newCon.Contact_Type_Trigger_Skip__c = true;
        conTypes = new List<ContactType_WrapperClass>();
        errors = new List<String>();
        
        //set the accountID if we came from the Account page...
        accountID = ApexPages.currentPage().getParameters().get('accid');
        
        if ((accountID != null) && (accountID != '')) {
            newCon.AccountId = accountID;
            currentAcct = [SELECT Phone, BILLINGSTREET, BILLINGCITY, BILLINGSTATE, BILLINGPOSTALCODE, BILLINGCOUNTRY FROM Account WHERE Id = :accountID];
            newCon.Phone = currentAcct.Phone;
            newCon.MailingStreet = currentAcct.BILLINGSTREET;
            newCon.MailingCity = currentAcct.BILLINGCITY;
            newCon.MailingState = currentAcct.BILLINGSTATE;
            newCon.MailingPostalCode = currentAcct.BILLINGPOSTALCODE;
            newCon.MailingCountry= currentAcct.BILLINGCOUNTRY;
        } 
        
        for (Brand__c brand : [select Name from brand__c order by Name]) {
            ContactType_WrapperClass ct = new ContactType_WrapperClass();
            ct.Brand = brand.Name;
            //ct.Contact__c = newCon.Id;
            conTypes.add(ct);
            
        }
    }

    public PageReference SaveItAll() {

      //save all the pieces
      Boolean GoodToGo = Validate();
      
      //validate if the record is ok to save, do not run edits if Contact is no longer with the company (CC-2489)
      if ((GoodToGo) || (newCon.No_Longer_With_Company__c == true)) {   
        upsert newCon;      
        integer i = 0;
        List<Contact_Type__c> CTInsert = new List<Contact_Type__c>();
         
        //Query for Account Brand
        Map<String, Id> accountBrandMap = new Map<String, Id>();
        for (Account_Brand__c ab : [select Id, Name, Brand_Name__c from Account_Brand__c where Account__c = :newCon.AccountId]) {
            System.debug('&&&&&&&&&& - ' + ab.Brand_Name__c);
            if (!accountBrandMap.containsKey(ab.Brand_Name__c)) accountBrandMap.put(ab.Brand_Name__c, ab.Id);    
        }
         
        //match the Brand from the Account brand with the Brand in the Contact Type list and update the appropriate Account Brand Id
        
        //save the Contact Types
        for (ContactType_WrapperClass ct: conTypes) {                        
            System.debug('%%%%%%%%%% - ' + ct.Brand);


            if (accountBrandMap.containsKey(ct.Brand)) {
                ct.CTRecord.Account_Brand__c = accountBrandMap.get(ct.Brand);
            }

            ct.CTRecord.Contact__c = newCon.Id;
           
            CTInsert.add(ct.CTRecord);
        }
      
        if (CTInsert.size() > 0) upsert CTInsert; 
         
        PageReference newConPage = new PageReference('/' + newCon.Id);
        newConPage.setRedirect(true);
        return newConPage;
      } else return null;
      
    }
    
    public PageReference Cancel() {
      return pgReturnPage;
    }

   public PageReference AccountChanged() {
                
        //set the accountID if it is being changed on the page
        accountID = newCon.Accountid;
        
        //Grab the address values and reset them on the page.
        if ((accountID != null) && (accountID != '')) {
            newCon.AccountId = accountID;
            currentAcct = [SELECT Phone, BILLINGSTREET, BILLINGCITY, BILLINGSTATE, BILLINGPOSTALCODE, BILLINGCOUNTRY FROM Account WHERE Id = :accountID];
            newCon.Phone = currentAcct.Phone;
            newCon.MailingStreet = currentAcct.BILLINGSTREET;
            newCon.MailingCity = currentAcct.BILLINGCITY;
            newCon.MailingState = currentAcct.BILLINGSTATE;
            newCon.MailingPostalCode = currentAcct.BILLINGPOSTALCODE;
            newCon.MailingCountry= currentAcct.BILLINGCOUNTRY;
        }   

        return null;
    }
        
    private Boolean Validate() {
        //reset the error collection...
        errors = new List<String>();         
        integer iTypeCnt = 0;
        
        //Query for Account Brand
        Map<String, String> accountBrandMap = new Map<String, String>();
        for (Account_Brand__c ab : [select Id, Name, Brand_Name__c, Primary_Owner__c from Account_Brand__c where Account__c = :newCon.AccountId]) {
            System.debug('&&&&&&&&&& - ' + ab.Brand_Name__c);
            if (!accountBrandMap.containsKey(ab.Brand_Name__c)) accountBrandMap.put(ab.Brand_Name__c, ab.Primary_Owner__c);    
        }
                   
        //Account name
        if (newCon.AccountId == null)  errors.add('Missing Account Name');
        
        //only one contact can be the 'Campaign Recipient' for each brand
        Set<ID> conIDset = new Set<ID>();
        for (Contact CONall : [Select Id from Contact where AccountId = :newCon.AccountId]) {
            conIDset.add(CONall.Id);
        }
        
        //For every Contact Type at least one type MUST be completed
        for (ContactType_WrapperClass ct: conTypes) {                        
            if (ct.CTRecord.Type__c != null) iTypeCnt++;
        }
               
        //At least 1 Contact Type must have a valid Type value chosen
        if (iTypeCnt == 0) errors.add('Please choose a Type value under the Contact Brand Attributes section for at least one brand.');
               
        if (errors.size() > 0) return false;
        return true;
    }    
}