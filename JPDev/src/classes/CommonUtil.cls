/***************************************************************************
// (c) 2012 Appirio, Inc.
//
// Description    : Class that contains common Utility Functions
//                  
// Jan 09th, 2013  :  Naresh Ojha (Appirio Offshore)
// 06 June 2013    :  Karun Gangwani updated for I-55196
//***************************************************************************/
public with sharing class CommonUtil {
    public String UnknownCountryID;
    public String UnknownProductID;
    public String UNKNOWN = 'Unknown';
    public static Map<String, Brand__c> brandMap = getBrandMap();
    public static List<PricebookEntry> PBEList = getPBEList();
    public static List<pw_ccpro__CountryObject__c> countryList = getCountryList();
    
    // Constructor     
    public CommonUtil() {
        UnknownCountryID = [SELECT ID FROM pw_ccpro__CountryObject__c WHERE  pw_ccpro__IsoCode_2__c = '??'].ID;
        UnknownProductID = [SELECT ID From Product2 Where External_Id__c = 'UNKNOWN'].ID;
    }
    
    //Returns brand map with key Brand name and object of Brand
      public static Map<String, Brand__c> getBrandMap() {
        Map<String, Brand__c> brand_Map = new Map<String, Brand__c>();
        for(Brand__c br : [SELECT Id, Name, External_Id__c, isActive__c, isMigrated__c FROM Brand__c]) {
          if(!brand_Map.containsKey(br.Name)) {
            brand_Map.put(br.Name, br);
          }
        }
        return brand_Map;
      }
      
      //Returns the Pricebook Entry List
      public static List<PricebookEntry> getPBEList() {
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
        for(PricebookEntry pbe : [SELECT Product2.Name, Product2.Id, Product2Id, Id, CurrencyIsoCode 
                                  FROM PricebookEntry 
                                  //WHERE CurrencyIsoCode = 'USD' 
                                  Limit 10000]) {
          pbEntryList.add(pbe);   
        }
        return pbEntryList;
      }
  
    // returns the pw_ccpro__CountryObject__c list
    public static List<pw_ccpro__CountryObject__c> getCountryList() {
        List<pw_ccpro__CountryObject__c> cList = new List<pw_ccpro__CountryObject__c>();
        for(pw_ccpro__CountryObject__c pco : [SELECT ID, Name 
                                              FROM pw_ccpro__CountryObject__c Limit 5000]) {
        cList.add(pco);
      }
      return cList;
    }
    
    //----------------------------------------------------------------------------
    // Method that assigns the job title to Lead, Contact
    // T-108395: Assign job title
    //----------------------------------------------------------------------------
    public static void AssignJobTitle(List<Sobject> newList, Map<Id, Sobject> oldMap, 
                                      String entityName) {
   Set<String> jobTitleSet = new Set<String>();
   Map<String, String> jtName_jtID_Map = new Map<String, String>(); 
   
   Lead newLead;
   Contact newContact;
   Lead oldLead;
   Contact oldContact;
    
    if(entityName == 'Lead') {
        
        for(Sobject sObj : newList) {
            newLead = (Lead)sObj;
          if(newLead.Title <> null) {
            jobTitleSet.add(newLead.Title);
          }
        }
        
        for(Job_Title__c jt : [SELECT ID, Name FROM Job_Title__c WHERE Name IN : jobTitleSet]) {
          if(!jtName_jtID_Map.containsKey(jt.Name)) {
            jtName_jtID_Map.put(jt.Name, jt.ID);
          }
        }
        //Populating Job title reference field    
        for(Sobject sObj : newList) {
            newLead = (Lead)sObj;
          //In case insert
          if(oldMap == null || oldMap.isEmpty()) {          
            if(newLead.Job_Title__c == null && newLead.Title <> null && 
               jtName_jtID_Map.containsKey(newLead.Title)) {
              newLead.Job_Title__c = jtName_jtID_Map.get(newLead.Title);
            }
          } else { //in case Edit
            oldLead = (Lead)(oldMap.get(newLead.ID)); 
            if(newLead.Title <> null &&            
               newLead.Title <> oldLead.Title && 
               jtName_jtID_Map.containsKey(newLead.Title)) newLead.Job_Title__c = jtName_jtID_Map.get(newLead.Title);
            
          }
        }    
    }   else if(entityName == 'Contact') {
          for(Sobject sObj : newList) {
            newContact = (Contact)sObj;
            if(newContact.Title <> null) {
              jobTitleSet.add(newContact.Title);
            }
          }
          
          for(Job_Title__c jt : [SELECT ID, Name FROM Job_Title__c 
                               WHERE Name IN : jobTitleSet]) {
            if(!jtName_jtID_Map.containsKey(jt.Name)) {
              jtName_jtID_Map.put(jt.Name, jt.ID);
            }
          }
          //Populating Job title reference field    
          for(Sobject sObj : newList) {
            newContact = (Contact)sObj;
            //In case insert
            if(oldMap == null || oldMap.isEmpty()) {          
              if(newContact.Job_Title__c == null && newContact.Title <> null && 
                 jtName_jtID_Map.containsKey(newContact.Title)) {
                newContact.Job_Title__c = jtName_jtID_Map.get(newContact.Title);
              }
            } else { //in case Edit
                oldContact = (Contact)(oldMap.get(newContact.ID));
              if(newContact.Title <> null && 
                 newContact.Title <> oldContact.Title && 
                 jtName_jtID_Map.containsKey(newContact.Title)) newContact.Job_Title__c = jtName_jtID_Map.get(newContact.Title);
              
            }
          }    
    }       
    }

  //T-105259: Sync Line Items from Quote to Opportunity
  public static void OLIsOnOppty (List<sObject> sObjectList, String sObjName, Set<String> quoteIDs) {
    Set<String> quoteIdSet = new Set<String>();
    Map<String, double> groupOfQC_total_map = new Map<String, double>(); 
    List<OpportunityLineItem> oliListToUpsert = new List<OpportunityLineItem>();
    Map<String, PricebookEntry> productNameIdMap = getProductNameMap();
    Map<String, String> countryMap = getCountryNameIDMap();
    String saleType;

    //Map<String, Brand__c> brandMap = getBrandMap();
    Set<String> opptyIDset = new Set<String>();
    Set<String> oliIDset = new Set<String>();    
    zqu__Quote__c quote = new zqu__Quote__c();
    zqu__QuoteCharge__c quoteChrg = new zqu__QuoteCharge__c();
    
    if(quoteIDs.isEmpty()) {
        if (sObjName == 'Quote') {
            for (sObject qt : sObjectList) {
                quote = (zqu__Quote__c)qt;
                quoteIdSet.add(quote.ID);
            }
        } else if(sObjName == 'QuoteCharge') {
          for (sObject qt : sObjectList) {
            quoteChrg = (zqu__QuoteCharge__c)qt;
            quoteIdSet.add(quoteChrg.zqu__Quote__c);
          }
        }
    } else quoteIdSet.addAll(quoteIDs);
    
    system.debug('quoteIdSet :: ' + quoteIdSet);
    //Retreiving all the related QuoteCharge to process OLIs
    //added the product group selection & BrandTag on 2014.07.29 as part of CC-2768 - Byrnes
    List<zqu__QuoteCharge__c> quoteChargeList = [SELECT Id, zqu__Quote__c, Country__c, zqu__Total__c, zqu__TCV__c, Sale_Type__c,
                                                    zqu__ProductRatePlanCharge__c, 
                                                    zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c, 
                                                    zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c,
                                                    zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c,
                                                    zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__c,
                                                    zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c,
                                                    zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c,
                                                    zqu__Quote__r.isSyncing__c,
                                                    zqu__Quote__r.zqu__Opportunity__c,
                                                    zqu__Quote__r.zqu__Opportunity__r.SyncedQuote__c,
                                                    zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode,
                                                    zqu__Quote__r.zqu__Subscription_Term_Type__c,
                                                                            zqu__Type__c,
                                                                            PRR__c
                                                FROM zqu__QuoteCharge__c
                                                WHERE zqu__Quote__c IN : quoteIdSet
                                                AND  zqu__Quote__r.isSyncing__c = true];
    Decimal totalAmount = 0;

    for (zqu__QuoteCharge__c quoteCharge : quoteChargeList) {
      
      if (quoteCharge.zqu__Quote__r.zqu__Subscription_Term_Type__c == 'Termed') {
        
          //If one-time use total
          if (quoteCharge.zqu__Type__c == 'One-Time') {
              if(quoteCharge.zqu__Total__c <> null) totalAmount = quoteCharge.zqu__Total__c;
              else totalAmount = 0;
          }
          //else not one-time (recurring, etc) use TCV
          else {
              if(quoteCharge.zqu__TCV__c <> null) totalAmount = quoteCharge.zqu__TCV__c;
              else totalAmount = 0;             
          }
      }
      //termed logic above, 'Evergreen' logic below... 
      //If evergreen always use PRR (Period Reccuring revenue)
      else {
        if(quoteCharge.PRR__c <> null) totalAmount = quoteCharge.PRR__c;
        else totalAmount = 0;
      }
  

      //Checking whether the country opportunity and Brand should not be null - and the brandtag and product group, sub category & sale type
      if (quoteCharge.Country__c <> null && quoteCharge.zqu__Quote__r.zqu__Opportunity__c <> null && 
              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c <> null && 
              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c <> null && 
              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c <> null &&
              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c <> null) {

          if (quoteCharge.Sale_Type__c == null) saleType = '';
          else saleType = quoteCharge.Sale_Type__c.toLowerCase();
                                    
          if (!groupOfQC_total_map.containsKey(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                quoteCharge.Country__c+'-'+
                quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType)) {

            groupOfQC_total_map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                                          quoteCharge.Country__c+'-'+
                                          quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                                          quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                                          quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                                          quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType, totalAmount);
          } 
          else { 
            groupOfQC_total_map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                                          quoteCharge.Country__c+'-'+
                                          quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                                          quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                                          quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                                          quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType,                                        

                                     groupOfQC_total_map.get(
                                           quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                                           quoteCharge.Country__c+'-'+
                                           quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                                           quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                                           quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                                           quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType) + totalAmount
                                     );
          }
      }
    }//End for loop
    
    OpportunityLineItem oli;
    Set<String> oliExtIDset = new Set<String>();
    Map<String, String> oliExtID_PricebookEntryID_Map = new Map<String, String>();
    Map<String, OpportunityLineItem> oliExtID_oli_Map = new Map<String, OpportunityLineItem>();
    for (zqu__QuoteCharge__c quoteCharge : quoteChargeList) {
        if (quoteCharge.Country__c <> null && quoteCharge.zqu__Quote__r.zqu__Opportunity__c <> null && 
              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c <> null && 
              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c <> null && 
              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c <> null && 
              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c <> null) {

            if (quoteCharge.Sale_Type__c == null) saleType = '';
            else saleType = quoteCharge.Sale_Type__c.toLowerCase();

            oli = new OpportunityLineItem();
            oli.Quantity = 1;
            oli.External_Id__c = quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                                    quoteCharge.Country__c+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType;

            oliExtIDset.add(oli.External_Id__c);

            oli.OpportunityId = quoteCharge.zqu__Quote__r.zqu__Opportunity__c;
            opptyIDset.add(quoteCharge.zqu__Quote__r.zqu__Opportunity__c);

            if (quoteCharge.zqu__Quote__r.zqu__Opportunity__c <> null && quoteCharge.Country__c <> null && 
                  quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c <> null && 
                  quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c <> null && 
                  quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c <> null &&
                  quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c <> null && 
                  productNameIdMap.get(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c + '-' + quoteCharge.zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode) <> null && 
                  !oliExtID_PricebookEntryID_Map.containsKey(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                      quoteCharge.Country__c+'-'+
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType) && 

                  groupOfQC_total_map.get(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                      quoteCharge.Country__c+'-'+
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType) <> null) {
                
          //Total amount
              oli.TotalPrice = groupOfQC_total_map.get(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                                    quoteCharge.Country__c+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+                                    
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType);
          //Pricebook entry map
              oliExtID_PricebookEntryID_Map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                                    quoteCharge.Country__c+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType, 
                                    productNameIdMap.get(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c + '-' + quoteCharge.zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode).ID);
            } else {
            oli.TotalPrice = 0.00;
            if (quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c == null) {
                oliExtID_PricebookEntryID_Map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                                    quoteCharge.Country__c+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                                    quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType, 

                                    productNameIdMap.get('Unknown' + '-' + quoteCharge.zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode).ID);
            } else {
                if (quoteCharge.zqu__Quote__r.zqu__Opportunity__c <> null && quoteCharge.Country__c <> null && 
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c <> null && 
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c <> null && 
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c <> null &&
                      quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c <> null &&
                    productNameIdMap.containsKey(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c + '-'+ 
                                    quoteCharge.zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode) && 
                                    productNameIdMap.get(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c+'-'+
                                      quoteCharge.zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode).ID <> null) {
                    
                    oliExtID_PricebookEntryID_Map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                              quoteCharge.Country__c+'-'+
                              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                              quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType, 

                              productNameIdMap.get(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c+'-'+quoteCharge.zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode).ID);
                }
            }
            }
            
            //Setting pricebookentry
            
            if(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c <> null &&
                brandMap.containsKey(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c) &&
                brandMap.get(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c).ID <> null) {
                
                oli.Brand__c = brandMap.get(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c).ID;
                //oli.PricebookEntryId = productNameIdMap.get(quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c + '-' + quoteCharge.zqu__Quote__r.zqu__Opportunity__r.CurrencyIsoCode).ID;
            } else if (brandMap.containsKey('Unknown')) {
                oli.Brand__c = brandMap.get('Unknown').ID;
            }

            //Setting country
            if (quoteCharge.Country__c <> null || quoteCharge.Country__c <> '') oli.Country__c = countryMap.get(quoteCharge.Country__c);
            else oli.Country__c = countryMap.get('??');

            //Setting the BrandTag
            if (quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c <> null && quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c <> '') oli.BrandTag__c = quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c;

            //Setting the Product Group
            if (quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c <> null && quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c <> '') oli.Product_Group__c = quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c;

            //Setting the Product Sub Category
            if (quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c <> null && quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c <> '') oli.Sub_Category__c = quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c;

            //Setting the Sale Type
            if (quoteCharge.Sale_Type__c <> null) oli.Sale_Type__c = quoteCharge.Sale_Type__c;
            else oli.Sale_Type__c = '';

            if (!oliExtID_oli_Map.containsKey(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                        quoteCharge.Country__c+'-'+
                        quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                        quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                        quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                        quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType)) {

                oliExtID_oli_Map.put(quoteCharge.zqu__Quote__r.zqu__Opportunity__c+'-'+
                        quoteCharge.Country__c+'-'+
                        quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c.toLowerCase()+'-'+
                        quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c.toLowerCase()+'-'+
                        quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c.toLowerCase()+'-'+
                        quoteCharge.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c.toLowerCase()+'-'+saleType, oli);
            }          
            //oliListToUpsert.add(oli);
        }
    }
    //To check weather the oli should not get updated with PricebookEntryID olisExistsSet
    Set<String> olisExistsSet = new Set<String>();
    
    Map<String, String> extID_curISOMap = new Map<String, String>();
    if (oliExtIDset.size() > 0) {
        for (OpportunityLineItem ol : [SELECT PricebookEntryID, ID, External_ID__c, Opportunity.CurrencyIsoCode FROM OpportunityLineItem WHERE External_Id__c IN : oliExtIDset]) {
                if (ol.PricebookEntryId == null && 
                       oliExtID_oli_Map.containsKey(ol.External_ID__c) &&
                       oliExtID_PricebookEntryID_Map.containsKey(ol.External_ID__c)) {
                    oliExtID_oli_Map.get(ol.External_ID__c).PricebookEntryId = oliExtID_PricebookEntryID_Map.get(ol.External_ID__c);
                }
                //To check weather the oli should not get updated with PricebookEntryID olisExistsSet
                olisExistsSet.add(ol.External_ID__c);
                extID_curISOMap.put(ol.External_ID__c, ol.Opportunity.CurrencyISOCode);
        }
    }
    
    oliListToUpsert = new List<OpportunityLineItem>();    
    for (OpportunityLineItem ol : oliExtID_oli_Map.values()) {
      //To check weather the oli should not get updated with PricebookEntryID olisExistsSet
        if (ol.PricebookEntryId == null && oliExtID_PricebookEntryID_Map.containsKey(ol.External_ID__c) && !olisExistsSet.contains(ol.External_ID__c)) {
          ol.PricebookEntryId = oliExtID_PricebookEntryID_Map.get(ol.External_ID__c);
        } else if (ol.PricebookEntryId == null && !olisExistsSet.contains(ol.External_ID__c) && extID_curISOMap.containsKey(ol.External_ID__c) && productNameIdMap.containsKey('Unknown' + '-' + extID_curISOMap.get(ol.External_ID__c))) {
            ol.PricebookEntryId = productNameIdMap.get('Unknown' + '-' + extID_curISOMap.get(ol.External_ID__c)).ID;
        }      

        if (ol.Country__c != null) oliListToUpsert.add(ol);
    }

    List<Database.upsertResult> uResults = Database.upsert(oliListToUpsert, OpportunityLineItem.External_Id__c);
    for (Database.upsertResult result : uResults) {
        if (result.isSuccess()) oliIDset.add(result.getId());
    }
    
    if (oliIDset.size()>0 && opptyIDset.size() > 0) {
      TriggerProcessControl.ignoreBeforeAfterUpdateCall = true; 
      //Using same list to upsert for other OLIs which were not impacted from upsert
      oliListToUpsert = [Select UnitPrice, OpportunityId, Id From OpportunityLineItem WHERE OpportunityID IN: opptyIDset AND ID NOT IN: oliIDset];
       
      //Byrnes - 2768, no longer are we setting the value to zero, instead unmatched items are being deleted.
      if (!oliListToUpsert.isEmpty()) delete oliListtoUpsert;
    }
  }
  
  //Returns brand map with key Brand Id and object of Brand
  public static Map<String, Brand__c> getID_BrandMap() {
    Map<String, Brand__c> brand_Map = new Map<String, Brand__c>();
    for(Brand__c br : [SELECT Name, ID FROM Brand__c]) {
      if(!brand_Map.containsKey(br.ID)) {
        brand_Map.put(br.ID, br);
      }
    }
    return brand_Map;
  }
  
  //Override method for set of string to join
  public static String joinString(Set<String> valueCopySet, String separator) {
    List<String> valCopyList = new List<String>();
    for(String val : valueCopySet) {
        valCopyList.add(val);
    }
    String result = joinString(valCopyList, separator);
    
    return result;
  }
  
  //Returns joined string from a list.
  public static String joinString(List<String> valueCopy, String separator) {
    
      if(valueCopy.isEmpty()) return null;
      
        
      String result = valueCopy[0];
      valueCopy.remove(0);
      while(!valueCopy.isEmpty()) {
        result += separator + valueCopy[0];
        valueCopy.remove(0);
      }
      
      return result;    
  }
  
  /* get countries from country object
    returns country id and country name as map.
  */
  public static Map<String, String> getCountryNameMap() {
    Map<String, String> contID_contName_Map = new Map<String, String>();
    //Populating country map
    for(pw_ccpro__CountryObject__c cnt : countryList) {
      if(!contID_contName_Map.containsKey(cnt.ID)) {
        contID_contName_Map.put(cnt.ID, cnt.Name);
      }
    }
    
    return contID_contName_Map;     
  }

  /* get countries from country object
    returns country id and country name as map.
  */
  public static Map<String, String> getCountryNameIDMap() {
    Map<String, String> contName_contID_Map = new Map<String, String>();
    //Populating country map
    for(pw_ccpro__CountryObject__c cnt : countryList) {
      if(!contName_contID_Map.containsKey(cnt.Name)) {
        contName_contID_Map.put(cnt.Name, cnt.ID);
      }
    }
    return contName_contID_Map;   
  }
   
  //get countries from country object
  public static Map<String, PricebookEntry> getProductNameMap() {
    Map<String, PricebookEntry> prodName_prodID_Map = new Map<String, PricebookEntry>();
    //Populating Product map
    system.debug('PBEList :: ' + PBEList);
    for(PricebookEntry prd : PBEList) {
      if(!prodName_prodID_Map.containsKey(prd.Product2.Name+'-'+prd.CurrencyIsoCode)) {
        prodName_prodID_Map.put(prd.Product2.Name+'-'+prd.CurrencyIsoCode, prd);
      }
    }
    
    return prodName_prodID_Map;  
  }
    
    //Recall Accoubt Brand Status from Subscription and SubcriptionProductCharge
    //If 'RealTimeProcessing' is true, then the ServiceEndDate__c is >=, else it's just >
    //>= is used for realtime execution (when Zuora updates/inserts) the > is used for massRecalc at end of day via the schedulable, batchable job.
    //It also changes the filter around the start date to include active contracts starting 'tomorrow' so that they are correct upon start of business the next day.
    public static void recallABstatus (Set<String> accountIDset, boolean RealTimeProcessing) {

        //Set<String> accountIDset = new Set<String>();
        Map<String, Zuora__SubscriptionProductCharge__c> acIDbrandName_SubscriptionMap = new Map<String, Zuora__SubscriptionProductCharge__c>();
        Map<ID, Account_Brand__c> accountBrandMapToUpdate = new Map<ID, Account_Brand__c>();
        Map<String, Account_Brand__c> accIDBrand_accountBrand_Map = new Map<String, Account_Brand__c>();
        
        List<Zuora__SubscriptionProductCharge__c> spcList = new List<Zuora__SubscriptionProductCharge__c>();
        
        if (RealTimeProcessing) {
            spcList = [SELECT   Id, 
                            Zuora__Account__c, 
                            Zuora__Zuora_Id__c, 
                            Zuora__Subscription__c, 
                            Zuora__Subscription__r.Zuora__SubscriptionEndDate__c,
                            Zuora__Subscription__r.ServiceEndDate__c,
                            Zuora__Subscription__r.Zuora__Status__c, 
                            Zuora__Subscription__r.Zuora__TermSettingType__c,
                            Country__c, 
                            Notes__c, 
                            Product_Rate_Plan__c, 
                            Brand__c, 
                            Zuora__EffectiveStartDate__c 
                        FROM Zuora__SubscriptionProductCharge__c 
                        WHERE Zuora__Account__c IN : accountIDset 
                            //AND Zuora__EffectiveStartDate__c <= TODAY
                            AND Zuora__Subscription__r.Zuora__SubscriptionStartDate__c <= TODAY
                            AND Brand__c != Null
                            AND (
                                    ( 
                                        Zuora__Subscription__r.Zuora__Status__c = 'Active'
                                        OR
                                        Zuora__Subscription__r.Zuora__Status__c = 'Cancelled'
                                        OR
                                        Zuora__Subscription__r.Zuora__Status__c = 'Expired'
                                    )
                                )
                            AND (
                                    (
                                        Zuora__Subscription__r.Zuora__TermSettingType__c = 'TERMED' 
                                        AND Zuora__Subscription__r.ServiceEndDate__c >= TODAY
                                    )
                                    OR 
                                    (
                                        Zuora__Subscription__r.Zuora__TermSettingType__c = 'EVERGREEN' 
                                        AND (Zuora__Subscription__r.ServiceEndDate__c >= TODAY OR Zuora__Subscription__r.ServiceEndDate__c = null)
                                    )
                                )
                                ];
        }
        else {
            spcList = [SELECT   Id, 
                            Zuora__Account__c, 
                            Zuora__Zuora_Id__c, 
                            Zuora__Subscription__c, 
                            Zuora__Subscription__r.Zuora__SubscriptionEndDate__c,
                            Zuora__Subscription__r.ServiceEndDate__c,
                            Zuora__Subscription__r.Zuora__Status__c, 
                            Zuora__Subscription__r.Zuora__TermSettingType__c,
                            Country__c,
                            Notes__c, 
                            Product_Rate_Plan__c, 
                            Brand__c, 
                            Zuora__EffectiveStartDate__c 
                        FROM Zuora__SubscriptionProductCharge__c 
                        WHERE Zuora__Account__c IN : accountIDset 
                            //AND Zuora__EffectiveStartDate__c <= TOMORROW
                            AND Zuora__Subscription__r.Zuora__SubscriptionStartDate__c <= TOMORROW
                            AND Brand__c != Null
                            AND (
                                    ( 
                                        Zuora__Subscription__r.Zuora__Status__c = 'Active'
                                        OR
                                        Zuora__Subscription__r.Zuora__Status__c = 'Cancelled'
                                        OR
                                        Zuora__Subscription__r.Zuora__Status__c = 'Expired'
                                    )
                                )
                            AND (
                                    (
                                        Zuora__Subscription__r.Zuora__TermSettingType__c = 'TERMED' 
                                        AND Zuora__Subscription__r.ServiceEndDate__c > TODAY
                                    )
                                    OR 
                                    (
                                        Zuora__Subscription__r.Zuora__TermSettingType__c = 'EVERGREEN' 
                                        AND (Zuora__Subscription__r.ServiceEndDate__c > TODAY OR Zuora__Subscription__r.ServiceEndDate__c = null)
                                    )
                                )
                                ];          
        }
        for (Zuora__SubscriptionProductCharge__c spc : spcList) 
        {
            if (spc.Zuora__Account__c <> null && spc.Brand__c <> ''){}
 
            //So now we loop through the results of the Active charges we 1st need to check if the Account & Brand combination exists using Map.containsKey()
            //If it doesn't exist use Map.put to create the key/value pair in the map.
            if (!acIDbrandName_SubscriptionMap.containsKey(spc.Zuora__Account__c+'_'+spc.Brand__c)) {
                acIDbrandName_SubscriptionMap.put(spc.Zuora__Account__c+'_'+spc.Brand__c, spc);
            }
            //If it DOES exist we need to compare the Zuora__Subscription__r.ServiceEndDate__c of the Zuora__SubscriptionProductCharge__c that is currently in the Map    
            else {
                //If the Zuora__Subscription__r.ServiceEndDate__c of the record in the loop in greater 
                //then one in the map we should replace the value. 
                //This is because we always want Zuora__SubscriptionProductCharge__c  with 
                //the Max(Zuora__Subscription__r.ServiceEndDate__c)  of all the Active Records for that Brand
                
                //if the current SPC is termed & the existing one is NOT evergreen...
                if (spc.Zuora__Subscription__r.Zuora__TermSettingType__c == 'TERMED') {
                    
                    //if pre-existing record is EVERGREEN w/out SED
                    if (acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.Zuora__TermSettingType__c == 'EVERGREEN' && acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.ServiceEndDate__c == null) {
                        //do nothing...  this is essentially the MAX value we can ever have...
                    }
                    
                    //else if pre-existing record is EVERGREEN w/ a SED
                    else if (acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.Zuora__TermSettingType__c == 'EVERGREEN' && acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.ServiceEndDate__c != null) {
                        if (spc.Zuora__Subscription__r.ServiceEndDate__c > acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.ServiceEndDate__c) {
                            acIDbrandName_SubscriptionMap.put(spc.Zuora__Account__c+'_'+spc.Brand__c, spc);
                        } 
                    }
                    
                    //else if pre-existing record is TERMED...
                    else if (acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.Zuora__TermSettingType__c != 'EVERGREEN') {
                        if (spc.Zuora__Subscription__r.ServiceEndDate__c > acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.ServiceEndDate__c) {
                            acIDbrandName_SubscriptionMap.put(spc.Zuora__Account__c+'_'+spc.Brand__c, spc);
                        }
                    }
                }
                //else it is EVERGREEN
                else {
                    
                    //if pre-existing record is EVERGREEN w/out SED
                    if (acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.Zuora__TermSettingType__c == 'EVERGREEN' && acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.ServiceEndDate__c == null) {
                        //do nothing...  this is essentially the MAX value we can ever have...
                    }
                    
                    //else if pre-existing record is EVERGREEN w/ a SED
                    else if (acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.Zuora__TermSettingType__c == 'EVERGREEN' && acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.ServiceEndDate__c != null) {
                        if ((spc.Zuora__Subscription__r.ServiceEndDate__c == null) || (spc.Zuora__Subscription__r.ServiceEndDate__c > acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.ServiceEndDate__c)) {
                            acIDbrandName_SubscriptionMap.put(spc.Zuora__Account__c+'_'+spc.Brand__c, spc);
                        } 
                    }
                    
                    //else if pre-existing record is TERMED...
                    else if (acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.Zuora__TermSettingType__c != 'EVERGREEN') {
                        if ((spc.Zuora__Subscription__r.ServiceEndDate__c == null) || (spc.Zuora__Subscription__r.ServiceEndDate__c > acIDbrandName_SubscriptionMap.get(spc.Zuora__Account__c+'_'+spc.Brand__c).Zuora__Subscription__r.ServiceEndDate__c)) {
                            acIDbrandName_SubscriptionMap.put(spc.Zuora__Account__c+'_'+spc.Brand__c, spc);
                        }
                    }
                }
            }
        }
            //#3 brandMap and acIDbrandName_SubscriptionMap (2maps)
              //brandMap has been created at the top of class for multiple use. 
            //#4 accIDBrand_accountBrand_Map
            for (Account_Brand__c ab : [SELECT  Id, 
                                                Name, 
                                                Account__c, 
                                                Brand__c, 
                                                Status__c,
                                                Brand_Name__c,
                                                Valid_Thru__c 
                                        FROM Account_Brand__c
                                        WHERE Account__c IN : accountIDset]) 
            {
                if (!accIDBrand_accountBrand_Map.containsKey(ab.Account__c+'_'+ab.Brand_Name__c)) accIDBrand_accountBrand_Map.put(ab.Account__c+'_'+ab.Brand_Name__c, ab);
                
            }
                        
            //#5
            for (Account_Brand__c ab : accIDBrand_accountBrand_Map.values()) {
                
                if (!acIDbrandName_SubscriptionMap.containsKey(ab.Account__c+'_'+ab.Brand_Name__c) && ab.Status__c == 'Prospect') {
                    //Do nothing
                } else if (!acIDbrandName_SubscriptionMap.containsKey(ab.Account__c+'_'+ab.Brand_Name__c) && ab.Status__c == 'Active') {
                    ab.Status__c = 'Inactive';
                    ab.Valid_Thru__c = null;
                    //Adding account brand record to list to update.
                    accountBrandMapToUpdate.put(ab.ID, ab);
                } else if (acIDbrandName_SubscriptionMap.containsKey(ab.Account__c+'_'+ab.Brand_Name__c) && ab.Status__c <> 'Active') {
                    ab.Status__c = 'Active';
                    
                    //if found and active & termed, set the MAX SED / Valid Thru date to the Service End Date
                    ab.Valid_Thru__c = acIDbrandName_SubscriptionMap.get(ab.Account__c+'_'+ab.Brand_Name__c).Zuora__Subscription__r.ServiceEndDate__c;
                     
                    //Adding account brand record to list to update.
                    accountBrandMapToUpdate.put(ab.ID, ab);
                    
                } else if (acIDbrandName_SubscriptionMap.containsKey(ab.Account__c+'_'+ab.Brand_Name__c) && ab.Status__c == 'Active' && (acIDbrandName_SubscriptionMap.get(ab.Account__c+'_'+ab.Brand_Name__c).Zuora__Subscription__r.ServiceEndDate__c > ab.Valid_Thru__c)) {
                    ab.Valid_Thru__c = acIDbrandName_SubscriptionMap.get(ab.Account__c+'_'+ab.Brand_Name__c).Zuora__Subscription__r.ServiceEndDate__c; 
                    //Adding account brand record to list to update.
                    accountBrandMapToUpdate.put(ab.ID, ab);
                }
            }

            //Update account brands
            if (!accountBrandMapToUpdate.values().isEmpty()) update accountBrandMapToUpdate.values();
        
    }

    //T-115008 Date Feb 13th, 2013.
    public static void recallATM (Set<String> accountIDset) {
      Map<String, Set<String>> accID_SetOfUserID_Map = new Map<String, Set<String>>();
      Set<String> ATM_SetToDelete = new Set<String>();
      List<AccountTeamMember> accountTeamMemberList = new List<AccountTeamMember>();
      List<AccountTeamMember> ATMsListToDel = new List<AccountTeamMember>();
      
      Map<String, List<Account_Brand__c>> accId_AccountBrandList_Map = new Map<String, List<Account_Brand__c>>();
      Map<String, List<Account_Team_Member__c>> accId_ATM_cList_Map = new Map<String, List<Account_Team_Member__c>>();
            
      //Collecting all the users on Account Brand and Account_Team_Member__c
      for (Account account : [SELECT Id, 
                              (SELECT ID, User__c, Role__c, Account__c FROM Account_Team_Members__r), 
                              (SELECT Id, CS__c, Primary_Owner__c, Account__c FROM Account_Brands__r),
                              (Select Id, UserId, AccountId From AccountTeamMembers) 
                               FROM Account WHERE ID IN: accountIDset]) {
        for (Account_Brand__c accountBrand : account.Account_Brands__r) {
          if (accountBrand.Primary_Owner__c <> null) {
            if (!accID_SetOfUserID_Map.containsKey(account.ID)) {
              accID_SetOfUserID_Map.put(account.ID, new Set<String>());
            }
            accID_SetOfUserID_Map.get(account.ID).add(accountBrand.Primary_Owner__c);
          }
          
          if (accountBrand.CS__c <> null) {
            if (!accID_SetOfUserID_Map.containsKey(account.ID)) {
              accID_SetOfUserID_Map.put(account.ID, new Set<String>());
            }
            accID_SetOfUserID_Map.get(account.ID).add(accountBrand.CS__c);
          }
          
          if (!accId_AccountBrandList_Map.containsKey(account.ID)) {
            accId_AccountBrandList_Map.put(account.ID, new List<Account_Brand__c>());
          }
          accId_AccountBrandList_Map.get(account.ID).add(accountBrand);
        }
            
        for (Account_Team_Member__c a_t_m : account.Account_Team_Members__r) {
          if (a_t_m.User__c <> null) {
            if (!accID_SetOfUserID_Map.containsKey(account.ID)) {
              accID_SetOfUserID_Map.put(account.ID, new Set<String>());
            }
            accID_SetOfUserID_Map.get(account.ID).add(a_t_m.User__c);

            if (!accId_ATM_cList_Map.containsKey(account.ID)) {
              accId_ATM_cList_Map.put(account.ID, new List<Account_Team_Member__c>());
            }
            accId_ATM_cList_Map.get(account.ID).add(a_t_m);       
          }
        }

            
        for (AccountTeamMember atm : account.AccountTeamMembers) {
          accountTeamMemberList.add(atm);
        }
      }//End of main loop
      
      /** //T-128087***Fetching and populating active users for ATM *********/
      //Set to add user ids which is to rev
        Set<ID> checkUserIDs = new Set<ID>();
        Map<String, User> uid_userMap = new Map<String, User>();
        
        for (String accID : accId_AccountBrandList_Map.keySet()) {
        for (Account_Brand__c ab : accId_AccountBrandList_Map.get(accID)) {
          if (ab.Primary_Owner__c <> null) {
            checkUserIDs.add(ab.Primary_Owner__c);
          }
          if (ab.CS__c <> null) {
            checkUserIDs.add(ab.CS__c);
          }     
        }
        }
        for (String accID : accId_ATM_cList_Map.keySet()) {
          for (Account_Team_Member__c a_t_m : accId_ATM_cList_Map.get(accID)) {
            if (a_t_m.User__c <> null) {
              checkUserIDs.add(a_t_m.User__c);
            }
          }
        }        
        for (User u : [SELECT ID FROM User WHERE IsActive = true AND ID IN: checkUserIDs]) {
            if (!uid_userMap.containsKey(u.ID)) {
                uid_userMap.put(u.ID, u);
            }
        }
        /****************End of Fetching and populating active users*********/
      Map<String, Set<String>> acID_existingUsersSetMap = new Map<String, Set<String>>();
      Set<String> addedATMs = new Set<String>();  
      //Looping over AccountTeamMember
      for (AccountTeamMember atm : accountTeamMemberList) {
        if (!accID_SetOfUserID_Map.containsKey(atm.AccountID)) {
          ATMsListToDel.add(atm);
          addedATMs.add(atm.ID);
        } else {
          if(!accID_SetOfUserID_Map.get(atm.AccountID).contains(atm.UserId)) {
            ATMsListToDel.add(new AccountTeamMember(ID = atm.ID, UserId = atm.UserId));
            addedATMs.add(atm.ID);
          } else {
            if (!acID_existingUsersSetMap.containsKey(atm.AccountID)) {
              acID_existingUsersSetMap.put(atm.AccountID, new Set<String>());
            }
            acID_existingUsersSetMap.get(atm.AccountId).add(atm.UserId);
          }
        }
        //T-128087
        if (!uid_userMap.containsKey(atm.UserId) && !addedATMs.contains(atm.ID)) {
            ATMsListToDel.add(atm);
            addedATMs.add(atm.ID);
        }
      }
      //Delete ATMs which are not on any of ATM__c or AB__c
      //INC0012497 - removing deletes because people making Account Team changes do no have delete rights.  This cleanup will be handled in a batch job
      //if (!ATMsListToDel.isEmpty()) {
      //  delete ATMsListToDel;
      //}
      AccountTeamUtility.DeleteATMs(ATMsListToDel);
      
      // I-61318 - Fix for AccountTeamMember Calculation
      for(String a:accountIDset){
            if (!acID_existingUsersSetMap.containsKey(a)) {
                      acID_existingUsersSetMap.put(a, new Set<String>());
            }      
      }      
      
      List<AccountTeamMember> atmListToInsert = new List<AccountTeamMember>();
      //Inserting ATM from Account Brand 
      for (String accID : accId_AccountBrandList_Map.keySet()) {
        for (Account_Brand__c ab : accId_AccountBrandList_Map.get(accID)) {
          if (ab.Primary_Owner__c <> null && acID_existingUsersSetMap.containsKey(ab.Account__c) 
                  && !acID_existingUsersSetMap.get(ab.Account__c).contains(ab.Primary_Owner__c) &&
                  uid_userMap.containsKey(ab.Primary_Owner__c)) { //T-128087
              atmListToInsert.add(new AccountTeamMember(AccountId = ab.Account__c, UserId = ab.Primary_Owner__c, TeamMemberRole = 'Sales Rep'));
          }
          if (ab.CS__c <> null && acID_existingUsersSetMap.containsKey(ab.Account__c) 
              && !acID_existingUsersSetMap.get(ab.Account__c).contains(ab.CS__c) && 
              uid_userMap.containsKey(ab.CS__c)) { //T-128087
            
            atmListToInsert.add(new AccountTeamMember(AccountId = ab.Account__c, UserId = ab.CS__c, TeamMemberRole = 'CS'));
          }               
        }
      }
      //Inserting ATM from ATM__c
      for (String accID : accId_ATM_cList_Map.keySet()) {
        for (Account_Team_Member__c a_t_m : accId_ATM_cList_Map.get(accID)) {
          if (a_t_m.User__c <> null && acID_existingUsersSetMap.containsKey(a_t_m.Account__c) 
                 && !acID_existingUsersSetMap.get(a_t_m.Account__c).contains(a_t_m.User__c) && 
                    uid_userMap.containsKey(a_t_m.User__c)) { //T-128087                  
              atmListToInsert.add(new AccountTeamMember(AccountId = a_t_m.Account__c, UserId = a_t_m.User__c, TeamMemberRole = a_t_m.Role__c));
          }
        }
      }    
      if (!atmListToInsert.isEmpty()) insert atmListToInsert;
      
    }
    
  //---------------------------------------------------------------------------
  // T-151014
  //--------------------------------------------------------------------------- 
  public static void recalcContact4PU(String csvIn) {
    //calling style 1
    //recalcContact4PUFuture(csvIn);
    
    //calling style 3
    if(csvIn.equalsIgnoreCase('ALL')) {
      //recalcContact4PUBatch(csvIn);
      RecalcContact4PUBatch batch1 = new RecalcContact4PUBatch();
      Database.executeBatch(batch1);
    //calling style 2
    } else recalcContact4PUSimple(csvIn);
   
  } 
   
  //---------------------------------------------------------------------------
  // recalcContact4PUFuture 
  // calling style 1
  // T-151014
  //---------------------------------------------------------------------------
  @future
  public static void recalcContact4PUFuture(String csvIn) {
    recalcContact4PUSimple(csvIn);
  }
  
  //---------------------------------------------------------------------------
  // recalcContact4PUSimple
  // calling style 2
  // T-151014
  //---------------------------------------------------------------------------
  public static void recalcContact4PUSimple(String csvIn) {
    Set<String> csvSet = new Set<String>(); //set of contact IDs
    for(String str : csvIn.split(',')) {
      csvSet.add(str);         
    }
   
    Map<ID, Set<String>> conIDActiveAllocationBrandSetMap = new Map<ID, Set<String>>();
    Map<ID, Set<String>> conIDInactiveAllocationBrandSetMap = new Map<ID, Set<String>>();         
    for(Product_User__c pu : [select id, Brand__c, Status__c , Contact__c 
                              from Product_User__c 
                              where Contact__c in :csvSet AND Status__c <> null]) {
      
      if(pu.Status__c == 'Active') {
        Set<String> brandSet = new Set<String>();
        if(!conIDActiveAllocationBrandSetMap.containsKey(pu.Contact__c)) {
            brandSet.add(pu.Brand__c);
        } else if(!(conIDActiveAllocationBrandSetMap.get(pu.Contact__c).contains(pu.Brand__c))) {
            brandSet = conIDActiveAllocationBrandSetMap.get(pu.Contact__c);
            brandSet.add(pu.Brand__c);
        }
        conIDActiveAllocationBrandSetMap.put(pu.Contact__c, brandSet);
      } else if(pu.Status__c == 'Inactive') {
        Set<String> brandSet = new Set<String>();
        if(!conIDInactiveAllocationBrandSetMap.containsKey(pu.Contact__c)) {
          brandSet.add(pu.Brand__c);
        } else if(!(conIDInactiveAllocationBrandSetMap.get(pu.Contact__c).contains(pu.Brand__c))) {
          brandSet = conIDInactiveAllocationBrandSetMap.get(pu.Contact__c);
          brandSet.add(pu.Brand__c);
        }
        conIDInactiveAllocationBrandSetMap.put(pu.Contact__c, brandSet);        
      }
    }     
    List<Contact> contactList = new List<Contact>();
    for(Contact c : [SELECT User_Allocations_Active__c, User_Allocations_Inactive__c 
                     FROM Contact Where Id IN :csvSet]) {
      String activeString , inactiveString;
      if(conIDActiveAllocationBrandSetMap.containsKey(c.ID)) {
        activeString = prepareActiveString(conIDActiveAllocationBrandSetMap.get(c.ID));
        c.User_Allocations_Active__c = activeString;        
      } else {
        c.User_Allocations_Active__c = '';
      }
      if(conIDInactiveAllocationBrandSetMap.containsKey(c.ID)) {
        inactiveString = prepareInactiveString(conIDActiveAllocationBrandSetMap.get(c.ID), conIDInactiveAllocationBrandSetMap.get(c.ID) );
        c.User_Allocations_Inactive__c = inactiveString;        
      } else c.User_Allocations_Inactive__c = '';
      contactList.add(c);
    }
    update contactList;
  }
  
//---------------------------------------------------------------------------
  // recalcContact4PUSimple
  // calling style 2
  // T-151014
  //---------------------------------------------------------------------------
  public static void recalcContactAuthorized(Set<Id> csvSet) {
   
    Map<ID, Set<String>> conIDAuthBrandSetMap = new Map<ID, Set<String>>();
         
    for(Contact_Type__c ct : [SELECT Id, Contact__c, Authorized__c, Brand_Name__c
                              FROM Contact_Type__c 
                              WHERE Contact__c in :csvSet AND Authorized__c = true]) {
            
        Set<String> brandSet = new Set<String>();
        
        if(!conIDAuthBrandSetMap.containsKey(ct.Contact__c)) brandSet.add(ct.Brand_Name__c);
        else if(!(conIDAuthBrandSetMap.get(ct.Contact__c).contains(ct.Brand_Name__c))) {
            brandSet = conIDAuthBrandSetMap.get(ct.Contact__c);
            brandSet.add(ct.Brand_Name__c);
        }
        
        conIDAuthBrandSetMap.put(ct.Contact__c, brandSet);      
    }     
    
    List<Contact> contactList = new List<Contact>();
    
    for(Contact c : [SELECT Authorized__c FROM Contact WHERE Id IN :csvSet]) {
        
        if (conIDAuthBrandSetMap.containsKey(c.ID)) c.Authorized__c = prepareActiveStringForWrap(conIDAuthBrandSetMap.get(c.ID));        
        else c.Authorized__c = '';

        contactList.add(c);
    }
    
    update contactList;
  }  
  
  
  //---------------------------------------------------------------------------
  // Prpares the string for Active User Allocations with a space so it'll wrap...
  //---------------------------------------------------------------------------
  private static String prepareActiveStringForWrap(Set<String> activeBrandSet) {
    String returnStr = null;
    if(activeBrandSet <> null) {
        for(String str : activeBrandSet) {
            if(returnStr == null) {
                returnStr = str;
            } else returnStr += '; ' + str;
          
        }       
    }
    if(returnStr == null) returnStr = '';
      
    return returnStr;
  }  
  
  //---------------------------------------------------------------------------
  // Prpares the string for Active User Allocations
  //---------------------------------------------------------------------------
  private static String prepareActiveString(Set<String> activeBrandSet) {
    String returnStr = null;
    if(activeBrandSet <> null) {
        for(String str : activeBrandSet) {
            if(returnStr == null) returnStr = str;
            else returnStr += ';' + str;
        }       
    }
    if(returnStr == null) returnStr = '';
  
    return returnStr;
  }
  
  //---------------------------------------------------------------------------
  // Prpares the string for Inactive User Allocations
  //---------------------------------------------------------------------------  
  private static String prepareInactiveString(Set<String> activeBrandSet, Set<String> inactiveBrandSet) {
    String returnStr = null;
    if(inactiveBrandSet <> null) {
        for(String str : inactiveBrandSet) {
          if(activeBrandSet == null || 
             (activeBrandSet <> null && !activeBrandSet.contains(str))) {
              if(returnStr == null) {
                returnStr = str;
              } else {
                returnStr += ';' + str;
              }
          }
        }
    }
    if(returnStr == null) returnStr = '';
    
    return returnStr;
  }
  
  //---------------------------------------------------------------------------
  // Returns TRUE if the user is a 'System Administrator', false otherwise
  //---------------------------------------------------------------------------  
  public static Boolean IsUserAdmin(Id UserID) {
    Boolean result = false;
    Id sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
    
    User u = [SELECT Id, ProfileId FROM User WHERE Id = :UserID LIMIT 1];
    
    if ((u != null) && (u.ProfileId == sysAdminProfileId)) result = true;
    
    return result;
  }
  
  //Returns TRUE if the passed-in string (payment gateway, really) is approved...
  //Note that this is not bulkified and is meant only for the manual use-case of clicking the button.
  public static Boolean IsPaymentGatewayApproved(String paymentGateway)
  {     
    //list of approved gateways.  The formula field, 'Payment_Gateway__c' on the Quote__c object will end with one here if it can be accepted in this manner.
    List<CreditCardPaymentGateways__c> listCCPG = [SELECT Gateway__c FROM CreditCardPaymentGateways__c WHERE Approved__c = true];
                
    for (CreditCardPaymentGateways__c ccpg : listCCPG) {
        if (paymentGateway.endsWith(ccpg.Gateway__c)) return true;
    }
            
    return false;
  }
}