/***************************************************************************
// (c) 2012 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  zquQuoteChargeTrigger. All contexts should be in this class.
//                  
// Jan 22nd, 2013  :  Naresh Ojha (Appirio Offshore)
// Mar 05th, 2013  :  Naresh Ojha (Appirio Offshore) Modified for T-120997
// 03 June 2013 :: Karun Gangwani changed for // for T-148272
//***************************************************************************/
public with sharing class zquQuoteChargeTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  private static Map<String, String> countryMap; // for T-148272
  
  //Constructor
  public zquQuoteChargeTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

  //On before insert trigger method
  public void OnBeforeInsert (List<zqu__QuoteCharge__c> newList) { 
    SetQuoteChargeRegions(newList);
    setApprovalType(newList);
    SetSalesRepID(newList);   //CC-2668
  } 

  //On before update trigger method
  public void OnBeforeUpdate (Map<ID, zqu__QuoteCharge__c> oldMap, List<zqu__QuoteCharge__c> newList) { 
    SetQuoteChargeRegions(newList);
    setApprovalType(newList);
    SetSalesRepID(newList);   //CC-2668
  }    

  //On after insert trigger method
  public void OnAfterInsert (Map<Id, zqu__QuoteCharge__c> newMap) { 
    CommonUtil.OLIsOnOppty(newMap.values(), 'QuoteCharge', new Set<String>());
  }  

  // On after update trigger method
  public void OnAfterUpdate (Map<Id, zqu__QuoteCharge__c> oldMap, Map<Id, zqu__QuoteCharge__c> newMap) {
    CommonUtil.OLIsOnOppty(newMap.values(), 'QuoteCharge', new Set<String>()); 
  }

  // On after update trigger method
  public void OnAfterDelete (Map<Id, zqu__QuoteCharge__c> oldMap ) {
    SetZeroForNoQuoteChargeOnQuotes(oldMap);
    //CommonUtil.OLIsOnOppty(oldMap.values(), 'QuoteCharge', new Set<String>()); 
  }
  
  //CC-3055 - Moved 'RegionsQuoteChargeTrigger' logic here...
  private void SetQuoteChargeRegions(List<zqu__QuoteCharge__c> newList) {

    Set<String> quoteChrgCountries = new Set<String>();
    Set<String> quoteIds = new Set<String>();
    
    for (zqu__QuoteCharge__c quoteCharge: newList) {
      quoteChrgCountries.add(quoteCharge.Country__c);
      quoteIds.add(quoteCharge.zqu__Quote__c);
    }
      
    List<pw_ccpro__CountryObject__c> countryList = [SELECT Id, Name, Region__c, Region_Energy__c, Sub_Region1__c, Sub_Region2__c FROM pw_ccpro__CountryObject__c WHERE Name IN: quoteChrgCountries];
    List<zqu__QuoteCharge__c> quoteChrgList = [SELECT Id, Sales_Representative__c, Country__c, zqu__Quote__r.Global_Deal__c FROM zqu__QuoteCharge__c WHERE zqu__Quote__c IN :quoteIds];
    List<zqu__Quote__c> quoteList = [Select Id, Global_Deal__c from zqu__Quote__c where Id IN:quoteIds];
      
    for (zqu__QuoteCharge__c qc : newList) {
          
      // Set the country Regions and Sub-Regions
      for (pw_ccpro__CountryObject__c country : countryList) {
        
        if (qc.Country__c == country.Name) {
          if (country.Region__c != null) qc.Region__c = country.Region__c;
                  
          if (country.Region_Energy__c != null) qc.EnergyRegion__c = country.Region_Energy__c;
                  
          if (country.Sub_Region1__c != null) qc.SubRegion1__c = country.Sub_Region1__c;
                  
          if (country.Sub_Region2__c != null) qc.SubRegion2__c = country.Sub_Region2__c;
        }
      }
     
      //I'm pretty sure the global deal logic here isn't necessary and should be removed so I'll just comment it out.
      //I'm leaving it in case if I'm totally wrong... 
      /* if (Trigger.isUpdate){
        // To update Global Deal on the Quote when the Country/Sales Rep fields have been changed on a Quote Charge:
        boolean tempGlobalDeal = false;
        
        if (quoteChrgList.size() > 0){      
          for (zqu__QuoteCharge__c quoteChrg : quoteChrgList){    
            // Look for Global Deal   
              if(quoteChrg.Country__c != null && quoteChrg.Sales_Representative__c != null){
              if(quoteChrgList[0].Country__c != quoteChrg.Country__c){    
                for (zqu__QuoteCharge__c myQC : quoteChrgList){                             
                  if(quoteChrgList[0].Sales_Representative__c != myQC.Sales_Representative__c){
                    tempGlobalDeal = true;
                      break; //Global Deal has been found don't continue iterating
                  }
                  else{
                    tempGlobalDeal = false;                               
                  }
                }
                break;
              } 
              else {
                tempGlobalDeal = false;                 
              }       
               } 
               else {
                tempGlobalDeal = false;           
               }            
           }
           System.Debug(tempGlobalDeal);
           for (zqu__Quote__c quote : quoteList){
             if (quote.Global_Deal__c != tempGlobalDeal){
              System.debug('Global Deal: '+ quote.Global_Deal__c);
              quote.Global_Deal__c = tempGlobalDeal;
              update quote;
              System.debug('Global Deal: '+ quote.Global_Deal__c);  
             }
           }
        }      
      }// End of Global Deal section      */
    }
  }

  //CC-2668
  private void SetSalesRepID(List<zqu__QuoteCharge__c> newList) {

    Map<String, Id> salesRepIdMap = new Map<String, Id>();

    for (User u : [SELECT Name, Id FROM User WHERE IsActive =: true AND Directly_Commissionable__c = :true ORDER BY Name]) {
      if (!salesRepIdMap.containsKey(u.Name)) salesRepIdMap.put(u.Name, u.Id);
    }

    for (zqu__QuoteCharge__c qc : newList) {
      if (qc.Sales_Representative__c != null && qc.Sales_Representative__c != '' && salesRepIdMap.containsKey(qc.Sales_Representative__c)) qc.SalesRepId__c = salesRepIdMap.get(qc.Sales_Representative__c);
    }
  }

  //T-120997: Copy ApporovalType__c
  //Initially created by Apirio upon launch.
  //Modified heavily by Byrnes as part of CPQ4.

  private void setApprovalType (List<zqu__QuoteCharge__c> newList) {
    Set<ID> productRatePlanChargeIDset = new Set<ID>();
    Set<Id> quoteIdSet = new Set<Id>();
    Map<ID, zqu__ProductRatePlanCharge__c> prpcID_prpcMap = new Map<ID, zqu__ProductRatePlanCharge__c>();

    //Map of quote Id to Opportunity object
    Map<Id, Opportunity> quoteIdMap = new Map<Id, Opportunity>();

    //Map of Brand (string) to Brand (object)
    Map<String, Brand__c> brandMap = new Map<String, Brand__c>();
    for (Brand__c brnd : [SELECT Discount_Approval_Threshold__c, Groups_that_Never_Require_Approval__c, Name FROM Brand__c]) {
      if (!brandMap.containsKey(brnd.Name)) brandMap.put(brnd.Name, brnd);
    }

    for (zqu__QuoteCharge__c qc : newList) {
        if (qc.zqu__ProductRatePlanCharge__c <> null) productRatePlanChargeIDset.add(qc.zqu__ProductRatePlanCharge__c);
        if (qc.zqu__Quote__c <> null) quoteIdSet.add(qc.zqu__Quote__c);
    }

    //I need to get the Quote Charge's, Quote's, Opportunity so that I can find the Brand it ties to now...
    for (zqu__Quote__c q : [SELECT Id, zqu__Opportunity__c, zqu__Opportunity__r.Primary_Brand__c FROM zqu__Quote__c WHERE Id IN :quoteIdSet]) {
      if (q.zqu__Opportunity__r != null && q.zqu__Opportunity__r.Primary_Brand__c != null && (!quoteIdMap.containsKey(q.Id))) quoteIdMap.put(q.Id, q.zqu__Opportunity__r);
    }
    
    //getting collection of Product Rate Plan approval types with zProduct details.
    for (zqu__ProductRatePlanCharge__c prpc : [SELECT zqu__ProductRatePlan__r.ApprovalType__c, Id, 
                                                      zqu__productrateplan__r.zqu__zproduct__r.id, 
                                                      zqu__productrateplan__r.zqu__zproduct__r.ProductGroup__c,
                                                      zqu__Model__c
                                                 FROM zqu__ProductRatePlanCharge__c 
                                                 WHERE ID IN : productRatePlanChargeIDset
                                                 AND zqu__ProductRatePlan__r.ApprovalType__c <> null]) {
                                                  
        if (!prpcID_prpcMap.containsKey(prpc.ID)) prpcID_prpcMap.put(prpc.ID, prpc); 
    }

    //Setting approval type
    for (zqu__QuoteCharge__c qc : newList) {

      //first, set the base-line approval as defined in the product catalog.
      if (qc.zqu__ProductRatePlanCharge__c <> null && prpcID_prpcMap.containsKey(qc.zqu__ProductRatePlanCharge__c)) {
        qc.ApprovalType__c  = prpcID_prpcMap.get(qc.zqu__ProductRatePlanCharge__c).zqu__ProductRatePlan__r.ApprovalType__c;

        //Now if it's a discount charge, set approval to none - always! - AND is Excluded to tru - always!
        if (prpcID_prpcMap.get(qc.zqu__ProductRatePlanCharge__c).zqu__Model__c.startsWithIgnoreCase('discount') && quoteIdMap.containsKey(qc.zqu__Quote__c) && brandMap.containsKey(quoteIdMap.get(qc.zqu__Quote__c).Primary_Brand__c)) {
          qc.ApprovalType__c = 'None';
          qc.IsExcludedFromApprovals__c = true;
        }

        //discounts are taken care of now - now go for the auto-approval product groups and edit if necessary
        else if ((!prpcID_prpcMap.get(qc.zqu__ProductRatePlanCharge__c).zqu__Model__c.startsWithIgnoreCase('discount')) && quoteIdMap.containsKey(qc.zqu__Quote__c) && brandMap.containsKey(quoteIdMap.get(qc.zqu__Quote__c).Primary_Brand__c)) {

          Brand__c thisB = brandMap.get(quoteIdMap.get(qc.zqu__Quote__c).Primary_Brand__c);
          String productGroup = prpcID_prpcMap.get(qc.zqu__ProductRatePlanCharge__c).zqu__productrateplan__r.zqu__zproduct__r.ProductGroup__c;
          if (productGroup != null && thisB.Groups_that_Never_Require_Approval__c != null && thisB.Groups_that_Never_Require_Approval__c.containsIgnoreCase(productGroup)) {
            qc.ApprovalType__c = 'None';
            qc.IsExcludedFromApprovals__c = true;   //needed for the discount threshold seeing as they only matter if at least one quote charge has a value of 'false' here.
          }
        }
      }
    }
  }

  //
  private void SetZeroForNoQuoteChargeOnQuotes(Map<ID, zqu__QuoteCharge__c> oldMap) {
    Set<String> quoteIDset = new Set<String>();
    Set<String> optyIDset = new Set<String>();
    //Set<String> quoteIdSet = new Set<String>();
    Map<String, double> groupOfQC_total_map = new Map<String, double>(); 
    List<OpportunityLineItem> oliListToUpsert = new List<OpportunityLineItem>();
    Map<String, PricebookEntry> productNameIdMap = CommonUtil.getProductNameMap();
    if(countryMap == null) { // for T-148272
      countryMap = CommonUtil.getCountryNameIDMap();
    }
    Map<String, Brand__c> brandMap = CommonUtil.getBrandMap();
    Set<String> opptyIDset = new Set<String>();
    Set<String> oliIDset = new Set<String>();
        
    
    for (zqu__QuoteCharge__c qc : oldMap.values()) {
        if (qc.zqu__Quote__c <> null) {
            quoteIDset.add(qc.zqu__Quote__c);
        }
    }

    //Retreiving all the related QuoteCharge to process OLIs
    List<zqu__QuoteCharge__c> quoteChargeList = [SELECT Id, zqu__Quote__c, Country__c, zqu__Total__c,
                                                    zqu__ProductRatePlanCharge__c, 
                                                    zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c, 
                                                    zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c,
                                                    zqu__Quote__r.isSyncing__c,
                                                    zqu__Quote__r.zqu__Opportunity__c,
                                                    zqu__Quote__r.zqu__Opportunity__r.SyncedQuote__c,
                                                    zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode
                                                FROM zqu__QuoteCharge__c
                                                WHERE zqu__Quote__c IN : quoteIDset
                                                AND  zqu__Quote__r.isSyncing__c = true];
    Integer cnt = 0;
    Decimal totalAmount = 0;
    for (zqu__QuoteCharge__c quoteCharge : quoteChargeList) {
        cnt++;
        if (quoteCharge.zqu__Total__c <> null) {
            totalAmount = quoteCharge.zqu__Total__c;
        }
      //Checking weather the country opportunity and Brand should not be null
      if(quoteCharge.Country__c <> null && quoteCharge.zqu__Quote__r.zqu__Opportunity__c <> null && quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c <> null) {
                                    
        if(!groupOfQC_total_map.containsKey(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c)) {
          if(oldMap.keySet().contains(quoteCharge.Id)) {
            groupOfQC_total_map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c, 0);
            
          } else {
            groupOfQC_total_map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c, totalAmount);
          }
        } else {
          groupOfQC_total_map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c,
                                   groupOfQC_total_map.get(
                                         quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                                         quoteCharge.Country__c+'-'+
                                         quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c) + totalAmount
                                   );
        }
      }
    }//End for loop

    OpportunityLineItem oli;
    Set<String> oliExtIDset = new Set<String>();
    Map<String, String> oliExtID_PricebookEntryID_Map = new Map<String, String>();
    Map<String, OpportunityLineItem> oliExtID_oli_Map = new Map<String, OpportunityLineItem>();
    String debugString = '';
    for (zqu__QuoteCharge__c quoteCharge : quoteChargeList) {
      if(quoteCharge.Country__c <> null && quoteCharge.zqu__Quote__r.zqu__Opportunity__c <> null && quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c <> null) {
        oli = new OpportunityLineItem();
        oli.Quantity = 1;
        oli.External_Id__c = quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c;
        oliExtIDset.add(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c);
        
        oli.OpportunityId = quoteCharge.zqu__Quote__r.zqu__Opportunity__c;
        opptyIDset.add(quoteCharge.zqu__Quote__r.zqu__Opportunity__c);

        //Setting total value for OLI
        if(groupOfQC_total_map.containsKey(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c) && 
           groupOfQC_total_map.get(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c) <> 0.00) {
          oli.TotalPrice = groupOfQC_total_map.get(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c);

          oliExtID_PricebookEntryID_Map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c, productNameIdMap.get(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c + '-' + quoteCharge.zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode).ID);
          debugString += '>> From IF first >> ';
        } else {
          oli.TotalPrice = 0.00;
          debugString += '>> From Else first >> ';
          if(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c == null) {
            oliExtID_PricebookEntryID_Map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c, productNameIdMap.get('Unknown' + '-' + quoteCharge.zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode).ID);
            debugString += '>> From Else IF >> ';
          } else {
            oliExtID_PricebookEntryID_Map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c, productNameIdMap.get(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c + '-' + quoteCharge.zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode).ID);
            debugString += '>> From Else else >> ';
          }
        }
        
        //Setting pricebookentry
        if(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c <> null) {
          oli.Brand__c = brandMap.get(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c).ID;
        } else {
          oli.Brand__c = brandMap.get('Unknown').ID;
        }
        //Setting country
        if (quoteCharge.Country__c <> null || quoteCharge.Country__c <> '') {
          oli.Country__c = countryMap.get(quoteCharge.Country__c);
        } else {
          oli.Country__c = countryMap.get('??');
        }
        
        if (!oliExtID_oli_Map.containsKey(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c)) {
          oliExtID_oli_Map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+quoteCharge.Country__c+'-'+quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c, oli);
        }
        //oliListToUpsert.add(oli);
      }
    }

    //To check weather the oli should not get updated with PricebookEntryID olisExistsSet
    Set<String> olisExistsSet = new Set<String>();

    Map<String, String> extID_curISOMap = new Map<String, String>();
    for (OpportunityLineItem ol : [SELECT PricebookEntryID, ID, External_ID__c, Opportunity.CurrencyIsoCode 
                                                    FROM OpportunityLineItem WHERE External_Id__c IN : oliExtIDset]) {
    //for (OpportunityLineItem ol : optyLineItemList) {
      //if(oliExtIDset.contains(ol.External_ID__c)) {
        if(ol.PricebookEntryId == null && 
               oliExtID_oli_Map.containsKey(ol.External_ID__c) &&
               oliExtID_PricebookEntryID_Map.containsKey(ol.External_ID__c)) {
          oliExtID_oli_Map.get(ol.External_ID__c).PricebookEntryId = oliExtID_PricebookEntryID_Map.get(ol.External_ID__c);
        }
        //To check weather the oli should not get updated with PricebookEntryID olisExistsSet
        olisExistsSet.add(ol.External_ID__c);
        extID_curISOMap.put(ol.External_ID__c, ol.Opportunity.CurrencyISOCode);
      //}
    }
    
    oliListToUpsert = new List<OpportunityLineItem>();    
    for (OpportunityLineItem ol : oliExtID_oli_Map.values()) {
      //To check weather the oli should not get updated with PricebookEntryID olisExistsSet
      if(ol.PricebookEntryId == null && oliExtID_PricebookEntryID_Map.containsKey(ol.External_ID__c)
             && !olisExistsSet.contains(ol.External_ID__c)) {
        ol.PricebookEntryId = oliExtID_PricebookEntryID_Map.get(ol.External_ID__c);
      } else if (ol.PricebookEntryId == null && !olisExistsSet.contains(ol.External_ID__c) &&
                    extID_curISOMap.containsKey(ol.External_ID__c) && 
                    productNameIdMap.containsKey('Unknown' + '-' + extID_curISOMap.get(ol.External_ID__c))) {
        ol.PricebookEntryId = productNameIdMap.get('Unknown' + '-' + extID_curISOMap.get(ol.External_ID__c)).ID; 
      }
      oliListtoUpsert.add(ol);
    }
    TriggerProcessControl.inRecursiveCall = true;
    List<Database.upsertResult> uResults = Database.upsert(oliListToUpsert, OpportunityLineItem.External_Id__c);
    for(Database.upsertResult result : uResults) {
      if(result.isSuccess()) {
        oliIDset.add(result.getId());
      }
    }
    
    
    //Using same list to upsert for other OLIs which were not impacted from upsert
    //Byrnes comment, 2015.09.21 as part of diagnosing TOO MANY SOQL on the ZuoraQuote page:
    // The following two lines assigning to 'oliListToUpsert' were both being executed - not clue why.
    // Clearly the first is a total waste of a precious SOQL statement as it's immediately being reset.
    // I'm commenting it out now with hopes that we can dive into this in more detail in a future sprint and fix the mess that is here.
    
    //oliListToUpsert = [Select UnitPrice, OpportunityId, Id From OpportunityLineItem WHERE OpportunityID IN: opptyIDset AND ID NOT IN: oliIDset];
    oliListToUpsert = new List<OpportunityLineItem>();//new
    
    for (OpportunityLineItem ol : oliListToUpsert) {
       ol.UnitPrice = 0.00;
    }
    if(!oliListToUpsert.isEmpty()) {
      update oliListToUpsert;
    }       
  }  
}