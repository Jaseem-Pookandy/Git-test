/************************************************************************
// (c) 2013 Appirio, Inc.
// Description    : Class that contains method which updates opportunity after 
//                  successfull payment information capture.
//                  
// Mar 25th, 2013  :  Naresh Ojha (Appirio Offshore) for T-124828
************************************************************************/
public with sharing class zCC_ConfirmController {

    public PageReference updateOpportunity() {
      String quoteID = ApexPages.currentPage().getParameters().get('QID');
      String refId = ApexPages.currentPage().getParameters().get('pmid');      

      if (quoteID <> null) {
        
          zqu__Quote__c quote = [SELECT zqu__Opportunity__c, Id, IS_Verified__c 
                                       FROM zqu__Quote__c 
                                       WHERE ID =: quoteID];
        
          if (quote.zqu__Opportunity__c <> null && refId <> null) {
            Opportunity oppty = new Opportunity(ID = quote.zqu__Opportunity__c, 
                                                    ZuoraPaymentID__c = refId);
            update oppty;
          }
      }
      return null;
    }

}