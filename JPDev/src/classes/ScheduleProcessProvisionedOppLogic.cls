/***************************************************************************
//
// Description    : Contains the logic for cc cleanup
// Moved to this class away from the OpportunityTrigerHandler class so updates
// aren't prohibited by the scheduled class
//                  
//***************************************************************************/

public with sharing class ScheduleProcessProvisionedOppLogic {

//CC-1013, called from the schedulable, batchable stuff (ScheduleProcessProvisionedOppBatch.cls)
  public static void ClearApplicableCreditCards(List<Opportunity> listOpps) {
    
    // This will update credit card numbers from 1234-1234-1234-9876 to be 
    // ****-****-****-9876 to minimize liability.
    // NOTE this this will occur for ALL opportunities passed in with only the following
    // two exceptions:  If:
    //     Opportunity.SyncedQuote.BrandTag == RigZone, Opportunity.SyncedQuote.Currency != USD && ALL of the SyncedQuote.QuoteCharges are NOT 'One Time' 
    //     Opportunity.SyncedQuote.BrandTag != 'eFC-Amer' but does start with 'eFC%' && ALL of the SyncedQuote.QuoteCharges are NOT 'One Time'
    //(added on 2014.02.05)
    // AND if the Quote's Payment Gateway is Approved.  (If not approved the card needs to stay for future processing.)
        
    
    String permMask = '****-****-****-';
    Set<Id> quoteIDs = new Set<Id>();
    Map<Id, List<zqu__QuoteCharge__c>> quoteChargeMap = new Map<Id, List<zqu__QuoteCharge__c>>();       //id is Quote ID here
    List<CreditCardPaymentGateways__c> ccGatewaysToAllow = [SELECT Gateway__c FROM CreditCardPaymentGateways__c WHERE Approved__c = true];
    List<CreditCardPaymentGateways__c> ccKeepEntireContract = [SELECT Gateway__c FROM CreditCardPaymentGateways__c WHERE KeepCreditCardLengthofContract__c = true];
    
    List<Opportunity> oppsToProcess = new List<Opportunity>();
    List<Opportunity> oppsToUpdate = new List<Opportunity>();
    List<Opportunity> rejectedOpps = new List<Opportunity>();
        
    //get the set of quote IDs so we can get a map of quoteCharges...
    for (Opportunity o : listOpps) {
        if (o.SyncedQuote__r != null) quoteIDs.add(o.SyncedQuote__r.Id);
    }
    
    for (zqu__QuoteCharge__c qc : [SELECT Id, zqu__ChargeType__c, zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__r.Id FROM zqu__QuoteCharge__c WHERE zqu__Quote__c IN :quoteIDs]) {
        if (!quoteChargeMap.containsKey(qc.zqu__Quote__r.zqu__Opportunity__r.Id))  quoteChargeMap.put(qc.zqu__Quote__r.zqu__Opportunity__r.Id, new List<zqu__QuoteCharge__c>());
        quoteChargeMap.get(qc.zqu__Quote__r.zqu__Opportunity__r.Id).add(qc);    
    }
        
    for (Opportunity o : listOpps) {
        //Because we're excluding the failures, the default will be to include the opp...
        Boolean include = true; 
        
       //***** - This exlusion is not needed anymore - CC-2285 ********************************************
       // if ((o.SyncedQuote__r.BrandTag__c == 'RigZone') && (o.SyncedQuote__r.zqu__Currency__c != 'USD')) {
       //     //check the frequency       
       //     if (quoteChargeMap.containsKey(o.Id)) {
       //         for (zqu__QuoteCharge__c qc : quoteChargeMap.get(o.Id)) {
       //             
       //             if (qc.zqu__ChargeType__c != 'One-Time') {
       //                 include = false;
       //                 break;
       //             }                   
       //         }
       //     } 
       //     else include = false;
       // }
       // //This completes the first exception case.
        
       //***** - This exlusion is not needed anymore - CC-2285 ********************************************
       // //Now begins the second exception case...
       // if (o.SyncedQuote__r.BrandTag__c != 'eFC-Amer' && o.SyncedQuote__r.BrandTag__c.startsWith('eFC')) {
       //     //check the frequency       
       //     
       //     if (quoteChargeMap.containsKey(o.Id)) {
       //         for (zqu__QuoteCharge__c qc : quoteChargeMap.get(o.Id)) {
       //             if (qc.zqu__ChargeType__c != 'One-Time') {
       //                 include = false;
       //                 break;
       //             }                   
       //         }
       //     }
       //     else include = false;
       // }
       // //This ends the second use case
        
       //***** - This exlusion is not needed anymore - CC-2285 ******************************************** 
       // //This begins the third exception case (excluding based on payment gateways...)
       // Boolean gatewayExcluded = true;
       // if (ccGatewaysToAllow != null) {
       //     for (CreditCardPaymentGateways__c ccpg : ccGatewaysToAllow) {
       //         if (o.SyncedQuote__r.Payment_Gateway__c.endsWith(ccpg.Gateway__c)) {
       //             gatewayExcluded = false;
       //             break;
       //         }
       //     }
       // }        
       // if (gatewayExcluded == true) include = false;
       // //This ends the third exception case...

       //***** - This exlusion is based on the removed exclusion above - CC-2285 *************************** 
       //***** - the new rules state if the Gateway is on the excluded list then we can purge the CC# 7 days after the contract end date
       if (ccKeepEntireContract != null) {
            for (CreditCardPaymentGateways__c ccpg : ccKeepEntireContract) {
                if (o.SyncedQuote__r.Payment_Gateway__c.endsWith(ccpg.Gateway__c)&& o.SyncedQuote__r.Contract_End_Date_Apex__c > date.today().addDays(-7)) {
                    include = false;
                    break;
                }
            }
       }        
//System.debug('$$$$$$$$$$ : ' + o.Id + ' : ' + include );
        //If include is still true, then we're processing the Opportunity.        
        if (include) oppsToProcess.add(o);              
    } 
    
    for (Opportunity o : oppsToProcess) {       
        if (o.Credit_Card_Number__c != null && o.Credit_Card_Number__c.length() > 3 && (!o.Credit_Card_Number__c.startsWith('****'))) {
            o.Credit_Card_Number__c = permMask + o.Credit_Card_Number__c.substring(o.Credit_Card_Number__c.length() - 4);
            oppsToUpdate.add(o);
        }               
    }           
    
    if (oppsToUpdate.size() > 0) update oppsToUpdate;
  }

}