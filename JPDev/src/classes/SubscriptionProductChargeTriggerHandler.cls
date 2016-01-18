/***
*Class          ---- SubscriptionProductChargeTriggerHandler
*Author         ---- Naresh Ojha
*Story          ---- Initial Implementation
*Created Date   ---- 2013.02.08
*Description    ---- Trigger handler for Zuora's Subscription Product Charge (zContractLineItem) object
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Tim Byrnes
*Story          ---- CCBOB-148
*Modified Date  ---- 2015.11.30
*Description    ---- Altered method 'populateCustomFields' to populate the custom fields on this object, specifically the Account Brand lookup.
***/

public with sharing class SubscriptionProductChargeTriggerHandler {
    private boolean m_isExecuting = false;  
    private integer BatchSize = 0;
    
    //Constructor
    public SubscriptionProductChargeTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    
    //On before insert trigger method
    public void OnBeforeInsert(List<Zuora__SubscriptionProductCharge__c> newList) { 
        populateCustomFields (newList); 
    }  
    // On before update trigger method
    public void OnBeforeUpdate (Map<Id, Zuora__SubscriptionProductCharge__c> oldMap, Map<Id, Zuora__SubscriptionProductCharge__c> newMap) {
        populateCustomFields (newMap.values()); 
    }
    
    // On before delete trigger method
    public void OnBeforeDelete (Map<Id, Zuora__SubscriptionProductCharge__c> oldMap) {
        Set<String> acIDset = new Set<String>();

        for (Zuora__SubscriptionProductCharge__c spc : oldMap.values()) {
            if (spc.Zuora__Account__c <> null) acIDset.add(spc.Zuora__Account__c);
        } 

        if (!acIDset.isEmpty()) CommonUtil.recallABstatus(acIDset, true);
    }
        
        //On after insert trigger method
    public void OnAfterInsert(List<Zuora__SubscriptionProductCharge__c> newList) { 
        Set<String> acIDset = new Set<String>();

        for (Zuora__SubscriptionProductCharge__c spc : newList) {
            if (spc.Zuora__Account__c <> null) acIDset.add(spc.Zuora__Account__c);
        } 

        if (!acIDset.isEmpty()) CommonUtil.recallABstatus(acIDset, true);

        //CC-911
        UpdateAccountBrandLastSoldDetails(newList);
    }  

    // On before update trigger method
    public void OnAfterUpdate (Map<Id, Zuora__SubscriptionProductCharge__c> oldMap, Map<Id, Zuora__SubscriptionProductCharge__c> newMap) {
        Set<String> acIDset = new Set<String>();

        for (Zuora__SubscriptionProductCharge__c spc : newMap.values()) {
            if (spc.Zuora__Account__c <> null) acIDset.add(spc.Zuora__Account__c);
        }

        if (!acIDset.isEmpty()) CommonUtil.recallABstatus(acIDset, true);

        //CC-911
        UpdateAccountBrandLastSoldDetails(newMap.values());     
    }  
    
    private string ConvertBrandTagToBrand(String brandTagValue) {
        if ((brandTagValue != null) && (brandTagValue.startsWith('eFC'))) return 'eFinancialCareers';
        else return brandTagValue;
    }

    //CC-911 - Opp Close Date drives the 'most recent'
    private void UpdateAccountBrandLastSoldDetails(List<Zuora__SubscriptionProductCharge__c> newList) {

        //map of account brand records --> each item in this newList collection
        Map<String, Zuora__SubscriptionProductCharge__c> abMapToLineItem = new Map<String, Zuora__SubscriptionProductCharge__c>();  //String is accountid + '_' + brand text
        Map<String, Account_Brand__c> abIDtoABMap = new Map<String, Account_Brand__c>();
        Set<Id> AccountIDsInPlay = new Set<Id>();
        Set<Id> ZContractIDsInPlay = new Set<Id>();
        Set<Id> ZProductRatePlansInPlay = new Set<Id>();
        Map<Id, zqu__ProductRatePlan__c> ratePlanToProductGroupMap = new Map<Id, zqu__ProductRatePlan__c>();  //key is the zsubLine.Product_Rate_Plan__c, value is the object (zqu__ProductRatePlan__c)
        Map<String, Opportunity> zContractToOppMap = new Map<String, Opportunity>();  //key is the AccountID_zContractID, value is the Opp info
        Map<String, MostRecentPurchaseProductHierarchy__c> productHierarchyMap = new Map<String, MostRecentPurchaseProductHierarchy__c>();  //key is the productGroup, value is the sort order as defined in the custom settings object, 'Most Recent Purchase Product Hierarchy'.   Note that these are not brand specific.

        Set<String> ABMapKeysToUpdate = new Set<String>();
        List<Account_Brand__c> ABsToUpdate = new List<Account_Brand__c>();

        for (MostRecentPurchaseProductHierarchy__c mrpph : [SELECT Sort_Order__c, Name FROM MostRecentPurchaseProductHierarchy__c order by Sort_Order__c]) {
            if (!productHierarchyMap.containsKey(mrpph.Name)) productHierarchyMap.put(mrpph.Name, mrpph);
        }

        //populate the maps
        for (Zuora__SubscriptionProductCharge__c zsubLine : newList) {
            AccountIDsInPlay.add(zsubLine.Zuora__Account__c);
            ZContractIDsInPlay.add(zsubLine.Zuora__Subscription__c);
            ZProductRatePlansInPlay.add(zsubLine.Product_Rate_Plan__c);
        }

        //Map of the zContracts for the BrandTag...
        Map<Id, Zuora__Subscription__c> zContractMap = new Map<Id, Zuora__Subscription__c>([SELECT Id, BrandTag__c FROM Zuora__Subscription__c WHERE Id IN :ZContractIDsInPlay]);    

        //populate the maps
        for (Zuora__SubscriptionProductCharge__c zsubLine : newList) {
            if ((zContractMap.containsKey(zsubLine.Zuora__Subscription__c)) && (!abMapToLineItem.containsKey(zsubLine.Zuora__Account__c + '_' + ConvertBrandTagToBrand(zContractMap.get(zsubLine.Zuora__Subscription__c).BrandTag__c)))) abMapToLineItem.put((zsubLine.Zuora__Account__c + '_' + ConvertBrandTagToBrand(zContractMap.get(zsubLine.Zuora__Subscription__c).BrandTag__c)), zsubLine);
        }

        for (zqu__ProductRatePlan__c zRatePlan : [SELECT zqu__ZProduct__r.ProductGroup__c, zqu__ZProduct__r.Name, Id FROM zqu__ProductRatePlan__c WHERE Id IN : ZProductRatePlansInPlay]) {
            if ((zRatePlan.zqu__ZProduct__r != null) && (!ratePlanToProductGroupMap.containsKey(zRatePlan.Id))) ratePlanToProductGroupMap.put(zRatePlan.Id, zRatePlan);
        }
        //We have the product details now in the map

        //Get the Opportunity details now
        for (Opportunity o : [SELECT 
                                    Id,                             
                                    CloseDate, 
                                    Sold_By_Partner__c, 
                                    Sold_By_Partner__r.Name, 
                                    Net_Amount__c, 
                                    ZuoraSubscription__c, 
                                    ZuoraSubscription__r.CurrencyIsoCode, 
                                    ZuoraSubscription__r.Zuora__TermStartDate__c, 
                                    ZuoraSubscription__r.ServiceEndDate__c,
                                    AccountId
                                FROM Opportunity 
                                WHERE ZuoraSubscription__c IN : ZContractIDsInPlay]) {
            if (!zContractToOppMap.containsKey(o.AccountId + '_' + o.ZuoraSubscription__c)) zContractToOppMap.put(o.AccountId + '_' + o.ZuoraSubscription__c, o);
        }

        //get all accountBrand records in play...  (This selects more than we need - we filter by adding to the map)
        for (Account_Brand__c ab : [SELECT 
                                        Account__c, 
                                        Name, 
                                        Brand_Picklist__c, 
                                        MostRecentOrderOpp__c,
                                        MostRecentOrderOpp__r.CloseDate, 
                                        MostRecentOrderOpp__r.Id, 
                                        MostRecentOrderOpp__r.Sold_By_Partner__r.Name, 
                                        Primary_Product__c, 
                                        Contract_Currency__c, 
                                        Service_Start_Date__c, 
                                        Service_End_Date__c, 
                                        Net_Contract_Amount__c,
                                        Id,
                                        Is_Webstore_Order__c 
                                    FROM Account_Brand__c
                                    WHERE Account__c IN :AccountIDsInPlay]) {
            if ((abMapToLineItem.containsKey(ab.Account__c + '_' + ab.Brand_Picklist__c)) && (!abIDtoABMap.containsKey(ab.Account__c + '_' + ab.Brand_Picklist__c))) abIDtoABMap.put(ab.Account__c + '_' + ab.Brand_Picklist__c, ab);
        }

        //All the data is now collected in maps - now we can iterate over the newList, check values and update where/when necessary...

        for (Zuora__SubscriptionProductCharge__c zsub : newList) {

            //get the account brand record
            Account_Brand__c thisAB;
            Boolean isWS;

            if (abIDtoABMap.containsKey(zsub.Zuora__Account__c + '_' + ConvertBrandTagToBrand(zContractMap.get(zsub.Zuora__Subscription__c).BrandTag__c))) thisAB = abIDtoABMap.get(zsub.Zuora__Account__c + '_' + ConvertBrandTagToBrand(zContractMap.get(zsub.Zuora__Subscription__c).BrandTag__c));

            try {

                if ((thisAB != null)                    
                    && (zContractToOppMap.containsKey(zsub.Zuora__Account__c + '_' + zsub.Zuora__Subscription__c))
                    && (ConvertBrandTagToBrand(zContractMap.get(zsub.Zuora__Subscription__c).BrandTag__c) == thisAB.Brand_Picklist__c)
                    && (zsub.Zuora__Account__c == thisAB.Account__c)
                    && (
                            (thisAB.MostRecentOrderOpp__c == null) 
                            || (zContractToOppMap.get(zsub.Zuora__Account__c + '_' + zsub.Zuora__Subscription__c).ZuoraSubscription__r.ServiceEndDate__c > thisAB.Service_End_Date__c)
                            || (
                                    (zContractToOppMap.get(zsub.Zuora__Account__c + '_' + zsub.Zuora__Subscription__c).ZuoraSubscription__r.ServiceEndDate__c == thisAB.Service_End_Date__c) 
                                        && (ratePlanToProductGroupMap.get(zsub.Product_Rate_Plan__c) != null) 
                                        && (ratePlanToProductGroupMap.get(zsub.Product_Rate_Plan__c).zqu__ZProduct__c != null) 
                                        && (productHierarchyMap.get(thisAB.Primary_Product__c).Sort_Order__c) > productHierarchyMap.get(ratePlanToProductGroupMap.get(zsub.Product_Rate_Plan__c).zqu__ZProduct__r.ProductGroup__c).Sort_Order__c
                                )
                         ) 
                    ) {
                    
                        thisAB.MostRecentOrderOpp__c = zContractToOppMap.get(zsub.Zuora__Account__c + '_' + zsub.Zuora__Subscription__c).Id;                    

                        if (ratePlanToProductGroupMap.containsKey(zsub.Product_Rate_Plan__c)) thisAB.Primary_Product__c = ratePlanToProductGroupMap.get(zsub.Product_Rate_Plan__c).zqu__ZProduct__r.ProductGroup__c;
                        else thisAB.Primary_Product__c = '';                    

                        thisAB.Contract_Currency__c = zContractToOppMap.get(zsub.Zuora__Account__c + '_' + zsub.Zuora__Subscription__c).ZuoraSubscription__r.CurrencyIsoCode;                   

                        thisAB.Net_Contract_Amount__c = zContractToOppMap.get(zsub.Zuora__Account__c + '_' + zsub.Zuora__Subscription__c).Net_Amount__c;                    

                        thisAB.Service_Start_Date__c = zContractToOppMap.get(zsub.Zuora__Account__c + '_' + zsub.Zuora__Subscription__c).ZuoraSubscription__r.Zuora__TermStartDate__c;                  

                        thisAB.Service_End_Date__c = zContractToOppMap.get(zsub.Zuora__Account__c + '_' + zsub.Zuora__Subscription__c).ZuoraSubscription__r.ServiceEndDate__c;

                        thisAB.Sold_By_Partner__c = zContractToOppMap.get(zsub.Zuora__Account__c + '_' + zsub.Zuora__Subscription__c).Sold_By_Partner__r.Name;
                        
                        //if the rate plan id is in the map of objects, the relationship to product is not null, and that relationship zProduct name starts with 'Webstore', then it's a webstore order.
                        if ((ratePlanToProductGroupMap.containsKey(zsub.Product_Rate_Plan__c)) && (ratePlanToProductGroupMap.get(zsub.Product_Rate_Plan__c).zqu__ZProduct__r != null) && (ratePlanToProductGroupMap.get(zsub.Product_Rate_Plan__c).zqu__ZProduct__r.Name.startsWith('Webstore'))) isWS = true;
                        else isWS = false;

                        thisAB.Is_Webstore_Order__c = isWS;

                        ABMapKeysToUpdate.add(zsub.Zuora__Account__c + '_' + ConvertBrandTagToBrand(zContractMap.get(zsub.Zuora__Subscription__c).BrandTag__c));

                        //put this updated record back in the map so things are current when compared with in the next iteration of the loop...
                        abIDtoABMap.put(zsub.Zuora__Account__c + '_' + ConvertBrandTagToBrand(zContractMap.get(zsub.Zuora__Subscription__c).BrandTag__c), thisAB);
                }
            }
            catch (Exception e) {
                system.debug('&&&&&&&&&&&&&&&&&& - Exception! ' + e.getMessage());
            }
        }

        for (String s : ABMapKeysToUpdate) {
            ABsToUpdate.add(abIDtoABMap.get(s));
        }

        if (ABsToUpdate.size() > 0) update ABsToUpdate;
    }

    //Populate product rate plan on subscription product charge.
    //And the account brand lookup in one fell swoop.  CCBOB-148
    private void populateCustomFields (List<Zuora__SubscriptionProductCharge__c> newList) {
        Set<String> ratePlanNameSet = new Set<String>();
        Set<String> productNameSet = new Set<String>();
        Set<String> productSKUSet = new Set<String>();
                
        Map<String, zqu__ProductRatePlan__c> ratePlanProdName_ProductRatePlanID_Map = new Map<String, zqu__ProductRatePlan__c>(); 
        Map<Id, zqu__ProductRatePlan__c> ratePlanId_ratePlanObject_Map = new Map<Id, zqu__ProductRatePlan__c>();                    //to be used for setting the Account_Brand field, not the product rate plan.

        for (Zuora__SubscriptionProductCharge__c spc : newList) {
            
            //Populating rateplan set
            if (spc.Zuora__RatePlanName__c <> null) ratePlanNameSet.add(spc.Zuora__RatePlanName__c);

            //Populating product name set.
            if (spc.Zuora__ProductName__c <> null) productNameSet.add(spc.Zuora__ProductName__c);

            //Populating product SKU set
            if (spc.Zuora__ProductSKU__c <> null || spc.Zuora__ProductSKU__c <> '') productSKUSet.add(spc.Zuora__ProductSKU__c);        
        }
        
        for (zqu__ProductRatePlan__c prp : [SELECT 
                                                Name, 
                                                Id, 
                                                Brand__c, 
                                                zqu__ZProduct__c,                                                 
                                                zqu__ZProduct__r.zqu__SKU__c,
                                                zqu__ZProduct__r.Name, 
                                                zqu__ZProduct__r.Id
                                            FROM zqu__ProductRatePlan__c 
                                            WHERE   Name IN : ratePlanNameSet AND
                                                    (zqu__ZProduct__r.Name IN: productNameSet OR zqu__ZProduct__r.zqu__SKU__c IN:productSKUSet)] ) {

                if (!ratePlanProdName_ProductRatePlanID_Map.containsKey(prp.Name+'-'+prp.zqu__ZProduct__r.Name)) ratePlanProdName_ProductRatePlanID_Map.put(prp.Name+'-'+prp.zqu__ZProduct__r.Name, prp);
                if (!ratePlanId_ratePlanObject_Map.containsKey(prp.Id)) ratePlanId_ratePlanObject_Map.put(prp.Id, prp);
        }

        //Get the account & account brand values for consideration...
        Set<Id> accountIdsInPlay = new Set<Id>();
        Map<String, Account> accountMap = new Map<String, Account>();   //for the account brand

        for (Zuora__SubscriptionProductCharge__c spc : newList) {
            if (spc.Zuora__Account__c != null) accountIdsInPlay.add(spc.Zuora__Account__c);
        }

        for (Account a : [SELECT Id, (SELECT Id, Brand_Name__c FROM Account_Brands__r) FROM Account WHERE Id IN :accountIdsInPlay ]) {
            accountMap.put(a.Id, a);
        }
        //Done gathering data...

        //Now that we have all the data collected and organized we can set the values:
        for (Zuora__SubscriptionProductCharge__c spc : newList) {


            //Set the 'Product Rate Plan' value
            if (spc.Zuora__RatePlanName__c <> null && spc.Zuora__ProductName__c <> null) {
                    if (ratePlanProdName_ProductRatePlanID_Map.containsKey(spc.Zuora__RatePlanName__c+'-'+spc.Zuora__ProductName__c)) spc.Product_Rate_Plan__c = ratePlanProdName_ProductRatePlanID_Map.get(spc.Zuora__RatePlanName__c+'-'+spc.Zuora__ProductName__c).id;                
            }


            //Set the Account Brand lookup now...  (CCBOB-148)
            if (spc.Zuora__Account__c != null && accountMap.containsKey(spc.Zuora__Account__c) && spc.Product_Rate_Plan__c != null && (ratePlanId_ratePlanObject_Map.containsKey(spc.Product_Rate_Plan__c) || spc.Product_Rate_Plan__c!=null)) {

                //For each account brand record for the applicable account
                for (Account_Brand__c ab : accountMap.get(spc.Zuora__Account__c).Account_Brands__r) {

                    if ((spc.brand__c!=null && ab.Brand_Name__c.equalsIgnoreCase(spc.Brand__c)) || (ratePlanId_ratePlanObject_Map.containsKey(spc.Product_Rate_Plan__c) && ab.Brand_Name__c.equalsIgnoreCase(ratePlanId_ratePlanObject_Map.get(spc.Product_Rate_Plan__c).Brand__c))) {
                        spc.Account_Brand__c = ab.Id;
                        break;  //no use looping more if we've found the match.  Time to bug out of this for loop...
                    }
                }
            }
            else system.debug('### - Unable to populate Account Brand lookup at this time as the Zuora__Account__c field is null.  D\'oh!');
        
        }
    }

}