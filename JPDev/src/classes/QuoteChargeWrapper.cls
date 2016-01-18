public class QuoteChargeWrapper {
    public List<Attribute> invisibleAttributes {get; set;}
    public List<Attribute> visibleAttributes {get; set;}
    public String GUID {get; private set;}
    public zqu__QuoteCharge__c quoteCharge {get; set;}
    public List<LineAttribute> QCLines {get; set;}
    public String Country {get; set;}                               //needed because this is a picklist field but we have to override the options so we have to bind it to someplace - here.
    private static final Integer MAX_ATTRIBUTE_COUNT_PER_ROW = 3;   //The MAXIMUM number of attributes that will be displayed per row.
    public Boolean isDiscountCharge {get; set;}
    public Decimal FauxTCV {get; set;}
    public Decimal FauxTCVNet {get; set;}                           //This is the TCV less any rate plan discounts.  (Used for contract-level calculations)
    public String backgroundColor     {get; set;}
    public Boolean displayChargeLineTotalAsInput {get; set;}
    public Boolean quoteChargeTotalManuallySet {get; set;}

    public static final String COLOR_DISCOUNT   = '#F5F6CE';
    public static final String COLOR_NORMAL     = '#FFFFFF';

    public QuoteChargeWrapper() {
        visibleAttributes = new List<Attribute>();
        invisibleAttributes = new List<Attribute>();
        isDiscountCharge = false;
        displayChargeLineTotalAsInput = false;
        quoteChargeTotalManuallySet = false;
        GUID = GUIDUtil.NewGuid();
        
        backgroundColor = COLOR_NORMAL;
    }

    private void BuildLines() {

        Integer iProcessed = 0;

        List<LineAttribute> result = new List<LineAttribute>();
        LineAttribute workingLine = new LineAttribute();

        for (Attribute a : visibleAttributes) {
            if (workingLine.attributes.size() < MAX_ATTRIBUTE_COUNT_PER_ROW) workingLine.attributes.add(a);
            else {
                if (!workingLine.attributes.isEmpty()) result.add(workingLine);  
                workingLine = new LineAttribute();
                workingLine.attributes.add(a);
            }                

            iProcessed++;

            //if we just processed the last one...
            if (iProcessed == visibleAttributes.size()) result.add(workingLine);
        }
        QCLines = result;
    }

    public void BuildAttributesAndSetDefaults(List<QuoteChargeAttributes__c> listoAtts, zqu__ProductRatePlan__c prp, zqu__ProductRatePlanCharge__c prpc, Opportunity sourceOpp, String countryName, zqu__Quote__c thisQuote, List<SelectOption> salesRepList, List<SelectOption> countryList, String saleType) {

        //First set the render flag for the quote charge total
        if (prpc.zqu__Model__c.containsIgnoreCase('discount')) isDiscountCharge = true;
        else isDiscountCharge = false;

        if ((!prpc.zqu__Model__c.containsIgnoreCase('flat fee')) && (prp.RatePlanPricingModel__c != null) && (prp.RatePlanPricingModel__c.containsIgnoreCase('custom'))) displayChargeLineTotalAsInput = true;
        else displayChargeLineTotalAsInput = false;

        if (isDiscountCharge) backgroundColor = COLOR_DISCOUNT;
        else backgroundColor = COLOR_NORMAL;

        Boolean isEvergreen;
        if (thisQuote.zqu__Subscription_Term_Type__c.startsWithIgnoreCase('evergreen')) isEvergreen = true;
        else isEvergreen = false;        

        for (QuoteChargeAttributes__c qca : listoAtts) {

            Attribute a = new Attribute();
            a.labelText = qca.Label__c;
            a.APIName = qca.APIName__c;
            a.control = qca.ControlType__c;
            a.defaultValue = qca.DefaultValue__c;
            a.postbackAction = qca.PostbackAction__c;
            a.picklist_IDField = qca.Picklist_IDField__c;
            a.picklist_ValueField = qca.Picklist_ValueField__c;
            a.soqlSelect = qca.SOQLSelect__c;

            a.renderingLogic = QuoteUtilities.CalcQuoteChargeRendering(prp, qca.APIName__c, prpc, isEvergreen);

            //If the picklist needs manual adjustment... - but only if it's visible!  Otherwise, skip the SOQL...
            if ((a.renderingLogic.isVisible) && (a.control == 'selectListEvent')) a.FixCustomSelectListOptions(thisQuote);

            if (a.control == 'SalesRepList') a.picklistObjects = salesRepList;
            if (a.control == 'Country') a.picklistObjects = countryList;            
            
            //Defaults now - but only set defaults on the attribute if the charge is new!
            if (quoteCharge.Id == null) {

                if ((a.APIName == 'SalesRepId__c') && (a.defaultValue == 'Opportunity.OwnerId')) {
                    quoteCharge.SalesRepId__c = sourceOpp.OwnerId;
                    quoteCharge.Sales_Representative__c = sourceOpp.Owner.Name;  
                }

                if ((a.APIName == 'FakeQuantity__c') && (prp.AlternatePriceCalculation__c == null || (prp.AlternatePriceCalculation__c != 'Monthly List Price' && prp.AlternatePriceCalculation__c != 'Monthly Per Unit List Price'))) {
                    if (prpc.zqu__Model__c.startsWith('Flat Fee')) quoteCharge.FakeQuantity__c = 1;
                    else if (a.defaultValue == 'PRPC.DefaultQuantity') quoteCharge.FakeQuantity__c = prpc.zqu__DefaultQuantity__c;
                }
                else if (a.APIName == 'FakeQuantity__c' && prp.AlternatePriceCalculation__c != null && (!prp.AlternatePriceCalculation__c.equalsIgnoreCase('Monthly Per Unit List Price'))) quoteCharge.FakeQuantity__c = 1;
                else if (a.APIName == 'FakeQuantity__c' && prp.AlternatePriceCalculation__c != null && prp.AlternatePriceCalculation__c.equalsIgnoreCase('Monthly Per Unit List Price')) quoteCharge.FakeQuantity__c = prpc.zqu__DefaultQuantity__c;    //CCBOB-68

                if ((a.APIName == 'Country__c') && (a.defaultValue == 'FilterPreset.Country')) Country = countryName;

                //Only default the Start Date if the product group is NOT Attending and NOT Attending AND saleType == Standard
                if ((!isEvergreen) && (a.APIName == 'ServiceStart__c') && (a.defaultValue == 'Quote.ServiceStartDate') && (prpc.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c != 'Attending') && (prpc.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c != 'Advertising') && (saleType == 'Standard')) quoteCharge.ServiceStart__c = thisQuote.zqu__StartDate__c;
                else if ((isEvergreen) && (a.APIName == 'ServiceStart__c') && (saleType == 'Standard')) quoteCharge.ServiceStart__c = thisQuote.zqu__StartDate__c;   

                //Only default the End Date if the product group is NOT Attending and NOT Attending AND saleType == Standard
                if ((!isEvergreen) && (a.APIName == 'ServiceEnd__c') && (a.defaultValue == 'Quote.ServiceEndDate') && (prpc.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c != 'Attending') && (prpc.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c != 'Advertising') && (saleType == 'Standard')) quoteCharge.ServiceEnd__c = thisQuote.Service_End_Date__c;
                else if ((isEvergreen) && (a.APIName == 'ServiceEnd__c') && (prpc.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c != 'Attending') && (prpc.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c != 'Advertising') && (saleType == 'Standard')) if (quoteCharge.ServiceStart__c != null) quoteCharge.ServiceEnd__c = quoteCharge.ServiceStart__c.addMonths(1);

                //Period  (In all cases this will be set to product rate plan charge.recurring period (because that's Zuora's model))
                if ((a.APIName == 'zqu__Period__c') && (a.defaultValue == 'PRPC.zqu__RecurringPeriod__c')) quoteCharge.zqu__Period__c = prpc.zqu__RecurringPeriod__c;

                //Evergreen's chargelineTerm is ALWAYS '1'.
                if ((a.APIName == 'ChargeLineTerm__c') && (isEvergreen)) quoteCharge.ChargeLineTerm__c = 1;

                //Default number of months now - but only if it's visible & the product groups is NOT Advertising or Attending
                if ((a.APIName == 'NumberOfMonths__c') && (a.renderingLogic.isVisible) && (!prp.zqu__ZProduct__r.ProductGroup__c.equalsIgnoreCase('Advertising')) && (!prp.zqu__ZProduct__r.ProductGroup__c.equalsIgnoreCase('Attending')) && (thisQuote.zqu__StartDate__c != null) && (thisQuote.Service_End_Date__c != null) && saleType == 'Standard') quoteCharge.NumberOfMonths__c = QuoteUtilities.CalculateChargeLineTerm(thisQuote.zqu__StartDate__c, thisQuote.Service_End_Date__c);
            }

            if (a.renderingLogic.isVisible) visibleAttributes.add(a);
            else invisibleAttributes.add(a);
        }

        BuildLines();
    }
}