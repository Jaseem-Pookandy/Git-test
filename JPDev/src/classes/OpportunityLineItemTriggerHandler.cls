/***************************************************************************
// (c) 2012 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  OpportunityTrigger. All contexts should be in this class.
//                  
// Jan 18th, 2012  :  Naresh Ojha (Appirio Offshore)
// June 03, 2013   :  Karun Gangwani changed for T-148272
//***************************************************************************/
public with sharing class OpportunityLineItemTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  private Set<String> syncQutSet = new Set<String>();
  public static Map<String, Brand__c> brandID_brandMap; // for T-148272
  public static Map<String, String> contID_contName_Map; // for T-148272
  //Constructor
  public OpportunityLineItemTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;

    if (brandID_brandMap == null) brandID_brandMap = CommonUtil.getID_BrandMap();
    if (contID_contName_Map == null) contID_contName_Map = CommonUtil.getCountryNameMap();
  }
  
  //On Before insert trigger method
  public void OnBeforeInsert(List<OpportunityLineItem> newList) {
    populateOppLineItemBrand(newList);
  }
  
  //On After insert trigger method
  public void OnAfterInsert(Map<Id, OpportunityLineItem> newMap) { 
    populateOpportunityByProductLines(newMap);

    if (!TriggerProcessControl.inRecursiveCall) {
      TriggerProcessControl.inRecursiveCall = true;
      syncQutSet = synchedQuotesOnOptys(newMap.values());
      CommonUtil.OLIsOnOppty(new List<sObject>(), '', syncQutSet);
    }
  }  

    //On Before update trigger method
  public void OnBeforeUpdate(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap) {
    
    if (!TriggerProcessControl.ignoreBeforeAfterUpdateCall) populateOppLineItemBrand(newList);
  } 

  // On After update trigger method
  public void OnAfterUpdate (Map<Id, OpportunityLineItem> oldMap, Map<Id, OpportunityLineItem> newMap) {
    
    if (!TriggerProcessControl.ignoreBeforeAfterUpdateCall) populateOpportunityByProductLines(newMap);

    if (!TriggerProcessControl.inRecursiveCall) {
      TriggerProcessControl.inRecursiveCall = true;
      syncQutSet = synchedQuotesOnOptys(newMap.values());
      CommonUtil.OLIsOnOppty(new List<sObject>(), '', syncQutSet);
    }    
  }

  // On After delete trigger method
  public void OnAfterDelete (Map<Id, OpportunityLineItem> oldMap) {
    populateOpportunityByProductLines(oldMap);
    if(!TriggerProcessControl.inRecursiveCall) {
      TriggerProcessControl.inRecursiveCall = true;     
      syncQutSet = synchedQuotesOnOptys(oldMap.values());
      CommonUtil.OLIsOnOppty(new List<sObject>(), '', syncQutSet);
    }
  }
  
  //T-105586: Reliast or repopulate opporunity.country and Opportunity Brand
  private void populateOpportunityByProductLines (Map<ID, OpportunityLineItem> newMap) {
                                            
    Set<String> opptyIDset = new Set<String>();
    //Map<String, Brand__c> brandID_brandMap = new Map<String, Brand__c>();
    //brandID_brandMap = CommonUtil.getID_BrandMap(); // for T-148272
    //Map<String, String> contID_contName_Map = CommonUtil.getCountryNameMap(); // for T-148272
        
    Map<String, List<Opportunity>> optyID_optyListMap = new Map<String, List<Opportunity>>();    
    
    List<Opportunity> optyListToUpdate = new List<Opportunity>();
    Set<String> countryList;
    Set<String> brandList;
                       
    for (OpportunityLineItem oli : newMap.values()) {
      opptyIDset.add(oli.OpportunityId);
    }
    //Populating countries and brand fields with oli values.
    for (Opportunity opty : [SELECT Id, Countries__c, Brands__c, (SELECT Id, Brand__c, Country__c FROM OpportunityLineItems where TotalPrice > 0 ) FROM Opportunity WHERE Id IN : opptyIDset]) {
      if (opty.OpportunityLineItems.size() > 0) {
        countryList = new Set<String>();
        brandList = new Set<String>();
        
        for (OpportunityLineItem oli : opty.OpportunityLineItems) {
          countryList.add(contID_contName_Map.get(oli.Country__c));
          brandList.add(brandID_brandMap.get(oli.Brand__c).Name);          
        }
        
        optyListToUpdate.add(new Opportunity(ID = opty.ID, Countries__c = CommonUtil.joinString(countryList, ';'), Brands__c = CommonUtil.joinString(brandList, ';')));
      }
    }
    //Calling update
    if (!optyListToUpdate.isEmpty()) update optyListToUpdate;
  }
  
  /*****************************************************************************
  //T-111617: Populate Brand__c on OpportunityLineItem
  *****************************************************************************/
  private void populateOppLineItemBrand(List<OpportunityLineItem> newList) {
    Set<String> priceBookEntryIDset = new Set<String>();
    Map<String, PricebookEntry> priceBookEntryMap = new Map<String, PricebookEntry>();
    
    //Add Opportunity Line Item PricebookEntryId in a set if its Brand__c is null.
    for (OpportunityLineItem oli : newList) {
      if (oli.Brand__c == null) priceBookEntryIDset.add(oli.PricebookEntryId);
    }
    
    //Select Product's brand name from PriceBookEntry for all the PriceBookEntries 
    //in the set priceBookEntryIDset and add them in map priceBookEntryMap with 
    //key as the PriceBookEntry.ID
    if (!priceBookEntryIDset.isEmpty()) {
      for (PricebookEntry pbe : [SELECT ID, Name, Product2.Brand__c FROM PricebookEntry WHERE ID IN : priceBookEntryIDset]) {
        if (!priceBookEntryMap.containsKey(pbe.ID)) priceBookEntryMap.put(pbe.ID, pbe);
      }
    }
    
    for (OpportunityLineItem oli : newList) {      
      //Update the Opportunity Line Item Brand__c if it is null.
      if (oli.Brand__c == null && priceBookEntryMap.get(oli.PricebookEntryId).Product2.Brand__c != null) oli.Brand__c = priceBookEntryMap.get(oli.PricebookEntryId).Product2.Brand__c;

      if (oli.Brand__c <> null && oli.Country__c <> null && oli.OpportunityId <> null && oli.BrandTag__c <> null) {
        String subCat;
        String pGroup;
        String saleType;

        if (oli.Sub_Category__c == null) subCat = '';
        else subCat = oli.Sub_Category__c.toLowerCase();

        if (oli.Product_Group__c == null) pGroup = '';
        else pGroup = oli.Product_Group__c.toLowerCase();

        if (oli.Sale_Type__c == null) saleType = '';
        else saleType = oli.Sale_Type__c.toLowerCase();
        
        //oli.External_Id__c = oli.OpportunityId+'-'+contID_contName_Map.get(oli.Country__c)+'-'+brandID_brandMap.get(oli.Brand__c).Name.toLowerCase()+'-'+oli.BrandTag__c.toLowerCase()+'-'+pGroup+'-'+subCat+'-'+saleType;
      }
    }
  }  
  //revreives synched quotes from opportunities for the OLIs
  private Set<String> synchedQuotesOnOptys(List<OpportunityLineItem> newList) {
    Set<String> optyIDsSet = new Set<String>();
    Set<String> synchedQuoteSet = new Set<String>();
    
    for(OpportunityLineItem ol : newList) {
      optyIDsSet.add(ol.OpportunityID);
    }
    
    for (Opportunity opty : [SELECT SyncedQuote__c, Id FROM Opportunity WHERE ID IN : optyIDsSet]) {
      if(opty.SyncedQuote__c <> null) synchedQuoteSet.add(opty.SyncedQuote__c);
    }
    
    return synchedQuoteSet;
  } 
}