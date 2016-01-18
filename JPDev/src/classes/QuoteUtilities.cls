/***************************************************************************
// Description    : Static, common utlity functions specific the Quote
//                  
// 2014.10.24     : Created as part of CPQ2, Sprint 2.
//                  This will most likely be extended come product selection time,
                    But right now it's a small class                    
//***************************************************************************/
public without sharing class QuoteUtilities {
    

    public QuoteUtilities() {
        //empty constructor
    }

    //Calls Godfrey's method to get/create the billing account.
    //Returns the Zuuora Id of the matching/created billing account.
    public static RESTZuoraOperationPlugIn.ReturnClass GetBillingAccount(zqu__Quote__c quote, Opportunity opp, String InvoiceTemplateName) {

        Set<Id> contactIds = new Set<Id>();
        contactIds.add(quote.zqu__SoldToContact__c);
        contactIds.add(quote.zqu__BillToContact__c);

        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, MailingCity, MailingCountry, MailingState, MailingStreet, MailingPostalCode, FirstName, LastName, Language__c, Email, Phone FROM Contact WHERE Id IN :contactIds LIMIT 2]);

        Contact soldToContact = new Contact();
        Contact billToContact = new Contact();

        if (contactMap.containsKey(quote.zqu__SoldToContact__c)) soldToContact = contactMap.get(quote.zqu__SoldToContact__c);
        if (contactMap.containsKey(quote.zqu__BillToContact__c)) billToContact = contactMap.get(quote.zqu__BillToContact__c);

        if (soldToContact.Id != null && billToContact.Id != null) {        
            Map<String, String> requestParameterMap = new Map<String, String>();
            requestParameterMap.put('Operation', 'CreateBillingAccount');
            requestParameterMap.put('BillToAddress', billToContact.MailingStreet);
            requestParameterMap.put('BillToCity', billToContact.MailingCity);
            requestParameterMap.put('BillToCountry', billToContact.MailingCountry);            
            requestParameterMap.put('BillToFirstName', billToContact.FirstName);
            requestParameterMap.put('BillToLastName', billToContact.LastName);
            requestParameterMap.put('BillToPostalCode', billToContact.MailingPostalCode);
            requestParameterMap.put('BillToState', billToContact.MailingState);
            requestParameterMap.put('BillToWorkEmail', billToContact.Email);
            requestParameterMap.put('BillToWorkPhone', billToContact.Phone);
            requestParameterMap.put('BrandTag', quote.BrandTag__c);
            if (opp != null) requestParameterMap.put('CRMAccountId', opp.AccountId);
            requestParameterMap.put('IsoCurrency', quote.zqu__Currency__c);
            requestParameterMap.put('PaymentMethod', quote.zqu__PaymentMethod__c);
            requestParameterMap.put('SoldToAddress', soldToContact.MailingStreet);
            requestParameterMap.put('SoldToCity', soldToContact.MailingCity);
            requestParameterMap.put('SoldToCountry', soldToContact.MailingCountry);
            requestParameterMap.put('SoldToFirstName', soldToContact.FirstName);
            requestParameterMap.put('SoldToLastName', soldToContact.LastName);
            requestParameterMap.put('SoldToPostalCode', soldToContact.MailingPostalCode);
            requestParameterMap.put('SoldToState', soldToContact.MailingState);
            requestParameterMap.put('SoldToWorkEmail', soldToContact.Email);
            requestParameterMap.put('SoldToWorkPhone', soldToContact.Phone);
            requestParameterMap.put('ContextLanguage', soldToContact.Language__c);     //sold to language            
            requestParameterMap.put('PaymentTerm', quote.zqu__PaymentTerm__c);
            if (InvoiceTemplateName != '') requestParameterMap.put('InvoiceTemplateName', InvoiceTemplateName);
            if (quote.zqu__BillingMethod__c != '') requestParameterMap.put('InvoiceDeliveryPref', quote.zqu__BillingMethod__c);
            if (opp!= null && opp.Owner != null)
            {
                requestParameterMap.put('SalesRepName', opp.Owner.Name);
                requestParameterMap.put('SalesRepDivision', opp.Owner.Division);
            } 
            if (opp!= null && opp.Account_Brand__r != null && opp.Account_Brand__r.CS__r != null) requestParameterMap.put('CustomerServiceRepName', opp.Account_Brand__r.CS__r.Name);
            
      
            RESTZuoraOperationPlugIn.ReturnClass result = RESTZuoraOperationPlugIn.ZuoraOperationHandler(requestParameterMap); 
            return result;
        }
        else return new RESTZuoraOperationPlugIn.ReturnClass('', '', 'false', 'FAILED', 'Contacts not populated from QuoteUtlities.cls');
    }


    //Returns true if the updatedQuote passed in had values changed that required the billing account to be recalculated.
    //So far this is only called from the ZuoraQuoteController.
    //This means, (obviously) that programmatic changes to quotes (either via workflows, triggers or data loads) will NOT EVER
    //recalculate the billing account and, according to the business & Andrews, this is okay.
    //This is a known, acceptable side-effect of programmatically creating/selecting a billing account (which must be done via a callout).
    //NOTE:  If a contact's address changes we don't care - well, yet, anyway...
    public static Boolean QuoteNeedsBillingAccountRecalculated(zqu__Quote__c originalQuote, zqu__Quote__c updatedQuote) {

        if (originalQuote == null) return true;                           
        if (updatedQuote == null) return false;

        //If the quote is NOT synching, do not do any billing account stuff...
        if (updatedQuote.IsSyncing__c == false) return false;

        //If the currency was changed via the 'Change Currency' button
        if (updatedQuote.Billing_Account_Selection_Response__c == Constants.QUOTE_CURRENCY_CHANGED) return true;

        //If the language of the sold to contact was edited
        if (updatedQuote.Billing_Account_Selection_Response__c == Constants.CONTACT_LANGUAGE_CHANGED) return true;

        //If the updated quote is now syncing where it wasn't before
        if ((originalQuote.IsSyncing__c != updatedQuote.IsSyncing__c) && (updatedQuote.IsSyncing__c == true)) return true;

        //If the invoice template is different
        if (originalQuote.InvoiceTemplateName__c != updatedQuote.InvoiceTemplateName__c) return true;

        //If the payment method changed
        if (originalQuote.zqu__PaymentMethod__c != updatedQuote.zqu__PaymentMethod__c) return true;

        //If either of the contacts changed
        if (originalQuote.zqu__SoldToContact__c != updatedQuote.zqu__SoldToContact__c) return true;       
        
        if (originalQuote.zqu__BillToContact__c != updatedQuote.zqu__BillToContact__c) return true;

        if (originalQuote.BrandTag__c != updatedQuote.BrandTag__c) return true;

        //If the payment term changed
        if (originalQuote.zqu__PaymentTerm__c != updatedQuote.zqu__PaymentTerm__c) return true;

        //If the invoice preferences change
        if (originalQuote.zqu__BillingMethod__c != updatedQuote.zqu__BillingMethod__c) return true;

        return false;
    }

    //This returns what the trigger will commit to the invoice template field on the Quote object.
    //Because this is needed prior to the actual database commit (for the Zuora Rest Billing Account selection)
    //This sub needs to exist and be called from the ZuoraQuoteController just prior to calling the webservice.
    public static String CalcQuotesInvoiceTemplateName(zqu__Quote__c originalQuote, zqu__Quote__c updatedQuote) {

        String templateId;
        Boolean calcId = false;
        String result = '';

        //If nothing changed, return the original value
        if ((originalQuote.zqu__Currency__c == updatedQuote.zqu__Currency__c) 
                && (originalQuote.BrandTag__c == updatedQuote.BrandTag__c) 
                && (originalQuote.zqu__SoldToContact__r == updatedQuote.zqu__SoldToContact__r) 
                && (originalQuote.InvoiceTemplateName__c == updatedQuote.InvoiceTemplateName__c)) templateId = updatedQuote.InvoiceTemplateName__c;

        //If something changed that WASN'T the Invoice Template Id...
        else if (((originalQuote.zqu__Currency__c != updatedQuote.zqu__Currency__c) || (originalQuote.BrandTag__c != updatedQuote.BrandTag__c) || (originalQuote.zqu__SoldToContact__r != updatedQuote.zqu__SoldToContact__r)) && (originalQuote.InvoiceTemplateName__c == updatedQuote.InvoiceTemplateName__c)) calcId = true;

        //Else if the InvoiceTemplate Id was changed manually by the user, use it.
        else if (originalQuote.InvoiceTemplateName__c != updatedQuote.InvoiceTemplateName__c) templateId = updatedQuote.InvoiceTemplateName__c;

        if (calcId) {
            Invoice_Template__c it = GetInvoiceTemplate(updatedQuote);
            if (it != null) result = it.Name;
        }
        else {
            //Get the name from the Id
            List<Invoice_Template__c> templates = [SELECT Id, Name FROM Invoice_Template__c WHERE Id = :templateId LIMIT 1];
            if ((templates != null) && (!templates.isEmpty())) result = templates[0].Name;
        }

        return result;
    }

    //This does NO comparisons of data changed, etc.
    //It simply returns the Invoice_Template__c object record that should be
    //matched to the Quote based on the fields and values in the Quote.
    //This is NOT bulkified and should never be called from triggers.
    public static Invoice_Template__c GetInvoiceTemplate(zqu__Quote__c quote) {

        Invoice_Template__c result = new Invoice_Template__c();
        String matchedId = '';

        String sSOQL = 'SELECT Id, Name, Invoice_Template_Id__c FROM Invoice_Template__c WHERE Name like \'' + quote.BrandTag__c + '%\'';
        List<Invoice_Template__c> invoiceTemplates = Database.query(sSOQL);

        //Map of Invoice Templates
        Map<String, String> mapInvoiceTemplates = new Map<String, String>();
        Map<String, Invoice_Template__c> mapInvoiceTemplatesbyId = new Map<String, Invoice_Template__c>();
        
        for (Invoice_Template__c invoiceTemplate : invoiceTemplates) {
            mapInvoiceTemplates.put(invoiceTemplate.Name.toUpperCase(), invoiceTemplate.Id);
            mapInvoiceTemplatesbyId.put(invoiceTemplate.Id, invoiceTemplate);
        }

        List<pw_ccpro__CountryObject__c> countries = [SELECT Id, Name, Sub_Region1__c, Region_Energy__c FROM pw_ccpro__CountryObject__c ];

        Map<Id, Contact> mapContacts = new Map<Id, Contact>([
            SELECT Id, pw_ccpro__MailingCountryLookup__r.Sub_Region1__c, pw_ccpro__MailingCountryLookup__r.Region_Energy__c, Language__c
            FROM Contact
            Where Id = :quote.zqu__SoldToContact__c
        ]);

        if (((quote.zqu__SoldToContact__c != null) && (quote.BrandTag__c.startsWithIgnoreCase('efc')) && (mapContacts.get(quote.zqu__SoldToContact__c).pw_ccpro__MailingCountryLookup__c != null) && (mapContacts.get(quote.zqu__SoldToContact__c).pw_ccpro__MailingCountryLookup__r.Sub_Region1__c == 'Middle East')))     quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(('eFC-MiddleEast_'               + (String)mapContacts.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());
        else if ((quote.BrandTag__c.equalsIgnoreCase('rigzone')) && (mapContacts.get(quote.zqu__SoldToContact__c).pw_ccpro__MailingCountryLookup__r.Region_Energy__c != 'AMERICAS'))                                                                                                                                        quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(('Rigzone-ROW_'                  + (String)mapContacts.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());
        else if (mapInvoiceTemplates.get(((String)quote.BrandTag__c + '_' + (String)mapContacts.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase()) != null)                                                                                                                quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(((String)quote.BrandTag__c + '_' + (String)mapContacts.get(quote.zqu__SoldToContact__c).Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());

        if (matchedId != '') result = mapInvoiceTemplatesbyId.get(matchedId);

        return result;
    }

    public static QCAttributeLogic CalcQuoteChargeRendering(zqu__ProductRatePlan__c prp, String attribute, zqu__ProductRatePlanCharge__c prpc, Boolean isEvergreen) {

        //The constructor looks like this, so visible is first, editable is second.
        //public QCAttributeLogic(Boolean vis, Boolean edit)

        //Notes is always visible and always editable.
        if (attribute == 'Notes__c') return new QCAttributeLogic(true, true);

        //Country is always visible and always editable.
        if (attribute == 'Country__c') return new QCAttributeLogic(true, true);
        
        //Quantity - for NORMAL pricing calculations
        if ((attribute == 'FakeQuantity__c') && (prp.AlternatePriceCalculation__c == null || (prp.AlternatePriceCalculation__c != 'Monthly List Price' && prp.AlternatePriceCalculation__c != 'Monthly Per Unit List Price'))) {

            //If this product rate plan charge is a discount, don't show Quantity.
            if (prpc.zqu__Model__c.containsIgnoreCase('discount')) return new QCAttributeLogic(false, false);

            if (prpc.zqu__Model__c.startsWith('Flat Fee')) return new QCAttributeLogic(false, false);
            else return new QCAttributeLogic(true, true);  

        } 
        //Quantity - for ALTERNATE pricing calculation (monthly list price quantity is NOT displayed)
        else if ((attribute == 'FakeQuantity__c') && (prp.AlternatePriceCalculation__c != null && prp.AlternatePriceCalculation__c == 'Monthly List Price')) {

            //NEVER show quantity for 'Monthly List Price'
            return new QCAttributeLogic(false, false);
        } 
        //Quantity - for ALTERNATE pricing calculation (monthly per unit list price quantity IS displayed)
        else if ((attribute == 'FakeQuantity__c') && (prp.AlternatePriceCalculation__c != null && prp.AlternatePriceCalculation__c == 'Monthly Per Unit List Price')) {

            //ALWAYS show quantity for 'Monthly Per Unit List Price'
            return new QCAttributeLogic(true, true);
        }         

        //Sales Rep is always visible and always editable.
        if (attribute == 'SalesRepId__c') return new QCAttributeLogic(true, true);

        //List Price - visible & read-only if list price, hidden and readonly if custom price.
        if (attribute == 'zqu__ListPriceDisplay__c') {
            if (prp.RatePlanPricingModel__c != null && prp.RatePlanPricingModel__c.startsWithIgnoreCase('custom')) return new QCAttributeLogic(false, false);
            else return new QCAttributeLogic(true, false);
        }

        //Service Start Date - always visible, always editable.
        if (attribute == 'ServiceStart__c') {
            //if (isEvergreen) return new QCAttributeLogic(false, false);
            //else return new QCAttributeLogic(true, true);  
            return new QCAttributeLogic(true, true);  
        }

        //Service End Date - always visible, always editable.
        if (attribute == 'ServiceEnd__c') {
            //if (isEvergreen) return new QCAttributeLogic(false, false);  
            //else return new QCAttributeLogic(true, true);  
            return new QCAttributeLogic(true, true);  
        } 

        //Event - only visible and editable IF Product Group == 'Attending'.  Otherwise hidden.
        if (attribute == 'Event__c') {
            if ((prp.zqu__ZProduct__r != null) && (prp.zqu__ZProduct__r.ProductGroup__c == 'Attending')) return new QCAttributeLogic(true, true);  
            else return new QCAttributeLogic(false, false);
        } 

        //Period - if 'one-time' we display it read-only on the screen, else it's not displayed at all.
        if (attribute == 'zqu__Period__c') {
            if (prpc.zqu__Type__c.startsWithIgnoreCase('one')) return new QCAttributeLogic(false, false);
            else return new QCAttributeLogic(true, false);
        }

        //Effective Price - for NORMAL pricing calculations
        if ((attribute == 'zqu__EffectivePrice__c') && (prp.AlternatePriceCalculation__c == null || prp.AlternatePriceCalculation__c != 'Monthly List Price')) {
            if (prp.RatePlanPricingModel__c != null && prp.RatePlanPricingModel__c.startsWithIgnoreCase('list')) return new QCAttributeLogic(true, false);
            else return new QCAttributeLogic(true, true);
        }

        //Effective Price - for ALTERNATE pricing calculations
        if ((attribute == 'zqu__EffectivePrice__c') && (prp.AlternatePriceCalculation__c != null && prp.AlternatePriceCalculation__c == 'Monthly List Price')) return new QCAttributeLogic(true, false);

        //Charge model - Always visible, always readonly.
        if (attribute == 'zqu__Model__c') return new QCAttributeLogic(true, false);

        //UOM - Always visible, always readonly IF NOT Discount
        if (attribute == 'zqu__UOM__c') {
            
            //If this product rate plan charge is a discount, don't show UOM.
            if (prpc.zqu__Model__c.containsIgnoreCase('discount')) return new QCAttributeLogic(false, false);
            return new QCAttributeLogic(true, false);
        }

        //Charge Line Term - not a field on the database, just a working, mathematical field only.
        if (attribute == 'ChargeLineTerm__c') {
            if (isEvergreen || (prp.AlternatePriceCalculation__c != null && prp.AlternatePriceCalculation__c == 'Monthly List Price')) return new QCAttributeLogic(false, false);
            else return new QCAttributeLogic(true, false);            
        }

        //Fake attribute that does NOT have a place-holder on the database, 'Number of Months' - for NORMAL methods
        if ((attribute == 'NumberOfMonths__c') && (prp.AlternatePriceCalculation__c == null || (prp.AlternatePriceCalculation__c != 'Monthly List Price' && prp.AlternatePriceCalculation__c != 'Monthly Per Unit List Price'))) return new QCAttributeLogic(false, false);

        //Fake attribute that does NOT have a place-holder on the database, for the alternate, or monthly method
        else if ((attribute == 'NumberOfMonths__c') && (prp.AlternatePriceCalculation__c != null && prp.AlternatePriceCalculation__c == 'Monthly List Price')) return new QCAttributeLogic(true, true);

        //Fake attribute that does NOT have a place-holder on the database, for the alternate, or monthly method
        else if ((attribute == 'NumberOfMonths__c') && (prp.AlternatePriceCalculation__c != null && prp.AlternatePriceCalculation__c == 'Monthly Per Unit List Price')) return new QCAttributeLogic(true, true);

        return new QCAttributeLogic(false, false);
    }

    public static Decimal CalcEffectivePriceForAlternateMonthlyMethod(zqu__QuoteCharge__c charge, zqu__ProductRatePlan__c prp, Decimal numMonths, Decimal termLength, String billingFrequency) {

        Decimal numBills = NumberofInvoicesRequired(termLength, billingFrequency);

        Decimal result = (charge.zqu__ListPriceDisplay__c * numMonths) / numBills;

        return result.setScale(2);
    }

    public static Integer GetPeriodNumber(String period) {        
        if (period == 'Month') return 1;
        if (period == 'Quarter') return 3;
        if (period == 'Semi-Annual') return 6;
        if (period == 'Annual') return 12;
        return 0;
    }

    //Returns the number of months (whole - always rounded up) between start & end dates
    public static Integer CalculateChargeLineTerm(Date startDate, Date endDate) {
        if (startDate == null || endDate == null || endDate < startDate) return null;

        //If the dates are the same
        if (startDate == endDate) return 1;

        if (startDate.day() == endDate.day()) return startDate.monthsBetween(endDate);

        if (startDate.day() > endDate.day()) return startDate.monthsBetween(endDate);
        else return startDate.monthsBetween(endDate) + 1;
    }

    public static Decimal NumberofInvoicesRequired(Decimal termLength, String billingFrequency) {
    
        if (billingFrequency == null) return 1;
    
        if (billingFrequency.startsWithIgnoreCase('one')) return 1;

        if (termLength == null) return 1;

        if (billingFrequency.toLowerCase() == 'annual') return termLength / 12;

        if (billingFrequency.startsWithIgnoreCase('semi')) return termLength / 6;

        if (billingFrequency.toLowerCase() == 'quarter') return termLength / 3;

        if (billingFrequency.toLowerCase() == 'month') return termLength;

        return 1;
    }

    public static Set<ID> FilteredRatePlans(String zCurrency, Date zStartDate){
        
        List<zqu__ZProduct__c> products;
        Set<Id> productIds = new Set<Id> ();
        
        for (zqu__ProductRatePlanChargeTier__c result : [SELECT zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id
                                                            FROM zqu__ProductRatePlanChargeTier__c
                                                            WHERE zqu__Currency__c = :zCurrency
                                                            AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.zqu__EffectiveStartDate__c <= :zStartDate
                                                            AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.zqu__EffectiveEndDate__c >= :zStartDate
                                                            AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.zqu__Deleted__c = false
                                                            ORDER BY Name ASC Limit 10000]) {
        
            productIds.add(result.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id);
        }
        return productIds;
    }      

    //CCBOBS-36
    //This method is the only code to update if/when new values are added to the field, 'Restricted From' in the Zuora product catalog.
    //The current picklist options are as such:
    //  'Sales Users' means that profiles of 'DHX Sales' & 'DHX Sales with Lattice' should *not* be able to see said rate plans.
    //  'None' means that all profiles can see/use/consume that product rate plan.
    //  null operates the same as 'None'
    public static String ReturnRestrictedFromWhereClauseForCPQ(String profileName) {

        String result = null;

        //This IF handles profiles:
            //DHX Sales
            //DHX Sales with Lattice
        if (profileName.startsWithIgnoreCase('DHX Sales') || profileName.startsWithIgnoreCase('DHX Account Coordinators')) result = '( RestrictedFrom__c != \'Sales Users\' )';

        return result;
    }

    public static Map<Id, List<zqu__ProductRatePlanChargeTier__c>> GetTierMapBasedOnPRPCharges(Set<Id> prpChargeIds, String quotesCurrency) {

        Map<Id, List<zqu__ProductRatePlanChargeTier__c>> result = new Map<Id, List<zqu__ProductRatePlanChargeTier__c>>();
        for (zqu__ProductRatePlanChargeTier__c prpcT : [SELECT  zqu__Currency__c, 
                                                                zqu__EndingUnit__c, 
                                                                zqu__Price__c, 
                                                                zqu__PriceFormat__c, 
                                                                zqu__ProductRatePlanCharge__c, 
                                                                zqu__StartingUnit__c, 
                                                                zqu__Tier__c 
                                                            FROM zqu__ProductRatePlanChargeTier__c
                                                            WHERE zqu__ProductRatePlanCharge__c IN :prpChargeIds
                                                                AND zqu__Currency__c = :quotesCurrency
                                                                AND zqu__Deleted__c = false
                                                            ORDER BY zqu__ProductRatePlanCharge__c, zqu__StartingUnit__c]) {

            if (!result.containsKey(prpcT.zqu__ProductRatePlanCharge__c)) result.put(prpcT.zqu__ProductRatePlanCharge__c, new List<zqu__ProductRatePlanChargeTier__c>());
            result.get(prpcT.zqu__ProductRatePlanCharge__c).add(prpcT);
        }
        return result;
    }    

    //Function returns either true or false to indicate if said quote charge should be invoice on said invoice number.
    //The invoiceNumber parameter starts counting at 1 for the first invoice.
    public static Boolean InvoiceQC(Integer invoiceNumber, QuoteChargeWrapper qcw) {

        //If this is a one-time charge:
        if ((qcw.quoteCharge.zqu__Period__c == null || qcw.quoteCharge.zqu__Period__c == '') && (qcw.quoteCharge.zqu__ChargeType__c.toLowerCase() == 'one-time')) {
            if (invoiceNumber == 1) return true;
            else return false;
        }
        else if ((qcw.quoteCharge.zqu__Period__c != null && qcw.quoteCharge.zqu__Period__c != '') && (qcw.quoteCharge.zqu__ChargeType__c.toLowerCase() == 'recurring')) {

            //Then we're dealing with a recurring charge.

            if (qcw.quoteCharge.zqu__Period__c.toLowerCase() == 'month') return true;
            else if ((qcw.quoteCharge.zqu__Period__c.toLowerCase() == 'quarter') && (math.mod(invoiceNumber - 1, 3) == 0)) return true;
            else if ((qcw.quoteCharge.zqu__Period__c.toLowerCase() == 'semi-annual') && (math.mod(invoiceNumber - 1, 6) == 0)) return true;
            else if ((qcw.quoteCharge.zqu__Period__c.toLowerCase() == 'annual') && (math.mod(invoiceNumber - 1, 12) == 0)) return true;
            else return false;

        }
        return false;
    }

    public static Boolean IsOpportunityWaitingOnApproval(Id oppId) {
        return ![ Select Id From ProcessInstance WHERE TargetObjectId =:oppId AND Status = 'Pending'].isEmpty();
    }


    //This returns a date.  It *may* be the exact date that was passed in (firstBillDate) or it may be adjusted.
    //This is the logic for CCBOB-96, called by changing the Service Start Date on the Quote Insert/Edit screen.
    public static Date ReturnFirstBillDate(Date serviceStartDate, Date firstBillDate) {

        Date today = System.today();
        if (serviceStartDate != null && firstBillDate != null) {

            if (serviceStartDate.month() == today.month() && serviceStartDate.year() == today.year()) {
                //If the service start date is in the current month...
                
                //If they equal, return the first bill date unchanged
                if (serviceStartDate.isSameDay(firstBillDate)) return firstBillDate;

                //If the month and year are the same, update the date to the new service start date.
                if (serviceStartDate.month() == firstBillDate.month() && serviceStartDate.year() == firstBillDate.year()) return serviceStartDate;

                //If the first bill date is in a prior month to the service start date, update the date to the new service start date.
                if ((serviceStartDate.month() > firstBillDate.month() && serviceStartDate.year() == firstBillDate.year()) || (serviceStartDate.year() > firstBillDate.year())) return serviceStartDate;

                //If the first bill date is in a future month to the service start date, change nothing, return the unaltered firstBillDate
                if ((firstBillDate.month() > serviceStartDate.month() && firstBillDate.year() == serviceStartDate.year()) || (firstBillDate.year() > serviceStartDate.year())) return firstBillDate;
            }
            else if ((serviceStartDate.month() > today.month() && serviceStartDate.year() == today.year()) || serviceStartDate.year() > today.year()) {
                //If the service start date is in a future month...

                //If they equal, return the first bill date unchanged
                if (serviceStartDate.isSameDay(firstBillDate)) return firstBillDate;

                //If the month and year are the same, update the date to the new service start date.
                if (serviceStartDate.month() == firstBillDate.month() && serviceStartDate.year() == firstBillDate.year()) return serviceStartDate;

                //If the first bill date is in a prior month to the service start date, update the date to the new service start date.
                if ((serviceStartDate.month() > firstBillDate.month() && serviceStartDate.year() == firstBillDate.year()) || (serviceStartDate.year() > firstBillDate.year())) return firstBillDate;

                //If the first bill date is in a future month to the service start date, change nothing, return the unaltered firstBillDate
                if ((firstBillDate.month() > serviceStartDate.month() && firstBillDate.year() == serviceStartDate.year()) || (firstBillDate.year() > serviceStartDate.year())) return firstBillDate;
            }
            else {
                //else if the service start date is in a prior month...

                //If they equal, return the first bill date unchanged
                if (serviceStartDate.isSameDay(firstBillDate)) return firstBillDate;

                //If the month and year are the same, update the date to the new service start date.
                if (serviceStartDate.month() == firstBillDate.month() && serviceStartDate.year() == firstBillDate.year()) return serviceStartDate;

                //If the first bill date is in a prior month to the service start date, update the date to the new service start date.
                if ((serviceStartDate.month() > firstBillDate.month() && serviceStartDate.year() == firstBillDate.year()) || (serviceStartDate.year() > firstBillDate.year())) return serviceStartDate;

                //If the first bill date is in a future month to the service start date, change nothing, return the unaltered firstBillDate
                if ((firstBillDate.month() > serviceStartDate.month() && firstBillDate.year() == serviceStartDate.year()) || (firstBillDate.year() > serviceStartDate.year())) return firstBillDate;            
            }
        }

        //If we somehow manage to get down here, return the first bill date (don't change anything)
        return firstBillDate;
    }

    public static Map<String, Decimal> GetEstimatedSalesTaxFromAvalara(zqu__Quote__c thisQuote, List<ProductRatePlanWrapper> thisQuotesRatePlans) {        

        Map<String, Decimal> returnMap = new Map<String, Decimal>();

        final Decimal errorResult = -1;

        if (thisQuote == null) {
            returnMap.put('ERROR 11: zqu__Quote__c object is null.', errorResult);
            return returnMap;
        }       

        List<Contact> contactList = [SELECT 
                                            Id, 
                                            Name, 
                                            MailingStreet, 
                                            MailingState, 
                                            MailingCountry, 
                                            MailingCity, 
                                            MailingPostalCode
                                        FROM Contact 
                                        WHERE Id = :thisQuote.zqu__SoldToContact__c LIMIT 1];        

        if (contactList == null || contactList.isEmpty()) {
            returnMap.put('ERROR 13: Unable to find the Sold To Contact\'s address for tax calculation.', errorResult);
            return returnMap;
        }

        Contact soldToContact = contactList[0];        

        List<Opportunity> oppList = [SELECT Account.Account_Number__c FROM Opportunity WHERE Id = :thisQuote.zqu__Opportunity__c LIMIT 1];

        if (oppList == null || oppList.isEmpty()) {
            returnMap.put('ERROR 15: While attempting to locate the Account\'s Account Number, the Opportunity was not found.', errorResult);
            return returnMap;            
        }

        //Now check the tax settings so we know which company code to use:
        String companyCode = null;
        BrandTagsToZQUTaxRegion__c potentialMatch = BrandTagsToZQUTaxRegion__c.getInstance(thisQuote.BrandTag__c);
        if (potentialMatch == null || potentialMatch.BindToAvalaraCo__c != true) companyCode = Label.AvalaraTaxEstimateCompanyCode;
        else companyCode = thisQuote.BrandTag__c;

        String accountsAccountNumber = oppList[0].Account.Account_Number__c;

        //If there are no rate plans, return 0
        if (thisQuotesRatePlans.isEmpty()) {
            returnMap.put('Success', 0.00);
            return returnMap;
        } 

        AVA_SF_SDK.TaxSvc.TaxSvcSoap taxSvc = new AVA_SF_SDK.TaxSvc.TaxSvcSoap(Label.AvalaraTaxEstimateURL);
        taxSvc.Security = new AVA_SF_SDK.TaxSvc.Security();
        taxSvc.Security.UsernameToken.Username = Label.AvalaraTaxEstimateUser;
        taxSvc.Security.UsernameToken.Password = Label.AvalaraTaxEstimatePass;
        taxSvc.Profile = new AVA_SF_SDK.TaxSvc.Profile();
        taxSvc.Profile.Client = 'SalesTaxCPQPOC,0,1';

        AVA_SF_SDK.TaxSvc.GetTaxRequest gtreq = new AVA_SF_SDK.TaxSvc.GetTaxRequest();

        String docCode = thisQuote.zqu__Opportunity__c + '_' + thisQuote.Name;
        if (docCode.length() > 50)  docCode = docCode.left(50);
        gtreq.DocCode = docCode;
        // SalesOrder, SalesInvoice, ReturnOrder, ReturnInvoice, PurchaseOrder, PurchaseInvoice
        gtreq.DocType = 'SalesInvoice';
        gtreq.CustomerCode = accountsAccountNumber;
        gtreq.CompanyCode = companyCode;
        // Document (default), Line, Tax
        gtreq.DetailLevel = 'Document';

        AVA_SF_SDK.TaxSvc.BaseAddress orgAddr = new AVA_SF_SDK.TaxSvc.BaseAddress();
        orgAddr.AddressCode = 'Origin';
        orgAddr.Line1 = '12150 Meredith Dr';
        orgAddr.City = 'Urbandale';
        orgAddr.Region = 'IA';
        orgAddr.PostalCode = '50323-1500';

        AVA_SF_SDK.TaxSvc.BaseAddress dstAddr = new AVA_SF_SDK.TaxSvc.BaseAddress();
        dstAddr.AddressCode = 'Destination';

        String street, city, state, postal, country = '';
        street = soldToContact.MailingStreet + '';
        city = soldToContact.MailingCity + '';
        state = soldToContact.MailingState + '';
        postal = soldToContact.MailingPostalCode + '';
        country = soldToContact.MailingCountry + '';

        dstAddr.Line1 = street;
        dstAddr.City = city;
        dstAddr.Region = state;
        dstAddr.PostalCode = postal;
        dstAddr.Country = country;

        gtreq.Addresses = new AVA_SF_SDK.TaxSvc.ArrayOfBaseAddress();
        gtreq.Addresses.BaseAddress = new AVA_SF_SDK.TaxSvc.BaseAddress[2];

        gtreq.Addresses.BaseAddress[0] = orgAddr;
        gtreq.Addresses.BaseAddress[1] = dstAddr;

        gtreq.OriginCode = orgAddr.AddressCode;
        gtreq.DestinationCode = dstAddr.AddressCode;

        //Count the charges on the quote
        Integer iChargeCount = 0;
        for (ProductRatePlanWrapper prpw : thisQuotesRatePlans) {
            for (QuoteChargeWrapper qcw : prpw.QuoteChargeWrappers) {
                iChargeCount++;
            }
        }

        gtreq.Lines = new AVA_SF_SDK.TaxSvc.ArrayOfLine();
        gtreq.Lines.Line = new AVA_SF_SDK.TaxSvc.Line[iChargeCount];

        Integer iLineNum = 0;

        for (ProductRatePlanWrapper prpw : thisQuotesRatePlans) {

            List<QuoteChargeWrapper> embeddedDiscountsToApply = new List<QuoteChargeWrapper>();

            //First loop is to identify all embedded rate plan discounts
            for (QuoteChargeWrapper qcw : prpw.QuoteChargeWrappers) {
                if (qcw.isDiscountCharge) embeddedDiscountsToApply.add(qcw);
            }

            //Second loop is to adjust the value using the rate plan discounts
            for (QuoteChargeWrapper qcw : prpw.QuoteChargeWrappers) {
                if (!qcw.isDiscountCharge && qcw.FauxTCV != null && qcw.FauxTCV > 0) {
                    for (QuoteChargeWrapper discountWrapper : embeddedDiscountsToApply) {
                        //Apply the embedded discount to the quote charge
                        if (discountWrapper.quoteCharge != null && discountWrapper.quoteCharge.zqu__EffectivePrice__c != null && discountWrapper.quoteCharge.zqu__EffectivePrice__c != 0) qcw.FauxTCV = qcw.FauxTCV * (1-(discountWrapper.quoteCharge.zqu__EffectivePrice__c * .01));
                    }
                }
            }            
        }

        //At this point 'FauxTCV' now has embedded discounts applied to it, time to loop and simultaniously apply global discounts, if applicable.
        for (ProductRatePlanWrapper prpw : thisQuotesRatePlans) {
            for (QuoteChargeWrapper qcw : prpw.QuoteChargeWrappers) {

                if (!qcw.isDiscountCharge) {

                    gtreq.Lines.Line[iLineNum] = new AVA_SF_SDK.TaxSvc.Line();

                    //'No' must be unique
                    gtreq.Lines.Line[iLineNum].No = 'Line ' + (iLineNum + 1);
                    gtreq.Lines.Line[iLineNum].ItemCode = qcw.quoteCharge.zqu__ProductRatePlanCharge__r.zqu__TaxCode__c;
                    gtreq.Lines.Line[iLineNum].TaxCode = qcw.quoteCharge.zqu__ProductRatePlanCharge__r.zqu__TaxCode__c;
                    
                    Decimal netVal = qcw.FauxTCV;
                    if (netVal > 0 && thisQuote.Discount_Percent__c != null && thisQuote.Discount_Percent__c != 0) netVal = netVal * (1-(thisQuote.Discount_Percent__c * .01));
                    else netVal = netVal;

                    gtreq.Lines.Line[iLineNum].Amount = netVal;
                    gtreq.Lines.Line[iLineNum].Qty = 1.0;               //Irrelevant to the result and process, but should be included.

                    iLineNum++;
                }
            }
        }
    
        gtreq.DocDate = Date.Today();
        gtreq.Commit_x=false;

        AVA_SF_SDK.TaxSvc.GetTaxResult gtres = null;

        try {
            gtres = taxSvc.GetTax(gtreq);
            if (gtres.ResultCode == 'Success') {
                returnMap.put('Success', gtres.TotalTax);
                return returnMap;
            }
            
            else {
                returnMap.put('Avalara Returned Other Than Success: ' + gtres.ResultCode + ' : ' + gtres.Messages.Message[0].Name + ' : ' + gtres.Messages.Message[0].Summary, errorResult);
                return returnMap;
            }
        }
        catch (Exception ex) {
            returnMap.put('Avalara Threw an Exception: ' + ex.getmessage(), errorResult);
            return returnMap;
        }

        returnMap.put('No idea how we got down here...', errorResult);
        return returnMap;        

    }
    
     /**
    * @author        Jaseem Pookandy
    * @date          01/10/2016
    * @description   generic method to retrieve the picklist values in a list
    * @param         object api name
    * @param         Field Api name
    * @return        set<string> with picklist values
    */
   public static Set<String> getPicklistValues(String ObjectApi_name,String Field_name){ 

        Set<String> SetPickvals=new Set<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
            SetPickvals.add(a.getValue());//add the value  to our final list
        }

        return SetPickvals;
    }
}