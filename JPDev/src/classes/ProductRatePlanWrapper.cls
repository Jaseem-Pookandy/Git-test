public class ProductRatePlanWrapper {

    public zqu__ProductRatePlan__c              productRatePlan     {get; set;}
    public List<zqu__ProductRatePlanCharge__c>  prpCharges          {get; set;}
    public List<QuoteChargeWrapper>             quoteChargeWrappers {get; set;}
    public zqu__Quote__c                        quote               {get; set;}
    public Integer                              rowNum              {get; set;}
    public Boolean                              isDiscountProduct   {get; set;}
    public String                               ratePlanSaleType    {get; set;}
    public String                               backgroundColor     {get; set;}
    public String                               tooltip             {get; set;}
    public String                               GUID                {get; private set;}

    public Boolean IsMonthlyAlternatePricing {
        get {
            if (productRatePlan == null)                                                            return false;
            if (productRatePlan.AlternatePriceCalculation__c == null)                               return false;
            if (productRatePlan.AlternatePriceCalculation__c == 'Monthly List Price')               return true;
            if (productRatePlan.AlternatePriceCalculation__c == 'Monthly Per Unit List Price')      return true;       //new method as of 2015.06, yes, different than 'Monthly List Price'.
            return false;
        }
    }

    public static final String STANDARD_STANDARD_TIP   = 'This rate plan is marked as a \'Standard\' Sale Type.';
    public static final String STANDARD_CONVERSION_TIP = 'This rate plan is marked as a \'Trial Conversion\' Sale Type';
    public static final String STANDARD_TRIAL_TIP      = 'This rate plan is marked as a \'Trial\' Sale Type.';

    public static final String MONTHLY_STANDARD_TIP    = 'This rate plan uses the alternate (monthly) pricing calculation.';    
    public static final String MONTHLY_TRIAL_TIP       = 'This rate plan is marked as a \'Trial\' Sale Type and also uses the alternate (monthly) pricing calculation.';
    public static final String MONTHLY_CONVERSION_TIP  = 'This rate plan is marked as a \'Trial Conversion\' Sale Type and also uses the alternate (monthly) pricing calculation.';


    public static final String STANDARD_STANDARD_COLOR   = '#8A9EBE';
    public static final String STANDARD_TRIAL_COLOR      = '#D0D8E5';
    public static final String STANDARD_CONVERSION_COLOR = '#99D6AD';

    public static final String MONTHLY_STANDARD_COLOR    = '#C98A8A';
    public static final String MONTHLY_TRIAL_COLOR       = '#E9D0D0';
    public static final String MONTHLY_CONVERSION_COLOR  = '#CCCCB2';

    public static final String TRIAL_NOTES          = 'Trial Addendum Attached';

    public ProductRatePlanWrapper() {
        isDiscountProduct = false;       //default to false.
        ratePlanSaleType = 'Standard';
        prpCharges = new List<zqu__ProductRatePlanCharge__c>();
        quoteChargeWrappers = new List<QuoteChargeWrapper>();
        quote = new zqu__Quote__c();
        rowNum = -1;        
        backgroundColor = STANDARD_STANDARD_COLOR;
        tooltip = STANDARD_STANDARD_TIP;
        GUID = GUIDUtil.NewGuid();
    }

    public void SetColorAndToolTip(zqu__ProductRatePlan__c prp, String saleType) {

        //No specific scenarios for 'Monthly Per Unit List Price' as that will eventually be the normal as they are faded into the product catalog

        //If it's a monthly & trial:
        if ((prp.AlternatePriceCalculation__c != null && prp.AlternatePriceCalculation__c == 'Monthly List Price') && (saleType == 'Trial')) {
            backgroundColor = MONTHLY_TRIAL_COLOR;
            tooltip = MONTHLY_TRIAL_TIP;
        }

        //monthly list price & standard sale
        else if ((prp.AlternatePriceCalculation__c != null && prp.AlternatePriceCalculation__c == 'Monthly List Price') && ((saleType == 'Standard') || (saleType == null) || (saleType == ''))) {
            backgroundColor = MONTHLY_STANDARD_COLOR;
            tooltip = MONTHLY_STANDARD_TIP;               
        }

        //monthly price, conversion
        else if ((prp.AlternatePriceCalculation__c != null && prp.AlternatePriceCalculation__c == 'Monthly List Price') && (saleType == 'Trial Conversion')) {
            backgroundColor = MONTHLY_CONVERSION_COLOR;
            tooltip = MONTHLY_CONVERSION_TIP;   
        }        

        //normal price, as trial
        else if ((prp.AlternatePriceCalculation__c == null || prp.AlternatePriceCalculation__c != 'Monthly List Price') && (saleType == 'Trial')) {
            backgroundColor = STANDARD_TRIAL_COLOR;
            tooltip = STANDARD_TRIAL_TIP;   
        }

        //normal price, conversion
        else if ((prp.AlternatePriceCalculation__c == null || prp.AlternatePriceCalculation__c != 'Monthly List Price') && (saleType == 'Trial Conversion')) {
            backgroundColor = STANDARD_CONVERSION_COLOR;
            tooltip = STANDARD_CONVERSION_TIP;   
        }

        //normal price, standard
        else if ((prp.AlternatePriceCalculation__c == null || prp.AlternatePriceCalculation__c != 'Monthly List Price') && ((saleType == 'Standard') || (saleType == null) || (saleType == ''))) {
            backgroundColor = STANDARD_STANDARD_COLOR;
            tooltip = STANDARD_STANDARD_TIP;   
        }

        ////normal price, standard sale type - not necessary though because this is the default from the constructor.
    }

    public void AddProductRatePlan(zqu__ProductRatePlanCharge__c prpc, Integer thisRowNum, String timeAdded, String thisCurrency, List<QuoteChargeAttributes__c> listoAtts, Opportunity sourceOpp, String countryName, zqu__Quote__c thisQuote, List<SelectOption> salesRepList, List<SelectOption> countryList, String saleType) {
        prpCharges.add(prpc);

        //set visibility:  If this is a discount only product, we won't show this line item.
        if (prpc.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c == 'Discount') isDiscountProduct = true;

        zqu__QuoteCharge__c newQuoteCharge = new zqu__QuoteCharge__c();

        ratePlanSaleType = saleType;

        if (quote.Id != null) newQuoteCharge.zqu__Quote__c = quote.Id;
        newQuoteCharge.zqu__ProductRatePlanCharge__c = prpc.Id;
        newQuoteCharge.Name = prpc.Name;
        newQuoteCharge.zqu__ProductRatePlanName__c = prpc.zqu__ProductRatePlan__r.Name;
        newQuoteCharge.zqu__ProductName__c = prpc.zqu__ProductRatePlan__r.zqu__ZProduct__r.Name;
        newQuoteCharge.zqu__RatePlanCharge_ZuoraID__c = prpc.zqu__ZuoraId__c;
        newQuoteCharge.zqu__Upto_How_Many_Periods__c = prpc.zqu__Upto_How_Many_Periods__c;
        newQuoteCharge.zqu__UOM__c = prpc.zqu__UOM__c;
        newQuoteCharge.zqu__ChargeType__c = prpc.zqu__Type__c;
        newQuoteCharge.zqu__Apply_Discount_To_Recurring_Charges__c = prpc.zqu__Apply_Discount_To_Recurring_Charges__c;
        newQuoteCharge.zqu__Apply_Discount_To_Usage_Charges__c = prpc.zqu__Apply_Discount_To_Usage_Charges__c;
        newQuoteCharge.zqu__Apply_Discount_To_One_Time_Charges__c = prpc.zqu__Apply_Discount_To_One_Time_Charges__c;
        newQuoteCharge.zqu__Model__c = prpc.zqu__Model__c;
        newQuoteCharge.zqu__PrepaymentPeriods__c = prpc.zqu__PrepaymentPeriods__c;
        newQuoteCharge.zqu__Discount_Level__c = prpc.zqu__Discount_Level__c;
        //IncludedUnits is ALWAYS null with the current Zuora implementation.
        newQuoteCharge.zqu__IncludedUnits__c = null;
        newQuoteCharge.zqu__ProductRatePlanCharge__r = prpc;    //for tax code only, really.

        //START FEE TYPE
        if (newQuoteCharge.zqu__Model__c.contains('Flat')) newQuoteCharge.zqu__FeeType__c = 'Flat Fee';
        else if ((newQuoteCharge.zqu__Model__c.contains('Unit')) || (newQuoteCharge.zqu__Model__c.contains('Volume'))) newQuoteCharge.zqu__FeeType__c = 'Per Unit';
        else newQuoteCharge.zqu__FeeType__c = '';
        //END FEE TYPE

        newQuoteCharge.CurrencyIsoCode = thisCurrency;
        newQuoteCharge.zqu__Currency__c = thisCurrency;
        newQuoteCharge.zqu__TimeProductAdded__c = timeAdded;              //because Zuora considers this column a foreign-key group by, really.  *sigh*

        QuoteChargeWrapper qcw = new QuoteChargeWrapper();
        qcw.quoteCharge = newQuoteCharge;
        qcw.BuildAttributesAndSetDefaults(listoAtts, prpc.zqu__ProductRatePlan__r, prpc, sourceOpp, countryName, thisQuote, salesRepList, countryList, saleType);

        //set the initial quote charge total now:
        if (newQuoteCharge.zqu__EffectivePrice__c != null && newQuoteCharge.FakeQuantity__c != null) qcw.quoteCharge.zqu__Total__c = newQuoteCharge.FakeQuantity__c * newQuoteCharge.zqu__EffectivePrice__c;
        else qcw.quoteCharge.zqu__Total__c = null;

        SetColorAndToolTip(prpc.zqu__ProductRatePlan__r, saleType);

        if (saleType == 'Trial') newQuoteCharge.Notes__c = TRIAL_NOTES;

        //initially calculate the charge line term upon adding - IF the start and end dates are populated:
        qcw.quoteCharge.ChargeLineTerm__c = QuoteUtilities.CalculateChargeLineTerm(qcw.quoteCharge.ServiceStart__c, qcw.quoteCharge.ServiceEnd__c);
        quoteChargeWrappers.add(qcw);
        rowNum = thisRowNum;
    }

    public void AddProductRatePlanWithExistingQuoteCharge(zqu__ProductRatePlanCharge__c prpc, zqu__QuoteCharge__c qc, Integer thisRowNum, List<QuoteChargeAttributes__c> listoAtts, Opportunity sourceOpp, String countryName, zqu__Quote__c thisQuote, List<SelectOption> salesRepList, List<SelectOption> countryList, String saleType) {
    
        if (prpc != null && prpc.zqu__ProductRatePlan__r != null) {

            ratePlanSaleType = saleType;
            if (saleType == null || saleType == '') ratePlanSaleType = 'Standard';

            prpCharges.add(prpc);
            productRatePlan = prpc.zqu__ProductRatePlan__r;
        
            //set visibility:  If this is a discount only product, we won't show this line item.
            if (prpc.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c == 'Discount') isDiscountProduct = true;

            QuoteChargeWrapper qcw = new QuoteChargeWrapper();
            qcw.quoteCharge = qc;
            qcw.quoteCharge.FakeQuantity__c = qc.zqu__Quantity__c;
            qcw.Country = qc.Country__c;
            qcw.BuildAttributesAndSetDefaults(listoAtts, productRatePlan, prpc, sourceOpp, countryName, thisQuote, salesRepList, countryList, saleType);

            SetColorAndToolTip(prpc.zqu__ProductRatePlan__r, ratePlanSaleType);

            quoteChargeWrappers.add(qcw);
            rowNum = thisRowNum;
        }
    }

    public void AppendExistingQuoteCharge(zqu__ProductRatePlanCharge__c prpc, zqu__QuoteCharge__c qc, List<QuoteChargeAttributes__c> listoAtts, Opportunity sourceOpp, String countryName, zqu__Quote__c thisQuote, List<SelectOption> salesRepList, List<SelectOption> countryList, String saleType) {
        //if the rowNum hasn't been set yet, abort.
        if (rowNum == -1) return;

        ratePlanSaleType = saleType;
        if (saleType == null || saleType == '') ratePlanSaleType = 'Standard';

        QuoteChargeWrapper qcw = new QuoteChargeWrapper();
        qcw.quoteCharge = qc;
        qcw.quoteCharge.FakeQuantity__c = qc.zqu__Quantity__c;
        qcw.Country = qc.Country__c;
        qcw.BuildAttributesAndSetDefaults(listoAtts, prpc.zqu__ProductRatePlan__r, prpc, sourceOpp, countryName, thisQuote, salesRepList, countryList, saleType);

        SetColorAndToolTip(prpc.zqu__ProductRatePlan__r, ratePlanSaleType);

        quoteChargeWrappers.add(qcw);
    }

    //This defaults the list price on the quoteChargeWrapper based upon the (current) quantity, currency, etc...
    //The ID in the tierMap is a ProductRatePlanCharge Id.
    public void SetListPriceBasedOnTiersAndWhatnot(List<QuoteChargeWrapper> qcWrapperList, Map<Id, List<zqu__ProductRatePlanChargeTier__c>> tierMap, zqu__Quote__c thisQuote) {

        Boolean foundIt = false;

        for (QuoteChargeWrapper qcw : qcWrapperList) {

            if ((qcw.quoteCharge != null) && (qcw.quoteCharge.zqu__ProductRatePlanCharge__c != null) && (tierMap.containsKey(qcw.quoteCharge.zqu__ProductRatePlanCharge__c))) {

                if (qcw.quoteCharge.zqu__Model__c.startsWithIgnoreCase('volume')) {
                    for (zqu__ProductRatePlanChargeTier__c prpcTier : tierMap.get(qcw.quoteCharge.zqu__ProductRatePlanCharge__c)) {
                        if (prpcTier.zqu__Currency__c == thisQuote.zqu__Currency__c && prpcTier.zqu__StartingUnit__c <= qcw.quoteCharge.FakeQuantity__c && ((prpcTier.zqu__EndingUnit__c >= qcw.quoteCharge.FakeQuantity__c) || (prpcTier.zqu__EndingUnit__c == null))) {
                            qcw.quoteCharge.zqu__ListPriceDisplay__c = prpcTier.zqu__Price__c;
                            qcw.quoteCharge.zqu__EffectivePrice__c = prpcTier.zqu__Price__c;
                            foundIt = true;
                            //Found it!  break!
                            break;
                        }
                    }
                }
                else if (qcw.quoteCharge.zqu__Model__c.startsWithIgnoreCase('tier')) {
                    //NOT IMPLEMENTED YET!
                }                
                else if ((qcw.quoteCharge.zqu__Model__c.startsWithIgnoreCase('per')) || (qcw.quoteCharge.zqu__Model__c.startsWithIgnoreCase('flat'))) {
                    //Find the list price from the tier record that matches the currency.  If not found, return 0;
                    for (zqu__ProductRatePlanChargeTier__c prpcTier : tierMap.get(qcw.quoteCharge.zqu__ProductRatePlanCharge__c)) {
                        if (prpcTier.zqu__Currency__c == thisQuote.zqu__Currency__c) {
                            qcw.quoteCharge.zqu__ListPriceDisplay__c = prpcTier.zqu__Price__c;
                            qcw.quoteCharge.zqu__EffectivePrice__c = prpcTier.zqu__Price__c;

                            //Update the line item (charge) total now:
                            if (qcw.quoteCharge.zqu__EffectivePrice__c != null && qcw.quoteCharge.FakeQuantity__c != null) qcw.quoteCharge.zqu__Total__c = qcw.quoteCharge.FakeQuantity__c * qcw.quoteCharge.zqu__EffectivePrice__c;
                            else qcw.quoteCharge.zqu__Total__c = null;

                            foundIt = true;
                            //Found it!  break!
                            break;
                        }
                    }
                }
                else if (qcw.quoteCharge.zqu__Model__c == 'Discount-Fixed Amount') {
                    //Nothing to do here
                }
                else if (qcw.quoteCharge.zqu__Model__c == 'Discount-Percentage') {
                    //Find the list price from the tier record that matches the currency.  If not found, return 0;
                    for (zqu__ProductRatePlanChargeTier__c prpcTier : tierMap.get(qcw.quoteCharge.zqu__ProductRatePlanCharge__c)) {
                        if (prpcTier.zqu__Currency__c == thisQuote.zqu__Currency__c) {
                            qcw.quoteCharge.zqu__ListPriceDisplay__c = prpcTier.zqu__Price__c;
                            qcw.quoteCharge.zqu__EffectivePrice__c = prpcTier.zqu__Price__c;

                            //Update the line item (charge) total now:
                            if (qcw.quoteCharge.zqu__EffectivePrice__c != null && qcw.quoteCharge.FakeQuantity__c != null) qcw.quoteCharge.zqu__Total__c = qcw.quoteCharge.FakeQuantity__c * qcw.quoteCharge.zqu__EffectivePrice__c;
                            else qcw.quoteCharge.zqu__Total__c = null;

                            foundIt = true;
                            //Found it!  break!
                            break;
                        }
                    }
                }

                //If this isn't found - set the values to null so that the user cannot continue and use this rate plan.
                if (!foundIt) {
                    qcw.quoteCharge.zqu__ListPriceDisplay__c = null;
                    qcw.quoteCharge.zqu__EffectivePrice__c = null;
                    qcw.quoteCharge.zqu__Total__c = null;
                }
            }   //end if map contains it...
            else {
                qcw.quoteCharge.zqu__ListPriceDisplay__c = null;
                qcw.quoteCharge.zqu__EffectivePrice__c = null;
                qcw.quoteCharge.zqu__Total__c = 0;
            }
        }
    }
}