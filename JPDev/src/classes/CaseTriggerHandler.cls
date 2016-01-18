/***************************************************************************
// (c) 2013 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  CaseTrigger. All contexts should be in this class.
//                  
// Feb 12th, 2013  :  Naresh Ojha (Appirio Offshore)
//***************************************************************************/
public with sharing class CaseTriggerHandler {
    private boolean m_isExecuting = false;  
    private integer BatchSize = 0;

    //Constructor
    public CaseTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
  
    //On before insert trigger method
    public void OnBeforeInsert(List<Case> newList) { 

        checkIfSpamEmail(newList);
        ProductUserDefaults(newList);

    }  
  
    // On before update trigger method
    public void OnBeforeUpdate (Map<Id, Case> oldMap, Map<Id, Case> newMap) {

        ProductUserDefaults(newMap.values());

    }

    //On After insert trigger method
    public void OnAfterInsert(List<Case> newList) { 

        CountCasesForRemittanceLinks(newList);
        AssignToCSRAndSetFields (newList); 
        
    }
    
    // On After update trigger method
    public void OnAfterUpdate (Map<Id, Case> oldMap, Map<Id, Case> newMap) {
                              
        AssignToCSRAndSetFields (newMap.values());    
        
    }
  
    // On after before trigger method
    public void OnBeforeDelete (Map<Id, Case> oldMap) {

        CountCasesForRemittanceLinks(oldMap);

    }
  
    public void OnAfterDelete (Map<Id, Case> oldMap) {
        //Nothing currently...
    }
  
  
    //T-114806:  Case to assign the Case to the CSR on the Account Brand object.
    //Account restructure.  Expanded logic to help set Account Brand in more scenarios as well.
    private void AssignToCSRAndSetFields (List<Case> newList) {
		system.debug('#$$$$## in the method #### ');
        Set<String> caseAccountIDset = new Set<String>();
        Set<String> brandNameSet = new Set<String>();
        boolean bypassProfile = false; 
        
        Map<String, Map<String, Account_Brand__c>> accID_mapOfAcBrandId_AB_Map = new Map<String, Map<String, Account_Brand__c>>();
        
        //New created map to remove contact reference map.
        Map<String, String> caseID_AccID_Map = new Map<String, String>();
        
        //This is a list of profiles where the Case should not be reassigned to the CSR Owner on the Account Brand
        //They prefer to keep the Case or have it assigned to a Queue.  This is managed via the CaseAssignmentSetting Custom Setting
        List<String> bypassProfileList = CaseAssignUtils.CaseAssignmentProfiles();

        //Get the Profile Name for the Current User.  We will use it later when we determine if we should assign to a CSR
        Profile p = [Select Name from Profile where Id =: userinfo.getProfileId()];
        String CurrentProfile = p.Name;

        for (String s : bypassProfileList) {
            if (CurrentProfile.equals(s)) bypassProfile=true;
        }

        List<Case> caseListToUpdate = new List<Case>();
    	Map<string,string>MapCasewithAccId = new Map<string,string>();
    	Set<ID> CaseIDset = new Set<ID>();
    	for(Case c : newList){
    		
    			CaseIDset.add(c.id);
    	}
    	for(Case caserecord : [select id,accountid,contactid,contact.accountid from Case where id in:CaseIDset]){ //query case to get accountid through contact in case account is not populated
    		
    		if(caserecord.accountid!=null)
    			MapCasewithAccId.put(caserecord.id,caserecord.accountid);
    		else if (caserecord.contactid!=null && caserecord.contact.accountid!=null && caserecord.accountid==null)
    			MapCasewithAccId.put(caserecord.id,caserecord.contact.accountid);
    	}
        //Populating case contact ID and brand sets to query account brands.
        for (Case c : newList) {
            //As this map is used for more (added functionality of SetAccountBrand) the 'If' has been commented out, yet the logic comparison remain a about 25 lines down inside the 'for' loop
            //if (c.Assign_to_CSR__c == true && c.AccountID <> null && c.Brand__c <> null && c.IsClosed <> true) {                
            brandNameSet.add(c.Brand__c);
            if (!caseID_AccID_Map.containsKey(c.ID)) caseID_AccID_Map.put(c.ID, MapCasewithAccId.get(c.Id));
            caseAccountIDset.add(MapCasewithAccId.get(c.Id));
            //}
        }
    
        //Populating map to be used to assign CSR to case from account brand
        for (Account_Brand__c ab : [SELECT Account__c, Brand__c, Brand_Name__c, CS__c  
                                       FROM Account_Brand__c 
                                       WHERE Brand_Name__c IN: brandNameSet 
                                       AND Account__c IN: caseAccountIDset]) {
            if (!accID_mapOfAcBrandId_AB_Map.containsKey(ab.Account__c)) accID_mapOfAcBrandId_AB_Map.put(ab.Account__c, new Map<String, Account_Brand__c>());
            accID_mapOfAcBrandId_AB_Map.get(ab.Account__c).put(ab.Brand_Name__c, ab);    
        }
        
        //Populating case list to update
        for (Case c : newList) {
            if (c.Assign_to_CSR__c == true && c.AccountID <> null && c.Brand__c <> null && c.Origin <> 'Chat') {
                if (caseID_AccID_Map.containsKey(c.ID) &&
                     c.IsClosed <> true &&                     
                     accID_mapOfAcBrandId_AB_Map.containsKey(caseID_AccID_Map.get(c.ID)) && 
                     accID_mapOfAcBrandId_AB_Map.get(caseID_AccID_Map.get(c.ID)).containsKey(c.Brand__c) &&
                     accID_mapOfAcBrandId_AB_Map.get(caseID_AccID_Map.get(c.ID)).get(c.Brand__c).CS__c <> null
                     ) {
                    //Assigning owner from account brand. 
                    if (!bypassProfile) caseListToUpdate.add(new Case(ID = c.ID, Assign_to_CSR__c = false, isCSR_Assignment_Found__c = true, Account_Brand__c = accID_mapOfAcBrandId_AB_Map.get(caseID_AccID_Map.get(c.ID)).get(c.Brand__c).Id,  OwnerId = accID_mapOfAcBrandId_AB_Map.get(caseID_AccID_Map.get(c.ID)).get(c.Brand__c).CS__c));
                    else caseListToUpdate.add(new Case(ID = c.ID, Assign_to_CSR__c = false, isCSR_Assignment_Found__c = false, Account_Brand__c = accID_mapOfAcBrandId_AB_Map.get(caseID_AccID_Map.get(c.ID)).get(c.Brand__c).Id));
                } 
                else if (c.Account_Brand__c == null) {
                    //Account restructure
                    Case updatedCase = SetAccountBrand(c, accID_mapOfAcBrandId_AB_Map, caseID_AccID_Map);
                    if (updatedCase != null) caseListToUpdate.add(updatedCase);
                }
            }
            else if (c.Account_Brand__c == null) {
                //Account restructure
                Case updatedCase = SetAccountBrand(c, accID_mapOfAcBrandId_AB_Map, caseID_AccID_Map);
                if (updatedCase != null) caseListToUpdate.add(updatedCase);                
            } 
        }

        if (!caseListToUpdate.isEmpty()) update caseListToUpdate;
    }  
  

    private Case SetAccountBrand(Case c, Map<String, Map<String, Account_Brand__c>> accID_mapOfAcBrandId_AB_Map, Map<String, String> caseID_AccID_Map) {

        if (c.Id != null 
                && c.Brand__c != null 
                && caseID_AccID_Map.containsKey(c.Id) 
                && accID_mapOfAcBrandId_AB_Map.containsKey(caseID_AccID_Map.get(c.Id)) 
                && accID_mapOfAcBrandId_AB_Map.get(caseID_AccID_Map.get(c.Id)).containsKey(c.Brand__c)) {
           
            return new Case(Id = c.Id, Account_Brand__c = accID_mapOfAcBrandId_AB_Map.get(caseID_AccID_Map.get(c.Id)).get(c.Brand__c).Id);

        }

        return null;
    }

  
    // Check if a new email-to-case subject line is spam or junk email
    private void checkIfSpamEmail (List<Case> newList) {

        List<Case> caseListToAllow = new List<Case>();

        //Group g = [SELECT Id FROM Group WHERE Name = 'Email-SPAM/JUNK' LIMIT 1];
        List<String> regexList = new List<String>();
        List<Spam_Filter_List__c> splc = Spam_Filter_List__c.getall().values();
        for (Spam_Filter_List__c t: splc) { 
            regexList.add(t.Spam_RegEx_Text__c.trim()); 
        }
           
        for (Integer j = 0; j < newList.size(); j++) {

            if (String.isBlank(newList.get(j).Subject)) {
                continue;
            }
                
            for (Integer a = 0; a < regexList.size(); a++) {
            
                Pattern pat = Pattern.compile(regexList[a]);
                Matcher patm = pat.matcher( newList.get(j).Subject );            
                if (patm.matches()) {
                    newList.get(j).addError('Bad data');          
                    //System.debug('Found email with matching subject line');
                    continue;
                }
            }
        }
    } 

    private void ProductUserDefaults (List<Case> newList) {
        //This was mainly implemented for the LIve Agent chat so that when a Product USer is associated to the Chat Case, the Account, Contact, User Group., and Account Brand are also set

        Set<String> puIDset = new Set<String>();
        //New created map to set reference fields.
        Map<String, Product_User__c> PUMap = new Map<String, Product_User__c>();
        List<Case> caseListToUpdate = new List<Case>();

        for (Case thecase : newList) {
            puIDset.add(theCase.Product_User__c);
        }

        //Populating map to be used to set the Product User fields
        for (Product_User__c pu : [SELECT Id, Account__c, Account_Brand__c, Contact__c, User_Group__c
                                       FROM Product_User__c 
                                       WHERE Id IN: puIDset]) {
            if (!PUMap.containsKey(pu.Id)) PUMap.put(pu.Id, pu);      
        }

        for (Case checkCases : newList) {
            if (checkCases.Product_User__c != null) {
                if (checkCases.AccountId == null) checkCases.AccountId = PUMap.get(checkCases.Product_User__c).Account__c;
                if (checkCases.ContactId == null) checkCases.ContactId = PUMap.get(checkCases.Product_User__c).Contact__c;
                if (checkCases.User_Group__c == null) checkCases.User_Group__c = PUMap.get(checkCases.Product_User__c).User_Group__c;
                if (checkCases.Account_Brand__c == null) checkCases.Account_Brand__c = PUMap.get(checkCases.Product_User__c).Account_Brand__c;
            }
        }
    }

    //For insert...
    private void CountCasesForRemittanceLinks(List<Case> newList) {

        Set<Id> remittanceLinkIdSet = new Set<Id>();
        Map<Id, List<Case>> remittanceCaseMap = new Map<Id, List<Case>>();
        List<Payment_Link__c> rlListToUpdate = new List<Payment_Link__c>();

        for (Case c : newList) {
            if (c.Remittance_Link__c != null) remittanceLinkIdSet.add(c.Remittance_Link__c);
        }

        for (Case c : [SELECT Id, Remittance_Link__c, IsDeleted FROM Case WHERE Remittance_Link__c IN :remittanceLinkIdSet]) {
            if (!remittanceCaseMap.containsKey(c.Remittance_Link__c)) remittanceCaseMap.put(c.Remittance_Link__c, new List<Case>());
            remittanceCaseMap.get(c.Remittance_Link__c).add(c);
        }

        for (Id thisId : remittanceCaseMap.keySet()) {
            Payment_Link__c rl = new Payment_Link__c(Id = thisId, NumberCases__c = remittanceCaseMap.get(thisId).size());
            rlListToUpdate.add(rl);
        }

        if (!rlListToUpdate.isEmpty()) update rlListToUpdate;
    }

    //For delete...
    private void CountCasesForRemittanceLinks(Map<Id, Case> oldMap) {

        Set<Id> remittanceLinkIdSet = new Set<Id>();
        Map<Id, List<Case>> remittanceCaseMap = new Map<Id, List<Case>>();
        List<Payment_Link__c> rlListToUpdate = new List<Payment_Link__c>();

        for (Case c : oldMap.values()) {
            if (c.Remittance_Link__c != null) remittanceLinkIdSet.add(c.Remittance_Link__c);
        }

        for (Case c : [SELECT Id, Remittance_Link__c, IsDeleted FROM Case WHERE Remittance_Link__c IN :remittanceLinkIdSet]) {
            if (!remittanceCaseMap.containsKey(c.Remittance_Link__c)) remittanceCaseMap.put(c.Remittance_Link__c, new List<Case>());
            if (!oldMap.containsKey(c.Id)) remittanceCaseMap.get(c.Remittance_Link__c).add(c);
        }

        for (Id thisId : remittanceCaseMap.keySet()) {
            Payment_Link__c rl = new Payment_Link__c(Id = thisId, NumberCases__c = remittanceCaseMap.get(thisId).size());
            rlListToUpdate.add(rl);
        }

        if (!rlListToUpdate.isEmpty()) update rlListToUpdate;
    }     
}