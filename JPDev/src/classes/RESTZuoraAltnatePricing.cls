@RestResource(urlMapping='/ZuoraAltnatePricing/*')
global with sharing class RESTZuoraAltnatePricing {
    /* Try to use getLevenshteinDistance for fuzzy matching */
              
    global class ReturnClass {
        global Boolean isFound;
        global Double listPrice;
        global String message;

        global ReturnClass() {}
    }  
  
    public static ReturnClass ZuoraAltnatePricingHandler(Map<String, String> requestParameterMap) {

        Integer Quantity, NumberOfMonths;
        Double Price = 0.00;
        Boolean enforceMonthUOMRequirement = false;
        ReturnClass rtnClass = new ReturnClass();
        String RatePlanChargeId = requestParameterMap.get('RatePlanChargeId');

        if (IsParameterNull(RatePlanChargeId)) {
            rtnClass.message = 'Invalid Request - RatePlanChargeId is required';
            rtnClass.isFound = false;
            return rtnClass;
        }

        try {
            Quantity = Integer.valueOf(requestParameterMap.get('Quantity'));
            if (Quantity < 1) {
                Quantity = 1;
                enforceMonthUOMRequirement = false;
            }
            else enforceMonthUOMRequirement = true;
        } catch (Exception e) {            
            Quantity = 1;
            enforceMonthUOMRequirement = false;
        }

        try {
            NumberOfMonths = Integer.valueOf(requestParameterMap.get('NumberOfMonths'));
        } catch (Exception e) {
            rtnClass.message = 'Invalid format for NumberOfMonths - ' + e.getMessage();
            rtnClass.isFound = false;
            return rtnClass;
        }

        try {  
 
            List<zqu__ProductRatePlanCharge__c> pRPChargeLst = [SELECT zqu__ListPrice__c, zqu__UOM__c FROM zqu__ProductRatePlanCharge__c WHERE zqu__ZuoraId__c = :RatePlanChargeId];

            if (!pRPChargeLst.isEmpty()) {

                if (!enforceMonthUOMRequirement && pRPChargeLst[0].zqu__UOM__c.toLowerCase() != 'month') {

                    Price = (pRPChargeLst[0].zqu__ListPrice__c * Quantity * NumberOfMonths).setScale(2, System.RoundingMode.HALF_DOWN);
                    rtnClass.listPrice = Price;
                    rtnClass.message = 'Successful';
                    rtnClass.isFound = true;

                } else if (enforceMonthUOMRequirement && pRPChargeLst[0].zqu__UOM__c.toLowerCase() == 'month') {
                    Quantity = 1;
                    Price = (pRPChargeLst[0].zqu__ListPrice__c * NumberOfMonths).setScale(2, System.RoundingMode.HALF_DOWN);
                    rtnClass.listPrice = Price;
                    rtnClass.message = 'Successful';
                    rtnClass.isFound = true;

                } else {
                    rtnClass.message = 'Invalid UOM for the Rate Plan Charge';
                    rtnClass.isFound = false;
                }
            }
            else {
                rtnClass.message = 'Rate Plan Charge with Id ' + RatePlanChargeId + ' was Not Found';
                rtnClass.isFound = false;
            }
            return rtnClass;
        } 
        catch (Exception e) {
            rtnClass.message = e.getMessage();
            rtnClass.isFound = false;
            return rtnClass;
        } 
    }

    @HttpGet
    global static ReturnClass doGet() { 
        RestRequest req = RestContext.request; 
        Map<String, String> parameterMap = RestContext.request.Params;
        return ZuoraAltnatePricingHandler(parameterMap);
    }
    
    public static boolean IsParameterNull(String param) {
        return param == null | ''.equals(param);
    }
}