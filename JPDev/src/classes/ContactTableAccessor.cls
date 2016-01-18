public with sharing class ContactTableAccessor {

    public String accountID {get; set;}
    private List<ContactWrapper> wrappedContacts {get; set;}
    public Boolean shouldRedirect {public get; private set;}
    public String redirectURL {public get; private set;}

    public Integer contactCount {
        get {
            if (wrappedContacts != null) return wrappedContacts.size();
            else return 0;
        }
    }

    public ContactTableAccessor() {
        shouldRedirect = false;
        WrappedContacts = new List<ContactWrapper>();
    }

    public PageReference NewContactAction() {
        //this is an example of the URL for using Mike's fancy-schmancy new Contact visualforce page:
        //https://dice--config--c.cs18.visual.force.com/apex/ContactPage?retURL=%2F00111000008AuK5AAK&accid=00111000008AuK5&save_new=1&sfdc.override=1
        shouldRedirect = true;
        PageReference pageRef = New PageReference('/apex/ContactPage?retURL=%2F' + accountID + '&accid=' + accountID + '&save_new=1&sfdc.override=1');
        //pageRef.setRedirect(true);
        redirectURL = pageRef.getUrl();
        //return pageRef;
        return null;
    }

    public Boolean getUserCanDeleteContacts() {

        Contact feelerContact = [SELECT Id FROM Contact LIMIT 1];
        if (feelerContact != null) {

            Boolean bResult = [SELECT HasDeleteAccess, RecordId
                                FROM  UserRecordAccess 
                                WHERE UserId = :UserInfo.getUserId() 
                                AND   RecordId = :feelerContact.Id].HasDeleteAccess;

            return bResult;
        }
        return false;
    }

    public PageReference MergeContactsClick() {
        PageReference pageRef = New PageReference('/merge/conmergewizard.jsp'); 
        pageRef.getParameters().put('id', accountID); 
        pageRef.getParameters().put('retURL', accountID);                   
        return pageRef;             
      
    }    

    public List<ContactWrapper> getWrappedContacts() {
        wrappedContacts = new List<ContactWrapper>();
        map<String, ContactBrandDetails> cbMap = new Map<String, ContactBrandDetails>();

        if (accountID != null) {

            //Brand sort order (master list)
            List<String> brandOrder = new List<String>();
            for (Brand__c b : [SELECT Name FROM Brand__c ORDER BY Name asc]) {
                brandOrder.add(b.Name);
            }

            for (Contact c : [SELECT    Contact_Preferences_Flag__c, 
                                        Title, 
                                        No_Longer_With_Company__c, 
                                        Email, 
                                        Id, 
                                        Full_Mailing_Address__c, 
                                        Name, 
                                        FirstName,
                                        LastName,
                                        Phone,
                                        AccountId,
                                        User_Allocations_Active__c, 
                                        Authorized__c,
                                        (SELECT CloseDate, Amount, Primary_Brand__c FROM Opportunities__r 
                                            WHERE IsClosed=True AND IsWon=True ORDER BY CloseDate DESC),
                                        (SELECT Brand_Name__c,Type__c FROM Contact_Types__r WHERE Type__c != null),
                                        (SELECT Name,Account__c,Primary_Recipient__c,Brand_Picklist__c FROM Campaign_Brand_Recipient__r)
                                FROM Contact 
                                Where AccountId = :accountID
                                ORDER BY No_Longer_With_Company__c, LastName, FirstName]) {

                cbMap = new Map<String, ContactBrandDetails>();

                ContactWrapper cw = new ContactWrapper();
                cw.Contact = c;
                
                //Contact is set.  Now loop through the Contact Type records
                for (Contact_Type__c ct : c.Contact_Types__r) {
                    if (!cbMap.containsKey(ct.Brand_Name__c)) cbMap.put(ct.Brand_Name__c, new ContactBrandDetails());
                    cbMap.get(ct.Brand_Name__c).Brand = ct.Brand_Name__c;
                    cbMap.get(ct.Brand_Name__c).ContactType = ct;
                    cbMap.get(ct.Brand_Name__c).AccountID = c.AccountId;
                }

                //Now loop through the Account Brand records
                for (Account_Brand__c ab : c.Campaign_Brand_Recipient__r) {
                    if (!cbMap.containsKey(ab.Brand_Picklist__c)) cbMap.put(ab.Brand_Picklist__c, new ContactBrandDetails());
                    cbMap.get(ab.Brand_Picklist__c).Brand = ab.Brand_Picklist__c;
                    cbMap.get(ab.Brand_Picklist__c).ContactIsPrimaryRecipient = true;
                }

                //Now loop through the opps...
                for (Opportunity o : c.Opportunities__r) {
                    if (!cbMap.containsKey(o.Primary_Brand__c)) cbMap.put(o.Primary_Brand__c, new ContactBrandDetails());
                    
                    if ((o.CloseDate > cbMap.get(o.Primary_Brand__c).LastCloseWonOpp.CloseDate) || (cbMap.get(o.Primary_Brand__c).LastCloseWonOpp.CloseDate == null)) {
                        cbMap.get(o.Primary_Brand__c).Brand = o.Primary_Brand__c;
                        cbMap.get(o.Primary_Brand__c).LastCloseWonOpp = o;  
                        cbMap.get(o.Primary_Brand__c).AccountID = c.AccountId;
                    }               
                }               
                
                for (String s : brandOrder) {
                    if (cbMap.containsKey(s)) cw.listCBD.add(cbMap.get(s));
                }               
                
                wrappedContacts.add(cw);
            }
        }

        return wrappedContacts;
    }
}