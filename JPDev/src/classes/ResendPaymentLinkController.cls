// Byrnes
// 2015.04.21
// Part of Credit Card Capture

public with sharing class ResendPaymentLinkController {

	public Payment_Link__c thisPL {get; set;}
	public List<String> errors {get; set;}
    public List<String> infoMessages {get; set;}
	public Contact existingContact {get; set;}
	public List<SelectOption> contactOptions {get; set;}
    public List<SelectOption> contactTypeOptions {get; set;}
    public String contactTypeValue {get; set;}
	public Contact newContact {get; set;}
	public String tabInFocus {get; set;}
	public String oppId {get;set;}
	public Boolean pageIsPrepped {get; set;}
	public String switcherooLabel {get; set;}                       //for the toggle commandbutton...
	public Boolean useThePicklist {get; set;}                       //for the toggle...
    public Boolean createCaseOnCompletion {get; set;}
    public String reasonHelpText {get; set;}

    public Boolean emailLink {get; set;}            //if true link will be emailed.  If false, link will NOT be emailed and instead the user will be redirected to the CC page themselves.
    public Boolean renderBehalfJavascript {get; set;}   //for when the process is completed.  This will trigger the visualforce page to open a popup and also redirect the user back to the Opp.
    public String continueButtonText {get; set;}
    public String onBehalfOfURL {get; set;}

	public Opportunity thisOpp {get; set;}

    private Payment_Link__c priorOnBehalfOfLink {get; set;}

    private Map<String, PaymentLinkLogic__c> linkLogicMap {get; set;}
    private Boolean setContact {get; set;}

    private final String REASON_HELP_NULL = 'Select a reason for sending another payment link email.';
    private final String REASON_HELP_CASECOMP_Y = 'Upon completion of this Payment Link a Case will automatically be created.  As such, please fill the Notes field below as that data will carry over to the case.';
    private final String REASON_HELP_CASECOMP_N = 'This reason will not create a Case upon completion.';

    private final String CREATE_WITH_SEND = 'Create and Send the Remittance Link';
    private final String CREATE_WITHOUT_SEND = 'Continue to Enter Credit Card Info';

    private final String REASON_BEHALF_OF = 'For Entry on Behalf of Customer';

    public ResendPaymentLinkController(ApexPages.StandardController controller) {

		pageIsPrepped = false;
        createCaseOnCompletion = false;
        renderBehalfJavascript = false;
        reasonHelpText = REASON_HELP_NULL;
    	errors = new List<String>();
        infoMessages = new List<String>();
    	tabInFocus = '';
    	existingContact = new Contact();
        contactOptions = new List<SelectOption>();
    	thisPL = new Payment_Link__c();
        priorOnBehalfOfLink = null;
        emailLink = false;
    	newContact = new Contact();		//in case if the user needs to create a contact on the fly
        newContact.Language__c = 'English'; //default
        setContact = true;

    	thisOpp = null;
    	oppId = ApexPages.currentPage().getParameters().get('OppId');
        String bSendFlag = ApexPages.currentPage().getParameters().get('send');

        if (bSendFlag == null || (bSendFlag != '0' && bSendFlag != '1')) errors.add('Unable to properly initialize the page - missing Send flag from the querystring.');
        else if (bSendFlag == '0') {
            emailLink = false;
            createCaseOnCompletion = true;
        }
        else if (bSendFlag == '1') emailLink = true;
        else oppId = null;                              //if the send flag is missing ensure the page is not properly rendered.

    	if (oppId == null) errors.add('Unable to properly initialize the page - missing OppId from the querystring.');
    	else {
            //Grabbing the address & phone details in order to have the data ready in case if we're creating a contact
    		for (Opportunity o : [SELECT Id, Name, AccountId, Sold_By_Partner__c, Contact__c, Account.Phone, Account_Brand__c, Account.Name, StageName, SyncedQuote__r.Name, SyncedQuote__c, SyncedQuote__r.zqu__Opportunity__c,
                                    Account.BillingCity, Account.BillingCountry, Account.BillingState, Account.BillingStreet, 
                                    Account.BillingPostalCode, Account.pw_ccpro__BillingZipCodeLookup__c, Account.pw_ccpro__BillingStateLookup__c, 
                                    Account.pw_ccpro__BillingCountryLookup__c, Account.pw_ccpro__BillingAddressStatus__c 
                                    FROM Opportunity WHERE Id = :oppId LIMIT 1])	{
    			thisOpp = o;
    		}

            //Get the reason list now..
            linkLogicMap = PaymentLinkLogic__c.getAll();
    	}
    	
        if (thisOpp == null || thisOpp.SyncedQuote__c == null || thisOpp.StageName != 'Closed Won' ) errors.add('Before this feature can be used, a Synced Quote must be tied to this Opportunity and the Opportunity\'s Stage must equal \'Closed Won\'');

    	if ((errors.isEmpty()) && (thisOpp != null)) {
    		SetContactDefaults();

            SetContactTypeOptions();

            if (!emailLink) {
                thisPL.Reason__c = REASON_BEHALF_OF;  

                //At this time we'll also grab an existing remittance link to resuse, if available
                List<Payment_Link__c> priorRLList = [SELECT Payment_Link_URL_NoHTML__c, Id, Link_Created_For__c FROM Payment_Link__c WHERE Reason__c = :REASON_BEHALF_OF AND Status__c != 'Expired' AND IsExpired__c = false AND Opportunity__c = :oppId ORDER BY CREATEDDATE DESC LIMIT 1];
                if (!priorRLList.isEmpty()) priorOnBehalfOfLink = priorRLList[0];        
                else priorOnBehalfOfLink = null;        
            } 

            if (emailLink) continueButtonText = CREATE_WITH_SEND;
            else continueButtonText = CREATE_WITHOUT_SEND;

    		pageIsPrepped = true;            
    	}
    	else if (thisOpp == null) errors.add('Unable to locate the Opportunity.  OppId is most likely invalid.');
    }

    private void SetContactDefaults() {

        contactOptions = new List<SelectOption>();

        RefreshContactList();
        GetContactInfo();

        switcherooLabel = 'Use the lookup';
        useThePicklist = true;
    }    

    private void SetContactTypeOptions() {
        contactTypeOptions = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = Contact_Type__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry f : ple) {
            contactTypeOptions.add(new SelectOption(f.getLabel(), f.getValue()));
        }

        contactTypeValue = 'Accounts Payable';      //default it
    }

    public PageReference SaveItAll() {

    	if (ValidationIsSuccessful()) {

            Contact contactToEmail = new Contact();

    		//Save everything in the order necessary and kick off the emails.
            if (tabInFocus == 'existingContact') {
                contactToEmail = existingContact;
            }
            else if (tabInFocus == 'newContact') {
                Database.SaveResult sr = Database.insert(newContact);

                if (!sr.isSuccess()) {
                    errors.add('Error 901:  Unable to create contact.  Process aborted, no Payment Links were created nor were any emails sent.');  
                    for (Database.Error er : sr.getErrors()) {
                        errors.add(er.getMessage());
                    }
                    return null;
                } 
                else {
                    //Else the contact was properly insert, now update the contact type record
                    List<Contact_Type__c> ctList = [SELECT Id FROM Contact_Type__c WHERE Contact__c = :newContact.Id AND Account_Brand__c = :thisOpp.Account_Brand__c LIMIT 1];
                    if (ctList != null && !ctList.isEmpty()) {
                        //Update the contact type record
                        Contact_Type__c newCT = ctList[0];
                        newCT.Type__c = contactTypeValue;
                        update newCT;                        
                    }
                    else {
                        errors.add('Error 902:  Unable to update the new contact\'s applicable Contact Type record.  Process aborted, no Payment Links were created nor were any emails sent.');  
                        return null;
                    }

                    contactToEmail = [SELECT Id, FirstName, LastName, Email, Account.Channel_Partner__c FROM Contact WHERE Id = :newContact.Id LIMIT 1];
                }
            }

            //If we're here, the new contact is chosen or inserted and the contact type record is updated correctly as well...  Now, on to the next step...
            //Create the payment link:

            String linkResult = null;
            if (emailLink) linkResult = WebServices.CreatePaymentLink(thisOpp.Id, contactToEmail.Id, thisPL.Reason__c, thisPL.Case_Description__c, thisPL.Additional_Email_Text__c, thisPL.AutoPay_Off__c, contactToEmail.Account.Channel_Partner__c);
            else {
                if (priorOnBehalfOfLink == null) linkResult = WebServices.CreatePaymentLink(thisOpp.Id, contactToEmail.Id, thisPL.Reason__c, thisPL.Case_Description__c, thisPL.Additional_Email_Text__c, thisPL.AutoPay_Off__c, thisOpp.Sold_By_Partner__c != null);
                else {
                    //We need to update Link_Created_For__c now before we reuse the old link
                    priorOnBehalfOfLink.Link_Created_For__c = thisOpp.Sold_By_Partner__c == null ? 'Customer' : 'Sold By Partner';
                    update priorOnBehalfOfLink;
                    linkResult = priorOnBehalfOfLink.Id;
                }
            }

            if (linkResult.startsWithIgnoreCase('error')) errors.add('Error 913:  Unable to create the Payment Link record.  Note that if you were creating a contact it now exists, but no emails have been sent.  ' + linkResult);

            else if (emailLink) {
                //Payment link has been successfully inserted... now to email it.
                String sError = CCCaptureUtilities.SendPaymentEmail(linkResult, contactToEmail.Id, null);

                if (sError != null) errors.add('Error 959:  Problem encountered sending email: ' + sError);
                else {                    
                    Payment_Link_History__c plh = PaymentLinkTriggerHandler.ReturnNewLinkHistoryRecord(linkResult, 'Emailed to ' + contactToEmail.Email, 'Salesforce.com');
                    insert plh;
                    return new PageReference('/' + oppId);
                }
            }
            else if (!emailLink) {

                List<Payment_Link__c> newLinkList = [SELECT Payment_Link_URL_NoHTML__c, Id, Name FROM Payment_Link__c WHERE Id = :linkResult LIMIT 1];

                //update the notes & checkbox now
                newLinkList[0].Case_Description__c = thisPL.Case_Description__c;
                newLinkList[0].AutoPay_Off__c = thisPL.AutoPay_Off__c;
                update newLinkList[0];

                if (newLinkList != null && !newLinkList.isEmpty()) onBehalfOfURL = newLinkList[0].Payment_Link_URL_NoHTML__c;

                infoMessages = new List<String>();
                infoMessages.add('If you do not see a new tab with the Credit Card capture page it was blocked by your popup blocker.  Edit your settings to allow popups from Salesforce.com to go to that page.');

                renderBehalfJavascript = true;                
            } 

    		return null;
    	}
    	
    	return null;
    }    

    private void RefreshContactList() {

        if (thisOpp != null) {
            Set<Id> accountIDs = new Set<Id>();
            accountIDs.add(thisOpp.AccountId);

            if (thisOpp.Sold_By_Partner__c != null) accountIDs.add(thisOpp.Sold_By_Partner__c);

            contactOptions = new List<SelectOption>();      
            
            for (Contact c : [SELECT AccountId, Id, FirstName, LastName, Title, Email FROM Contact WHERE AccountId IN :accountIDs AND No_Longer_With_Company__c = false ORDER BY FirstName, LastName ASC]) {

                //set the contact to the opportunity's contact
            	if (thisPL.Contact__c == null && setContact) thisPL.Contact__c = c.Id;		//set it to the first one if blank

                if (thisPL.Contact__c != null && c.Id == thisOpp.Contact__c && setContact) {
                    thisPL.Contact__c = c.Id;  //if the contact matches the opp's contact, set it
                    setContact = false;
                } 
                               
                if (c.AccountId != thisOpp.AccountId) contactOptions.add(new SelectOption(c.Id, '* ' + c.FirstName + ' ' + c.LastName));
                else contactOptions.add(new SelectOption(c.Id, c.FirstName + ' ' + c.LastName));
            }
        }
        else contactOptions.add(new SelectOption('', 'An odd thing just happened.  Double-check your data and try again.'));
        
        //return contactOptions;
    }    

    public PageReference SwitcherooClick() {
        if (switcherooLabel == 'Use the picklist') {
            
            //Then we're now on the picklist...
            
            switcherooLabel = 'Use the lookup';         
            useThePicklist = true;
            
            //This sets the bound contact to the first option in the select list if we're toggling back FROM the lookup control.
            if ((contactOptions.size() > 0) && (contactOptions[0].getValue() != '')) {
                
                //First, check and see if the contact is in the list, if so, that's the one to use...
                if (thisPL.Contact__c != null) {
                    for (SelectOption so : contactOptions) {
                        //If the contact exists in the picklist, then don't do anything...
                        if (so.getValue() == thisPL.Contact__c) return null;
                    }
                }
                
                //Then we have at least one viable option as the contact did not exist in the picklist - change it and update the values...
                thisPL.Contact__c = contactOptions[0].getValue();
            }
        }
        else {
            switcherooLabel = 'Use the picklist';
            useThePicklist = false;
        }
        
        return null;
    }    

    public PageReference ProcessReasonSelection() {
        //This is used to cross-check the chosen reason with the custom setting data and determine if a case will be created upon completion of said payment link.

        if (thisPL.Reason__c != null && linkLogicMap.containsKey(thisPL.Reason__c)) {

            PaymentLinkLogic__c pll = linkLogicMap.get(thisPL.Reason__c);
            if (pll.CreateCase_Completion__c) {
                reasonHelpText = REASON_HELP_CASECOMP_Y;
                createCaseOnCompletion = true;
            }
            else {
                reasonHelpText = REASON_HELP_CASECOMP_N;
                createCaseOnCompletion = false;   
            }
        }
        else {
            reasonHelpText = REASON_HELP_NULL;
            createCaseOnCompletion = false;
        }

        return null;
    }

    public PageReference GetContactInfo() {

    	if (thisPL.Contact__c != null) existingContact = [SELECT Id, FirstName, LastName, Email, Account.Channel_Partner__c FROM Contact WHERE Id = :thisPL.Contact__c LIMIT 1];    	
    	else existingContact = null;

    	return null;
    }

    private Boolean ValidationIsSuccessful() {

    	errors.clear();

        //Generic validation first
        if (thisPL.Reason__c == null) errors.add('Reason is required.');
        if (createCaseOnCompletion && (thisPL.Case_Description__c == null || thisPL.Case_Description__c == '')) errors.add('Case Notes are required.');

        if (emailLink) {
    		if (tabInFocus == 'existingContact') {
    			//Validate all the data for selecting an existing contact (in addition to the payment link record)
    			if (existingContact == null) errors.add('Select a contact');
    			if (existingContact != null && existingContact.Email == null) errors.add('The selected contact is missing an email address.');
        	}
        	else if (tabInFocus == 'newContact') {
    			//Validate all the data for creating a new contact (in addition to the payment link record)
                if (newContact.FirstName == null || newContact.FirstName == '') errors.add('First Name is required when creating a new contact.');
                if (newContact.LastName == null || newContact.LastName == '') errors.add('Last Name is required when creating a new contact.');
                if (newContact.Email == null || newContact.Email == '') errors.add('Email is required when creating a new contact.');

                if (newContact.Language__c == null) errors.add('Language is required when creating a new contact.');

                //newContact.Phone will be populated from the Account
                //as will the Mailing Address pieces.
                //Contact Type will equal 'Accounts Payable' for whatever Brand the opty is tied to.
                //Language will be set to 'English'.
                newContact.Phone = thisOpp.Account.Phone;
                newContact.MailingCity = thisOpp.Account.BillingCity;
                newContact.MailingCountry = thisOpp.Account.BillingCountry;
                newContact.MailingState = thisOpp.Account.BillingState;
                newContact.MailingStreet = thisOpp.Account.BillingStreet;
                newContact.MailingPostalCode = thisOpp.Account.BillingPostalCode;
                newContact.pw_ccpro__MailingZipCodeLookup__c = thisOpp.Account.pw_ccpro__BillingZipCodeLookup__c;
                newContact.pw_ccpro__MailingStateLookup__c = thisOpp.Account.pw_ccpro__BillingStateLookup__c;
                newContact.pw_ccpro__MailingCountryLookup__c = thisOpp.Account.pw_ccpro__BillingCountryLookup__c;
                newContact.pw_ccpro__MailingAddressStatus__c = thisOpp.Account.pw_ccpro__BillingAddressStatus__c;
                newContact.AccountId = thisOpp.AccountId;
        	}
        	else errors.add('Problem identifying the focused tab.  Try again.');
        }

    	if (!errors.isEmpty()) return false;
    	return true;
    }

    public PageReference Cancel() {

    	return new PageReference('/' + oppId);
    }
}