/***
*Class          ---- CustomerFeedbackTrigger
*Author         ---- Tim Byrnes
*Story          ---- Customer_Feedback__c Restructure
*Created Date   ---- 2015.12.07
*Description    ---- Trigger handler for the Customer Feedback trigger
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Jaseem Pookandy	
*Story          ---- CCBOB - 193
*Modified Date  ---- 2015.12.11
*Description    ---- Included the piece to get account ID through contact in case account__c is not populated
***/

public with sharing class CustomerFeedbackTriggerHandler {
    
    private boolean m_isExecuting = false;  
    private integer BatchSize = 0;

    //Constructor
    public CustomerFeedbackTriggerHandler(boolean isExecuting, integer size) {
        m_isExecuting = isExecuting;
        BatchSize = size;
    }  
 
    //On Before insert trigger method
    public void OnBeforeInsert(List<Customer_Feedback__c> newList) {   

        PopulateCustomFields(newList);

    }
 
    // On Before update trigger method
    public void OnBeforeUpdate(Map<Id, Customer_Feedback__c> oldMap, Map<Id, Customer_Feedback__c> newMap) {    

        PopulateCustomFields(newMap.values());

    }
 
    // On Before delete trigger method
    public void OnBeforeDelete(Map<Id, Customer_Feedback__c> oldMap) {
        //Nothing yet...
    }
 
    //On after insert trigger method
    public void OnAfterInsert(Map<Id, Customer_Feedback__c> newMap) {   
        //Nothing yet...
        //PopulateCustomFields(newMap.values());
    }  
 
    // On after update trigger method
    public void OnAfterUpdate(Map<Id, Customer_Feedback__c> oldMap, Map<Id, Customer_Feedback__c> newMap) {    
        //Nothing yet...
        //PopulateCustomFields(newMap.values());
    }
 
    // On after update trigger method
    public void OnAfterDelete(Map<Id, Customer_Feedback__c> oldMap) {    
        //Nothing yet...
    }       
    private void populatecustomfields(List<Customer_Feedback__c> newList){
        Set<Id>accountIdSet = new Set<Id>();
        Set<Id>contactIdSet = new Set<Id>();
        Map<String,String>contactaccountMap = new MAp<string,string>();
        Map<String, Account_Brand__c> accountToAccountBrandMap = new Map<String, Account_Brand__c>();   //Key (string) = accountId + '~' + brand name, Id (value) = account brand object
        for(customer_feedback__c cf:newList){
            if(cf.Account_Brand__c == null && cf.Primary_Brand__c !=null && (cf.Account__c !=null || cf.contact__c !=null)){
                if(cf.Account__c!=null)
                    accountIdSet.add(cf.Account__c);
                else if(cf.Contact__c!=null)
                    contactIdSet.add(cf.Contact__c);
            }
            
        }
        //query contact to get accountid when account is not populated on customer feedback
        if(!contactIdSet.isEmpty()){
            for(Contact c:[select id,accountid from Contact where id in:contactIdSet]){
                accountIdSet.add(c.accountid);
                contactaccountMap.put(c.id,c.accountid);
            }
            
        }
        //query customer feedback to get accountid through contact in case accountid is null on customer feedback
        for (Account_Brand__c ab : [SELECT Id, Name, Account__c, Brand_Picklist__c FROM Account_Brand__c WHERE Account__c IN :accountIdSet]) {
        accountToAccountBrandMap.put(ab.Account__c + '~' + ab.Brand_Picklist__c, ab);
        }
        
        for(Customer_feedback__c cf :newList){
            if(cf.Account_Brand__c == null && cf.Primary_Brand__c !=null && cf.Account__c!=null && accountToAccountBrandMap.containsKey(cf.Account__c + '~' + cf.Primary_Brand__c)){
                cf.ACcount_BRand__c = accountToAccountBrandMap.get(cf.Account__c + '~' + cf.Primary_Brand__c).id;
            }else if(cf.Account_BRand__c == null && cf.Primary_Brand__c !=null && cf.Account__c == null && cf.Contact__c !=null && accountToAccountBrandMap.containsKey(contactaccountMap.get(cf.contact__c) + '~' + cf.Primary_Brand__c)){
                cf.Account_BRand__c =  accountToAccountBrandMap.get(contactaccountMap.get(cf.Contact__c) + '~' + cf.Primary_Brand__c).id;
            }
        }
    }
    
}