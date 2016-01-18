//***************************************************************************
//
// Description    : Class that contains all of the functionality called by the 
//                  RegionsQuoteRatePlanChargeTrigger. All contexts should be in this class.
//
// That trigger 'RegionsQuoteRatePlanChargeTrigger' is named oddly because it was
// Zuora's code that has since been refactored to fit the better model, but not renamed.
//                  
// Jul 14th, 2014  :  Byrnes, creation for 2668
//***************************************************************************/

public with sharing class zquQuoteRatePlanChargeTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  
  //Constructor
  public zquQuoteRatePlanChargeTriggerHandler (boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

  //On before insert trigger method
  public void OnBeforeInsert (List<zqu__QuoteRatePlanCharge__c> newList) { 
    SetRegion(newList);
    SetSalesRepID(newList);   //CC-2668
  } 
  
  //On before update trigger method
  public void OnBeforeUpdate (Map<ID, zqu__QuoteRatePlanCharge__c> oldMap, Map<ID, zqu__QuoteRatePlanCharge__c> newMap) {
    SetRegion(newMap.values());
    SetSalesRepID(newMap.values()); //CC-2668
  }    
  
  //On after insert trigger method
  public void OnAfterInsert (Map<Id, zqu__QuoteRatePlanCharge__c> newMap) { 

  }  
  // On after update trigger method
  public void OnAfterUpdate (Map<Id, zqu__QuoteRatePlanCharge__c> oldMap, Map<Id, zqu__QuoteRatePlanCharge__c> newMap) {

  }

  // On before delete trigger method
  public void OnBeforeDelete (Map<Id, zqu__QuoteRatePlanCharge__c> oldMap ) {

  }

  // On after delete trigger method
  public void OnAfterDelete (Map<Id, zqu__QuoteRatePlanCharge__c> oldMap ) {

  }

  /////////////////////////////////////
  // End Handler methods, begin methods
  /////////////////////////////////////

  //CC-2668
  private void SetSalesRepID(List<zqu__QuoteRatePlanCharge__c> newList) {

    Map<String, Id> salesRepIdMap = new Map<String, Id>();

    for (User u : [SELECT Name, Id FROM User WHERE IsActive =: true AND Directly_Commissionable__c = :true ORDER BY Name]) {
      if (!salesRepIdMap.containsKey(u.Name)) salesRepIdMap.put(u.Name, u.Id);
    }

    for (zqu__QuoteRatePlanCharge__c qc : newList) {
      if (qc.Sales_Representative__c != null && qc.Sales_Representative__c != '' && salesRepIdMap.containsKey(qc.Sales_Representative__c)) qc.SalesRepId__c = salesRepIdMap.get(qc.Sales_Representative__c);
    }
  }

  private void SetRegion(List<zqu__QuoteRatePlanCharge__c> newList) {
    Set<String> qrpcCountries = new Set<String>();

    for (zqu__QuoteRatePlanCharge__c qrpChrg : newList){
      qrpcCountries.add(qrpChrg.Country__c);
    }
  
    List<pw_ccpro__CountryObject__c> countryList = [SELECT Id, Name, Region__c, Region_Energy__c, Sub_Region1__c, Sub_Region2__c FROM pw_ccpro__CountryObject__c WHERE Name IN: qrpcCountries];
  
    for (zqu__QuoteRatePlanCharge__c qrpChrg : newList) {
      for (pw_ccpro__CountryObject__c country : countryList) {
        if(qrpchrg.Country__c == country.Name) {   
        
          if(country.Region__c != null) qrpchrg.Region__c = country.Region__c;
            
          if(country.Region_Energy__c != null) qrpchrg.EnergyRegion__c = country.Region_Energy__c;
            
          if(country.Sub_Region1__c != null) qrpchrg.SubRegion1__c = country.Sub_Region1__c;
            
          if(country.Sub_Region2__c != null) qrpchrg.SubRegion2__c = country.Sub_Region2__c;
        }      
      } 
    }
  }
}