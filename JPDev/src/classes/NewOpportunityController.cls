/*******************************************************************
Name            : NewOpportunityController
Author          : Byrnes
Date            : September 30, 2013
Related Task    : CC-922
*************************************************************************/

public class NewOpportunityController {
    
    //Public stuff...  (referenced on the .page file)
    public Opportunity newOpp {get; set;}
    public Opportunity renewalOppSource {get; set;}                 //Only used when coming from 'Create Renewal Opportunity' link.
    public Account currentAccount {get; set;}
    public List<String> errors {get; set;}
    public List<String> warn {get; set;}
    public List<SelectOption> contactOptions {get; set;}
    public Integer rowNum {get; set;}
    public List<OpportunityLineItem> oppLineItems {get; set;}       //'Description' is holding just the placeholder text from the selectList.  It will be used in conjunction with the newOpp.CurrencyIsoCode to find the correct pricebookentry records upon save.
    public List<SelectOption> productOptions {get; set;}
    public List<SelectOption> productGroupOptions {get; set;}
    public String switcherooLabel {get; set;}                       //for the toggle commandbutton...
    public Boolean UseThePicklist {get; set;}                       //for the toggle...
    public User currentUser {get; set;}                 
    public Boolean userCanChangeBrandTag {get; set;}
    
    //Private stuff... (reference internally only)
    private Boolean isRenewal {get; set;}
    private PageReference pgReturnPage {get; set;}
    
    private String accountID {get; set;}
    private String contactID {get; set;}
    private String campaignID {get; set;}               //used only on page IF the user is coming from the campaign screen.
    private Boolean setDefaultContact {get; set;}       //used only on page IF the user is coming from the contact screen.  After that, it's ignored...
    private String defaultCountryId {get; set;}         //used for Country defaults.  Populated upon account change as it's driven by the account.
    private String AccountWarn {get; set;}              //used for Account Warnings

    public NewOpportunityController(ApexPages.StandardController controller) {
        
        PrepPage();
    }
    
    private void PrepPage() {   
        
        pgReturnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
        
        currentUser = [SELECT Username, Id, State, Country, DefaultBrand__c, Default_BrandTag__c, FirstName, Name, LastName, Title, UserType, CurrencyIsoCode FROM User WHERE Id = :Userinfo.getUserID()];
        
        //Setup the opportunity...
        newOpp = new Opportunity();         
        oppLineItems = new List<OpportunityLineItem>();
        
        errors = new List<String>();
        warn = new List<String>();
        contactOptions = new List<SelectOption>();
        
        SetAvailableProducts();

        //Check if this should be a renewal oppportunity...
        if (ApexPages.currentPage().getParameters().get('renewOpp') != null) {          
            string renewOppId = ApexPages.currentPage().getParameters().get('renewOpp');
            isRenewal = true;
            
            renewalOppSource = [SELECT  Account_Brand__c, AccountId, StageName, Source_Opportunity__c, Renewal_Opportunity__c, CampaignId,
                                        Account_Name__c, Account_Number__c, Account_State__c, Contact__c, Currency__c, Description, 
                                        Name, Id, CurrencyIsoCode, Type, Primary_Brand__c, BrandTag__c, Renewal_Comments__c, Renewal_Owner__c, Sold_By_Partner__c,
                                        Renewal_Owner_Email__c, (SELECT Country__c, Quantity, UnitPrice, CurrencyIsoCode, PricebookEntryId, Product_Group__c, BrandTag__c, Sub_Category__c FROM OpportunityLineItems)
                                FROM Opportunity
                                WHERE Id = :renewOppId ];
        }
        else isRenewal = false; 

        newOpp.Primary_Brand__c = currentUser.DefaultBrand__c;
        newOpp.BrandTag__c = currentUser.Default_BrandTag__c;
        
        switcherooLabel = 'Use the lookup';
        UseThePicklist = true;
        
        //BrandTag accessibility now...
        CheckBrandTagPermissions();
        
        if (isRenewal) PrepPageForRenewalOpp();
        else PrepPageForNewOpp();                   
    } 
    
    private void PrepPageForRenewalOpp() {   
    
        if (renewalOppSource != null) {
            accountID = renewalOppSource.AccountId;
            contactID = renewalOppSource.Contact__c;
            campaignID = renewalOppSource.CampaignId;
            newOpp.Primary_Brand__c = renewalOppSource.Primary_Brand__c;
            if (renewalOppSource.BrandTag__c != null) newOpp.BrandTag__c = renewalOppSource.BrandTag__c;
            newOpp.AccountId = accountID;
            newOpp.Source_Opportunity__c = renewalOppSource.Id;
            
            newOpp.Name = 'Renewal: ' + renewalOppSource.Name.replace('Renewal: ', '');     //Get rid of previous 'Renewal: ' text so as to not end up with opps named:  'Renewal: Renewal: Renewal: Renewal: 5 Jobs', etc.
            
            RefreshContactDropDown();
            
            //check if we need to use the lookup control...
            RenderTheCorrectContactControl();
            
            newOpp.Contact__c = contactID;
            newOpp.Sold_By_Partner__c = renewalOppSource.Sold_By_Partner__c;
            
            SetLeadSource();
            SetDefaultCountry();
            DefaultTaxFields();
            checkforAccountWarn();
            
            newOpp.Renewal_Feedback__c = 'Not Submitted';
            newOpp.StageName = 'Qualified Need';
            
            InitializeOppProductList();
        }
        else {
            //Unable to find the source opp...
        }
    }
    
    private void CheckBrandTagPermissions() {

        if (!Schema.SObjectType.Opportunity.fields.BrandTag__c.isUpdateable()) userCanChangeBrandTag = false;
        else userCanChangeBrandTag = true;
    }

    private void RenderTheCorrectContactControl() {
    
        if ((renewalOppSource != null) && (renewalOppSource.Contact__c != null)) {
            
            //search the contactOptions list and see if this particular contactID is an option...
            //This will drive whether we first display the picklist or lookup control to the user...
            
            for (Selectoption so : contactOptions) {
                if (so.getValue() == renewalOppSource.Contact__c) {
                    
                    //If we're here, then the contact exists in the picklist...
                    
                    switcherooLabel = 'Use the lookup';
                    UseThePicklist = true;
                    return;
                }
            }
        }
        
        switcherooLabel = 'Use the picklist';
        UseThePicklist = false;
    }
    
    private void PrepPageForNewOpp() {
      
        //set the accountID if we came from the Account page...
        accountID = ApexPages.currentPage().getParameters().get('accid');
        
        //set the contactID if we came from the Contact page...
        contactID = ApexPages.currentPage().getParameters().get('conid');
        if ((contactID != null) && (contactID != '')) setDefaultContact = true;
        else setDefaultContact = false;
        
        //set the campaignID if we came from the Campaign page...
        campaignID = ApexPages.currentPage().getParameters().get('campid');
        
        //Example here is the 'Create Opportunity' button from the Campaign Member object.
        if (((accountID == null) || (accountID == '')) && (setDefaultContact)) accountID = [SELECT AccountId FROM Contact WHERE Id = :contactID LIMIT 1].AccountId;
        
        if ((accountID != null) && (accountID != '')) newOpp.AccountId = accountID;
        
        RefreshContactDropdown();
                
        if (setDefaultContact) newOpp.Contact__c = contactID;
        
        SetLeadSource();
        SetDefaultCountry();
        DefaultTaxFields();
        checkforAccountWarn();
                
        InitializeOppProductList();
        
        //Default, not showing this on the screen.
        newOpp.Renewal_Feedback__c = 'Not Submitted';
        newOpp.StageName = 'Unqualified Need';
            
        if ((campaignID != null) && (campaignID != '')) newOpp.CampaignId = campaignID;             
    }
    
    public PageReference Cancel() {        
        return pgReturnPage;
    }
    
    public PageReference AccountChanged() {
       
        contactOptions = RefreshContactDropdown();      
        SetDefaultCountry();
        checkforAccountWarn();
        
        return null;
    }
    
    
    public PageReference SwitcherooClick() {
  
        if (switcherooLabel == 'Use the picklist') {
            
            //Then we're now on the picklist...
            
            switcherooLabel = 'Use the lookup';         
            UseThePicklist = true;
            newOpp.Sold_By_Partner__c = null;
            
            //This sets the bound contact to the first option in the select list if we're toggling back FROM the lookup control.
            if ((contactOptions.size() > 0) && (contactOptions[0].getValue() != '')) {
                
                //First, check and see if the contact is in the list, if so, that's the one to use...
                if (newOpp.Contact__c != null) {
                    for (SelectOption so : contactOptions) {
                        //If the contact exists in the picklist, then don't do anything...
                        if (so.getValue() == newOpp.Contact__c) return null;
                    }
                }
                
                //Then we have at least one viable option as the contact did not exist in the picklist - change it and update the values...
                newOpp.Contact__c = contactOptions[0].getValue();
                ContactChanged();
            }
        }
        else {
            switcherooLabel = 'Use the picklist';
            UseThePicklist = false;
            
            //No need to do extra processing here as ALL contacts in the picklist are ALWAYS viable options in the lookup control.
        }
        
        return null;
    }
    
    public List<SelectOption> RefreshContactDropdown() {
     
        Boolean setContact = true;
        
        contactOptions = new List<SelectOption>();
        
        if (newOpp.AccountId != null) {
            for (Contact c : [SELECT AccountId, Id, FirstName, LastName, Title FROM Contact WHERE AccountId = :newOpp.AccountId ORDER BY LastName ASC]) {
                
                //set the first contact found to the opp's contact
                if (setContact) {
                    newOpp.Contact__c = c.Id;
                    setContact = false;
                }
                
                contactOptions.add(new SelectOption(c.Id, c.LastName + ', ' + c.FirstName));
            }
        } else {
            contactOptions.add(new SelectOption('', 'Select an account first...'));
        }
        
        return contactOptions;
    }
  
        
    public void SetAvailableProducts() {
      
        productOptions = new List<SelectOption>();      

        SelectOption blank = new SelectOption('null', '--None--');
        
        productOptions.add(blank);

        for (Product2 p : [SELECT Name FROM Product2 WHERE IsActive = true ORDER BY Name Asc]) {
            SelectOption s = new SelectOption(p.Name, p.Name);
            
            productOptions.add(s);
        }
    }
                
    //Called from the action script.
    public void ContactChanged() {
  
        SetDefaultCountry();        //this updates the country for all oppProducts to the new contact's country.
        checkforAccountWarn();
        SetLeadSource();            //checks for a lead source and populates it if a match is found from a recently converted lead...
        SetSoldByPartner();
    }
         
    public void SetSoldByPartner() {
       
        if ((newOpp.Contact__c != null) && (UseThePicklist == false)) {
            Contact c = [SELECT Id, Name, Account.Id, Account.Channel_Partner__c FROM Contact WHERE Id = :newOpp.Contact__c ];
            
            if ((c != null) && (c.Account != null) && (c.Account.Channel_Partner__c == true) && (c.Account.Id != newOpp.AccountId)) newOpp.Sold_By_Partner__c = c.Account.Id;
            else newOpp.Sold_By_Partner__c = null;
        }
        else newOpp.Sold_By_Partner__c = null;
    }
         
    public void SetLeadSource() {
   
        //Popluate lead source here as well if a good match is found...
        List<Lead> possibleResults = [SELECT LeadSource FROM Lead WHERE ConvertedContactId = :newOpp.Contact__c AND ConvertedDate >= YESTERDAY LIMIT 1];
        if ((possibleResults != null) && (possibleResults.size() > 0)) newOpp.LeadSource = possibleResults[0].LeadSource;
    }
    
    public void DeleteProductBrandRow() {
      
        rowNum = Integer.valueOf(apexpages.currentpage().getparameters().get('index'));
                
        oppLineItems.remove(rowNum);
    }    
        
    private void SetDefaultCountry() {
        
        //Unfortunately there are plenty of examples where there is a country in the contact mailingCountry, but the corresponding lookup isn't populated.
        //We have to do this the ugly way because of that...
        String oldDefault = defaultCountryId;
        String countryName = null;
        Contact placeHolderContact;
        pw_ccpro__CountryObject__c countryLookup = null;

        if (newOpp.Contact__c != null) {
            placeHolderContact = [SELECT MailingCountry FROM Contact WHERE Id = :newOpp.Contact__c LIMIT 1];
            
            if ((placeHolderContact != null) && (placeHolderContact.MailingCountry != null)) {
                countryLookup = [SELECT Id, Name FROM pw_ccpro__CountryObject__c WHERE Name = :placeHolderContact.MailingCountry LIMIT 1];
                if (countryLookup != null) defaultCountryId = countryLookup.Id; 
            }
            else defaultCountryId = null;
        }
        else defaultCountryId = null;
        
        if ((oldDefault != defaultCountryId) && (defaultCountryId != null) && (oppLineItems != null)) {
            for (OpportunityLineItem oli : oppLineItems) {
                oli.Country__c = defaultCountryId;
            }
        }               
    }
    
    private void checkforAccountWarn() {
    
         if (newOpp.AccountId != null) {
            
            warn = new List<String>();
            Set<String> allWarns = new Set<String>();
            
            currentAccount = [SELECT Name, Accounting_Flag__c FROM Account WHERE Id = :newOpp.AccountId];
            
            if (currentAccount != null) {
                AccountWarn = currentAccount.Accounting_Flag__c;
                //this is a test
                if ((AccountWarn != null) && (AccountWarn.contains('SDN'))) {
                    warn.add(label.SDN_Warning_Message);
                }
            }
        }
        
    }
    
    private void DefaultTaxFields() {
        
        if (newOpp.AccountId != null) currentAccount = [SELECT Name, isTax_Exempt__c, Eurozone_Account_without_VAT__c, Tax_Exempt_Certificate_ID__c, Tax_Number__c FROM Account WHERE Id = :newOpp.AccountId];
            
        if (currentAccount == null) return;
       
        if (currentAccount.isTax_Exempt__c == true) newOpp.Tax_Exempt__c = true; 
       
        if (currentAccount.Tax_Exempt_Certificate_ID__c != null) newOpp.Certification_Number__c = currentAccount.Tax_Exempt_Certificate_ID__c; 
         
        if (currentAccount.Tax_Number__c != null) newOpp.GST_VAT_Tax__c = currentAccount.Tax_Number__c;  
        
        if(currentAccount.Eurozone_Account_without_VAT__c == true) newOpp.Eurozone_Account_without_VAT__c = true; // CCBOB 95
    }
    
    private void InitializeOppProductList() {
          
        if (isRenewal) {
            
            List<Id> pricebookEntryIDs = new List<Id>();
            
            oppLineItems = new List<OpportunityLineItem>();
            
            //Map to translate pricebookentryID to product brand friendly text.
            //Map<Id, String> pricebookIDToNameMap = new Map<Id, String>(); 
            
            for (OpportunityLineItem oli : renewalOppSource.OpportunityLineItems) {
                pricebookEntryIDs.add(oli.PricebookEntryId);    
            }
            
            //for (PricebookEntry pbe : [SELECT Name, Id FROM PricebookEntry WHERE Id IN :pricebookEntryIDs]) {
                //if (!pricebookIDToNameMap.containsKey(pbe.Id)) pricebookIdToNameMap.put(pbe.Id, pbe.Name);
            //}                       
                
            for (OpportunityLineItem oli : renewalOppSource.OpportunityLineItems) { 
                OpportunityLineItem newOLI = new OpportunityLineItem();                

                newOLI.Country__c = oli.Country__c;
                newOLI.BrandTag__c = oli.BrandTag__c;
                newOLI.Product_Group__c = oli.Product_Group__c;
                newOLI.Sub_Category__c = oli.Sub_Category__c;
                newOLI.Quantity = 1;
                newOLI.UnitPrice = oli.UnitPrice;
                newOLI.Description = String.valueOf(oli.UnitPrice);     //for the temporary UI holding...  unitprive is 
                //newOLI.UnitPrice = 0.0;
            
                //if (pricebookIDToNameMap.containsKey(oli.PricebookEntryId)) {
                    //newOLI.Description = pricebookIDToNameMap.get(oli.PricebookEntryId);
                    //oppLineItems.add(newOLI);
                //}
                oppLineItems.add(newOLI);
                
                //we are NOT adding the OLI to the listview if it's not found.
            }
        }
        else {
            oppLineItems = new List<OpportunityLineItem>();
            OpportunityLineItem oli = new OpportunityLineItem();
                    
            if (defaultCountryId != null) oli.Country__c = defaultCountryId;
            oli.Quantity = 1;
            oli.UnitPrice = 0;
            oli.Description = '';
            
            //if (currentUser.DefaultBrand__c != null) oli.Description = currentUser.DefaultBrand__c;
            if (currentUser.Default_BrandTag__c != null) oli.BrandTag__c = currentUser.Default_BrandTag__c;
            
            oppLineItems.add(oli);
        }
    }
    
    public PageReference AddProductBrandRow() {
       
        OpportunityLineItem oli = new OpportunityLineItem();
                
        if (defaultCountryId != null) oli.Country__c = defaultCountryId;
        oli.Quantity = 1;
        oli.UnitPrice = 0;
        oli.Description = '';
        
        //if (currentUser.DefaultBrand__c != null) oli.Description = currentUser.DefaultBrand__c;
        if (currentUser.Default_BrandTag__c != null) oli.BrandTag__c = currentUser.Default_BrandTag__c;
        
        oppLineItems.add(oli);
        
        return null;
    }
    
    //Validate all the data here...
    //Note that this is really a secondary validation as the required fields logic still fires, though is mostly overridden on the page on purpose (to allow for no ajax postback interrupts)
    private Boolean Validate() {
     
        //reset the error collection...
        errors = new List<String>();        
                       
        //Account name
        if (newOpp.AccountId == null)  errors.add('Missing Account Name');
        
        //Opp name
        if ((newOpp.Name == null) || (newOpp.Name.length() < 1)) errors.add('Missing Opportunity Name');

        //Stage
        if ((newOpp.StageName == null) || (newOpp.StageName.length() < 1)) errors.add('Missing Stage');

        //Primary Brand
        if ((newOpp.Primary_Brand__c == null) || (newOpp.Primary_Brand__c.length() < 1)) errors.add('Missing Primary Brand');

        //Close Date
        if (newOpp.CloseDate == null) errors.add('Missing Close Date');

        //BrandTag
        if ((newOpp.BrandTag__c == null) || (newOpp.BrandTag__c.length() < 1)) errors.add('Missing BrandTag');

        //Currency
        if ((newOpp.CurrencyIsoCode == null) || (newOpp.CurrencyIsoCode.length() < 1)) errors.add('Missing Currency');
   
        //Contact
        if (newOpp.Contact__c == null) errors.add('Missing Contact');
            
        //Renewal Feedback limitation
        if (newOpp.Renewal_Feedback__c == 'Opportunity Created') errors.add('Renewal Feedback may not equal Opportunity Created.');
        
        //Renewal Feedback limitation
        if (newOpp.Renewal_Feedback__c == 'Declined – Other') errors.add('Renewal Feedback may not equal Declined – Other.');
        
        //Ensure that the Sold By Partner != Account
        if ((newOpp.Sold_By_Partner__c != null) && (newOpp.Sold_By_Partner__c == newOpp.AccountId)) errors.add('Account and Sold By Partner may not be the same.');
        
        if ((oppLineItems == null) || (oppLineItems.size() < 1)) errors.add('At least one Product Brand must be added');
        
        //Contact verification in case if the user types it in...
        if (newOpp.Contact__c != null) {
            
            Boolean bContactIsOkay = false;
            
            Contact c = [SELECT Id, Account.Id, Account.Channel_Partner__c FROM Contact Where Id = :newOpp.Contact__c];
            
            if ((c != null) && (c.Account != null)) {
                if (c.Account.Id == newOpp.AccountId) bContactIsOkay = true;
                else if (c.Account.Channel_Partner__c == true) bContactIsOkay = true;               
            }
            
            if (bContactIsOkay == false) errors.add('Invalid Contact.  The Contact must either belong to the Account, or it must belong to a Channel Partner account to be valid.');            
        }
        
        Set<String> uniqueExternalID = new Set<String>();
        
        if ((oppLineItems != null) && (oppLineItems.size() > 0)) {
            
            //make sure every line item has a price, a quantity greater than 0 and a country.
            Integer productBrandNumber = 1;
            Set<Id> countrySet = new Set<Id>();
            
            for (OpportunityLineItem oli : oppLineItems) {          
                
                if ((oli.Country__c == null) || (oli.Description == null) || (oli.Description == '') || (oli.BrandTag__c == null) || (oli.Product_Group__c == null)) errors.add('The Product Brand in row ' + productBrandNumber + ' is missing required information.  (Value, BrandTag, Product Group & Country must be populated.)');

                if (oli.Description.length() > 0) if (!NumberIsValid(oli.Description)) errors.add('The Product Brand in row ' + productBrandNumber + ' has an invalid Price.  Maximum value is 16.2 in length.');

                productBrandNumber++;
                
                //External ID validation now...
                uniqueExternalID.add(oli.BrandTag__c + '__' +  oli.Product_Group__c + '__' + oli.Country__c);
                countrySet.add(oli.Country__c);
            }
            
            //verify country is enabled...
            for (pw_ccpro__CountryObject__c ccpro : [SELECT pw_ccpro__Enabled__c, Name, Id FROM pw_ccpro__CountryObject__c WHERE Id IN :countrySet]) {
                if (ccpro.pw_ccpro__Enabled__c == false) errors.add(ccpro.Name + ' is invalid as it is not an active country.');
            }       
        }
        
        if (uniqueExternalID.size() != oppLineItems.size()) errors.add('Duplicate Product BrandTag / Product Group / Country rows found.  If a Product BrandTag is to be entered more than once, the Product Group and Country must differ.');


 System.debug('errors@@@@@@@@@@' +errors);       
        if (errors.size() > 0) return false;
        return true;
    }
    
    private Boolean NumberIsValid(String s) {
   
        try {
            Decimal d = Decimal.valueOf(s);
        }
        catch (exception e) {
            return false;
        }
            
        String[] splitUp = s.split('\\.');
        
        if (splitUp.size() > 2) return false;
        
        if (splitUp.size() == 1){
            if (splitUp[0].length() > 16) return false;
            else if (!splitUp[0].IsNumeric()) return false; 
        }
        
        if (splitUp.size() == 2) {
            if (splitUp[0].length() > 16) return false;
            else if (!splitUp[0].IsNumeric()) return false;
            
            if (splitUp[1].length() > 2) return false;          
            else if (!splitUp[1].IsNumeric()) return false;
        }  

        //If we made it this far, we're good.
        return true;    
    }
    
    public PageReference SaveItAll() {
    
        //save all the pieces - first being the raw opp itself.  
        Boolean GoodToGo = Validate();
        
        if (GoodToGo) {     
            
            SaveBaseOpportunity();
            SaveOppLineItems();

            //This will redirect the user to the saved opportunity that was just created...     
            PageReference newOppPage = new PageReference('/' + newOpp.Id);
            newOppPage.setRedirect(true);
            return newOppPage;
        }
        else {
            //this will redraw the page and update the pagemessage error pane.
            return null;
        }
    }
    
    private void SaveBaseOpportunity() {
        
        insert newOpp;
        
    }
    
    private void SaveOppLineItems() {
        
        CorrectOppLineItems();    
        
        for (OpportunityLineItem oli : oppLineItems) {                                  
            oli.OpportunityId = newOpp.Id;
            oli.Quantity = 1;
        }
        
        if (oppLineItems.size() > 0) insert oppLineItems;
    }
    
    //This corrects the opportunity line items and takes out the 'description' field (which is (WAS) temporarily storing the user's selected product name)
    //and compares against newOpp.currencyIsoCode to find the correct pricebookentryId.  Updates the list in order to insert these records correctly.
    //This has now been edited (again) as we're only exposing 'BrandTag' to the users - Brand (Product) will be derived.
    private void CorrectOppLineItems() {
    
        //Key here is the brand name (Dice, Rigzone, etc) - the ID returned will be the correct PricebookEntry Id for said brand based on the opp's currency.
        Map<String, Id> productBrandMap = new Map<String, Id>();
        
        for (PricebookEntry pbe : [SELECT Id, Name FROM PricebookEntry WHERE CurrencyIsoCode = :newOpp.CurrencyIsoCode ORDER BY Name ASC]) {
        
            if (!productBrandMap.containsKey(pbe.Name)) productBrandMap.put(pbe.Name, pbe.Id);                  
        }

        //Create the map for the value translation.  Hardcoded is a terrible idea, but until we opt to put applicable brandTags beneath the 'Brand' object, not much else can be done.
        Map<String, String> brandTagBrandMap = new Map<String, String>();
        brandTagBrandMap.put('eFC-EMEA', 'eFinancialCareers');
        brandTagBrandMap.put('eFC-Asia', 'eFinancialCareers');
        brandTagBrandMap.put('eFC-Aus', 'eFinancialCareers');
        brandTagBrandMap.put('eFC-Amer', 'eFinancialCareers');
        brandTagBrandMap.put('eFC-China', 'eFinancialCareers');
        brandTagBrandMap.put('ClearanceJobs', 'ClearanceJobs');
        brandTagBrandMap.put('Dice', 'Dice');
        brandTagBrandMap.put('Rigzone', 'Rigzone');
        brandTagBrandMap.put('RZ-Apac', 'Rigzone');
        brandTagBrandMap.put('RZ-Amer', 'Rigzone');
        brandTagBrandMap.put('RZ-MiddleEast', 'Rigzone');
        brandTagBrandMap.put('RZ-EurAfrica', 'Rigzone');        
        brandTagBrandMap.put('HealthCallings', 'HealthCallings');

        //Loop through and populate Description based on the BrandTag now...

        for (OpportunityLineItem oli : oppLineItems) {
            //first, save the unit price
            oli.UnitPrice = Decimal.valueOf(oli.Description);

            //then, fix the description.
            if (brandTagBrandMap.containsKey(oli.BrandTag__c)) oli.Description = brandTagBrandMap.get(oli.BrandTag__c);
        }
        
        for (OpportunityLineItem oli : oppLineItems) {
            if (productBrandMap.containsKey(oli.Description)) {
                oli.PricebookEntryId = productBrandMap.get(oli.Description);
                oli.Description = null;
            }
            else {
                //If we're here then the selected product has no matching pricebookentry record for said currency
                //which means it can't be sold.  Perhaps the system admins and/or the user creating the opp should be notified?
            }
        }       
    }    
}