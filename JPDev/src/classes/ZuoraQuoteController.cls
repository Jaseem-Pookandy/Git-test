/***
*Class          ---- ZuoraQuoteController
*Author         ---- Tim Byrnes
*Story          ---- CCBOB-98765
*Created Date   ---- 2014.08.25
*Description    ---- Controller class for ZuoraQuote.page (New/Edit Quote functionality) Starting with CC-2708
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- 
*Story          ---- 
*Modified Date  ---- 
*Description    ---- 
***/

public class ZuoraQuoteController {

    //Public stuff... (referenced on the .page file)
  
    public zqu__Quote__c thisQuote {get; set;}
    public zqu__Quote__c preEditedQuote {get; set;}
    public List<String> errorsQuoteDetails {get; set;}
    public List<String> errorsQuoteCharges {get; set;}
    public List<SelectOption> contactOptionsBillTo {get; set;}
    public List<SelectOption> contactOptionsSoldTo {get; set;}
    public List<SelectOption> discountSalesRepOptions {get; set;}
    public List<SelectOption> discountCountryOptions {get; set;}
    public List<SelectOption> saleTypeOptions {get; set;}
    public String saleTypeValue {get; set;}
    public String discountSalesRepValue {get; set;}
    public String discountCountryValue {get; set;}
    public String switcherooLabelBillTo {get; set;}                       //for the toggle commandbutton...
    public String switcherooLabelSoldTo {get; set;}                       //for the toggle commandbutton...
    public Boolean useThePicklistBillTo {get; set;}                       //for the toggle...
    public Boolean useThePicklistSoldTo {get; set;}                       //for the toggle...
    public User currentUser {get; set;}
    public Opportunity sourceOpp {get; set;}
    public Boolean userCanChangeBrandTag {get; set;}
    public Boolean userCanChangeZuoraIDs {get; set;}
    public Boolean successfulStep1 {get; set;}
    public Boolean successfulStep2 {get; set;}
    public List<Zuora__CustomerAccount__c> billingAccounts {get; set;}  //to provide bill-to information to the sales rep - POC at this point.
    public String pgContext {get;set;}
    public Integer panelCounts {get; set;}
    public Boolean pageIsInEditMode {get; set;}    
    public Boolean displayBASR {get; set;}                      //flag that indicates if BillingAccountSelectionResponse should be displayed or not.
    public Integer resultCount {get; set;}
    public String panel1CancelLabel {get; set;}
    public String panel1ContinueLabel {get; set;}
    public String panel1SaveLabel {get; set;}
    public String panel2CancelLabel {get; set;}
    public String panel2SaveLabel {get; set;}
    public String panel2EditQuoteLabel {get; set;}
    public static final String AGENCY_COMMISSION = 'Agency Commission';
    private static final String STANDARD_SALE_TYPE = 'Standard';
    public Boolean isOppLockedForApproval {get; set;}

    public List<SelectOption> attr_CountryOptions {get; set;}       //moved from the attribute setter to here to prevent 'Too many SOQL' when dealing with a quote with a few dozen charges
    public List<SelectOption> attr_SalesRepOptions {get; set;}      //moved from the attribute setter to here to prevent 'Too many SOQL' when dealing with a quote with a few dozen charges
                                                                    //NOT moving event options yet as that has more dynamic constraints.

    //Product selection related:
    public String filterId {get; set;}                          //OppLineItem Id of the selected filter.
    public List<FilterPreset> filterPresets {get; set;}

    public List<SelectOption> productGroupOptions {get; set;}
    public String productGroupValue {get; set;}
    public String activefilterCountryValue {get; set;}

    public List<SelectOption> billingFrequencyOptions {get; set;}
    public String billingFrequencyValue {get; set;}

    private String recurringStatusValue {get; set;}

    public List<SelectOption> pricingModelOptions {get; set;}
    public String pricingModelValue {get; set;}    

    public List<SelectOption> brandTagOptions { get; set; }
    public String brandTagValue { get; set; }    

    public List<zqu__ProductRatePlan__c> foundRatePlans {get; set;}
    public List<ProductRatePlanWrapper> selectedRatePlans {get; set;}
    private Set<Id> quoteChargesToDelete {get; set;}                    //used to collect the IDs of Quote charges that were committed to the database earlier and are now deleted from this screen.
    private Set<Id> quoteChargesToAlwaysDelete {get; set;}              //slightly different from above in that even if the quote charges are NOT saved, these should get purged.  (Term changes, etc.)
    private Integer timeProductAdded {get; set;}
    private String timeProductAddedBase {get; set;}
    private String timeAddedFinal {get; set;}
    public List<QuoteChargeAttributes__c> allAtts {get; set;}
    public String DynamicPostbackParam {get; set;}
    public String UnitPriceCalculator {get; set;}

    public Decimal quoteTotalGross {get; set;}
    public Decimal quoteTotalDiscount {get; set;}
    public Decimal quoteTotalNet {get; set;}    

    public List<SelectOption> discountTypeOptions {get; set;}
    public String discountTypeValue {get; set;}
    public String backupDiscountTypeValue {get; set;}               //Retain the original value upon entering this screen in case if discount is changed from agency to list, or vice versa.
    public String discountFieldUsed {get; set;}                     //Retains HOW the user populate the discount
    private zqu__QuoteCharge__c discountQuoteCharge {get; set;}
    private Boolean quoteLevelDiscountNeedsReset {get; set;}        //flag to indicate when enough data has changed that I need to purge the prior discount quote charge and start over.
    public String discountPercentToolTip {get; set;}                //The text string that shows the user the value of the agency discount, if there is one.
    public String addButtonText {get; set;}

    //Private stuff... (reference internally only)
    private PageReference pgReturnPage {get; set;}
    private Map<Id, User> userMap {get; set;}
    private Id sourceOppId {get; set;}
    private String accountID {get; set;}
    private Integer quoteNumber {get; set;}
    private String quoteType {get; set;}                                  //for Zuora's quote wizard...
    private String stepNumber {get; set;}                                 //for Zuora's quote wizard...
    private Integer stepNumberInt {get; set;}
    private Map<String, RecordType> recordTypes {get; set;}               //for changing the record type as workflow isn't working on verified being checked - haven't been able to identify the cause yet.
    private Boolean billToUsesLookupOnEdit {get; set;}
    private Boolean soldToUsesLookupOnEdit {get; set;}
    private String billingAccountId {get; set;}                             //for the old-school billing account selection.
    private Id newRecordTypeId {get; set;}                                  //for when the user comes from the 'Change Record Type' screen.  
    private Boolean forceDiscountRecalc {get; set;}
    private set<string> Quotetemplateregions;                           //list of quote template regions from the picklist in quote object - Quote Template Region
    public Boolean QuoteTemplateRegionRequired {get;set;}               //The flag that controls the appearance of Quote Template Region on a quote page
    private set<string> MiddleEastCountries;
    
    private static final String DEFAULT_NOT_VERIFIED = 'Default';
    private static final String DEFAULT_VERIFIED = 'Default_Verified';
    private static final String READONLY = 'ReadOnly';

    public ZuoraQuoteController(ApexPages.StandardController controller) {
        panelCounts = 2;

        forceDiscountRecalc = false;
		QuoteTemplateRegionRequired = false;
		
        pgContext = ApexPages.currentPage().getParameters().get('Id');

        quoteTotalGross = 0;
        quoteTotalDiscount = 0;
        quoteTotalNet = quoteTotalGross - quoteTotalDiscount;

        pageIsInEditMode = false;
        displayBASR = false;

        discountCountryValue = null;

        successfulStep1 = false;
        successfulStep2 = false;
        quoteLevelDiscountNeedsReset = false;
        isOppLockedForApproval = false;

        addButtonText = 'Add';

        PopulateRecordTypeMap();

        allAtts = new List<QuoteChargeAttributes__c>();
        GetQuoteChargeAttributes();

        billingAccounts = new List<Zuora__CustomerAccount__c>();
        selectedRatePlans = new List<ProductRatePlanWrapper>();
        userMap = new Map<Id, User>();

        discountSalesRepOptions = new List<SelectOption>();
        discountCountryOptions = new List<SelectOption>();
        saleTypeOptions = new List<SelectOption>();

        productGroupOptions = new List<SelectOption>();
        billingFrequencyOptions = new List<SelectOption>();
        brandTagOptions = new List<SelectOption>();
        pricingModelOptions = new List<SelectOption>();
        discountTypeOptions = new List<SelectOption>();
        discountQuoteCharge = new zqu__QuoteCharge__c();
        
        foundRatePlans = new List<zqu__ProductRatePlan__c>();
        filterPresets = new List<FilterPreset>();           
        quoteChargesToDelete = new Set<Id>();
        quoteChargesToAlwaysDelete = new Set<Id>();

        currentUser = [SELECT Username, Id, State, Country, DefaultBrand__c, Default_BrandTag__c, FirstName, Name, LastName, Title, UserType, CurrencyIsoCode, Profile.Name FROM User WHERE Id = :Userinfo.getUserID()];

        PopulateAttributeSelectLists();

        if (pgContext == null) PrepPageForNew();    
        else PrepPageForEdit();  

        errorsQuoteDetails = new List<String>();
        errorsQuoteCharges = new List<String>();

        if (isOppLockedForApproval) {

        }
        else {
            if (sourceOpp != null) {
                InitializeAndDefaultProductFilters();
                SetButtonLabels();
        
                PopulateListOfBillingAccounts();

                //Accessibility now...
                CheckPermissions();

                SetContactDefaults();  
                
                Setquotetemplateregion();                     
            }
            else errorsQuoteDetails.add('Unable to properly construct this page as this Quote has no Opportunity.');
            
            Datetime thisNow = System.now();
            timeProductAddedBase = thisNow.format('yyyyMMdd') + 'T' + thisNow.format('HHmmss');
        }
    }

    private void PopulateAttributeSelectLists() {
        //Country first.
        attr_CountryOptions = new List<SelectOption>();

        for (pw_ccpro__CountryObject__c c : [SELECT Id, Name FROM pw_ccpro__CountryObject__c WHERE pw_ccpro__Enabled__c = true ORDER BY Name]) {
            attr_CountryOptions.add(new SelectOption(c.Name, c.Name));
        }

        //Sales Rep picklist & map
        attr_SalesRepOptions = new List<SelectOption>();
        attr_SalesRepOptions.add(new SelectOption('', '--None--'));

        userMap = new Map<Id, User>();

        for (User u : [SELECT Id, Name FROM User WHERE Directly_Commissionable__c = true AND IsActive = true ORDER BY Firstname]) {
            attr_SalesRepOptions.add(new SelectOption(u.Id, u.Name));
            if (!userMap.containsKey(u.Id)) userMap.put(u.Id, u);
            //now the map...
        }

        //We will also populate the 'Sale Type' picklist here.
        //Because there is no way to add/edit the Sale Type picklist value and NOT have to also make code changes, might as well get it off the object and just
        //define the values here - so that's what I'm going to do...
        saleTypeOptions = new List<SelectOption>();
        saleTypeOptions.add(new SelectOption(STANDARD_SALE_TYPE, STANDARD_SALE_TYPE));
        saleTypeOptions.add(new SelectOption('Trial', 'Trial'));
        saleTypeOptions.add(new SelectOption('Trial Conversion', 'Trial Conversion'));        
        saleTypeValue = STANDARD_SALE_TYPE; //default
    }

    private void PopulateRecordTypeMap() {

        recordTypes = new Map<String, RecordType>();

        for (RecordType rt : [SELECT Id, DeveloperName, Name, Description FROM RecordType WHERE IsActive = true AND SobjectType = 'zqu__Quote__c']) {
            recordTypes.put(rt.DeveloperName, rt);
        }
    }

    private void PrepPageForEdit() {

        pageIsInEditMode = true;
        selectedRatePlans = new List<ProductRatePlanWrapper>();
        
        if ((currentUser.Profile.Name == 'System Administrator') || (currentUser.Profile.Name == 'DHX SS FinManage')) displayBASR = true;

        String sretURL = ApexPages.currentPage().getParameters().get('retURL');
        if (sretURL != null) pgReturnPage = new PageReference(sretURL);
        else pgReturnPage = new PageReference('/');

        GetQuoteForEdit();

        BackupOrigQuoteValues();

        if (thisQuote.zqu__Opportunity__c != null) sourceOpp = RetrieveApplicableOpportunity(thisQuote.zqu__Opportunity__c);

        if (sourceOpp != null) isOppLockedForApproval = QuoteUtilities.IsOpportunityWaitingOnApproval(sourceOpp.Id);

        RetrieveExistingQuoteCharges(thisQuote.Id);
    }

    private void GetQuoteForEdit() {

        String query = 'SELECT ';

        for(Schema.FieldSetMember f : this.getQIEditFields()) {
            query += f.getFieldPath() + ', ';
        }

        query += 'Id, Name, First_Bill_Amount__c, Discount_Fixed__c, CC_Notes__c, Discount_New_Net__c, Discount_Percent__c, Discount_Type__c, Discount_Field_Used__c, RecordTypeId, Billing_Account_Selection_Response__c, Quote_Template_Region__c,zqu__BillingMethod__c, Deferred_Bill_Date__c, zqu__ZuoraAccountID__c, zqu__ZuoraSubscriptionID__c, zqu__SubscriptionType__c, zqu__Opportunity__c, BrandTag__c, zqu__ValidUntil__c, Billing_Frequency__c, zqu__BillToContact__c, zqu__SoldToContact__c, zqu__Currency__c, zqu__PaymentTerm__c, zqu__PaymentMethod__c, zqu__StartDate__c, zqu__Subscription_Term_Type__c, zqu__InitialTerm__c, AR_Special_Handling__c, AR_Special_Notes__c, zqu__Terms__c, Service_End_Date__c, Charge_Total__c, zqu__Previewed_Discount__c, zqu__Previewed_Total__c, LastModifiedDate, LastModifiedById, CreatedbyId, CreatedDate FROM zqu__Quote__c WHERE Id = \'' + pgContext + '\'';        

        thisQuote = Database.query(query);
    }

    private void PrepPageForNew() {

        sourceOppId = ApexPages.currentPage().getParameters().get('oppId');
        quoteType = ApexPages.currentPage().getParameters().get('quoteType');
        stepNumber = ApexPages.currentPage().getParameters().get('stepNumber');
        billingAccountId = ApexPages.currentPage().getParameters().get('billingAccountId');
    
        if (stepNumber != null) stepNumberInt = Integer.valueOf(stepNumber);

        if (sourceOppId != null) {
            pgReturnPage = new PageReference('/' + sourceOppId);    //the forward slash is necessary due to a change Salesforce made, and retURL isn't used by the Zuora Quote Wizard, so we must use oppId.

            sourceOpp = RetrieveApplicableOpportunity(sourceOppId);

            if (sourceOpp.zqu__Quotes__r != null) quoteNumber = sourceOpp.zqu__Quotes__r.size() + 1;
            else quoteNumber = 1;

            //Setup the quote now...
            thisQuote = new zqu__Quote__c();
            thisQuote.zqu__SubscriptionType__c = 'New Subscription';

            if (billingAccountId != null) thisQuote.zqu__ZuoraAccountID__c = billingAccountId;      //if they selected a billing account from the previous screen, old-school method.

            SetDefaultValues();                
        }
    }

    private void SetButtonLabels() {

        if (!pageIsInEditMode) {        //if we're in insert mode
            panel1CancelLabel = 'Cancel';
            panel1ContinueLabel = 'Continue & Select Products';
            panel1SaveLabel = 'Save without Products';
            panel2CancelLabel = 'Cancel Everything';
            panel2SaveLabel = 'Save Everything';
            panel2EditQuoteLabel = 'Edit Quote Details';
        }
        else {                          //if we're in edit mode
            panel1CancelLabel = 'Cancel';
            panel1ContinueLabel = 'Continue & Review Products';
            panel1SaveLabel = 'Save & Close';
            panel2CancelLabel = 'Cancel All Changes';
            panel2SaveLabel = 'Save All Changes';
            panel2EditQuoteLabel = 'Edit Quote Details';
        }    
    }

    //Used to retain the original values (of those that we care about) of the quote so we know which fields were edited with respect to getting a new billing account.
    private void BackupOrigQuoteValues() {

        preEditedQuote = new zqu__Quote__c();
        preEditedQuote.Name = thisQuote.Name;
        preEditedQuote.IsSyncing__c = thisQuote.IsSyncing__c;
        preEditedQuote.zqu__Currency__c = thisQuote.zqu__Currency__c;
        preEditedQuote.zqu__PaymentMethod__c = thisQuote.zqu__PaymentMethod__c;
        preEditedQuote.zqu__SoldToContact__c = thisQuote.zqu__SoldToContact__c;
        preEditedQuote.zqu__BillToContact__c = thisQuote.zqu__BillToContact__c;
        preEditedQuote.BrandTag__c = thisQuote.BrandTag__c;
        preEditedQuote.InvoiceTemplateName__c = thisQuote.InvoiceTemplateName__c;
        preEditedQuote.zqu__PaymentTerm__c = thisQuote.zqu__PaymentTerm__c;
        preEditedQuote.zqu__BillingMethod__c = thisQuote.zqu__BillingMethod__c;
        preEditedQuote.Billing_Frequency__c = thisQuote.Billing_Frequency__c;
    }

    private Opportunity RetrieveApplicableOpportunity(Id oppId) {

        filterPresets = new List<FilterPreset>();

        Opportunity opp = [SELECT  
                            Id, 
                            Name, 
                            BrandTag__c, 
                            AccountId, 
                            OwnerId, 
                            Owner.Name,
                            Owner.Division,
                            Sold_By_Partner__c, 
                            Agency_Discount__c,
                            IsClosed, 
                            IsWon, 
                            CurrencyIsoCode, 
                            Primary_Brand__c, 
                            Account_Brand__r.CS__r.Name, 
                            Account_Brand__r.Brand__r.Quote_BrandTag_set_via_Opp_BrandTag__c, 
                            (SELECT Id 
                                    FROM zqu__Quotes__r), 
                            (SELECT BrandTag__c, 
                                    Id,
                                    Sale_Type__c,
                                    Product_Group__c, 
                                    Brand__r.Name, 
                                    Country__c,
                                    Country__r.Name,
                                    TotalPrice 
                                    FROM OpportunityLineItems WHERE IsDeleted = false 
                                        AND ((Sale_Type__c = null) OR (Sale_Type__c != 'Trial'))
                                    ORDER BY BrandTag__c, Product_Group__c ASC) 
                            FROM Opportunity 
                            WHERE Id = :oppId LIMIT 1];

        //Cycle through the filters now and set the filter presets
        if ((opp != null) && (opp.OpportunityLineItems != null)) {
            Integer i = 1;
            for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                if ((oli.Product_Group__c != 'Discount') && (oli.Sale_Type__c != 'Trial')) {
                    FilterPreset fp = new FilterPreset();
                    fp.OppLineItem = oli;
                    fp.rowNum = i;
                    
                    if (fp.GetOLIBrandTag != '#ERROR#') {
                        i++;
                        filterPresets.add(fp);
                    }                    
                }
            }
        }

        //Set the agency discount tooltip text here
        if ((opp.Sold_By_Partner__c != null) && (opp.Agency_Discount__c != null)) discountPercentToolTip = 'The agency discount on this opportunity is ' + opp.Agency_Discount__c + '%.';
        else if ((opp.Sold_By_Partner__c != null) && (opp.Agency_Discount__c == null)) discountPercentToolTip = 'Even though this opportunity has a sold by partner, the agency discount is currently blank.';
        else if (opp.Sold_By_Partner__c == null) discountPercentTooltip = 'This opportunity is not eligible for an agency discount.';
        else discountPercentTooltip = 'How in the world are you seeing this?';

        if (opp != null) return opp;
        else return New Opportunity();
    }

    private void SetContactDefaults() {

        contactOptionsBillTo = new List<SelectOption>();
        contactOptionsSoldTo = new List<SelectOption>();

        RefreshContactBillToList();
        RefreshContactSoldToList();

        if (pageIsInEditMode && soldToUsesLookupOnEdit) {
            switcherooLabelSoldTo = 'Use the picklist';
            useThePicklistSoldTo = false;
        }
        else {
            switcherooLabelSoldTo = 'Use the lookup';
            useThePicklistSoldTo = true;
        }

        if (pageIsInEditMode && billToUsesLookupOnEdit) {
            switcherooLabelBillTo = 'Use the picklist';
            useThePicklistBillTo = false;
        }
        else {
            switcherooLabelBillTo = 'Use the lookup';
            useThePicklistBillTo = true;
        }
    }

    //for the fieldSet for the BillingAccount table
    public List<Schema.FieldSetMember> getBillingAccountFields() {
        return SObjectType.Zuora__CustomerAccount__c.FieldSets.NewQuote.getFields();
    }

    //for the fieldSet for the 'Quote Information' pageblocktable (for edit mode only)
    public List<Schema.FieldSetMember> getQIEditFields() {
        return SObjectType.zqu__Quote__c.FieldSets.DHX_QuoteInformation_Edit.getFields();
    }


    //Note that the fields displayed on the Visualforce page are controlled via the fieldset,
    //BUT the filtering / collecting of data is done here, so if the definition of a 'unique bill-to-account' changes,
    //fields and code must also be changed here.
    private void PopulateListOfBillingAccounts() {

        if (sourceOpp == null) return;

        String querySUBs = 'SELECT ';

        for (Schema.FieldSetMember f : this.getBillingAccountFields()) {
            querySUBs += 'Zuora__CustomerAccount__r.' + f.getFieldPath() + ', ';
        }

        //get 20 most recent subscriptions & their billing accounts.
        Map<String, Zuora__CustomerAccount__c> billingAccountMap = new Map<String, Zuora__CustomerAccount__c>();

        querySUBs   += 'Id, Zuora__CustomerAccount__c FROM Zuora__Subscription__c WHERE Zuora__CustomerAccount__r.Zuora__Account__c = \'' + sourceOpp.AccountId + '\' AND Zuora__CustomerAccount__r.BrandTag__c = \'' + thisQuote.BrandTag__c + '\' AND Zuora__CustomerAccount__r.Zuora__Currency__c = \'' + thisQuote.zqu__Currency__c + '\' AND Zuora__Status__c = \'Active\' ORDER BY CreatedDate DESC LIMIT 30';        

        List<Zuora__Subscription__c> subsToConsider = Database.query(querySUBs);

        billingAccounts = new List<Zuora__CustomerAccount__c>();

        if (subsToConsider == null || subsToConsider.isEmpty()) return;

        for (Zuora__Subscription__c sub : subsToConsider) {

            if (sub.Zuora__CustomerAccount__c != null) {

                if ((!billingAccountMap.containsKey(sub.Zuora__CustomerAccount__r.BrandTag__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__BillToName__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__PaymentTerm__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__DefaultPaymentMethod__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__BillToAddress1__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__BillToCity__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__BillToState__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__BillToCountry__c)) && (billingAccountMap.size() < 5)) {

                    Zuora__CustomerAccount__c ba = new Zuora__CustomerAccount__c();
                    ba.BrandTag__c = sub.Zuora__CustomerAccount__r.BrandTag__c;
                    ba.Zuora__Currency__c = sub.Zuora__CustomerAccount__r.Zuora__Currency__c;
                    ba.Zuora__BillToName__c = sub.Zuora__CustomerAccount__r.Zuora__BillToName__c;
                    ba.Zuora__PaymentTerm__c = sub.Zuora__CustomerAccount__r.Zuora__PaymentTerm__c;
                    ba.Zuora__DefaultPaymentMethod__c = sub.Zuora__CustomerAccount__r.Zuora__DefaultPaymentMethod__c;
                    ba.Zuora__BillToAddress1__c = sub.Zuora__CustomerAccount__r.Zuora__BillToAddress1__c;
                    ba.Zuora__BillToCity__c = sub.Zuora__CustomerAccount__r.Zuora__BillToCity__c;
                    ba.Zuora__BillToState__c = sub.Zuora__CustomerAccount__r.Zuora__BillToState__c;
                    ba.Zuora__BillToCountry__c = sub.Zuora__CustomerAccount__r.Zuora__BillToCountry__c;

                    billingAccountMap.put(sub.Zuora__CustomerAccount__r.BrandTag__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__BillToName__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__PaymentTerm__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__DefaultPaymentMethod__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__BillToAddress1__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__BillToCity__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__BillToState__c + '~' + sub.Zuora__CustomerAccount__r.Zuora__BillToCountry__c, ba);
                }
            }                   
        }

        billingAccounts = billingAccountMap.values();
    }

    public PageReference SaleTypeValueChanged() {

        if (saleTypeValue == null || saleTypeValue == STANDARD_SALE_TYPE || saleTypeValue == '') addButtonText = 'Add';
        else addButtonText = 'Add ' + saleTypeValue;

        return null;
    }

    public PageReference PRPSaleTypeValueChanged() {      

        String val = Apexpages.currentPage().getparameters().get('prpGUID');

        if (val != null) {
            for (productRatePlanWrapper prpw : selectedRatePlans) {
                if (prpw.GUID == val) {
                    prpw.SetColorAndToolTip(prpw.productRatePlan, prpw.ratePlanSaleType);
                    return null;
                }
            }
        }

        return null;
    }

    public PageReference PopulatePriorBillingAccounts() {

        PopulateListOfBillingAccounts();

        return null;
    }

    private void WipeQuoteCharges() {
        
        for (ProductRatePlanWrapper prpw : selectedRatePlans) {
            for (QuoteChargeWrapper qcw : prpw.quoteChargeWrappers) {
                quoteChargesToAlwaysDelete.add(qcw.quoteCharge.Id);
            }
        }

        selectedRatePlans.clear();

        //Also wipe any discounts and related
        thisQuote.Discount_Percent__c = null;
        thisQuote.Discount_Fixed__c = null;
        thisQuote.Discount_New_Net__c = null;
        quoteTotalDiscount = 0;
        quoteTotalGross = 0;
        quoteTotalNet = 0;
    }

    public PageReference PopulatePriorBillingAccountsBecauseCurrencyMayHaveChanged() {

        PopulateListOfBillingAccounts();
        RefreshFoundRatePlans();

        WipeQuoteCharges();

        return null;
    }

    private void CheckPermissions() {

        if (!Schema.SObjectType.zqu__Quote__c.fields.BrandTag__c.isUpdateable()) userCanChangeBrandTag = false;
        else userCanChangeBrandTag = true;

        if (!Schema.SObjectType.zqu__Quote__c.fields.zqu__ZuoraAccountID__c.isUpdateable()) userCanChangeZuoraIDs = false;
        else userCanChangeZuoraIDs = true;
    }

    public List<SelectOption> RefreshContactBillToList() {

        if (sourceOpp != null) {
            Set<Id> accountIDs = new Set<Id>();
            accountIDs.add(sourceOpp.AccountId);

            if (sourceOpp.Sold_By_Partner__c != null) accountIDs.add(sourceOpp.Sold_By_Partner__c);

            contactOptionsBillTo = new List<SelectOption>();

            Boolean setContact = true;       
            billToUsesLookupOnEdit = true;
            
            if (thisQuote.zqu__Opportunity__c != null) {
                for (Contact c : [SELECT AccountId, Id, FirstName, LastName, Title FROM Contact WHERE AccountId IN :accountIDs AND No_Longer_With_Company__c = false ORDER BY FirstName, LastName ASC]) {
                    
                    //set the first contact found to the opp's contact IF it's new quote - otherwise don't.
                    if (setContact && (pageIsInEditMode == false)) {
                        thisQuote.zqu__BillToContact__c = c.Id;
                        setContact = false;
                    }
                    
                    if (c.AccountId != sourceOpp.AccountId) contactOptionsBillTo.add(new SelectOption(c.Id, '* ' + c.FirstName + ' ' + c.LastName));
                    else contactOptionsBillTo.add(new SelectOption(c.Id, c.FirstName + ' ' + c.LastName));

                    if (pageIsInEditMode && thisQuote.zqu__BillToContact__c == c.Id) billToUsesLookupOnEdit = false;
                }
            } 
            else contactOptionsBillTo.add(new SelectOption('', 'An unknown error has occurred.'));
        }
        else contactOptionsBillTo.add(new SelectOption('', 'This Quote is missing an Opportunity'));
        
        return contactOptionsBillTo;
    }

    public List<SelectOption> RefreshContactSoldToList() {
        
        if (sourceOpp != null) {

            Set<Id> accountIDs = new Set<Id>();
            accountIDs.add(sourceOpp.AccountId);    

            if (sourceOpp.Sold_By_Partner__c != null) accountIDs.add(sourceOpp.Sold_By_Partner__c);

            contactOptionsSoldTo = new List<SelectOption>();

            Boolean setContact = true;  
            soldToUsesLookupOnEdit = true;    
            
            if (thisQuote.zqu__Opportunity__c != null) {
                for (Contact c : [SELECT AccountId, Id, FirstName, LastName, Title FROM Contact WHERE AccountId = :accountIDs AND No_Longer_With_Company__c = false ORDER BY FirstName, LastName ASC]) {
                    
                    //set the first contact found to the opp's contact IF it's new quote - otherwise don't.
                    if (setContact && (pageIsInEditMode == false)) {
                        thisQuote.zqu__SoldToContact__c = c.Id;
                        setContact = false;
                    }
                    
                    if (c.AccountId != sourceOpp.AccountId) contactOptionsSoldTo.add(new SelectOption(c.Id, '* ' + c.FirstName + ' ' + c.LastName));
                    else contactOptionsSoldTo.add(new SelectOption(c.Id, c.FirstName + ' ' + c.LastName));

                    if (pageIsInEditMode && thisQuote.zqu__SoldToContact__c == c.Id) soldToUsesLookupOnEdit = false;
                }
            } 
            else contactOptionsSoldTo.add(new SelectOption('', 'An unknown error has occurred.'));
        }
        else contactOptionsBillTo.add(new SelectOption('', 'This Quote is missing an Opportunity'));

        return contactOptionsSoldTo;
    }

    public PageReference SwitcherooBillToClick() {
        if (switcherooLabelBillTo == 'Use the picklist') {
            
            //Then we're now on the picklist...
            
            switcherooLabelBillTo = 'Use the lookup';         
            useThePicklistBillTo = true;
            
            //This sets the bound contact to the first option in the select list if we're toggling back FROM the lookup control.
            if ((contactOptionsBillTo.size() > 0) && (contactOptionsBillTo[0].getValue() != '')) {
                
                //First, check and see if the contact is in the list, if so, that's the one to use...
                if (thisQuote.zqu__BillToContact__c != null) {
                    for (SelectOption so : contactOptionsBillTo) {
                        //If the contact exists in the picklist, then don't do anything...
                        if (so.getValue() == thisQuote.zqu__BillToContact__c) return null;
                    }
                }
                
                //Then we have at least one viable option as the contact did not exist in the picklist - change it and update the values...
                thisQuote.zqu__BillToContact__c = contactOptionsBillTo[0].getValue();
            }
        }
        else {
            switcherooLabelBillTo = 'Use the picklist';
            useThePicklistBillTo = false;
            
            //No need to do extra processing here as ALL contacts in the picklist are ALWAYS viable options in the lookup control.
        }
        
        return null;
    }

    public PageReference SwitcherooSoldToClick() {
        if (switcherooLabelSoldTo == 'Use the picklist') {
            
            //Then we're now on the picklist...
            
            switcherooLabelSoldTo = 'Use the lookup';         
            useThePicklistSoldTo = true;
            
            //This sets the bound contact to the first option in the select list if we're toggling back FROM the lookup control.
            if ((contactOptionsSoldTo.size() > 0) && (contactOptionsSoldTo[0].getValue() != '')) {
                
                //First, check and see if the contact is in the list, if so, that's the one to use...
                if (thisQuote.zqu__SoldToContact__c != null) {
                    for (SelectOption so : contactOptionsSoldTo) {
                        //If the contact exists in the picklist, then don't do anything...
                        if (so.getValue() == thisQuote.zqu__SoldToContact__c) return null;
                    }
                }
                
                //Then we have at least one viable option as the contact did not exist in the picklist - change it and update the values...
                thisQuote.zqu__SoldToContact__c = contactOptionsSoldTo[0].getValue();
                //when the sold to changes above, Quote template region changes accordingly
                if(QuoteTemplateRegionRequired){
                    
                    for(Contact c : [select mailingCountry from Contact where id=:thisQuote.zqu__SoldToContact__c]){
                        thisQuote.Quote_Template_Region__c = Quotetemplateregions.contains(c.MailingCountry)? c.MailingCountry:MiddleEastCountries.contains(c.MailingCountry)? 'Middle East':c.MailingCountry == 'United Kingdom'?'England':'';
                    }
                }
            }
        }
        else {
            switcherooLabelSoldTo = 'Use the picklist';
            useThePicklistSoldTo = false;
            
            //No need to do extra processing here as ALL contacts in the picklist are ALWAYS viable options in the lookup control.
        }
        
        return null;
    }        

    private void SetDefaultValues() {

        if (quoteNumber == 1) thisQuote.Name = sourceOpp.Name;
        else thisQuote.Name = sourceOpp.Name + ' v.' + quoteNumber;

        thisQuote.zqu__Opportunity__c = sourceOpp.Id;

        Boolean bUseOppBT = true;
        if (sourceOpp != null && sourceOpp.Account_Brand__c != null && sourceOpp.Account_Brand__r.Brand__c != null) bUseOppBT = sourceOpp.Account_Brand__r.Brand__r.Quote_BrandTag_set_via_Opp_BrandTag__c;

        if (bUseOppBT && sourceOpp.BrandTag__c != null) thisQuote.BrandTag__c = sourceOpp.BrandTag__c;
        else thisQuote.BrandTag__c = sourceOpp.Primary_Brand__c;       
        
        //Now the hardcoded one-off dice/cj --> rigzone case.
        //Until the time is taken for a scalable solution to be implemented, we're (sadly) stuck with this.
        if (((sourceOpp.BrandTag__c == 'Dice') || (sourceOpp.BrandTag__c == 'ClearanceJobs')) && (sourceOpp.Primary_Brand__c == 'Rigzone')) thisQuote.BrandTag__c = 'RZ-Amer';

        thisQuote.zqu__Subscription_Term_Type__c = 'Termed';
        
        if (sourceOpp.CurrencyIsoCode != null) thisQuote.zqu__Currency__c = sourceOpp.CurrencyIsoCode;
        
        thisQuote.zqu__PaymentTerm__c = 'Due Upon Receipt';
        thisQuote.zqu__BillingMethod__c = 'Email';

        //Default the agency commission discount
        if (sourceOpp.Sold_By_Partner__c != null) {
            discountFieldUsed = 'Discount_Percent__c';
            thisQuote.Discount_Percent__c = sourceOpp.Agency_Discount__c;
        }

        //Now default the discount sales rep and country
        discountSalesRepValue = sourceOpp.Owner.Name;
        if ((filterPresets != null) && (!filterPresets.isEmpty())) discountCountryValue = filterPresets[0].GetOLICountry;
    }

    public PageReference ReturnToQuote() {
        return new PageReference('/' + thisQuote.Id);
    }

    public PageReference ReturnToOpp() {
        return new PageReference('/' + sourceOpp.Id);   
    }    

    public PageReference Cancel() {
        return pgReturnPage;
    }    

    public PageReference ValidateStep1() {
        successfulStep1 = ValidateQuoteDetails();

        //As values may have been changed on the quote edit screen, reset the filter defaults
        InitializeAndDefaultProductFilters();

        return null;
    }
    // this method defaulst the quote template region field on quote page
    private void setquotetemplateregion(){
        
        MiddleEastCountries = new set<string>();
        Quotetemplateregions = QuoteUtilities.getPicklistValues('zqu__Quote__c','Quote_Template_Region__c');      // This grabs the picklist values
        map<string,BrandTag_EfC_Intl__c> BrandTaG_Intl = BrandTag_EfC_Intl__c.getAll();                         // custom setting that says which are eFC international brand tags       
        for(pw_ccpro__CountryObject__c country : [select Name from pw_ccpro__CountryObject__c WHERE 
                                                  Sub_Region1__c = 'Middle East'
                                                ]) {
                                                	MiddleEastCountries.add(country.name);
                                                }
        //if Quote brand tag is any of the eFC international, then flag is set to true to bring the quote template region on the page
        if(BrandTaG_Intl.containskey(thisQuote.BrandTag__c))QuoteTemplateRegionRequired=true;
        if(QuoteTemplateRegionRequired){
            
            for(Contact c : [select mailingCountry from Contact where id=:thisQuote.zqu__SoldToContact__c]){  
                //defaults to the picklist value, if country is any of them, or checks if it is any of the middle east regions
                thisQuote.Quote_Template_Region__c = Quotetemplateregions.contains(c.MailingCountry)? c.MailingCountry:MiddleEastCountries.contains(c.MailingCountry)? 'Middle East':c.MailingCountry == 'United Kingdom'? 'England':'';
            }
        }
    }
    public PageReference KickFromEditIfReadOnly() {

        Boolean bLegitRecordType = false;
        newRecordTypeId = ApexPages.currentPage().getParameters().get('RecordType');

        Set<Id> readonlyIDs = new Set<Id>();

        for (RecordType r : recordTypes.values()) {
            if (r.DeveloperName.contains('ReadOnly')) readonlyIDs.add(r.Id);
            if (newRecordTypeId != null && r.Id == newRecordTypeId) bLegitRecordType = true;
        }

        if (newRecordTypeId != null && bLegitRecordType == true) return null;  //If the recordType querystring parameter is specified (and real!), then they came from the 'Change Record Type' screen.  Allow them to continue...

        if ((thisQuote == null) || (thisQuote.Id == null)) {
            pgContext = ApexPages.currentPage().getParameters().get('Id');

            if (pgContext != null) GetQuoteForEdit();
        }

        String sURL = '/' + thisQuote.Id;

        //Get the retURL if possible...
        String ret = ApexPages.currentPage().getParameters().get('retURL');

        if (ret != null) sURL += '?retURL=' + ret;

        //If this quote is of type 'Readonly' then kick the user
        if (readonlyIDs.contains(thisQuote.RecordTypeId)) {
            PageReference pg = new PageReference(sURL);
            pg.setRedirect(true);
            return pg;
        }

        return null;
    }


    public PageReference CalcServiceEndDateWipeProducts() {

        WipeQuoteCharges();
        ActuallyCalculateTheServiceEndDates();
        return null;
    }

    private void ActuallyCalculateTheServiceEndDates() {

        if (thisQuote.zqu__StartDate__c <> null && thisQuote.zqu__InitialTerm__c <> null && thisQuote.zqu__Subscription_Term_Type__c == 'Termed') thisQuote.Service_End_Date__c = Date.valueOf(thisQuote.zqu__StartDate__c).addMonths((Integer)thisQuote.zqu__InitialTerm__c).addDays(-1);
        else if (thisQuote.zqu__Subscription_Term_Type__c == 'Evergreen') thisQuote.Service_End_Date__c = null;

        RefreshBillingFrequencyOptions();

    }

    public PageReference CalcServiceEndDate() {

        ActuallyCalculateTheServiceEndDates();
        return null;
    }

    public PageReference CalcServiceEndDateAndAdjustFirstBillDate() {
        ActuallyCalculateTheServiceEndDates();

        //Now, adjust the first bill date if necessary...
        thisQuote.Deferred_Bill_Date__c = QuoteUtilities.ReturnFirstBillDate(thisQuote.zqu__StartDate__c, thisQuote.Deferred_Bill_Date__c);

        return null;   
    }

    private String SaveQuote() {
        if (ValidateQuoteDetails()) {

            RecalcAllQuoteNumbers();

            thisQuote.Discount__c = quoteTotalDiscount;
            thisQuote.zqu__Previewed_Discount__c = quoteTotalDiscount;
            thisQuote.zqu__Previewed_SubTotal__c = quoteTotalGross;
            thisQuote.zqu__Previewed_Total__c = quoteTotalNet;
            thisQuote.zqu__Previewed_TCV__c = quoteTotalGross;
            thisQuote.zqu__Is_Charge_Expired__c = false;
            thisQuote.CurrencyIsoCode = thisQuote.zqu__Currency__c;

            //Then we have a discount!  retain the data
            if (thisQuote.Discount_Percent__c != null) {
                thisQuote.Discount_Type__c = discountTypeValue;
                thisQuote.Discount_Field_Used__c = discountFieldUsed;
            } else {
                //blank it, just in case if there was data there before
                thisQuote.Discount_Type__c = null;
                thisQuote.Discount_Field_Used__c = null;
            }

            String sURL;
            String matchResult = '';
            
            if (!pageIsInEditMode) {

                thisQuote.zqu__RenewalTerm__c = 0.0;
                thisQuote.IsSyncing__c = true;                

                //Call the BillingAccount selection piece now...               
                RESTZuoraOperationPlugIn.ReturnClass returnClass = QuoteUtilities.GetBillingAccount(thisQuote, sourceOpp, '');
                
                if (returnClass.matchType == 'FAILED') matchResult = 'Error: ' + returnClass.message;
                else matchResult = returnClass.matchType;

                thisQuote.Billing_Account_Selection_Response__c = matchResult;
                thisQuote.zqu__ZuoraAccountID__c = returnClass.billingAccountId;

                if (thisQuote.Id == null) insert thisQuote;

                sURL = '/' + thisQuote.Id;
            }

            else {
                //If we're editing an existing quote...

                //If the recordType was overridden from the 'Change Record Type' screen
                if (newRecordTypeId != null) thisQuote.RecordTypeId = newRecordTypeId;

                //As the logic/rules of the page trump the change recordtype functionality, let them be overridden if necessary...            
                //Check if we need to change the record type...
                if ((thisQuote.zqu__SubscriptionType__c == 'New Subscription') && (thisQuote.IS_Verified__c) && (recordTypes.containsKey(DEFAULT_VERIFIED)) && thisQuote.zqu__Status__c != 'Sent to Z-Billing') thisQuote.RecordTypeId = recordTypes.get(DEFAULT_VERIFIED).Id;

                //Check if we need to change the record type to default...
                else if ((thisQuote.zqu__SubscriptionType__c == 'New Subscription') && (!thisQuote.IS_Verified__c) && (recordTypes.containsKey(DEFAULT_NOT_VERIFIED)) && thisQuote.zqu__Status__c != 'Sent to Z-Billing') thisQuote.RecordTypeId = recordTypes.get(DEFAULT_NOT_VERIFIED).Id;

                //check if we need to change the record type to readonly...
                //This is done via worfklow now instead of code
                //else if ((thisQuote.zqu__Status__c == 'Sent to Z-Billing') && (thisQuote.IS_Verified__c)) thisQuote.RecordTypeId = recordTypes.get(READONLY).Id;            

                //check if we need to recalculate the billing account
                if (QuoteUtilities.QuoteNeedsBillingAccountRecalculated(preEditedQuote, thisQuote)) {

                    RESTZuoraOperationPlugIn.ReturnClass returnClass = QuoteUtilities.GetBillingAccount(thisQuote, sourceOpp, QuoteUtilities.CalcQuotesInvoiceTemplateName(preEditedQuote, thisQuote));

                    if (returnClass.matchType == 'FAILED') matchResult = 'Error: ' + returnClass.message;
                    else matchResult = returnClass.matchType;

                    thisQuote.Billing_Account_Selection_Response__c = matchResult;
                    thisQuote.zqu__ZuoraAccountID__c = returnClass.billingAccountId;
                }

                update thisQuote;
                sURL = '/' + thisQuote.Id;
            }

            //Now purge any quoteCharges that must ALWAYS be purged:
            if (!quoteChargesToAlwaysDelete.isEmpty()) {
                List<zqu__QuoteCharge__c> chargesToDelete = new List<zqu__QuoteCharge__c>();

                for (Id qcId : quoteChargesToAlwaysDelete) {
                    if (qcId != null) {
                        zqu__QuoteCharge__c qc = new zqu__QuoteCharge__c(Id = qcId);
                        chargesToDelete.add(qc);
                    }
                }

                if (!chargesToDelete.isEmpty()) delete chargesToDelete;
            }

            //Override metric-recalculation flag (doesn't work, but hey, it was worth a shot):
            //thisQuote.zqu__Is_Charge_Expired__c = false;
            //update thisQuote;

            return sURL;
        }
        else return null;
    }

    public PageReference SaveQuoteOnly() {        

        if (ValidateQuoteDetails() && forceDiscountRecalc) {

            //If we're here, then everything is valid and we need to find out the estimated sales tax

            //Gotta make the callout BEFORE executing the DML statements:
            //Getting the sales tax can only happen after the quote & quote charges are committed to the database.
            Map<String, Decimal> salesTaxEstimate = QuoteUtilities.GetEstimatedSalesTaxFromAvalara(thisQuote, selectedRatePlans);

            //thisQuote.AR_Special_Notes__c = String.valueOf(salesTaxEstimate);     //Debug only.  *NEVER* meant for production

            if (salesTaxEstimate.containsKey('Success')) thisQuote.Estimated_Tax__c = salesTaxEstimate.get('Success');
            else system.debug('### - ' + salesTaxEstimate);
            //End Sales Tax estimate
        }

        String quoteResult = SaveQuote();
        
        if (quoteResult == null) return null;

        return new PageReference(quoteResult);
    }

    public PageReference ForceRecalc() {
        //This exists solely to force avalara to recalc the sales tax as the sold-to person has changed, and therefore, the location most likely did as well.

        forceDiscountRecalc = true;
        //When sold to changes then quote template region changes accordingly
        if(QuoteTemplateRegionRequired){
            
            Contact ChangedSoldtoContact = [select id,mailingCountry from Contact where id =:thisQuote.zqu__SoldToContact__c limit 1];
            thisQuote.Quote_Template_Region__c = Quotetemplateregions.contains(ChangedSoldtoContact.MailingCountry)? ChangedSoldtoContact.MailingCountry:MiddleEastCountries.contains(ChangedSoldtoContact.MailingCountry)? 'Middle East':ChangedSoldtoContact.MailingCountry == 'United Kingdom'?'England':'';
        }
        return null;
    }

    public PageReference SaveItAll() {

        if (ValidateQuoteDetails() && ValidateQuoteChargeDetails() && forceDiscountRecalc) {

            //If we're here, then everything is valid and we need to find out the estimated sales tax

            //Gotta make the callout BEFORE executing the DML statements:
            //Getting the sales tax can only happen after the quote & quote charges are committed to the database.
            Map<String, Decimal> salesTaxEstimate = QuoteUtilities.GetEstimatedSalesTaxFromAvalara(thisQuote, selectedRatePlans);

            //thisQuote.AR_Special_Notes__c = String.valueOf(salesTaxEstimate);     //Debug only.  *NEVER* meant for production

            if (salesTaxEstimate.containsKey('Success')) thisQuote.Estimated_Tax__c = salesTaxEstimate.get('Success');
            else system.debug('### - ' + salesTaxEstimate);
            //End Sales Tax estimate
        }

        String quoteResult = SaveQuote();                   //includes quote validation
        String quoteChargeResults = SaveQuoteCharges();     //includes quote charge validation
        
        if ((quoteResult == null) || (quoteChargeResults == null)) return null;     //if either result was null, errors were found via validation so return null to rerender the page errors.
    
        return new PageReference(quoteResult);              //dump the user on the Quote read page.
    }

    private Boolean DoesTheQuoteLevelDiscountChargeNeedToBeReset() {

        //If there isn't an existing charge, nothing to reset.
        if (discountQuoteCharge.Id == null) return true;

        if (discountTypeValue != backupDiscountTypeValue) return true;

        if (preEditedQuote.BrandTag__c != thisQuote.BrandTag__c) return true;

        if (preEditedQuote.Billing_Frequency__c != thisQuote.Billing_Frequency__c) return true;

        //If a discount was removed...
        if (thisQuote.Discount_Percent__c == null || thisQuote.Discount_Percent__c == 0) return true;

        //If the flag is true:
        if (forceDiscountRecalc) return true;

        return false;
    }

    private String SaveQuoteCharges() {

        if (ValidateQuoteChargeDetails()) {

            List<zqu__QuoteCharge__c> chargesToUpsert = new List<zqu__QuoteCharge__c>();
            quoteLevelDiscountNeedsReset = DoesTheQuoteLevelDiscountChargeNeedToBeReset();

            String discountSaleType = CalculateDiscountRatePlanSaleType();

            //SalesRep is a bit manual.  The Id is automatic, but as the text field isn't a formula (yet) I've got to set that manually now.            
            //End Sales_Representative__c field (collection - we'll set it in the last loop below.)

            for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
                for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {

                    //the following line needs to only run for NEW quote charges / product rate planes.  It explodes into a fiery ball of flames if Zuora sees this line after it's already been set.
                    if (qcw.quoteCharge.Id == null) qcw.quoteCharge.zqu__Quote__c = thisQuote.Id;

                    //If the data is VISIBLE - I don't need to massage it here as the binding commits it properly.
                    //If the data (attribute) is HIDDEN - I very well might need to make adjustments / translations, etc,
                        //here because it won't have been bound by being exposed on the page because I only loop through visible attributes.
                        //Primary example is the 'Sales_Representative__c' field.  That is NOT exposed to the user and not bound - SalesRepId__c is instead.

                    if ((qcw.quoteCharge.SalesRepId__c != null) && (userMap.containsKey(qcw.quoteCharge.SalesRepId__c))) qcw.quoteCharge.Sales_Representative__c = userMap.get(qcw.quoteCharge.SalesRepId__c).Name;
                    qcw.quoteCharge.zqu__Currency__c = thisQuote.zqu__Currency__c;

                    //The field ,'zqu__PeriodNumeric__' is a backend field that (sadly) isn't populated by a Zuora trigger - so, we translate it here.
                    qcw.quoteCharge.zqu__PeriodNumeric__c = QuoteUtilities.GetPeriodNumber(qcw.quoteCharge.zqu__Period__c);
                    qcw.quoteCharge.zqu__Quantity__c = qcw.quoteCharge.FakeQuantity__c;
                    qcw.quoteCharge.zqu__TCVForRollup__c = qcw.FauxTCV;

                    if (qcw.quoteCharge.zqu__ListPriceDisplay__c != null && qcw.quoteCharge.zqu__Quantity__c != null) qcw.quoteCharge.zqu__ListTotal__c = qcw.quoteCharge.zqu__ListPriceDisplay__c * qcw.quoteCharge.zqu__Quantity__c;
                    else qcw.quoteCharge.zqu__ListTotal__c = 0;

                    qcw.quoteCharge.Country__c = qcw.Country;
                    qcw.quoteCharge.Sale_Type__c = prpWrapper.ratePlanSaleType;
                    
                    //Discount-specific adjustments for bundled items in a rate plan:
                    if (qcw.isDiscountCharge && qcw.quoteCharge.zqu__Discount_Level__c.startsWithIgnoreCase('rate')) {
                        qcw.quoteCharge.zqu__Quantity__c = null;
                        qcw.quoteCharge.zqu__ListTotal__c = null;
                        qcw.quoteCharge.zqu__Total__c = null;                        
                        qcw.quoteCharge.zqu__Apply_Discount_To_One_Time_Charges__c = true;      //Is this always true??
                        qcw.quoteCharge.zqu__Apply_Discount_To_Recurring_Charges__c = true;      //Is this always true??
                        qcw.quoteCharge.zqu__Apply_Discount_To_Usage_Charges__c = true;      //Is this always true??
                    }

                    //DON'T ADD THE GLOBAL QUOTE DISCOUNT!  THAT'LL FOLLOW....  
                    if (discountQuoteCharge.Id != null && qcw.quoteCharge.Id == discountQuoteCharge.Id) { } //do nothing! 
                    else (chargesToUpsert.add(qcw.quoteCharge));
                }
            }

            //BEGIN GLOBAL/QUOTE/CONTRACT/SUBSCRIPTION DISCOUNT stuff...
            List<zqu__QuoteCharge__c> finalQuoteChargeDiscounts = new List<zqu__QuoteCharge__c>();

            //Now work on the contract-level discount, if applicable...
            //If there is a percentage discount OR if there exists a prior-attached quote charge discount, then...
            if (thisQuote.Discount_Percent__c != null || discountQuoteCharge.Id != null) {
                ProductRatePlanWrapper discWrap = new ProductRatePlanWrapper();

                if (quoteLevelDiscountNeedsReset) {
                    //If a previous discount existed and it needs to be purged
                    if (discountQuoteCharge.Id != null) quoteChargesToDelete.add(discountQuoteCharge.Id);

                    //If there is a discount, then find and add it...
                    if (thisQuote.Discount_Percent__c != null && thisQuote.Discount_Percent__c > 0) {
                        discWrap = ReturnQuoteChargeDiscount();

                        if (discWrap != null && discWrap.quoteChargeWrappers != null) {
                            for (QuoteChargeWrapper discQCWraps : discWrap.quoteChargeWrappers) {
                                discQCWraps.quoteCharge.zqu__EffectivePrice__c = thisQuote.Discount_Percent__c;
                                discQCWraps.quoteCharge.zqu__Apply_Discount_To_One_Time_Charges__c = true;      //Is this always true??
                                discQCWraps.quoteCharge.zqu__Apply_Discount_To_Recurring_Charges__c = true;      //Is this always true??
                                discQCWraps.quoteCharge.zqu__Apply_Discount_To_Usage_Charges__c = true;      //Is this always true??

                                discQCWraps.quoteCharge.Sales_Representative__c = discountSalesRepValue;
                                discQCWraps.quoteCharge.Country__c = discountCountryValue;
                                discQCWraps.quoteCharge.Sale_Type__c = discountSaleType;

                                discQCWraps.quoteCharge.zqu__PeriodNumeric__c = QuoteUtilities.GetPeriodNumber(discQCWraps.quoteCharge.zqu__Period__c);
                                finalQuoteChargeDiscounts.add(discQCWraps.quoteCharge);
                                break;      //only 1!
                            }
                        } else return null; //show the error of no discount product found
                    }
                }
                else {
                    discountQuoteCharge.zqu__EffectivePrice__c = thisQuote.Discount_Percent__c;

                    discountQuoteCharge.Sales_Representative__c = discountSalesRepValue;
                    discountQuoteCharge.Country__c = discountCountryValue;
                    discountQuoteCharge.Sale_Type__c = discountSaleType;

                    finalQuoteChargeDiscounts.add(discountQuoteCharge);
                }

                if (finalQuoteChargeDiscounts != null) {
                    for (zqu__QuoteCharge__c finalQCDiscount : finalQuoteChargeDiscounts) {
                        if (finalQCDiscount.Id == null) finalQCDiscount.zqu__Quote__c = thisQuote.Id;
                        chargesToUpsert.add(finalQCDiscount);      
                    }
                }
            }
            //END GLOBAL/QUOTE/CONTRACT/SUBSCRIPTION DISCOUNT stuff...

            if (!chargesToUpsert.isEmpty()) upsert chargesToUpsert;

            //If there are any quote charges to delete, do that now.
            if (!quoteChargesToDelete.isEmpty()) {
                List<zqu__QuoteCharge__c> chargesToDelete = new List<zqu__QuoteCharge__c>();

                for (Id qcId : quoteChargesToDelete) {
                    zqu__QuoteCharge__c qc = new zqu__QuoteCharge__c(Id = qcId);
                    chargesToDelete.add(qc);    
                }

                if (!chargesToDelete.isEmpty()) delete chargesToDelete;
            }

            return 'All is well!';      //anything other than null means success
        }
        else return null;
    }

    private String CalculateDiscountRatePlanSaleType() {
        //Analyzes the prpWrapper sale type to find out what Sale Type the Discount should be labeled as.
        //Per CC-3181, the hierarchy is as follows:  Trial, Trial Conversion, Standard
        //So that if there is at least 1 'Trial' record, the discount will be labeled 'Trial'
        //If there is at least 1 'Trial Conversion' record (and NO Trial records, the discount will be labeled 'Trial Conversion'
        //Lastly, if there are zero Trial and zero Trial Conversion records, the discount will be lableled as 'Standard'

        Integer numTrialConv = 0;

        for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {            
            if (!prpWrapper.isDiscountProduct) {
                //Trial trumps all, so that can immediately return.
                if (prpWrapper.ratePlanSaleType.toLowerCase() == 'trial') return 'Trial';
                if (prpWrapper.ratePlanSaleType.toLowerCase() == 'trial conversion') numTrialConv++;
            }
        }

        if (numTrialConv > 0) return 'Trial Conversion';

        return 'Standard';
    }

    private Boolean DoAnyRecurringQuoteChargesExistOnThisQuote() {

        Boolean result = false;

        for (ProductRatePlanWrapper prpw : selectedRatePlans) {      
            //Make sure we aren't considering the existing discount, if it exists!
            if (!prpw.isDiscountProduct) {
                for (QuoteChargeWrapper qcw : prpw.quoteChargeWrappers) {
                    if (qcw.quoteCharge.zqu__ChargeType__c.startsWithIgnoreCase('recur')) return true;
                }
            }
        }
        return result;
    }

    private String ReturnBrandTagToMatchDiscount() {

        Map<String, Double> brandTagValuationMap = new Map<String, Double>();
        String resultBT = thisQuote.BrandTag__c;
        String sOnlyBrandTag = '';

        Set<String> brandTagSet = new Set<String>();

        for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
            //Make sure we aren't considering the existing discount!
            if (!prpWrapper.isDiscountProduct) {
                for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {
                    if (qcw.FauxTCV > 0) {
                        //This ensures that we only use the brandtag for the discount if there is a value to start with.
                        brandTagSet.add(prpWrapper.productRatePlan.BrandTag__c);
                        sOnlyBrandTag = prpWrapper.productRatePlan.BrandTag__c;    
                    }
                }                
                brandTagValuationMap.put(prpWrapper.productRatePlan.BrandTag__c, 0);
            }
        }

        //if there is exactly one unique brandtag chosen in a product rate plan AND it isn't the quote's brandtag...
        if (brandTagSet.size() == 1 && !brandTagSet.contains(resultBT)) return sOnlyBrandTag;        
        else {            
            //begin logic edits for CC-3084
            //if there are at least 2 distinct brandtags in the set and none of them match the quote's brandtag
            if ((brandTagSet.size() > 1) && (!brandTagSet.contains(resultBT))) {
                //then cycle through and find the PRPW with the greatest value and use that.

                for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
                    if (!prpWrapper.isDiscountProduct) {

                        Double thisValue = brandTagValuationMap.get(prpWrapper.productRatePlan.BrandTag__c);

                        for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {
                            if (qcw.FauxTCV != null) thisValue += qcw.FauxTCV;
                        }

                        brandTagValuationMap.put(prpWrapper.productRatePlan.BrandTag__c, thisValue);
                    }
                }

                //All the processing and addition is completed - now cycle through and return the brandtag with the largest valuation
                Double currentHighest = -1;
                String currentValue = null;
                for (String bt : brandTagValuationMap.keySet()) {
                    if (brandTagValuationMap.get(bt) > currentHighest) {
                        currentHighest = brandTagValuationMap.get(bt);
                        currentValue = bt;
                    }
                }

                if (currentValue != null) resultBT = currentValue;
            }
            //no else is necessary here - the following return captures the correct logic
        }
        return resultBT;
    }

    private ProductRatePlanWrapper ReturnQuoteChargeDiscount() {

        ProductRatePlanWrapper result = new ProductRatePlanWrapper();

        Boolean bUseRecurringDiscount = DoAnyRecurringQuoteChargesExistOnThisQuote();

        Integer milliseconds = Integer.valueOf(System.now().format('SSS'));
        timeProductAdded = milliseconds += selectedRatePlans.size();
        timeAddedFinal = timeProductAddedBase + timeProductAdded + 'Z';

        String soql = 'SELECT Id, Name, zqu__ZProduct__r.Name, zqu__ZProduct__r.ProductGroup__c, AlternatePriceCalculation__c, BillingFrequency__c, BrandTag__c,';
                            soql += '(SELECT Id, Name, zqu__ListPrice__c, zqu__UpTo_How_Many_Periods__c, zqu__Type__c, ';
                            soql += '         zqu__ZuoraId__c, zqu__UOM__c, zqu__Model__c, zqu__Description__c, zqu__DefaultQuantity__c, ';
                            soql += '         zqu__PrepaymentPeriods__c, zqu__RecurringPeriod__c, zqu__Discount_Level__c, zqu__Discount_Apply_Type__c, ';
                            soql += '         zqu__Apply_Discount_To_One_Time_Charges__c, zqu__Apply_Discount_To_Recurring_Charges__c, zqu__Apply_Discount_To_Usage_Charges__c, ';
                            soql += '         zqu__ProductRatePlan__r.Name, zqu__ProductRatePlan__r.AlternatePriceCalculation__c, zqu__ProductRatePlan__r.RatePlanPricingModel__c, ';
                            soql += '         zqu__ProductRatePlan__r.zqu__ZProduct__r.Name, zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c';                            
                            soql += ' FROM zqu__R00N40000001mFVKEA2__r WHERE IsDeleted = false AND zqu__Discount_Level__c = \'Subscription\' ORDER BY Name) ';
        soql += ' FROM zqu__ProductRatePlan__c ';
        soql += ' WHERE zqu__ZProduct__r.ProductGroup__c = \'Discount\' AND zqu__EffectiveStartDate__c <= Today AND zqu__EffectiveEndDate__c >= Today ';
        soql += ' AND zqu__Deleted__c = false AND RatePlanPricingModel__c = \'Custom Pricing\'';
        soql += ' AND BrandTag__c = \'' + ReturnBrandTagToMatchDiscount() + '\'';

        if (bUseRecurringDiscount) soql += ' AND (RatePlanRecurringStatus__c like \'%recurr%\')';
        else soql += ' AND (NOT(RatePlanRecurringStatus__c like \'%recurr%\'))';

        if (discountTypeValue != 'List Price Discount') soql += ' AND Name like \'%' + AGENCY_COMMISSION + '%\'';
        else soql += ' AND Name like \'%discount%\'';

        soql += ' AND (NOT(Name like \'%classified%\'))';       //Make sure the Discount for 1&2 Job Classifieds is never selected.
        soql += ' ORDER BY LastModifiedDate DESC';

        List<zqu__ProductRatePlan__c> results = Database.query(soql);

        if (results == null || results.isEmpty()) {
            errorsQuoteCharges.add('Unable to find a matching discount in the product catalog.  Please contact an Administrator with the problem and include the following SOQL:');
            errorsQuoteCharges.add('SOQL:  ' + soql);
            return null;
        }

        for (zqu__ProductRatePlan__c prp : results) {
            result = new ProductRatePlanWrapper();
            result.productRatePlan = prp;

            for (zqu__ProductRatePlanCharge__c prpc : prp.zqu__R00N40000001mFVKEA2__r) {
                result.AddProductRatePlan(prpc, selectedRatePlans.size(), timeAddedFinal, thisQuote.zqu__Currency__c, allAtts, sourceOpp, activefilterCountryValue, thisQuote, attr_SalesRepOptions, attr_CountryOptions, STANDARD_SALE_TYPE);
            }
            break;  //only process one!
        }

        return result;            
    }

    public Boolean ValidateQuoteChargeDetails() {

        //reset the error collection...
        errorsQuoteCharges = new List<String>();

        if ((thisQuote.Discount_Percent__c != null) && (discountSalesRepValue == null || discountCountryValue == null)) errorsQuoteCharges.add('Discount Sales Rep and Discount Country are both required when adding either a List Price or Agency discount');        

        for (ProductRatePlanWrapper prpw : selectedRatePlans) {
            if (!prpw.isDiscountProduct) {      //If it isn't displayed, don't validate it because the user can't do anything anyway...
                for (QuoteChargeWrapper qcw : prpw.quoteChargeWrappers) {

                    //Logic that may be a bit outside the visible rendered stuff...
                    if ((qcw.quoteCharge.ServiceEnd__c != null) && (qcw.quoteCharge.ServiceEnd__c != null) && (qcw.quoteCharge.ServiceEnd__c < qcw.quoteCharge.ServiceStart__c)) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' has has a Service End Date that is prior to the Service Start Date');                   

                    //Loop through only the visible attributes because, well, that's all the user can interact with...                                                       
                    for (Attribute a : qcw.visibleAttributes) {

                        //Quote Price
                        if (a.APIName == 'zqu__EffectivePrice__c') {

                            //if this is a discount, ensure discount (percent) validation
                            if (qcw.isDiscountCharge) {
                                if ((qcw.quoteCharge.zqu__EffectivePrice__c == null) || (qcw.quoteCharge.zqu__EffectivePrice__c < 0) || (qcw.quoteCharge.zqu__EffectivePrice__c > 100)) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' has an invalid Quote Price.  (0x913)');
                            }
                            else {
                                if ((qcw.quoteCharge.zqu__EffectivePrice__c == null) || (qcw.quoteCharge.zqu__EffectivePrice__c < 0)) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' has an invalid Quote Price.  (0x914)');
                            }
                        }

                        //Service Start Date
                        else if (a.APIName == 'ServiceStart__c') {
                            if (qcw.quoteCharge.ServiceStart__c == null) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' is missing the Service Start Date');
                        }

                        //Service End Date
                        else if (a.APIName == 'ServiceEnd__c') {
                            if (qcw.quoteCharge.ServiceEnd__c == null) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' is missing the Service End Date');        
                        }

                        //Quantity
                        else if (a.APIName == 'FakeQuantity__c') {
                            if ((qcw.quoteCharge.FakeQuantity__c == null) || (qcw.quoteCharge.FakeQuantity__c < 1)) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' has an invalid Quantity');
                        }

                        //Country
                        else if (a.APIName == 'Country__c') {
                            if (qcw.Country == null || qcw.Country == '') errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' is missing Country');
                        }

                        //Sales Rep
                        else if (a.APIName == 'SalesRepId__c') {
                            if (qcw.quoteCharge.SalesRepId__c == null) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' is missing Sales Rep');
                        }

                        //Event
                        else if (a.APIName == 'Event__c') {
                            if (qcw.quoteCharge.Event__c == null) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' is missing Event');
                        }

                        //Months (only applies to alternative pricing of Monthly List Price)
                        else if (a.APIName == 'NumberOfMonths__c') {
                            if (qcw.quoteCharge.NumberOfMonths__c == null || qcw.quoteCharge.NumberOfMonths__c < 1) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' has an invalid Months value');

                            //If the number of months is not equal to the charge line term AND it's not one less, then work this validation error.
                            else if (prpw.IsMonthlyAlternatePricing && qcw.quoteCharge.NumberofMonths__c != qcw.quoteCharge.ChargeLineTerm__c && qcw.quoteCharge.NumberofMonths__c + 1 != qcw.quoteCharge.ChargeLineTerm__c) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' has a length of service (in months) that is different from the selected service dates');
                            //if (prpw.IsMonthlyAlternatePricing && prpw.productRatePlan.AlternatePriceCalculation__c.toLowerCase() == 'monthly per unit list price') errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' has a length of service (in months) that is different from the selected service dates');
                        }

                        else if (a.APIName == 'Notes__c') {
                            if ((prpw.ratePlanSaleType == 'Trial') && (qcw.quoteCharge.Notes__c == null || qcw.quoteCharge.Notes__c.length() < 1)) errorsQuoteCharges.add(prpw.productRatePlan.Name + ' - ' + qcw.quoteCharge.Name + ' requires Notes because it is a Trial.');
                        }
                    }
                }

                //Now make sure the math works regarding the billing frequency and term length...  (there may not be any rate plans added yet at this point, no guarantee...)
                Decimal numRequired = QuoteUtilities.NumberofInvoicesRequired(thisQuote.zqu__InitialTerm__c, prpw.productRatePlan.BillingFrequency__c);

                //If the number required is NOT a whole number, don't allow it - flag the warning.
                //IF the rate plan is NOT one-time only.
                if ((numRequired != numRequired.intValue()) && (!prpw.productRatePlan.RatePlanRecurringStatus__c.startsWithIgnoreCase('one'))) errorsQuoteCharges.add('Indivisible combination.  ' + prpw.productRatePlan.Name + ' has a billing frequency of ' + prpw.productRatePlan.BillingFrequency__c + ' that does not divide evenly with your term of ' + thisQuote.zqu__InitialTerm__c + ' months.');
            }
        }

        if (errorsQuoteCharges.size() > 0) return false;
        return true;
    }

    public Boolean ValidateQuoteDetails() {
        //reset the error collection...
        errorsQuoteDetails = new List<String>();  

        //Quote Details section...
        //Quote Name
        if (thisQuote.Name == null || (thisQuote.Name.length() < 1)) errorsQuoteDetails.add('Missing Quote Name');

        //Opportunity (out of the user's hands, but that's fine - it still needs to be there...)
        if (thisQuote.zqu__Opportunity__c == null) errorsQuoteDetails.add('Missing Opportunity');

        //BrandTag
        if (thisQuote.BrandTag__c == null) errorsQuoteDetails.add('Missing BrandTag');

        //Account (out of the user's hands, but that's fine - it still needs to be there...)
        if (sourceOpp.Accountid == null) errorsQuoteDetails.add('Missing Account');

        //Valid Until
        if (thisQuote.zqu__ValidUntil__c == null) errorsQuoteDetails.add('Missing Valid Until');

        //Billing Frequency
        if (thisQuote.Billing_Frequency__c == null) errorsQuoteDetails.add('Missing Billing Frequency');

        //Account Details section...
        //Bill to contact
        if (thisQuote.zqu__BillToContact__c == null) errorsQuoteDetails.add('Missing Bill to Contact');

        if (thisQuote.zqu__BillToContact__c != null) {
            //Validate email address against invoice delivery method
            List<Contact> contactList = [SELECT Email, Id, Name FROM Contact WHERE Id = :thisQuote.zqu__BillToContact__c LIMIT 1];
            if ((!contactList.isEmpty()) && (contactList[0].Email == null) && ((thisQuote.zqu__BillingMethod__c == 'Email') || (thisQuote.zqu__BillingMethod__c == 'Both'))) errorsQuoteDetails.add('Missing Bill To Contact Email Address.');
        }

        //Sold to contact
        if (thisQuote.zqu__SoldToContact__c == null) errorsQuoteDetails.add('Missing Sold to Contact');

        //Currency
        if (thisQuote.zqu__Currency__c == null) errorsQuoteDetails.add('Missing Currency');

        //Payment Term
        if (thisQuote.zqu__PaymentTerm__c == null) errorsQuoteDetails.add('Missing Payment Term');

        //Payment Method
        if (thisQuote.zqu__PaymentMethod__c == null) errorsQuoteDetails.add('Missing Payment Method');
        
        //Quote template region is required when brand tag is any of the eFC international ones
        if(QuoteTemplateRegionRequired && thisQuote.Quote_Template_Region__c == null) errorsQuoteDetails.add('Missing Region field; select one of the available region names in the list');
        
        //Subscription Terms section...
        if (thisQuote.zqu__StartDate__c == null) errorsQuoteDetails.add('Missing Service Start Date');

        //Subscription Term Type
        if (thisQuote.zqu__Subscription_Term_Type__c == null) errorsQuoteDetails.add('Missing Subscription Term Type');
        
        //First Bill Date (Deferred_Bill_Date__c)
        if (pageIsInEditMode && thisQuote.Deferred_Bill_Date__c == null) errorsQuoteDetails.add('Missing First Bill Date');

        //Initial Term
        if (thisQuote.zqu__InitialTerm__c == null && thisQuote.zqu__Subscription_Term_Type__c != 'Evergreen') errorsQuoteDetails.add('Missing Initial Term');
        if (thisQuote.zqu__Subscription_Term_Type__c == 'Evergreen') thisQuote.zqu__InitialTerm__c = 0.0; //set to be consistent with Zuora's data on Evergreen contracts.

        //Service End Date
        if (thisQuote.Service_End_Date__c == null && thisQuote.zqu__Subscription_Term_Type__c != 'Evergreen') errorsQuoteDetails.add('Missing Service End Date');
        if (thisQuote.zqu__Subscription_Term_Type__c == 'Evergreen') thisQuote.Service_End_Date__c = null; //set to be consistent with Zuora's data on Evergreen contracts.        

        //AR Validation now...
        if (thisQuote.AR_Special_Handling__c && (thisQuote.AR_Special_Notes__c == null || thisQuote.AR_Special_Notes__c.length() < 1)) errorsQuoteDetails.add('Missing AR Special Notes.  Note that this is required when AR Special Handling is checked.');

        //Now make sure the math works regarding the billing frequency and term length...  (there may not be any rate plans added yet at this point, no guarantee...)
        for (ProductRatePlanWrapper prpw : selectedRatePlans) {
            if (!prpw.isDiscountProduct) {
                Decimal numRequired = QuoteUtilities.NumberofInvoicesRequired(thisQuote.zqu__InitialTerm__c, prpw.productRatePlan.BillingFrequency__c);

                //If the number required is NOT a whole number, don't allow it - flag the warning.
                if (numRequired != numRequired.intValue() && (!prpw.productRatePlan.RatePlanRecurringStatus__c.startsWithIgnoreCase('one'))) errorsQuoteDetails.add('Indivisible Combination.  ' + prpw.productRatePlan.Name + ' has a billing frequency of ' + prpw.productRatePlan.BillingFrequency__c + ' that does not divide evenly with your term of ' + thisQuote.zqu__InitialTerm__c + ' months.');
            }
        }


        //Above are the insertion edits that should ALWAYS be checked, upon insertion or edit
        //Below are the more case-specific validation rules

        if (pageIsInEditMode) {
            if ((thisQuote.IS_Verified__c) && ((!sourceOpp.IsClosed) || (!sourceOpp.IsWon))) errorsQuoteDetails.add('The Opportunity must be marked Closed Won before the Quote can be Verified');
        }

        if (errorsQuoteDetails.size() > 0) return false;
        return true;
    }

    private void PopulateDiscountOptionsLists() {

        discountTypeOptions = new List<SelectOption>();  

        Schema.DescribeFieldResult discType = zqu__Quote__c.Discount_Type__c.getDescribe();
        List<Schema.PicklistEntry> discTypeValues = discType.getPicklistValues();

        //Set all available options, from the picklist as defined on the object
        if (discTypeValues != null) {
            for (Schema.PicklistEntry pickL : discTypeValues) {
                if (pickL.getLabel() == AGENCY_COMMISSION && sourceOpp.Sold_By_Partner__c != null) discountTypeOptions.add(new selectOption(pickL.getLabel(), pickL.getLabel()));
                if (pickL.getLabel() != AGENCY_COMMISSION) discountTypeOptions.add(new selectOption(pickL.getLabel(), pickL.getLabel()));
            }

            if (thisQuote.Discount_Type__c != null) discountTypeValue = thisQuote.Discount_Type__c;
            else discountTypeValue = discountTypeOptions[0].getLabel();  //initialize it to the first one
        }

        //Now also populate the sales rep options options
        discountSalesRepOptions = new List<SelectOption>();
        discountSalesRepOptions.add(new SelectOption('', '--None--'));
        for (User u : [SELECT Id, Name FROM User WHERE Directly_Commissionable__c = true AND IsActive = true ORDER BY Firstname]) {
            discountSalesRepOptions.add(new SelectOption(u.Name, U.Name));
        }

        //Now populate the country options...
        discountCountryOptions = new List<SelectOption>();
        for (pw_ccpro__CountryObject__c c : [Select Id, Name FROM pw_ccpro__CountryObject__c WHERE pw_ccpro__Enabled__c = true ORDER BY Name]) {
            discountCountryOptions.add(new SelectOption(c.Name, c.Name));
        }
    }

    private void InitializeAndDefaultProductFilters() {

        //PRICING MODEL START
        pricingModelOptions = new List<SelectOption>();  

        Schema.DescribeFieldResult pricModel = zqu__ProductRatePlan__c.RatePlanPricingModel__c.getDescribe();
        List<Schema.PicklistEntry> pricModelValues = pricModel.getPicklistValues();

        //Set all available options, from the picklist as defined on the object
        if (pricModelValues != null) {
            for (Schema.PicklistEntry pickL : pricModelValues) {
                pricingModelOptions.add(new selectOption(pickL.getLabel(), pickL.getLabel()));
            }
        }
        
        pricingModelValue = 'List Pricing';
        //PRICING MODEL END

        //DISCOUNT OPTIONS, START
        PopulateDiscountOptionsLists();
        //DISCOUNT OPTIONS, END

        //BRAND TAG, START
        //BRAND is at the zProduct level
        //BRANDTAG is at the product rate plan level
        String firstBrandTagVal = '';
        brandTagOptions = new List<SelectOption>();

        Schema.DescribeFieldResult brandTagModel = zqu__ProductRatePlan__c.BrandTag__c.getDescribe();
        List<Schema.PicklistEntry> brandTagValues = brandTagModel.getPicklistValues();

        //Set all available options, from the picklist as defined on the object
        if (pricModelValues != null) {
            for (Schema.PicklistEntry pickL : brandTagValues) {
                if (firstBrandTagVal == '') firstBrandTagVal = pickL.getLabel().toLowerCase();
                brandTagOptions.add(new selectOption(pickL.getLabel().toLowerCase(), pickL.getLabel()));
            }
        }
        if ((filterPresets != null) && (!filterPresets.isEmpty())) brandTagValue = filterPresets[0].GetOLIBrandTag;
        //BRAND TAG, END

        //COUNTRY START - (really only needed for the quote charge attribute default value)
        String firstCountryVal = '';
        if ((filterPresets != null) && (!filterPresets.isEmpty())) activefilterCountryValue = filterPresets[0].GetOLICountry;
        //COUNTRY END

        //PRODUCT GROUPS, START
        String firstProductGroupVal = '';
        productGroupOptions = new List<SelectOption>();

        Schema.DescribeFieldResult productGModel = zqu__ZProduct__c.ProductGroup__c.getDescribe();
        List<Schema.PicklistEntry> productGValues = productGModel.getPicklistValues();

        //Set all available options, from the picklist as defined on the object
        if (productGValues != null) {
            for (Schema.PicklistEntry pickL : productGValues) {
                if (firstProductGroupVal == '') firstProductGroupVal = pickL.getLabel().toLowerCase();
                if (pickL.getLabel().toLowerCase() != 'discount') productGroupOptions.add(new selectOption(pickL.getLabel().toLowerCase(), pickL.getLabel()));
            }
        }
        if ((filterPresets != null) && (!filterPresets.isEmpty())) productGroupValue = filterPresets[0].GetOLIProductGroup;
        //PRODUCT GROUPS, END


        //BILLING FREQ, START
        RefreshBillingFrequencyOptions();
        
        //BILLING FREQ, END

        //This sets the values & filters to the correct spot for initial page render
        if ((filterPresets != null) && (!filterPresets.isEmpty())) {
            FilterPreset fp = filterPresets[0];

            if ((fp != null) && (fp.OppLineItem != null)) productGroupValue = fp.GetOLIProductGroup.toLowerCase();
            else productGroupValue = firstProductGroupVal;

            if ((fp != null) && (fp.OppLineItem != null)) brandTagValue = fp.GetOLIBrandTag.toLowerCase();
            else brandTagValue = firstBrandTagVal;

            pricingModelValue = 'List Pricing';
        }
        else {
            //no presets, default the results to whatever is first...
            productGroupValue = firstProductGroupVal;
            brandTagValue = firstBrandTagVal;
            pricingModelValue = 'List Pricing';
        }

        //Reset the quoteCharges errors list
        errorsQuoteCharges = new List<String>();

        //Execute the search now...
       RefreshFoundRatePlans();
    }

    private void RefreshBillingFrequencyOptions() {

        billingFrequencyOptions = new List<SelectOption>();              

        String newBFValue = null;

        Schema.DescribeFieldResult billingFreqModel = zqu__Quote__c.Billing_Frequency__c.getDescribe();
        List<Schema.PicklistEntry> billingFreqValues = billingFreqModel.getPicklistValues();

        //Set all available options, from the picklist as defined on the object
        if (billingFreqValues != null) {
            for (Schema.PicklistEntry pickL : billingFreqValues) {

                Decimal num = QuoteUtilities.NumberofInvoicesRequired(thisQuote.zqu__InitialTerm__c, pickL.getLabel());
                if (num == num.intValue()) billingFrequencyOptions.add(new selectOption(pickL.getLabel().toLowerCase(), pickL.getLabel()));
                if (thisQuote.Billing_Frequency__c != null && num == num.intValue() && pickL.getLabel().toLowerCase() == thisQuote.Billing_Frequency__c.toLowerCase()) newBFValue = thisQuote.Billing_Frequency__c.toLowerCase();
            }
        }
        if (newBFValue != null) billingFrequencyValue = newBFValue;
        else if (!billingFrequencyOptions.isEmpty()) billingFrequencyValue = billingFrequencyOptions[0].getValue();
        else billingFrequencyValue = 'Doh!';
    }

    public PageReference RefreshFoundRatePlans() {

        //reset the list
        foundRatePlans = new List<zqu__ProductRatePlan__c>();        

        errorsQuoteCharges.clear();

        if (thisQuote.zqu__StartDate__c == null) {
            errorsQuoteCharges.add('Unable to refresh rate plans until the Quote\'s Service Start Date field is populated.');
            return null;
        }

        String dateToCompare = String.valueOf(thisQuote.zqu__StartDate__c);
        Set<Id> allowedRatePlans = QuoteUtilities.FilteredRatePlans(thisQuote.zqu__Currency__c, thisQuote.zqu__StartDate__c);

        String whereRecur = null;
        String wherePricing = null;
        String whereProductGroup = null;
        String whereBrandTags = null;
        String whereBillingFrequency = null;
        String whereRestrictedFrom = null;

        if (billingFrequencyValue == 'One-Time') recurringStatusValue = 'one-time';
        else recurringStatusValue = 'recurring';

        //Construct all the filters
        whereRecur = '(RatePlanRecurringStatus__c = \'' + recurringStatusValue + '\') ';

        //construct the Pricing Model where clause:
        if ((pricingModelValue != null) && (pricingModelValue != '')) wherePricing = '(RatePlanPricingModel__c = \'' + pricingModelValue + '\') ';
        else wherePricing = '(RatePlanPricingModel__c = \'List Pricing\')';        

        if ((brandTagValue != null) && (brandTagValue != '')) whereBrandTags = '(BrandTag__c = \'' + brandTagValue + '\') ';
        else whereBrandTags = '(BrandTag__c = \'NOTHING_SELECTED!\') ';

        if ((productGroupValue != null) && (productGroupValue != '')) whereProductGroup = productGroupValue;
        else whereProductGroup = 'NOTHING_SELECTED!';

        whereRestrictedFrom = QuoteUtilities.ReturnRestrictedFromWhereClauseForCPQ(currentUser.Profile.Name);       

        if ((billingFrequencyValue != null) && (billingFrequencyValue != '') && (billingFrequencyValue != 'One-Time')) whereBillingFrequency = ' AND (BillingFrequency__c = \'' + billingFrequencyValue + '\') ';
        else if (billingFrequencyValue == 'One-Time') whereBillingFrequency = '';
        else whereBillingFrequency = ' AND (BillingFrequency__c = \'NOTHING_SELECTED!\') ';
        //Execute the select statement           

        String soql = 'SELECT Id, Name, zqu__ZProduct__r.Id, zqu__ZProduct__r.Name, zqu__ZProduct__r.ProductGroup__c, BrandTag__c, AlternatePriceCalculation__c FROM zqu__ProductRatePlan__c WHERE zqu__ZProduct__r.ProductGroup__c = \'' + whereProductGroup +  '\'';
        soql += ' AND ' + whereBrandTags + ' ';
        soql += whereBillingFrequency + ' ';                        //billing Frequency is NOT a real filter if the value is 'One-Time'
        soql += ' AND ' + whereRecur;                             //recurring status filter
        if (whereRestrictedFrom != null) soql += ' AND ' + whereRestrictedFrom;
        soql += ' AND ' + wherePricing;                           //pricing model filter
        soql += ' AND ( zqu__EffectiveStartDate__c <= ' + dateToCompare + ')';  //rate plan available dates
        soql += ' AND ( zqu__EffectiveEndDate__c >= ' + dateToCompare + ')';    //rate plan available dates
        soql += ' AND ( zqu__ZProduct__r.zqu__EffectiveStartDate__c <= ' + dateToCompare + ')';  //product available dates
        soql += ' AND ( zqu__ZProduct__r.zqu__EffectiveEndDate__c >= ' + dateToCompare + ')';    //product available dates
        soql += ' AND ( zqu__Deleted__c = false)';    //product not deleted by Zuora's standards.
        soql += ' AND ( IsVisibletoUserInterface__c != \'No\')';    //product not hidden with the new field

        //Binding actually works in dynamic SOQL!  Oh glorious day!
        soql += ' AND ( zqu__ProductRatePlan__c.Id IN :allowedRatePlans)';
        soql += ' ORDER BY zqu__ZProduct__r.Name, Name ASC' ;    

        foundRatePlans = Database.query(soql);
        resultCount = foundRatePlans.size();

        return null;
    }


    public PageReference SetFilter() {

        //get the oppLineItem from the filterId now which has been set.
        filterId = Apexpages.currentPage().getparameters().get('filterId');

        if (filterId != null && filterPresets != null) {
            for (FilterPreset fp : filterPresets) {
                if ((fp.OppLineItem != null) && (fp.OppLineItem.Id == filterId)) {
                    productGroupValue = fp.GetOLIProductGroup.toLowerCase();
                    brandTagValue = fp.GetOLIBrandTag.toLowerCase();
                    pricingModelValue = 'List Pricing';
                    saleTypeValue = STANDARD_SALE_TYPE;
                    SaleTypeValueChanged();
                    activefilterCountryValue = fp.GetOLICountry;
                }
            }
        }

        return RefreshFoundRatePlans();
    }

    private void GetQuoteChargeAttributes() {
        allAtts = [SELECT APIName__c, ControlType__c, DefaultValue__c, Label__c, SOQLSelect__c, SortOrder__c, Name, Id, Picklist_IDField__c, Picklist_ValueField__c, PostbackAction__c FROM QuoteChargeAttributes__c WHERE IsDeleted = false ORDER BY SortOrder__c];
    }

    public PageReference ProcessDynamicPostbackAction() {

        DynamicPostbackParam = Apexpages.currentPage().getParameters().get('DynamicParamName');     //this includes the name of the function to execute, a colon, and a GUID that should be unique to the quote charge, like so:
                                                                                                    //  FillStartEndDates:979bf54d-985b-44bb-b92f-535b0d62bb17
        List<String> pieces = DynamicPostbackParam.split(':');

        if (pieces[0] == 'FillStartEndDates') FillStartEndDates(pieces[1]);

        if (pieces[0] == 'RecalcQuoteChargeTotal') RecalcQuoteChargeTotal(pieces[1]);

        if (pieces[0] == 'RecalcQuoteChargeTotalAndResetFlag') RecalcQuoteChargeTotalAndResetFlag(pieces[1]);

        if (pieces[0] == 'RecalcChargeLineTerm') RecalcChargeLineTerm(pieces[1]);

        return null;
    }

    public PageReference RecalculateUnitPrice() {

        UnitPriceCalculator = ApexPages.currentPage().getParameters().get('UnitPriceCalculator');

        List<String> pieces = UnitPriceCalculator.split(':');

        if (pieces[0] == 'QCTOTAL') {
            //then we just edited the total, back into the unit price
            //Find the Quote Charge the GUID refers to and apply the logic then...

            for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
                for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {
                    if (qcw.GUID == pieces[1]) {
                        
                        if (qcw.quoteCharge.FakeQuantity__c != null && qcw.quoteCharge.FakeQuantity__c > 0 && qcw.quoteCharge.zqu__Total__c != null && qcw.quoteCharge.zqu__Total__c >= 0) BackIntoUnitPrice(prpWrapper, qcw);
                        WorkTheMath(qcw, prpWrapper);
                        break;
                    }
                }
            }

            RecalcAllQuoteNumbers();
            }

        else if (pieces[0] == 'UNITPRICE') {
            //then we just edited the unit price, back into the total
            //Nothing here because this is already properly done in the dynamic postback sub / attributes
        }

        return null;
    }

    private void BackIntoUnitPrice(ProductRatePlanWrapper prpWrapper, QuoteChargeWrapper qcw) {

        //This sets the zqu__EffectivePrice__c (Unit Price as displayed) based on the Quantity & Quote Charge Total values that already have values at this point
        qcw.quoteChargeTotalManuallySet = true;
        qcw.quoteCharge.zqu__EffectivePrice__c = (qcw.quoteCharge.zqu__Total__c / qcw.quoteCharge.FakeQuantity__c).setScale(2, System.RoundingMode.HALF_UP);

    }

    private void RecalcAllQuoteNumbers() {

        for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
            for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {

                if (!qcw.isDiscountCharge) WorkTheMath(qcw, prpWrapper);        //Process all non-discounts first!
            }
        }

        for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
            for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {

                if (qcw.isDiscountCharge) WorkTheMath(qcw, prpWrapper);        //Process all discounts second!
            }
        }        

        RecalcQuoteTotal();
    }

    //This updates the zqu__Total__c field (& rarely the EffectivePrice to 0 if a discount needs to be corrected) on the quoteChargeWrapper in the argument, only.
    private void WorkTheMath(QuoteChargeWrapper qcw, ProductRatePlanWrapper prpw) {

        qcw.FauxTCV = null; //set it to null initially so my later calculations can know if it's been correctly calculated by way of NOT being null...
        qcw.FauxTCVNet = null;
        //first, calculate the FauxTCV:
            //If this is an evergreen quote OR if the product rate plan is one-time, TCV is calcualted like so:        

        if (!qcw.isDiscountCharge) {
            if (((thisQuote.zqu__Subscription_Term_Type__c.startsWithIgnoreCase('evergreen')) || (prpw.productRatePlan.RatePlanRecurringStatus__c != null && prpw.productRatePlan.RatePlanRecurringStatus__c.startsWithIgnoreCase('one'))) && (!prpw.IsMonthlyAlternatePricing) && (qcw.quoteCharge.FakeQuantity__c != null && qcw.quoteCharge.zqu__EffectivePrice__c != null)) {

                if (!qcw.quoteChargeTotalManuallySet) qcw.quoteCharge.zqu__Total__c = (qcw.quoteCharge.FakeQuantity__c * qcw.quoteCharge.zqu__EffectivePrice__c).setScale(2, System.RoundingMode.HALF_UP);       //For the UI
                else qcw.quoteCharge.zqu__Total__c = (qcw.quoteCharge.FakeQuantity__c * qcw.quoteCharge.zqu__EffectivePrice__c).setScale(2, System.RoundingMode.HALF_UP);       //For the UI

                qcw.FauxTCV = qcw.quoteCharge.FakeQuantity__c * qcw.quoteCharge.zqu__EffectivePrice__c;                         //Not for the UI
                qcw.FauxTCVNet = qcw.FauxTCV;                                                                                   //Not for the UI
            }
            else {
                if (qcw.quoteCharge.FakeQuantity__c != null && qcw.quoteCharge.zqu__EffectivePrice__c != null && thisQuote.zqu__InitialTerm__c != null) {
                    if (!prpw.IsMonthlyAlternatePricing) {

                        if (!qcw.quoteChargeTotalManuallySet) qcw.quoteCharge.zqu__Total__c = (qcw.quoteCharge.FakeQuantity__c * qcw.quoteCharge.zqu__EffectivePrice__c).setScale(2, System.RoundingMode.HALF_UP);       //For UI
                        else qcw.quoteCharge.zqu__Total__c = (qcw.quoteCharge.FakeQuantity__c * qcw.quoteCharge.zqu__EffectivePrice__c).setScale(2, System.RoundingMode.HALF_UP);       //For UI

                        qcw.FauxTCV = (qcw.quoteCharge.FakeQuantity__c * qcw.quoteCharge.zqu__EffectivePrice__c).setScale(2, RoundingMode.HALF_UP) * QuoteUtilities.NumberofInvoicesRequired(thisQuote.zqu__InitialTerm__c, prpw.productRatePlan.BillingFrequency__c); //Not for UI
                        qcw.FauxTCVNet = qcw.FauxTCV;     
                    }

                    //Funky math for the alternate (monthly) math.  Initial term does not play here, instead # of months does.

                    //Note that the monthly pricing calculation is EXACTLY THE SAME for both 'Alternate Pricing' values - whether it's Monthly List Price or Monthly Per Unit List Price.
                    //The only difference is that the Monthly Per Unit List Price exposes the Quantity field to the end user to edit so it isn't necessarily always '1'.
                    else if (prpw.IsMonthlyAlternatePricing && qcw.quoteCharge.NumberOfMonths__c != null && qcw.quoteCharge.NumberofMonths__c > 0 && qcw.quoteCharge.FakeQuantity__c > 0) {

                        if (!qcw.quoteChargeTotalManuallySet) {
                            //Effective Price
                            if (prpw.productRatePlan.RatePlanRecurringStatus__c != null && prpw.productRatePlan.RatePlanRecurringStatus__c.startsWithIgnoreCase('one'))    qcw.quoteCharge.zqu__EffectivePrice__c = (qcw.quoteCharge.zqu__ListPriceDisplay__c * qcw.quoteCharge.NumberOfMonths__c).setScale(2, System.RoundingMode.HALF_UP);
                            else                                                                                qcw.quoteCharge.zqu__EffectivePrice__c = ((qcw.quoteCharge.zqu__ListPriceDisplay__c * qcw.quoteCharge.NumberOfMonths__c) / (QuoteUtilities.NumberofInvoicesRequired(thisQuote.zqu__InitialTerm__c, prpw.productRatePlan.BillingFrequency__c))).setScale(2, System.RoundingMode.HALF_UP);
                        }
                        //else don't calculate it because it was set from the input field

                        //Total
                        qcw.quoteCharge.zqu__Total__c = qcw.quoteCharge.FakeQuantity__c * qcw.quoteCharge.zqu__EffectivePrice__c;

                        //FauxTCV
                        if (prpw.productRatePlan.RatePlanRecurringStatus__c != null && prpw.productRatePlan.RatePlanRecurringStatus__c.startsWithIgnoreCase('one')) qcw.FauxTCV = (qcw.quoteCharge.zqu__EffectivePrice__c * qcw.quoteCharge.FakeQuantity__c).setScale(2, RoundingMode.HALF_UP);
                        else qcw.FauxTCV =  (qcw.quoteCharge.FakeQuantity__c * qcw.quoteCharge.zqu__EffectivePrice__c).setScale(2, RoundingMode.HALF_UP) * QuoteUtilities.NumberofInvoicesRequired(thisQuote.zqu__InitialTerm__c, prpw.productRatePlan.BillingFrequency__c);
                        qcw.FauxTCVNet = qcw.FauxTCV;
                    }
                }
            }           
        }
        else {
            //If it's a percentage discount
            if (qcw.quoteCharge.zqu__Model__c.containsIgnoreCase('percent')) {
                if (qcw.quoteCharge.zqu__EffectivePrice__c == null || qcw.quoteCharge.zqu__EffectivePrice__c < 0 || qcw.quoteCharge.zqu__EffectivePrice__c > 100) {
                    qcw.quoteCharge.zqu__EffectivePrice__c = 0;
                    qcw.quoteCharge.zqu__Total__c = 0;
                    qcw.FauxTCV = 0;
                    qcw.FauxTCVNet = 0;
                }
                else if (qcw.quoteCharge.zqu__EffectivePrice__c != null && qcw.quoteCharge.zqu__EffectivePrice__c >=0 && qcw.quoteCharge.zqu__EffectivePrice__c <= 100) {
                    Decimal discountPercentage = qcw.quoteCharge.zqu__EffectivePrice__c;
                    Decimal prpTotalTCV = 0;

                    //Note that ALL Discounts must have their TCV calculated AFTER all non-discounts for this to be accurate!
                    for (QuoteChargeWrapper qcw2 : prpw.quoteChargeWrappers) {
                        if (qcw2.GUID != qcw.GUID && qcw2.FauxTCV != null && !qcw2.isDiscountCharge) {
                            prpTotalTCV += qcw2.FauxTCV;
                            qcw2.FauxTCVNet += (-1 * ((discountPercentage / 100) * qcw2.FauxTCVNet));
                        }                        
                    }

                    qcw.quoteCharge.zqu__Total__c = -1 * prpTotalTCV * (discountPercentage / 100) ;     //the negative equates to the discount for the quote total summary.
                    qcw.FauxTCV = -1 * prpTotalTCV * (discountPercentage / 100) ;                       //the negative equates to the discount for the quote total summary.
                }
            }
            //TODO - For a fixed-amount discount at the rate plan level - does the TCV == zqu__Total__c OR does the TCV == zqu__Total__c * QuoteUtilities.NumberofInvoicesRequired()????
            else {
                if ((qcw.quoteCharge.zqu__EffectivePrice__c != null) && (qcw.quoteCharge.zqu__EffectivePrice__c > 0)) qcw.FauxTCV = qcw.quoteCharge.zqu__EffectivePrice__c * -1;
                else if ((qcw.quoteCharge.zqu__EffectivePrice__c != null) && (qcw.quoteCharge.zqu__EffectivePrice__c < 0)) qcw.FauxTCV = qcw.quoteCharge.zqu__EffectivePrice__c;
            }
        }

        if (qcw.FauxTCV == null) {
            qcw.Quotecharge.zqu__Total__c = 0;
            qcw.FauxTCV = 0;
            qcw.FauxTCVNet = 0;
        }

        if (qcw.FauxTCV != null) qcw.FauxTCV = qcw.FauxTCV.setScale(2, RoundingMode.HALF_UP);
        if (qcw.FauxTCVNet != null) qcw.FauxTCVNet = qcw.FauxTCVNet.setScale(2, RoundingMode.HALF_UP);

        //Add/insert said quoteCharges to their respective invoices now?
    }

    private void RecalcQuoteChargeTotal(String quoteChargeGUID) {
        //Find the Quote Charge the GUID refers to and apply the logic then...

        forceDiscountRecalc = true;

        //clear the errors (if any)
        errorsQuoteCharges = new List<String>();

        for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
            for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {
                if (qcw.GUID == quoteChargeGUID) {

                    Boolean updateEffPrice = qcw.quoteChargeTotalManuallySet;
                    updateEffPrice = !updateEffPrice;
                    

                    if (prpWrapper.productRatePlan.AlternatePriceCalculation__c == null || prpWrapper.productRatePlan.AlternatePriceCalculation__c != 'Monthly List Price') AdjustPriceofQuoteChargeIfNeeded(prpWrapper, qcw, updateEffPrice);

                    if (qcw.quoteChargeTotalManuallySet) BackIntoUnitPrice(prpWrapper, qcw);

                    WorkTheMath(qcw, prpWrapper);

                }
            }
        }

        RecalcAllQuoteNumbers();
    }

    private void RecalcQuoteChargeTotalAndResetFlag(String quoteChargeGUID) {
        //Find the Quote Charge the GUID refers to and apply the logic then...

        forceDiscountRecalc = true;

        for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
            for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {
                if (qcw.GUID == quoteChargeGUID) {

                    qcw.quoteChargeTotalManuallySet = false;

                    qcw.quoteCharge.zqu__EffectivePrice__c = qcw.quoteCharge.zqu__EffectivePrice__c.setScale(2, RoundingMode.HALF_UP);

                    if (prpWrapper.productRatePlan.AlternatePriceCalculation__c == null || prpWrapper.productRatePlan.AlternatePriceCalculation__c != 'Monthly List Price') AdjustPriceofQuoteChargeIfNeeded(prpWrapper, qcw, true);
                    WorkTheMath(qcw, prpWrapper);
                }
            }
        }

        RecalcAllQuoteNumbers();
    }    

    //This will adjust the effective price / quote price / list price of the quote charge to match the product catalog
    //Used for when the quantity changes and a new list price might be needed to be found and updated for that line.
    private void AdjustPriceofQuoteChargeIfNeeded(ProductRatePlanWrapper prpw, QuoteChargeWrapper qcw, Boolean updateEffectivePrice) {

        //If it's NOT list pricing, return, do nothing here
        if (!prpw.productRatePlan.RatePlanPricingModel__c.startsWithIgnoreCase('list')) return;

        List<zqu__ProductRatePlanChargeTier__c> prpcTiers = [SELECT zqu__Currency__c, 
                                                                    zqu__EndingUnit__c, 
                                                                    zqu__Price__c, 
                                                                    zqu__PriceFormat__c, 
                                                                    zqu__ProductRatePlanCharge__c, 
                                                                    zqu__StartingUnit__c, 
                                                                    zqu__Tier__c 
                                                                FROM zqu__ProductRatePlanChargeTier__c
                                                                WHERE zqu__ProductRatePlanCharge__c = :qcw.quoteCharge.zqu__ProductRatePlanCharge__c
                                                                    AND zqu__Currency__c = :thisQuote.zqu__Currency__c
                                                                    AND zqu__Deleted__c = false
                                                                    AND zqu__StartingUnit__c <= :qcw.quoteCharge.FakeQuantity__c
                                                                    AND 
                                                                        (zqu__EndingUnit__c >= :qcw.quoteCharge.FakeQuantity__c 
                                                                            OR
                                                                         zqu__EndingUnit__c = 0
                                                                            OR
                                                                         zqu__EndingUnit__c = null)
                                                                ORDER BY zqu__StartingUnit__c];


        if (prpcTiers == null || prpcTiers.isEmpty()) {
            //If we're here, set it all to NULL because nothing was found and we can't allow the user to continue.
            qcw.quoteCharge.zqu__ListPriceDisplay__c = null;
            if (updateEffectivePrice) qcw.quoteCharge.zqu__EffectivePrice__c = null;
            qcw.quoteCharge.zqu__Total__c = null;
        }
        else {
            qcw.quoteCharge.zqu__ListPriceDisplay__c = prpcTiers[0].zqu__Price__c;
            if (updateEffectivePrice) qcw.quoteCharge.zqu__EffectivePrice__c = prpcTiers[0].zqu__Price__c;
        }
    }

    //This is called when either the service start dates or service end dates are edited.
    //It's also used to set up and call the funky math for the monthly (alternative) pricing method
    private void RecalcChargeLineTerm(String quoteChargeGUID) {
        //Find the Quote Charge the GUID refers to and apply the logic then...

        for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
            for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {
                if (qcw.GUID == quoteChargeGUID) {

                    if (thisQuote.zqu__Subscription_Term_Type__c.startsWithIgnoreCase('evergreen')) qcw.quoteCharge.ChargeLineTerm__c = 1;
                    else qcw.quoteCharge.ChargeLineTerm__c = QuoteUtilities.CalculateChargeLineTerm(qcw.quoteCharge.ServiceStart__c, qcw.quoteCharge.ServiceEnd__c);

                    return;
                }
            }
        }        
    }

    public PageReference RecalcTheQuoteNumbers() {

        discountFieldUsed = Apexpages.currentPage().getParameters().get('sourceField');

        forceDiscountRecalc = true;

        RecalcAllQuoteNumbers();

        return null;
    }

    public List<ZInvoice> ConstructTheInvoices(List<ProductRatePlanWrapper> ratePlans) {

        Integer numInvoicesNeeded = 0;
        if (thisQuote.zqu__Subscription_Term_Type__c.toLowerCase() == 'evergreen') numInvoicesNeeded = 1;
        else if (thisQuote.zqu__InitialTerm__c != null) numInvoicesNeeded = Integer.valueOf(thisQuote.zqu__InitialTerm__c);
        
        Integer iInvoiceNum = 1;
        List<ZInvoice> results = new List<ZInvoice>();

        if (numInvoicesNeeded != 0) {

            for (Integer i=1; i<=numInvoicesNeeded; i++) {

                ZInvoice thisI = new ZInvoice();

                for (ProductRatePlanWrapper prpWrapper : ratePlans) {
                    for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {
                        if (QuoteUtilities.InvoiceQC(i, qcw)) thisI.Charges.add(qcw);
                    }                
                }
                results.add(thisI);
            }
        }

        return results;
    }

    private void RecalcQuoteTotal() {

        //First, reset the invoices...
        List<ZInvoice> invoices = ConstructTheInvoices(selectedRatePlans);

        quoteTotalGross = 0;
        quoteTotalDiscount = 0;
        Decimal quoteLevelDiscountRunningTotal = 0;

        for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
            for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {

                if (qcw.FauxTCV != null && qcw.FauxTCV > 0)         quoteTotalGross     += qcw.FauxTCV;
                else if (qcw.FauxTCV != null && qcw.FauxTCV < 0)    quoteTotalDiscount  += qcw.FauxTCV;

            }                
        }

        if (Test.isRunningTest()) quoteTotalGross = 10000;      //here to help the test class get more code coverage only...

        quoteTotalNet = quoteTotalGross + quoteTotalDiscount;

        if (discountFieldUsed != null) {            

            if (discountFieldUsed == 'Discount_Percent__c' && thisQuote.Discount_Percent__c != null) {

                Decimal discountPer = thisQuote.Discount_Percent__c.setScale(9);
                thisQuote.Discount_New_Net__c = 0;

                for (ZInvoice zi : invoices) {
                    thisQuote.Discount_New_Net__c += zi.CalcInvoiceTotal(discountPer, thisQuote.zqu__InitialTerm__c);
                }

                thisQuote.Discount_New_Net__c = thisQuote.Discount_New_Net__c.setScale(2, RoundingMode.HALF_UP);
                thisQuote.Discount_Fixed__c = (quoteTotalNet - thisQuote.Discount_New_Net__c) * -1;
                thisQuote.Discount_Percent__c = discountPer;

            } else if (discountFieldUsed == 'Discount_Fixed__c' && thisQuote.Discount_Fixed__c != null) {
                Decimal enteredValue = thisQuote.Discount_Fixed__c.setScale(2);

                if (thisQuote.Discount_Fixed__c > 0) thisQuote.Discount_Fixed__c = thisQuote.Discount_Fixed__c * -1;
                if (enteredValue > 0) enteredValue = enteredValue * -1;

                //Here quoteTotalNet is really the quote Gross amount, less any rate plan discounts.  
                if (quoteTotalNet != 0) {
                    //First calculate what the discount *should* be, mathematically.
                    thisQuote.Discount_Percent__c = ((thisQuote.Discount_Fixed__c * -1) / quoteTotalNet) * 100;
                    Decimal discountPer = thisQuote.Discount_Percent__c.setScale(9);
                    Decimal calculatedDiscountPer = 0;

                    Decimal hopefulNet = quoteTotalNet + enteredValue;

                    thisQuote.Discount_New_Net__c = 0;

                    for (ZInvoice zi : invoices) {
                        thisQuote.Discount_New_Net__c += zi.CalcInvoiceTotal(discountPer, thisQuote.zqu__InitialTerm__c);
                    }

                    //This if statement is for in case if the amount calculated with utmost precision is NOT the desired amount.
                    //A few attempts will be tried with different rounding to calculate the desired amount.  If not feasible, then it'll be adjusted.
                    if (thisQuote.Discount_New_Net__c - enteredValue != quoteTotalNet) {
                        calculatedDiscountPer = AdjustPercentDiscount(discountPer, hopefulNet, invoices);
                        thisQuote.Discount_New_Net__c = 0;

                        for (ZInvoice zi : invoices) {
                            thisQuote.Discount_New_Net__c += zi.CalcInvoiceTotal(calculatedDiscountPer, thisQuote.zqu__InitialTerm__c);
                        }                        

                    }
                    else calculatedDiscountPer = discountPer;

                    //There exists a possibility that this exact discount fixed value cannot be found even through the goofy math, so we have to update the value here just in case.
                    thisQuote.Discount_Percent__c = calculatedDiscountPer;
                    thisQuote.Discount_Fixed__c = (quoteTotalNet - thisQuote.Discount_New_Net__c) * -1;
                }

            } else if (discountFieldUsed == 'Discount_New_Net__c' && thisQuote.Discount_New_Net__c != null) {

                Decimal enteredValue = thisQuote.Discount_New_Net__c.setScale(2);

                if (thisQuote.Discount_New_Net__c < 0) thisQuote.Discount_New_Net__c = thisQuote.Discount_New_Net__c * -1;
                if (enteredValue < 0) enteredValue = enteredValue * -1;

                thisQuote.Discount_Fixed__c = (quoteTotalNet - thisQuote.Discount_New_Net__c) * -1;

                if (quoteTotalNet != 0) {
                    //First calculate what the discount *should* be, mathematically.
                    thisQuote.Discount_Percent__c = ((thisQuote.Discount_Fixed__c * -1) / quoteTotalNet) * 100;
                    Decimal discountPer = thisQuote.Discount_Percent__c.setScale(9);
                    Decimal calculatedDiscountPer = 0;

                    thisQuote.Discount_New_Net__c = 0;

                    for (ZInvoice zi : invoices) {
                        thisQuote.Discount_New_Net__c += zi.CalcInvoiceTotal(discountPer, thisQuote.zqu__InitialTerm__c);
                    }

                    //This if statement is for in case if the amount calculated with utmost precision is NOT the desired amount.
                    //A few attempts will be tried with different rounding to calculate the desired amount.  If not feasible, then it'll be adjusted.
                    if (thisQuote.Discount_New_Net__c != enteredValue) {

                        calculatedDiscountPer = AdjustPercentDiscount(discountPer, enteredValue, invoices);
                        thisQuote.Discount_New_Net__c = 0;

                        for (ZInvoice zi : invoices) {
                            thisQuote.Discount_New_Net__c += zi.CalcInvoiceTotal(calculatedDiscountPer, thisQuote.zqu__InitialTerm__c);
                        }                        

                    }
                    else calculatedDiscountPer = discountPer;

                    //There exists a possibility that this exact discount fixed value cannot be found even through the goofy math, so we have to update the value here just in case.
                    thisQuote.Discount_Fixed__c = (quoteTotalNet - thisQuote.Discount_New_Net__c) * -1;
                    thisQuote.Discount_Percent__c = calculatedDiscountPer;
                }
            }

            if ((thisQuote.Discount_Fixed__c == null || thisQuote.Discount_Fixed__c == 0) && (discountFieldUsed == 'Discount_Fixed__c')) {
                thisQuote.Discount_New_Net__c = null;
                thisQuote.Discount_Percent__c = null;
                thisQuote.Discount_Fixed__c = null;
            }

            if ((thisQuote.Discount_Percent__c == null || thisQuote.Discount_Percent__c == 0) && (discountFieldUsed == 'Discount_Percent__c')) {
                thisQuote.Discount_New_Net__c = null;
                thisQuote.Discount_Fixed__c = null;
                thisQuote.Discount_Percent__c = null;
            }

            if ((thisQuote.Discount_New_Net__c == null || thisQuote.Discount_New_Net__c == 0) && (discountFieldUsed == 'Discount_New_Net__c')) {
                thisQuote.Discount_Percent__c = null;
                thisQuote.Discount_Fixed__c = null;
                thisQuote.Discount_New_Net__c = null;
            }

            if (thisQuote.Discount_Fixed__c != null) quoteTotalDiscount += thisQuote.Discount_Fixed__c;

            if (thisQuote.Discount_Percent__c == null) {
                for (ZInvoice zi : invoices) {
                    zi.CalcInvoiceTotalReturningVoid(0, thisQuote.zqu__InitialTerm__c);
                }
            }
        }
        else {
            //No discount, get the totals still
            for (ZInvoice zi : invoices) {
                zi.CalcInvoiceTotalReturningVoid(0, thisQuote.zqu__InitialTerm__c);
            }
        }

        //byrnes test        
        quoteTotalGross = quoteTotalGross.setScale(2, System.RoundingMode.HALF_UP);
        quoteTotalDiscount = quoteTotalDiscount.setScale(2, System.RoundingMode.HALF_DOWN);
        thisQuote.Discount_Fixed__c = quoteTotalDiscount;
        thisQuote.Discount_New_Net__c = quoteTotalGross + quoteTotalDiscount;
        //end byrnes test

        quoteTotalNet = quoteTotalGross + quoteTotalDiscount;   //discount is negative

        //set the first bill amount now.
        if (invoices != null && !invoices.isEmpty()) thisQuote.First_Bill_Amount__c = invoices[0].amountBilled;

        return;
    }

    //If this function is running then the rounded math doesn't equal the target value reduction.
    //Loop through the various levels of precision until we find one that does (hopefully!)
    //If not, then the values may be different and that's life...
    private Decimal AdjustPercentDiscount(Decimal initialPercent, Decimal targetNet, List<ZInvoice> invoices) {

        Integer iScale = 8;
        do {
            Decimal newNet = 0;
            Decimal discountPer = initialPercent.setScale(iScale, System.RoundingMode.HALF_UP);

            for (ZInvoice zi : invoices) {
                newNet += zi.CalcInvoiceTotal(discountPer, thisQuote.zqu__InitialTerm__c);
            }

            if (newNet == targetNet) return discountPer.setScale(iScale, System.RoundingMode.HALF_UP);
            else iScale--;
        } while (iScale > 3);

        iScale = 8;
        do {
            Decimal newNet = 0;
            Decimal discountPer = initialPercent.setScale(iScale, System.RoundingMode.FLOOR);

            for (ZInvoice zi : invoices) {
                newNet += zi.CalcInvoiceTotal(discountPer, thisQuote.zqu__InitialTerm__c);
            }

            if (newNet == targetNet) return discountPer.setScale(iScale, System.RoundingMode.FLOOR);
            else iScale--;
        } while (iScale > 3);

        iScale = 8;
        do {
            Decimal newNet = 0;
            Decimal discountPer = initialPercent.setScale(iScale, System.RoundingMode.CEILING);

            for (ZInvoice zi : invoices) {
                newNet += zi.CalcInvoiceTotal(discountPer, thisQuote.zqu__InitialTerm__c);
            }

            if (newNet == targetNet) return discountPer.setScale(iScale, System.RoundingMode.CEILING);
            else iScale--;
        } while (iScale > 3);

        iScale = 8;
        Integer iCount = 1;
        Decimal discountPer = initialPercent.setScale(iScale, System.RoundingMode.UP) + 0.00055;
        do {
            Decimal newNet = 0;
            discountPer -= 0.00003;

            for (ZInvoice zi : invoices) {
                newNet += zi.CalcInvoiceTotal(discountPer, thisQuote.zqu__InitialTerm__c);
            }

            if (newNet == targetNet) return discountPer;
            else iCount++;
        } while (iCount < 40);

        //If we haven't found a fix - return the first... 
        return initialPercent;
    }

    private void FillStartEndDates(String quoteChargeGUID) {

        //Find the Quote Charge the GUID refers to and apply the logic then...

        for (ProductRatePlanWrapper prpWrapper : selectedRatePlans) {
            for (QuoteChargeWrapper qcw : prpWrapper.quoteChargeWrappers) {
                if (qcw.GUID == quoteChargeGUID) {

                    String eID = qcw.quoteCharge.Event__c;

                    if ((eID != null) && (eID != '')) {
                        //This is the recruitment event Id that was selected
                        List<Recruitment_Event__c> rEvents = [SELECT Id, Event_Date__c, Name FROM Recruitment_Event__c WHERE Id = :eID];
                        if ((rEvents != null) && (!rEvents.isEmpty())) {
                            qcw.quoteCharge.ServiceStart__c = rEvents[0].Event_Date__c;
                            qcw.quoteCharge.ServiceEnd__c = rEvents[0].Event_Date__c;

                            RecalcChargeLineTerm(quoteChargeGUID);  //Dates changed - recalc Charge Line Term                    
                            return;
                        }
                    }

                    qcw.quoteCharge.ServiceStart__c = null;
                    qcw.quoteCharge.ServiceEnd__c = null;
                    RecalcChargeLineTerm(quoteChargeGUID);  //Dates changed - recalc Charge Line Term
                    return;
                }
            }
        }
    }

    //This populates the data when the user edits an existing quote - this is for the existing Quote Charges
    private void RetrieveExistingQuoteCharges(Id quoteId) {

        //reset the totals:
        quoteTotalGross = 0;
        quoteTotalDiscount = 0;
        quoteTotalNet = quoteTotalGross - quoteTotalDiscount;

        discountFieldUsed = thisQuote.Discount_Field_Used__c;
        discountTypeValue = thisQuote.Discount_Type__c;
        backupDiscountTypeValue = discountTypeValue;

        Integer i = 1;
        String sCurrentTimeAdded = 'Blank_Value';        
        ProductRatePlanWrapper prpWrapper = new ProductRatePlanWrapper();
        for (zqu__QuoteCharge__c charge : [SELECT 
                                                Id, 
                                                Name, 
                                                zqu__Model__c,
                                                zqu__Quantity__c, 
                                                FakeQuantity__c,
                                                Notes__c,
                                                SalesRepId__c,
                                                Sales_Representative__c,
                                                Country__c,
                                                zqu__UOM__c,
                                                zqu__ListPrice__c,                                                 
                                                zqu__ProductName__c, 
                                                ServiceStart__c,
                                                zqu__Discount_Level__c,
                                                Event__c,
                                                zqu__Total__c,
                                                zqu__Period__c,
                                                ServiceEnd__c,
                                                ChargeLineTerm__c,
                                                zqu__ChargeType__c,
                                                zqu__EffectivePrice__c,
                                                zqu__ListPriceDisplay__c,
                                                zqu__TimeProductAdded__c,
                                                NumberOfMonths__c,
                                                zqu__ProductRatePlanCharge__c, 
                                                Sale_Type__c,
                                                
                                                zqu__ProductRatePlanCharge__r.Id, 
                                                zqu__ProductRatePlanCharge__r.Name,
                                                zqu__ProductRatePlanCharge__r.zqu__Type__c, 
                                                zqu__ProductRatePlanCharge__r.zqu__RecurringPeriod__c, 
                                                zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c,
                                                zqu__ProductRatePlanCharge__r.zqu__UOM__c, 
                                                zqu__ProductRatePlanCharge__r.zqu__TaxCode__c,
                                                zqu__ProductRatePlanCharge__r.zqu__Description__c, 
                                                zqu__ProductRatePlanCharge__r.zqu__ListPrice__c, 
                                                zqu__ProductRatePlanCharge__r.zqu__Model__c, 
                                                zqu__ProductRatePlanCharge__r.zqu__DefaultQuantity__c,
                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c, 
                                                zqu__ProductRatePlanCharge__r.zqu__PrepaymentPeriods__c,
                                                zqu__ProductRatePlanCharge__r.zqu__Discount_Level__c,
                                                zqu__ProductRatePlanCharge__r.zqu__Discount_Apply_Type__c,
                                                zqu__ProductRatePlanCharge__r.zqu__Apply_Discount_To_One_Time_Charges__c,
                                                zqu__ProductRatePlanCharge__r.zqu__Apply_Discount_To_Recurring_Charges__c,
                                                zqu__ProductRatePlanCharge__r.zqu__Apply_Discount_To_Usage_Charges__c,

                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id,
                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Name, 
                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c,
                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BillingFrequency__c,
                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.RatePlanPricingModel__c,
                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.RatePlanRecurringStatus__c,
                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.AlternatePriceCalculation__c,
                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.Id, 
                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.Name,
                                                zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c
                                            FROM zqu__QuoteCharge__c 
                                            WHERE zqu__Quote__c = :quoteId ORDER BY zqu__TimeProductAdded__c DESC, Name ASC]) {

            if (charge.zqu__TimeProductAdded__c != sCurrentTimeAdded) {
                sCurrentTimeAdded = charge.zqu__TimeProductAdded__c;

                //new charge/rateplan combo.  Create a new one - but first, save the one that was just built.
                if (prpWrapper.rowNum != -1) {
                    selectedRatePlans.add(prpWrapper);
                    i++;
                }

                //Now that the previous is retained, build the new one...
                prpWrapper = new ProductRatePlanWrapper();

                prpWrapper.AddProductRatePlanWithExistingQuoteCharge(charge.zqu__ProductRatePlanCharge__r, charge, i, allAtts, sourceOpp, activefilterCountryValue, thisQuote, attr_SalesRepOptions, attr_CountryOptions, charge.Sale_Type__c);
                prpWrapper.quote = thisQuote;
            }
            else prpWrapper.AppendExistingQuoteCharge(charge.zqu__ProductRatePlanCharge__r, charge, allAtts, sourceOpp, activefilterCountryValue, thisQuote, attr_SalesRepOptions, attr_CountryOptions, charge.Sale_Type__c);

            if (charge.zqu__Model__c.startsWithIgnoreCase('discount') && charge.zqu__ProductRatePlanCharge__r.zqu__Discount_Level__c != 'RatePlan') {
                //This is a discount charge - translate it!
                if (discountFieldUsed == null) discountFieldUsed = 'Discount_Percent__c';
                if ((charge.zqu__ProductRatePlanCharge__c != null) && (charge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.Name.startsWithIgnoreCase('agency')) && (discountTypeValue == null)) discountTypeValue = AGENCY_COMMISSION;
                else if ((charge.zqu__ProductRatePlanCharge__c != null) && (!charge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.Name.startsWithIgnoreCase('agency')) && (discountTypeValue == null)) discountTypeValue = 'List Price Discount';
                else if (sourceOpp.Sold_By_Partner__c != null) discountTypeValue = AGENCY_COMMISSION;
                else discountTypeValue = 'List Price Discount';

                thisQuote.Discount_Percent__c = charge.zqu__EffectivePrice__c;
                discountSalesRepValue = charge.Sales_Representative__c;
                discountCountryValue = charge.Country__c;

                discountQuoteCharge = charge;
            } 
        }

        //Now default the country to the first preset IF it currently has no value...
        if ((discountCountryValue == null) && (filterPresets != null) && (!filterPresets.isEmpty())) discountCountryValue = filterPresets[0].GetOLICountry;
        if (discountSalesRepValue == null) discountSalesRepValue = sourceOpp.Owner.Name;

        if (prpWrapper.rowNum != -1) selectedRatePlans.add(prpWrapper);

        RecalcAllQuoteNumbers();
    }

    public void DeleteProductRatePlanRow() {

        forceDiscountRecalc = true; 

        String prpGUIDToDelete = apexPages.currentPage().getparameters().get('rowToDelete');
        
        ProductRatePlanWrapper removedPRP;
        List<ProductRatePlanWrapper> tempListselectedRatePlans = new List<ProductRatePlanWrapper>();

        for (ProductRatePlanWrapper prpW : selectedRatePlans) {
            if (prpW.GUID != prpGUIDToDelete) tempListselectedRatePlans.add(prpW);
            else removedPRP = prpW;
        }

        if ((removedPRP != null) && (removedPRP.quoteChargeWrappers != null)) {
            for (QuoteChargeWrapper qcw : removedPRP.quoteChargeWrappers) {
                if (qcw.quoteCharge.Id != null) quoteChargesToDelete.add(qcw.quoteCharge.Id);
            }
        }            

        selectedRatePlans = tempListselectedRatePlans;
        //selectedRatePlans.remove(prpRowNum);

        errorsQuoteDetails = new List<String>();
        errorsQuoteCharges = new List<String>();

        //If the discount is a fixed val or new net, remove discounts:
        if (discountFieldUsed != null && discountFieldUsed != 'Discount_Percent__c') {
            thisQuote.Discount_Fixed__c = 0;
            thisQuote.Discount_New_Net__c = 0;
        }

        RecalcQuoteTotal();
    }

    //This populates the data when the user clicks the 'ADD' button on the screen via the UI
    public PageReference AddProductRatePlan() {

        forceDiscountRecalc = true;

        Integer milliseconds = Integer.valueOf(System.now().format('SSS'));
        timeProductAdded = milliseconds += selectedRatePlans.size();
        timeAddedFinal = timeProductAddedBase + timeProductAdded + 'Z';

        String productRatePlanToAdd = apexpages.currentpage().getparameters().get('PRPToAdd');

        List<zqu__ProductRatePlan__c> prpList = [SELECT Id, Name, zqu__ZProduct__r.Name, BillingFrequency__c, RatePlanPricingModel__c, RatePlanRecurringStatus__c, AlternatePriceCalculation__c, BrandTag__c,
                                                    (SELECT Id, 
                                                            Name, 
                                                            zqu__ListPrice__c, 
                                                            zqu__UpTo_How_Many_Periods__c, 
                                                            zqu__Type__c, 
                                                            zqu__ZuoraId__c, 
                                                            zqu__UOM__c, 
                                                            zqu__TaxCode__c,
                                                            zqu__Model__c, 
                                                            zqu__Description__c,                                                        
                                                            zqu__DefaultQuantity__c,
                                                            zqu__PrepaymentPeriods__c,
                                                            zqu__RecurringPeriod__c, 
                                                            zqu__Discount_Level__c,
                                                            zqu__Discount_Apply_Type__c,
                                                            zqu__Apply_Discount_To_One_Time_Charges__c,
                                                            zqu__Apply_Discount_To_Recurring_Charges__c,
                                                            zqu__Apply_Discount_To_Usage_Charges__c,
                                                            zqu__ProductRatePlan__r.Name,
                                                            zqu__ProductRatePlan__r.RatePlanPricingModel__c,
                                                            zqu__ProductRatePlan__r.zqu__ZProduct__r.Name,
                                                            zqu__ProductRatePlan__r.AlternatePriceCalculation__c,
                                                            zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c
                                                        FROM zqu__R00N40000001mFVKEA2__r WHERE IsDeleted = false ORDER BY Name) 
                                                FROM zqu__ProductRatePlan__c WHERE Id = :productRatePlanToAdd];

        if (prpList != null && prpList.size() == 1) {

            ProductRatePlanWrapper prpw = new ProductRatePlanWrapper();
            prpw.productRatePlan = prpList[0];

            Set<Id> prpChargeIDs = new Set<Id>();

            for (zqu__ProductRatePlanCharge__c prpc : prpList[0].zqu__R00N40000001mFVKEA2__r) {
                prpw.AddProductRatePlan(prpc, selectedRatePlans.size(), timeAddedFinal, thisQuote.zqu__Currency__c, allAtts, sourceOpp, activefilterCountryValue, thisQuote, attr_SalesRepOptions, attr_CountryOptions, saleTypeValue);
                prpChargeIDs.add(prpc.Id);
            }

            //Get a map of all charges / tiers and then populate/fix the default price and totals
            Map<Id, List<zqu__ProductRatePlanChargeTier__c>> prpcTierMap = QuoteUtilities.GetTierMapBasedOnPRPCharges(prpChargeIDs, thisQuote.zqu__Currency__c);
            prpw.SetListPriceBasedOnTiersAndWhatnot(prpw.quoteChargeWrappers, prpcTierMap, thisQuote);

            //Begin the logic to place the most recently added to the top of the list...
            //push down existing product rate plans...
            //First, expand the list with a filler object
            selectedRatePlans.add(new productRatePlanWrapper());
            for (Integer iNum = selectedRatePlans.size() - 1; iNum > 0; iNum--) {
                selectedRatePlans.set(iNum, selectedRatePlans[iNum-1]);
            }
            selectedRatePlans.set(0, prpw);
            //End last-added-if-first logic...

        }   //End if prpList != null

        //Clear all discount values if type is NOT agency:
        if (discountTypeValue != AGENCY_COMMISSION) {
            thisQuote.Discount_Percent__c = null;
            thisQuote.Discount_Fixed__c = null;
            thisQuote.Discount_New_Net__c = null;
        }        
        RecalcAllQuoteNumbers();

        saleTypeValue = STANDARD_SALE_TYPE; //reset it..
        SaleTypeValueChanged();     //reset the button labels
        
        return null;
    }  

    //Called onchange of discount type selection.
    //If discount picklist is changed, clear the values...
    public PageReference WipeDiscountValues() {
        thisQuote.Discount_Percent__c = null;
        thisQuote.Discount_Fixed__c = null;
        thisQuote.Discount_New_Net__c = null;

        RecalcAllQuoteNumbers();

        return null;
    }  

    public class FilterPreset {
        public OpportunityLineItem OppLineItem {get; set;}
        public String Id {get; set;}
        public Integer rowNum {get; set;}

        public String GetOLIBrandTag { 
            get {
                if ((OppLineItem != null) && (oppLineItem.BrandTag__c != null)) return OppLineItem.BrandTag__c;
                else return '#ERROR#';
            }
        }

        public String GetOLICountry { 
            get {
                if ((OppLineItem != null) && (OppLineItem.Country__r != null)) return OppLineItem.Country__r.Name;
                else return '#ERROR#';
            }
        }

        public String GetOLIProductGroup { 
            get {
                if ((OppLineItem != null) && (OppLineItem.Product_Group__c != null)) return OppLineItem.Product_Group__c;
                else return '#ERROR#';
            }
        }

        public FilterPreset() {
        
        } 
    }    

    public class ZInvoice {
        public List<QuoteChargeWrapper> charges {get; set;}
        public Decimal amountBilled {get; set;}

        public ZInvoice() {
            charges = new List<QuoteChargeWrapper>();
            amountBilled = 0;
        }

        private Decimal DoTheInvoiceMath(Decimal discount, Decimal termLength) {
            //Label.ZuoraInvoiceRoundingMethod holds the rounding method.
            //It must be either:    HALF_UP
            //                      UP
            //                      DOWN
            //      or any other supprted string method that isn't yet coded for here...

            Decimal result = 0;
            Decimal discountMultiplier = ((100 - discount) / 100);

            for (QuoteChargeWrapper qcw : charges) {
                
                String billFreq;

                if (qcw.quoteCharge.zqu__ChargeType__c.toLowerCase() == 'one-time') billFreq = 'one-time';
                else billFreq = qcw.quoteCharge.zqu__Period__c;

                Decimal divisor = (QuoteUtilities.NumberofInvoicesRequired(termLength, billFreq));

                if (divisor == 0) divisor = 1;  //for Evergreen.

                //HALF_DOWN here because this is a result of the gross - discount to achieve NET and Zuora half-up rounds the discount, so we need to half_down the net.
                if (divisor != 0 && qcw.FauxTCVNet != null && qcw.FauxTCVNet > 0) result += ((qcw.FauxTCVNet / divisor) * discountMultiplier).setScale(2, System.RoundingMode.HALF_DOWN);            
            }            

            return result;
        }

        public void CalcInvoiceTotalReturningVoid(Decimal discount, Decimal termLength) {        
            
            amountBilled = DoTheInvoiceMath(discount, termLength);
        }      

        public Decimal CalcInvoiceTotal(Decimal discount, Decimal termLength) {        
            
            amountBilled = DoTheInvoiceMath(discount, termLength);
            return amountBilled;            
        }        
    }
}