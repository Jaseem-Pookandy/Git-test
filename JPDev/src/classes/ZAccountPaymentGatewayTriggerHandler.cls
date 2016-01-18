/***************************************************************************
//
// Description    : Class that contains all of the functionality called by the 
//                  BillingAccountPaymentGatewayTrigger. All contexts should be in this class.
//                  
// Feb 05, 2015    Godfrey Mwamsoyo  
//***************************************************************************/
public with sharing class ZAccountPaymentGatewayTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  public  static Zuora.zApi zApiInstance = new Zuora.zApi();    
  private static List<Zuora.zObject> zActObjs = new List<Zuora.zObject>();        
    
    //Constructor
  public ZAccountPaymentGatewayTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

  //On After Insert and Update trigger methods
  public void OnAfterInsertUpdate(Map<ID, Zuora__CustomerAccount__c> oldMap, Map<Id, Zuora__CustomerAccount__c> newMap) {     
     Set<ID> zAcctIdSet = newMap.KeySet();
     if(!system.isFuture()) 
     {
       populateAccountPaymentGateway(zAcctIdSet);
     }
  }  
  
  @future(callout=true) 
  private static void populateAccountPaymentGateway(Set<ID> acctIdLst) {
        List<Zuora__CustomerAccount__c> billingAcctLst = [SELECT Id, PaymentGateway__c, Zuora__Zuora_Id__c FROM Zuora__CustomerAccount__c WHERE Id IN :acctIdLst];
        String whereClause = '';
        if(billingAcctLst.size() > 0)
        {
           whereClause = 'Id = \'' + billingAcctLst[0].Zuora__Zuora_Id__c + '\'';
        }
        for(integer i = 1; i < billingAcctLst.size() ; i++)
        {
           whereClause += ' OR Id = \'' + billingAcctLst[i].Zuora__Zuora_Id__c + '\'';
        }
        String zoql = 'SELECT Id, CrmId, PaymentGateway FROM Account WHERE ' + whereClause;  
        if(!Test.isRunningTest())
        {     
           zApiInstance.zlogin();
           zActObjs = zApiInstance.zquery(zoql);
        }
        Map<String, String> zAcctMap = new Map<String, String>();
        for(Zuora.zObject zAcct : zActObjs)
        {
          zAcctMap.put((String)zAcct.getValue('Id'), (String)zAcct.getValue('PaymentGateway'));
        }
        List<Zuora__CustomerAccount__c> updBillingAcctLst = new List<Zuora__CustomerAccount__c>();
        Integer updateBatchSize = 1;
        for(Zuora__CustomerAccount__c billingAcct : billingAcctLst)
        {
           String paymentGateway = zAcctMap.get(billingAcct.Zuora__Zuora_Id__c);
           if(paymentGateway != null)
           {
               billingAcct.PaymentGateway__c = paymentGateway;
               updBillingAcctLst.add(billingAcct);
               ++updateBatchSize;
           }
           if(updateBatchSize >= 10000)
           {
              update updBillingAcctLst;
              updateBatchSize = 1;
              updBillingAcctLst = new List<Zuora__CustomerAccount__c>();
           }
        }
        if(updBillingAcctLst.size() > 0) update updBillingAcctLst ;
  }
}