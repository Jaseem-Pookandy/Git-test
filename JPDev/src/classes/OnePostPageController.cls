public class OnePostPageController {

    public One_Post_Order__c NewOrder {get; set;}
    public List<Agency_Agreement__c> agreements {get; set;}
    public List<zqu__ProductratePlan__c> products {get; set;}            //displayed on the datatable on the page
    // public List<zqu__ProductratePlanCharge__c> charges {get; set;}
    public List<Account_Brand__c> accountbrands{get; set;}
    public List<String> validationErrors {get; set;}
    public String billingacctdet{get; set;}
    public String BillingAccountId{get; set;}
    public String BillingAccountNumber{get; set;}
    public String partnerID {get; set;}
    public String theBrand {get; set;}
    public Decimal theDiscount {get; set;}
    public Decimal theListPrice {get; set;}
    public Decimal theNetPrice {get; set;}
    public Decimal totalDiscountAmt {get; set;}
    public Decimal totalList {get; set;}
    public Decimal totalNet {get; set;}
    public Boolean fromBrandTag {get; set;}
    public String matchingBrand {get; set;}

    public Id selectedRatePlanId {get; set;}
    public List<SelectOption> availableProducts {get; set;}
        
    public Opportunity theOppty {get; set;}
    public zqu__Quote__c theQuote {get; set;}
    public zqu__QuoteCharge__c theQuoteCharge {get; set;}
    public zqu__QuoteCharge__c theDiscountCharge {get; set;}
    public List<zqu__QuoteCharge__c> QuoteCharges {get; set;}
        
    public Id BrandId {get; set;}
    public Id ClientOwnerId {get; set;}
    public String ClientOwnerName {get; set;}
    public String ClientAccountName {get; set;}
    public String RatePlanName {get; set;}
    public String ChargeName {get; set;} 
    public String ChargeType {get; set;}   
    public String ChargeLevel {get; set;}
    public String ChargeModel {get; set;}
    public String ChargeRecurringPeriod {get; set;}
    public String ChargeZuoraID {get; set;}
    public String ChargeUOM {get; set;}
    public String RatePlanChargeID {get; set;}
    public String ProductName {get; set;}    
    
    public String DiscountRatePlanName {get; set;}
    public String DiscountChargeName {get; set;}
    public String DiscountChargeType {get; set;}   
    public String DiscountChargeLevel {get; set;}
    public String DiscountChargeModel {get; set;}
    public String DiscountChargeZuoraID {get; set;}
    public String DiscountRatePlanChargeID {get; set;}
    public String DiscountProductName {get; set;}
    public Decimal DiscountPercent {get; set;}
    public String OpptyName {get; set;}
    public String PrimaryBrand {get; set;}
    public String ChannelPartnerName {get; set;} 
     
    private String accountID {get; set;}
    private Account currentAcct {get; set;}
    private PageReference pgReturnPage {get; set;}
    private Id CountryID {get; set;}

    private Id AccountBrandId {get; set;}
    private Contact theContact {get; set;}    
    private Map<Id, zqu__ProductRatePlan__c> ratePlanMap {get; set;}
        
    public OnePostPageController(ApexPages.StandardController controller) {
 
        validationErrors = new List<String>();
        availableProducts = new List<SelectOption>();
        ratePlanMap = new Map<Id, zqu__ProductratePlan__c>();
        selectedRatePlanId = null;        
        PrepPageForNew();
    }

    private void PrepPageForNew(){

        String retURL = ApexPages.currentPage().getParameters().get('retURL');
        if (retURL != null) pgReturnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
        else pgReturnPage = new PageReference('/home');

        NewOrder = new One_Post_Order__c();   

        agreements = new List<Agency_Agreement__c>();        
        products = new List<zqu__ProductRatePlan__c>();
        // charges = new List<zqu__ProductRatePlanCharge__c>();
        
        //initialize all the values
        theDiscount=0;
        theListPrice=0;
        theNetPrice=0;
        totalDiscountAmt=0;
        totalList=0;
        totalNet=0;
        
        //set the accountID if we came from the Account page...
        accountID = ApexPages.currentPage().getParameters().get('accid');
        
        if ((accountID != null) && (accountID != '')) {
            NewOrder.Account__c = accountID;
            currentAcct = [SELECT Name, Phone, BILLINGSTREET, BILLINGCITY, BILLINGSTATE, BILLINGPOSTALCODE, BILLINGCOUNTRY FROM Account WHERE Id = :accountID];
            NewOrder.Country__c = [SELECT Id from pw_ccpro__CountryObject__c WHERE Name = :currentAcct.BILLINGCOUNTRY LIMIT 1].Id;
        } 
    }
    
    public PageReference ProductSelected() {

        //the selected product Id is now stored here:  selectedRatePlanId
        
        //find the Discount 
        for (zqu__ProductRatePlan__c prpd : [SELECT 
                                                Name, 
                                                Id, 
                                                zqu__EffectiveEndDate__c, 
                                                zqu__EffectiveStartDate__c, 
                                                BrandTag__c,
                                                (SELECT   
                                                        Id, 
                                                        Name, 
                                                        zqu__Description__c, 
                                                        zqu__ListPrice__c, 
                                                        zqu__Model__c, 
                                                        zqu__RecurringPeriod__c, 
                                                        zqu__DefaultQuantity__c,                                                                
                                                        zqu__Type__c, 
                                                        zqu__UOM__c, 
                                                        zqu__ZuoraId__c, 
                                                        zqu__Discount_Level__c

                                                FROM zqu__R00N40000001mFVKEA2__r 
                                                WHERE CurrencyIsoCode = :NewOrder.CurrencyISOCode 
                                                    AND zqu__Deleted__c = false
                                                )
                                            FROM zqu__ProductRatePlan__c 
                                            WHERE Name LIKE '%Agency Commission%' 
                                                AND BrandTag__c = :theBrand 
                                                AND CurrencyIsoCode = :NewOrder.CurrencyISOCode 
                                                AND RatePlanPricingModel__c = 'Custom Pricing' 
                                                AND RatePlanRecurringStatus__c = 'One-Time' 
                                                AND zqu__Deleted__c = false 
                                                AND zqu__EffectiveEndDate__c >= today 
                                                AND zqu__EffectiveStartDate__c <= today
                                            ORDER BY zqu__EffectiveStartDate__c DESC LIMIT 1]) {

            DiscountRatePlanName = prpd.Name;
            products.add(prpd);

            for (zqu__ProductRatePlanCharge__c prpcd : prpd.zqu__R00N40000001mFVKEA2__r) {

                DiscountChargeName = prpcd.Name;
                DiscountRatePlanChargeID = prpcd.Id;
                DiscountProductName = prpcd.zqu__Description__c;
                DiscountChargeLevel = prpcd.zqu__Discount_Level__c;
                DiscountChargeModel = prpcd.zqu__Model__c;
                DiscountChargeType = prpcd.zqu__Type__c;
                DiscountChargeZuoraID = prpcd.zqu__ZuoraId__c;
                // charges.add(prpcd);
            }          
        }

        //We have retrieved the discount - now find (via the already populated map) the correct rate plan to use:

        if (selectedRatePlanId != null && ratePlanMap.containsKey(selectedRatePlanId) && !ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r.isEmpty()) {

            products.add(ratePlanMap.get(selectedRatePlanId));

            ChargeName              = ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r[0].Name;
            RatePlanChargeID        = ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r[0].Id;
            ProductName             = ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r[0].zqu__Description__c;
            ChargeLevel             = ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r[0].zqu__Discount_Level__c;
            ChargeModel             = ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r[0].zqu__Model__c;
            ChargeRecurringPeriod   = ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r[0].zqu__RecurringPeriod__c;
            ChargeType              = ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r[0].zqu__Type__c;
            ChargeZuoraID           = ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r[0].zqu__ZuoraId__c;
            theListPrice            = ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r[0].zqu__ListPrice__c;
            ChargeUOM               = ratePlanMap.get(selectedRatePlanId).zqu__R00N40000001mFVKEA2__r[0].zqu__UOM__c;
            RatePlanName            = ratePlanMap.get(selectedRatePlanId).Name;
        }

        if (theListPrice != null && theListPrice != 0 && NewOrder.Quantity__c != null && NewOrder.Quantity__c > 0 && theDiscount != null) {
            //now let's compute the total list, total discount and total net price for review.
            totalDiscountAmt = -((theListPrice * NewOrder.Quantity__c) * (theDiscount/100)).setScale(2, RoundingMode.HALF_UP);           
            totalList = (theListPrice * NewOrder.Quantity__c).setScale(2, RoundingMode.HALF_UP);
            totalNet = (totalList + totalDiscountAmt).setScale(2, RoundingMode.HALF_UP);
        }

        return null;
    }

    public PageReference RecalcData() {
    
        validationErrors = new List<String>();  //reset it
        agreements = new List<Agency_Agreement__c>();
        
        products = new List<zqu__ProductRatePlan__c>();
        // charges = new List<zqu__ProductRatePlanCharge__c>();

        totalDiscountAmt = 0;
        totalList = 0;
        totalNet = 0;

        theContact = new Contact();
        Account thePartner = new Account();        
        Set<Id> ratePlanIDs = new Set<Id>();
      
        theBrand = NewOrder.BrandTag__c;

        if (theBrand == null || theBrand == '') return null;

        //Translate BrandTag into Brand for Agency Agreement matching.
        //This *NEEDS* to be scaled properly.  There *should* be a BrandTag object
        //underneath the 'Brand' object in Salesforce, but that doesn't exist (yet).

        if (theBrand.equalsIgnoreCase('Dice')) matchingBrand = 'Dice';
        else if (theBrand.startsWithIgnoreCase('efc')) matchingBrand = 'eFinancialCareers';
        else if (theBrand.startsWithIgnoreCase('rz')) matchingBrand = 'Rigzone';
        else if (theBrand.startsWithIgnoreCase('clearance')) matchingBrand = 'ClearanceJobs';
        
        if (matchingBrand == null || matchingBrand == '') return null;

        if (NewOrder.Contact__c != null) {
            theContact = [SELECT Id, Name, FirstName, LastName, Language__c, AccountId, MailingStreet, MailingCity, MailingCountry, MailingState, MailingPostalCode, Email, Phone, Account.Channel_Partner__c
                            FROM Contact WHERE Id = :NewOrder.Contact__c];
            NewOrder.Contact__r = theContact;
            partnerID = theContact.AccountId;
            thePartner = [Select Id, Name FROM Account WHERE Id = :partnerID];
            ChannelPartnerName = thePartner.Name;
            for (Agency_Agreement__c aaa : [select Name,Id,Account__c,Brand_Name__c,Country__c,Discount_Percent__c,End_Date__c,Region__c,Start_Date__c,Status__c from Agency_Agreement__c where Account__c = :partnerID AND Brand_Name__c = :matchingBrand AND Status__c = 'Active' order by Start_Date__c]) {
                theDiscount = aaa.Discount_Percent__c;
                agreements.add(aaa);
                break;
            } 
        } 

        if (matchingBrand == null || matchingBrand == '' || NewOrder.CurrencyIsoCode == null || NewOrder.CurrencyIsoCode == '') return null;

        else {
            //find the Account Brand
            for (Account_Brand__c ab : [SELECT Id, Brand__c, Primary_Owner__c, Primary_Owner__r.Name FROM Account_Brand__c WHERE Account__c = :NewOrder.Account__c AND Brand_Name__c = :matchingBrand LIMIT 1]) {
                AccountBrandId = ab.Id;
                ClientOwnerId = ab.Primary_Owner__c;
                ClientOwnerName = ab.Primary_Owner__r.Name;
                BrandId = ab.Brand__c;
            }
            
            //populate the picklist options for available one-post products:
            availableProducts = new List<SelectOption>();
            availableProducts.add(new SelectOption('', '--None--'));

            Integer chargeCount = 0;
            Double runningTotal = 0.0;

            ratePlanMap = new Map<Id, zqu__ProductratePlan__c>();

            for (zqu__ProductRatePlan__c prp : [SELECT  Name, 
                                                        Id, 
                                                        zqu__EffectiveEndDate__c, 
                                                        zqu__EffectiveStartDate__c, 
                                                        BrandTag__c,
                                                        (SELECT   Id, 
                                                                Name, 
                                                                zqu__Description__c, 
                                                                zqu__ListPrice__c, 
                                                                zqu__Model__c, 
                                                                zqu__RecurringPeriod__c, 
                                                                zqu__DefaultQuantity__c,                                                                
                                                                zqu__Type__c, 
                                                                zqu__UOM__c, 
                                                                zqu__ZuoraId__c, 
                                                                zqu__Discount_Level__c

                                                            FROM zqu__R00N40000001mFVKEA2__r 
                                                            WHERE CurrencyIsoCode = :NewOrder.CurrencyISOCode 
                                                                AND zqu__Deleted__c = false
                                                        )
                                                FROM zqu__ProductRatePlan__c 
                                                    WHERE Auto_Creation_Process__c = 'OnePost' 
                                                        AND BrandTag__c = :theBrand 
                                                        AND CurrencyIsoCode = :NewOrder.CurrencyISOCode 
                                                        AND zqu__Deleted__c = false 
                                                        AND zqu__EffectiveEndDate__c >= today 
                                                        AND zqu__EffectiveStartDate__c <= today
                                                    ORDER BY Name ASC]) {

                ratePlanMap.put(prp.Id, prp);

                chargeCount = 0;
                runningTotal = 0.0;

                for (zqu__ProductratePlanCharge__c prpc : prp.zqu__R00N40000001mFVKEA2__r) {
                    if (prpc.zqu__DefaultQuantity__c != null && prpc.zqu__ListPrice__c != null) {
                        runningTotal += (prpc.zqu__DefaultQuantity__c * prpc.zqu__ListPrice__c).setScale(2, RoundingMode.HALF_UP);
                        chargeCount++;
                    }
                }

                if (chargeCount == 1) availableProducts.add(new SelectOption(prp.Id, prp.Name + ' : Contains ' + chargeCount + ' charge totaling ' + runningTotal));
                else availableProducts.add(new SelectOption(prp.Id, prp.Name + ' : Contains ' + chargeCount + ' charges totaling ' + runningTotal));
            }
            
            if (selectedRatePlanId != null && !fromBrandTag) ProductSelected();

        }

        fromBrandTag = false;
            
        return null;
    }
    
    private Boolean PageIsValid() {

        validationErrors = new List<String>();

        if (NewOrder.Account__c == null) validationErrors.add('Account is required.');
        if (NewOrder.Opportunity_Owner__c == null) validationErrors.add('Opportunity Owner is required.');        
        if (NewOrder.CurrencyISOCode == null) validationErrors.add('Currency is required.');
        if (NewOrder.PaymentTerm__c == null) validationErrors.add('Payment Term is required.');
        if (NewOrder.Country__c == null) validationErrors.add('Country is required.');
        if (NewOrder.PaymentMethod__c == null) validationErrors.add('Payment Method is required.');
        if (NewOrder.Quantity__c == null) validationErrors.add('Quantity is required.');        
        if (NewOrder.BrandTag__c == null) validationErrors.add('Primary Brand is required.');
        
                
        if (NewOrder.Contact__c == null) validationErrors.add('Contact is required.');

        if (NewOrder.BrandTag__c != null && AccountBrandId == null) validationErrors.add('Unable to locate the applicable Account Brand record.  Unable to proceed.');
        if (NewOrder.BrandTag__c != null && AccountBrandId != null && ClientOwnerId == null) validationErrors.add('The derived Account Brand record (' + AccountBrandId + ') is missing the Primary Owner.  This must be populated before proceeding.');

        if (NewOrder.BrandTag__c != null && selectedRatePlanId == null) validationErrors.add('No products have been found to match.  Unable to proceed.');

        if (agreements.isEmpty()) validationErrors.add('No Agency Agreement has been found.  Unable to proceed.');

        if (validationErrors.isEmpty()) return true;
        return false;
    }
    
    public PageReference SaveItAll() {

        if (PageIsValid()) {

            //Get the data necessary now
            if (NewOrder.Opportunity_Owner__c != null) NewOrder.Opportunity_Owner__r = [SELECT Id, Name FROM User WHERE Id = :NewOrder.Opportunity_Owner__c];            

            if (NewOrder.Country__c != null)  NewOrder.Country__r = [SELECT Id, Name FROM pw_ccpro__CountryObject__c WHERE Id = :NewOrder.Country__c];            

            Datetime thisNow = System.now();
            String timeProductAddedBase = thisNow.format('yyyyMMdd') + 'T' + thisNow.format('HHmmss');
            Integer milliseconds = Integer.valueOf(System.now().format('SSS'));
            Integer timeProductAdded1 = milliseconds + 1;
            Integer timeProductAdded2 = milliseconds + 2;
            String timeAddedFinal1 = timeProductAddedBase + timeProductAdded1 + 'Z';
            String timeAddedFinal2 = timeProductAddedBase + timeProductAdded2 + 'Z';
            
            //Determine the SED based on the purchase date
            date SED = NewOrder.Purchase_Date__c.addMonths(1).addDays(-1);
            
            //Billing Account Service
            RESTZuoraOperationPlugIn.ReturnClass returnClass = GetBillingAccount(NewOrder, theContact, ClientOwnerName );
            billingacctdet = returnClass.message;
            BillingAccountId = returnClass.billingAccountId;
            BillingAccountNumber = returnClass.billingAccountNumber;
            //system.debug('$$$$$$$$$$' + returnClass.message);  
            
            //One Post Orders are not persisted.
            //insert newOrder;

            //Create an Opportunity
            theOppty = new Opportunity();
            theOppty.AccountId = NewOrder.Account__c;
            theOppty.Account_Brand__c = AccountBrandId;            
            theOppty.Bypass_State_Model_Workflows__c = true;
            theOppty.CloseDate = NewOrder.Purchase_Date__c;
            theOppty.Contact__c = NewOrder.Contact__c;
            theOppty.CurrencyIsoCode = NewOrder.CurrencyIsoCode;
            theOppty.IO_Number__c = NewOrder.IO_Number__c;
            theOppty.Name = 'One Post_' + OpptyNameDatePart(NewOrder.Purchase_Date__c)+ '_' + currentAcct.Name + '_' + ChannelPartnerName;
            //theOppty.One_Post_Order__c = NewOrder.Id;

            theOppty.Primary_Brand__c = matchingBrand;

            if (theBrand.startsWithIgnoreCase('clearance')) theOppty.BrandTag__c = 'Dice';
            else theOppty.BrandTag__c = theBrand;

            theOppty.Opportunity_Notes__c = NewOrder.Notes__c;
            theOppty.OwnerId = NewOrder.Opportunity_Owner__c;
            theOppty.Provisioning_Completed_Date__c = Datetime.now();
            theOppty.Provisioning_Owner__c = UserInfo.getUserId();
            theOppty.Provisioning_Start_Date__c = Datetime.now();
            theOppty.Renewal_Feedback__c = 'Declined - One Post';
            theOppty.Renewal_Owner_Assigned__c = NewOrder.Opportunity_Owner__c;
            theOppty.Sold_By_Partner__c = PartnerID;
            theOppty.Agency_Agreement__c = agreements[0].Id;
            theOppty.StageName = 'Qualified Need';
            theOppty.Approval_Source__c = 'Email';
            theOppty.hasConfirmed_Owner_Assignments__c = true;
            insert theOppty;
                
            //Let's create the quote
            theQuote = new zqu__Quote__c();
            theQuote.Billing_Account_Selection_Response__c = returnClass.MatchType;
            theQuote.Billing_Frequency__c = 'One-Time';
            theQuote.BrandTag__c = theBrand;
            theQuote.CurrencyIsoCode = NewOrder.CurrencyIsoCode;
            theQuote.Deferred_Bill_Date__c = NewOrder.Purchase_Date__c;
            theQuote.Discount__c = theDiscount;
            theQuote.First_Bill_Amount__c = ((theListPrice * newOrder.Quantity__c) * (1 - (theDiscount/100)));
            theQuote.IS_Verified__c = false;
            if (theOppty.Name.length() >= 80) theQuote.Name = theOppty.Name.substring(0,79);
            else theQuote.Name = theOppty.Name;
            theQuote.OwnerId = NewOrder.Opportunity_Owner__c;
            theQuote.Service_End_Date__c = SED;
            theQuote.zqu__BillToContact__c = NewOrder.Contact__c;
            theQuote.zqu__BillingMethod__c = 'Print';
            theQuote.zqu__Currency__c = NewOrder.CurrencyIsoCode;
            theQuote.zqu__InitialTerm__c = 1;
            theQuote.zqu__Is_Charge_Expired__c = false;
            theQuote.zqu__Opportunity__c = theOppty.Id;
            theQuote.zqu__PaymentMethod__c = NewOrder.PaymentMethod__c;
            theQuote.zqu__PaymentTerm__c = NewOrder.PaymentTerm__c;
            theQuote.zqu__Previewed_Discount__c = -((theListPrice * NewOrder.Quantity__c) * (theDiscount/100));
            theQuote.zqu__RenewalTerm__c = 0;
            theQuote.zqu__SoldToContact__c = NewOrder.Contact__c;
            theQuote.zqu__StartDate__c = NewOrder.Purchase_Date__c;
            theQuote.zqu__ValidUntil__c = NewOrder.Purchase_Date__c;
            theQuote.zqu__Status__c = 'New';
            theQuote.zqu__ZuoraAccountID__c = BillingAccountId;
            insert theQuote;                    

            //setup the discount Quote Charge
            QuoteCharges = new List<zqu__QuoteCharge__c>();
            
            theDiscountCharge = new zqu__QuoteCharge__c();
            theDiscountCharge.ChargeLineTerm__c = 1;
            theDiscountCharge.Country__c = NewOrder.Country__r.Name;
            theDiscountCharge.CurrencyIsoCode = NewOrder.CurrencyIsoCode;
            theDiscountCharge.Name = DiscountChargeName;
            theDiscountCharge.Sale_Type__c = 'Standard';
            theDiscountCharge.salesRepId__c = NewOrder.Opportunity_Owner__c;
            theDiscountCharge.Sales_Representative__c = NewOrder.Opportunity_Owner__r.Name;
            theDiscountCharge.ServiceEnd__c = SED;
            theDiscountCharge.ServiceStart__c = NewOrder.Purchase_Date__c;
            theDiscountCharge.zqu__Apply_Discount_To_One_Time_Charges__c = true;
            theDiscountCharge.zqu__Apply_Discount_To_Recurring_Charges__c = true;
            theDiscountCharge.zqu__Apply_Discount_To_Usage_Charges__c = true;
            theDiscountCharge.zqu__ChargeType__c = DiscountChargeType;

            theDiscountCharge.zqu__Currency__c = NewOrder.CurrencyIsoCode;
            theDiscountCharge.zqu__Discount_Level__c = DiscountChargeLevel;
            theDiscountCharge.zqu__EffectivePrice__c = theDiscount;
            theDiscountCharge.zqu__ListTotal__c = 0;
            theDiscountCharge.zqu__MRRForRollup__c = 0;
            theDiscountCharge.zqu__Model__c = DiscountChargeModel;
            theDiscountCharge.zqu__PeriodNumeric__c = 12;
            theDiscountCharge.zqu__Period__c = 'Annual';
            theDiscountCharge.zqu__ProductName__c = DiscountChargeName;
            theDiscountCharge.zqu__ProductRatePlanCharge__c = DiscountRatePlanChargeID;
            theDiscountCharge.zqu__ProductRatePlanName__c = DiscountRatePlanName;
            theDiscountCharge.zqu__Quote__c = theQuote.Id;
            theDiscountCharge.zqu__RatePlanCharge_ZuoraID__c = DiscountChargeZuoraID;
            theDiscountCharge.zqu__TCVForRollup__c = 0;
            theDiscountCharge.zqu__TimeProductAdded__c = timeAddedFinal1;
            
            QuoteCharges.add(theDiscountCharge);

            //Setup the One Post Quote Charge
            theQuoteCharge = new zqu__QuoteCharge__c();
            theQuoteCharge.ChargeLineTerm__c = 1;
            theQuoteCharge.Country__c = NewOrder.Country__r.Name;
            theQuoteCharge.CurrencyIsoCode = NewOrder.CurrencyIsoCode;
            theQuoteCharge.Name = ChargeName;
            theQuoteCharge.Sale_Type__c = 'Standard';
            theQuoteCharge.salesRepId__c = NewOrder.Opportunity_Owner__c;
            theQuoteCharge.Sales_Representative__c = NewOrder.Opportunity_Owner__r.Name;
            theQuoteCharge.ServiceEnd__c = SED;
            theQuoteCharge.ServiceStart__c = NewOrder.Purchase_Date__c;  
            theQuoteCharge.zqu__Currency__c = NewOrder.CurrencyIsoCode; 
            theQuoteCharge.zqu__Discount__c = 0;
            theQuoteCharge.zqu__ChargeType__c = ChargeType; 
            theQuoteCharge.zqu__EffectivePrice__c = theListPrice;
            theQuoteCharge.zqu__ListTotal__c = theListPrice * NewOrder.Quantity__c;
            theQuoteCharge.zqu__FeeType__c = 'Per Unit';
            theQuoteCharge.zqu__ListPriceDisplay__c = theListPrice;
            theQuoteCharge.zqu__MRRForRollup__c = theListPrice;
            theQuoteCharge.zqu__Model__c = ChargeModel;
            theQuoteCharge.zqu__PeriodNumeric__c = 0;
            theQuoteCharge.zqu__ProductName__c = ProductName;
            theQuoteCharge.zqu__ProductRatePlanCharge__c = RatePlanChargeID;
            theQuoteCharge.zqu__ProductRatePlanName__c = RatePlanName;
            theQuoteCharge.zqu__Quantity__c = NewOrder.Quantity__c;
            theQuoteCharge.zqu__RatePlanCharge_ZuoraID__c = ChargeZuoraID;
            theQuoteCharge.zqu__UOM__c = ChargeUOM;
            theQuoteCharge.zqu__Total__c = theListPrice * NewOrder.Quantity__c;
            theQuoteCharge.zqu__Period__c = ChargeRecurringPeriod;
            theQuoteCharge.zqu__Quote__c = theQuote.Id;
            theQuoteCharge.zqu__TimeProductAdded__c = timeAddedFinal2;
            
            QuoteCharges.add(theQuoteCharge);
            insert QuoteCharges;
            
            //now Close/Won the Opportunity to run all trigger code
            theOppty.StageName = 'Closed Won';
            theOppty.Provisioning_Status__c = 'Provisioned';
            update theOppty;
            
            //If everything is ok, then the One Post Order can be deleted
            //delete NewOrder;
            
            PageReference newOrderPage = new PageReference('/' + NewOrder.Account__c);
            newOrderPage.setRedirect(true);

            return newOrderPage;
        }  
        return null;
    }
    
    private String OpptyNameDatePart(Date theDate) {
        
        Integer month = theDate.month();
        Integer year = theDate.year();
        String retval = '';
        
        if (month == 1) retval = string.valueof(year) + '_JAN';
        else if (month == 2) retval = string.valueof(year) + '_FEB';
        else if (month == 3) retval = string.valueof(year) + '_MAR';
        else if (month == 4) retval = string.valueof(year) + '_APR';
        else if (month == 5) retval = string.valueof(year) + '_MAY';
        else if (month == 6) retval = string.valueof(year) + '_JUN';
        else if (month == 7) retval = string.valueof(year) + '_JUL';
        else if (month == 8) retval = string.valueof(year) + '_AUG';
        else if (month == 9) retval = string.valueof(year) + '_SEP';
        else if (month == 10) retval = string.valueof(year) + '_OCT';
        else if (month == 11) retval = string.valueof(year) + '_NOV';
        else if (month == 12) retval = string.valueof(year) + '_DEC';
        
        return retval;
    }
    
    public static RESTZuoraOperationPlugIn.ReturnClass GetBillingAccount(One_Post_Order__c order, Contact billingContact, String RepName) {
        Map<String, String> requestParameterMap = new Map<String, String>();
        
        requestParameterMap.put('Operation', 'CreateBillingAccount');
        requestParameterMap.put('BillToAddress', billingContact.MailingStreet);
        requestParameterMap.put('BillToCity', billingContact.MailingCity);
        requestParameterMap.put('BillToCountry', billingContact.MailingCountry);            
        requestParameterMap.put('BillToFirstName', billingContact.FirstName);
        requestParameterMap.put('BillToLastName', billingContact.LastName);
        requestParameterMap.put('BillToPostalCode', billingContact.MailingPostalCode);
        requestParameterMap.put('BillToState', billingContact.MailingState);
        requestParameterMap.put('BillToWorkEmail', billingContact.Email);
        requestParameterMap.put('BillToWorkPhone', billingContact.Phone);
        requestParameterMap.put('BrandTag', order.BrandTag__c);
        requestParameterMap.put('CRMAccountId', order.Account__c);
        requestParameterMap.put('IsoCurrency', order.CurrencyIsoCode);
        requestParameterMap.put('PaymentMethod', order.PaymentMethod__c);
        requestParameterMap.put('SoldToAddress', billingContact.MailingStreet);
        requestParameterMap.put('SoldToCity', billingContact.MailingCity);
        requestParameterMap.put('SoldToCountry', billingContact.MailingCountry);
        requestParameterMap.put('SoldToFirstName', billingContact.FirstName);
        requestParameterMap.put('SoldToLastName', billingContact.LastName);
        requestParameterMap.put('SoldToPostalCode', billingContact.MailingPostalCode);
        requestParameterMap.put('SoldToState', billingContact.MailingState);
        requestParameterMap.put('SoldToWorkEmail', billingContact.Email);
        requestParameterMap.put('SoldToWorkPhone', billingContact.Phone);
        requestParameterMap.put('ContextLanguage', billingContact.Language__c);     //sold to language            
        requestParameterMap.put('PaymentTerm', order.PaymentTerm__c);
        requestParameterMap.put('InvoiceTemplateName', '');
        requestParameterMap.put('InvoiceDeliveryPref', 'Print');
        requestParameterMap.put('SalesRepName', RepName );
            
        //system.debug('$$$$$$$$$$' + requestParameterMap);          
        RESTZuoraOperationPlugIn.ReturnClass result = RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap); 
        return result;    
    }
}