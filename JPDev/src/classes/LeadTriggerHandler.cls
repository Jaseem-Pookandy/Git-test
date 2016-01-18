/***************************************************************************
// (c) 2013 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  LeadTrigger. All contexts should be in this class.
//                  
// Jan 09th, 2013  :  Naresh Ojha (Appirio Offshore)
// Jan 23rd, 2013    :  Naresh Ojha Updated for Tastk T-111795
// Mar 13th, 2013    :  Naresh Ojha Updated for Tastk T-123867
//***************************************************************************/
public with sharing class LeadTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  public Map<String, Brand__c> brandMap;   
  //Constructor
  public LeadTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
    brandMap = new Map<String, Brand__c>();
    brandMap = CommonUtil.getBrandMap();
  }
  
  //On before insert trigger method
  public void OnBeforeInsert(List<Lead> newList) { 
    CommonUtil.AssignJobTitle(newList, null , 'Lead');
    setRelatedAccountByCompany(newList, new Map<ID, Lead>());
    //T-110465 auto assign owner if status of lead is : Open Not connected
    populateFieldsOnLead(newList, new Map<ID, Lead>());
  }  
  // On before update trigger method
  public void OnBeforeUpdate (Map<Id, Lead> oldMap, Map<Id, Lead> newMap) {
    CommonUtil.AssignJobTitle(newMap.values(), oldMap , 'Lead');
    setRelatedAccountByCompany(newMap.values(), oldMap);
    //T-110465 auto assign owner if status of lead is : Open Not connected
    populateFieldsOnLead(newMap.values(), oldMap);
    //On lead conversion
    populateBrandOwner(oldMap, newMap);
    //needsSetOnAccountBrands(newMap, oldMap);//T-110849
  }
  
  //On after update trigger method
  public void OnAfterUpdate (Map<ID, Lead> oldMap, Map<ID, Lead> newMap)  {
    needsSetOnAccountBrands(newMap, oldMap);//T-110849
    //Removed for CC-2643
    //sendMailToAutoAssignedOwner(newMap.values(), oldMap);
    
    //byrnes, 2013.09.05
    if (PreventRecursiveExecution.isFirstRun)
    {
        PreventRecursiveExecution.isFirstRun = false;
        UpdateStateCountryOnOpenTasks(oldMap, newMap);
    }           
  }
  

  //byrnes, new 2013.09.05, CC-597
  private void UpdateStateCountryOnOpenTasks (Map<Id, Lead> oldMap, Map<Id, Lead> newMap)
  {
    List<Task> tasksToUpdate = new List<Task>();
    Map<String, List<Task>> mapTasks = new Map<String, List<Task>>();
    
    String currentID = '';
    List<Task> tasksForMap = new List<Task>();
    
    for (Task t : [SELECT Id, State_Person__c, Country_Person__c, Account_Brand_Rank__c, WhoId FROM Task WHERE IsClosed = false AND WhoId IN : oldMap.Values()]) {
        if (currentID != String.valueOf(t.WhoId)) {
            
            if ((currentID != '') && (tasksForMap.size() > 0)) mapTasks.put(currentID, tasksForMap);
            tasksForMap.clear();
            currentID = t.WhoId;
        }
        
        tasksForMap.add(t);
    }
    //very last one to add...
    mapTasks.put(currentID, tasksForMap);
    
    for (Lead l : oldMap.values()) {
        if ((l.State != newMap.get(l.Id).State) || (l.Country != newMap.get(l.Id).Country) || (l.Rank__c != newMap.get(l.Id).Rank__c)) {
            
            //Then either the state or country changed.  In that case, update tasks...
            if (mapTasks.containsKey(l.Id)) {
                List<Task> affectedTasks = mapTasks.get(l.Id);
                if (affectedTasks.size() > 0) {
                    for (Task affectedTask : affectedTasks) {
                        affectedTask.State_Person__c = newMap.get(l.Id).State;
                        affectedTask.Country_Person__c = newMap.get(l.Id).Country;
                        affectedTask.Account_Brand_Rank__c = newMap.get(l.Id).Rank__c;
                        
                        tasksToUpdate.add(affectedTask);
                    }
                }
            }
        }
    }
    
    if (tasksToUpdate.size() > 0) update tasksToUpdate;
  }


 
  private void populateBrandOwner (Map<Id, Lead> oldMap, Map<Id, Lead> newMap) {
    Boolean flagABcheck = true;
    Set<String> brandSet = new Set<String>();
    Set<ID> convertedContactIDset = new Set<ID>();
    Set<String> convertedAccID_set = new Set<String>();
    Set<String> countrySet = new Set<String>();
    Set<String> convertedLeadIdSet = new Set<String>();
    Set<Id> convertedContactIDForBrandType = new Set<Id>();  //CC-940
    
    Map<ID, Lead> contID_LeadMap = new Map<ID, Lead>();
    Map<String, List<Account_Brand__c>> accountID_listOfBrand_Map =
                                   new Map<String, List<Account_Brand__c>>();
    Map<String, Brand__c> brID_BrandMap = CommonUtil.getBrandMap();
    Map<String, String> contName_contID_Map = new Map<String, String>();
    //for Task T-111795
    Map<String, String> oppIdContactIdMap = new Map<String, String>();
    Map<String, Lead> oppIDLeadMap = new Map<String, Lead>();
    Map<String, Account_Brand__c> acIDbrandID_AccountBrandMap = new Map<String, Account_Brand__c>();
    
    //T-125620
    Map<String, String> LeadIDBrand_CampaignIDMap = new Map<String, String>();
    
    //List to get inserted
    List<Account_Brand__c> accBrandListToUpdate = new List<Account_Brand__c>();
    
    //Temp objects to use to add list.
    Account_Brand__c acBrandObj;
     
    //Creating set for account IDs for converted leads
      for(Lead l : newMap.values()) {
          //for Task T-111795
          if(l.IsConverted && l.ConvertedOpportunityId <> null && l.ConvertedContactId <> null) {
            if(!oppIdContactIdMap.containsKey(l.ConvertedOpportunityId)) {
              oppIdContactIdMap.put(l.ConvertedOpportunityId, l.ConvertedContactId);
            }
            oppIDLeadMap.put(l.ConvertedOpportunityId, l);
            convertedLeadIdSet.add(l.ID);
          }
        if(l.IsConverted <> oldMap.get(l.ID).isConverted && l.isConverted == true) {
          convertedAccID_set.add(l.ConvertedAccountId);
          countrySet.add(l.Country);
          if (l.Brand__c <> null) {
            brandSet.add(l.Brand__c);
          }
        }
        //T-120993
        if (l.HasOptedOutOfEmail == true && l.ConvertedContactId <> null) {
            convertedContactIDset.add(l.ConvertedContactId);
            if (!contID_LeadMap.containsKey(l.ConvertedContactId)) {
             contID_LeadMap.put(l.ConvertedContactId, l);
            }
        }
        if (l.ConvertedContactId <> null) convertedContactIDForBrandType.add(l.ConvertedContactId);     //CC-940
        
      }
      //T-125620
      for (CampaignMember cm : [SELECT Lead.Brand__c, CreatedDate, LeadId, 
                                        ContactId, CampaignId, Campaign.Brand__c 
                                    FROM CampaignMember  
                                    WHERE LeadId = :convertedLeadIdSet AND Campaign.Influential_Campaign_Cutoff__c >= TODAY
                                                   ORDER BY CreatedDate DESC]) {
      if (newMap.get(cm.LeadID).Brand__c <> null &&
          cm.Campaign.Brand__c <> null &&  
            String.valueOf(cm.Campaign.Brand__c).contains(newMap.get(cm.LeadID).Brand__c)) {
            if (!LeadIDBrand_CampaignIDMap.containsKey(cm.LeadID + '-' + cm.Lead.Brand__c)) {
                LeadIDBrand_CampaignIDMap.put(cm.LeadID + '-' + cm.Lead.Brand__c, cm.CampaignId);
            }
      }
      }

    //Getting associated account brand for accounts of leads.
    for(Account a : [Select ID, (Select Id, Brand__c, Primary_Owner__c, Brand_Name__c, Account__c , Brand__r.isExplicit_Renewal_Owner_Required__c
                                     From Account_Brands__r) 
                          From Account WHERE ID IN :convertedAccID_set]) {
      if(!accountID_listOfBrand_Map.containsKey(a.ID)) {
        accountID_listOfBrand_Map.put(a.ID, new List<Account_Brand__c>());
        for(Account_Brand__c ab : a.Account_Brands__r){
          accountID_listOfBrand_Map.get(a.ID).add(ab);
          if(ab.Brand__c <> null && !acIDbrandID_AccountBrandMap.containsKey(a.ID + '-' + ab.Brand_Name__c)) {
            acIDbrandID_AccountBrandMap.put(a.ID + '-' + ab.Brand_Name__c, ab);
          }
        }
      }
    }
          
    //T-125620 && T-111795
    if(oppIdContactIdMap <> null && oppIdContactIdMap.size() > 0) {
      List<Opportunity> oppToUpdate = [SELECT Contact__c, Brands__c, Account_Brand__c, OwnerId, Account_Brand__r.Primary_Owner__c, Account_brand__r.Brand__r.isExplicit_Renewal_Owner_Required__c FROM Opportunity 
                                       WHERE ID IN :oppIdContactIdMap.keySet()];
      
      for(Opportunity opp : oppToUpdate) {
        opp.Contact__c = oppIdContactIdMap.get(opp.Id); //Task T-111795
        
        if (oppIDLeadMap.containsKey(opp.ID) && 
              oppIDLeadMap.get(opp.ID).Brand__c <> null) {
          if(LeadIDBrand_CampaignIDMap.containsKey(oppIDLeadMap.get(opp.ID).ID + '-' + oppIDLeadMap.get(opp.ID).Brand__c)) {
            opp.CampaignId = LeadIDBrand_CampaignIDMap.get(oppIDLeadMap.get(opp.ID).ID + '-' + oppIDLeadMap.get(opp.ID).Brand__c);
          }

          if (acIDbrandID_AccountBrandMap.containsKey(oppIDLeadMap.get(opp.ID).ConvertedAccountId + '-' + oppIDLeadMap.get(opp.ID).Brand__c)) {
            opp.Account_Brand__c = acIDbrandID_AccountBrandMap.get(oppIDLeadMap.get(opp.ID).ConvertedAccountId + '-' + oppIDLeadMap.get(opp.ID).Brand__c).ID;
            
            //I-50273            
            if(acIDbrandID_AccountBrandMap.get(oppIDLeadMap.get(opp.ID).ConvertedAccountId + '-' + oppIDLeadMap.get(opp.ID).Brand__c).Brand__r.isExplicit_Renewal_Owner_Required__c == true){
                opp.Renewal_Owner_Assigned__c = acIDbrandID_AccountBrandMap.get(oppIDLeadMap.get(opp.ID).ConvertedAccountId + '-' + oppIDLeadMap.get(opp.ID).Brand__c).Primary_Owner__c;
                if(opp.Renewal_Owner_Assigned__c == null) opp.Renewal_Owner_Assigned__c = opp.OwnerId;
            }
          }
        }
      }
      
      if(!oppToUpdate.isEmpty()) {
        update oppToUpdate;
      }
    }
    
    //Populating country map
    for(pw_ccpro__CountryObject__c cnt : [SELECT ID, Name 
                                               FROM pw_ccpro__CountryObject__c 
                                               WHERE Name IN: countrySet]) {
      if(!contName_contID_Map.containsKey(cnt.Name)) {
        contName_contID_Map.put(cnt.Name, cnt.ID);
      }
    }
    Boolean abExist = false;
    //Setting primary owner for Account Brand
    for(Lead l : newMap.values()) {
      if(l.Brand__c <> null && l.ConvertedAccountId<> null && //converted account id is not null 
            l.IsConverted <> oldMap.get(l.ID).isConverted &&  //lead is converted
            l.isConverted == true &&  
            accountID_listOfBrand_Map.containsKey(l.ConvertedAccountId)) {

        //If account brand exist for associated account with lead.
        if(accountID_listOfBrand_Map.containsKey(l.ConvertedAccountId)) {
            for(Account_Brand__c ab : accountID_listOfBrand_Map.get(l.ConvertedAccountId)) {
                if(brID_BrandMap.containsKey(l.Brand__c) && 
                                    ab.Brand__c ==  brID_BrandMap.get(l.Brand__c).ID) {
                    abExist = true;
                    break;
                }
            }
            //If Account brand not exist
            if(!abExist) {
              acBrandObj = new Account_Brand__c();
              acBrandObj.Account__c = l.ConvertedAccountId;
              acBrandObj.Brand__c = brID_BrandMap.get(l.Brand__c).ID;
              acBrandObj.Primary_Owner__c = l.OwnerId;
              acBrandObj.Rank__c = l.Rank__c;
                acBrandObj.Market_Segment__c = l.Market_Segment__c;
              accBrandListToUpdate.add(acBrandObj);
            } else {
            //if account brand exist.
                for(Account_Brand__c ab : accountID_listOfBrand_Map.get(l.ConvertedAccountId)) {
                    if(ab.Primary_Owner__c == null && ab.Brand__c == brID_BrandMap.get(l.Brand__c).ID) {
                        ab.Primary_Owner__c = l.OwnerId;
                        ab.Rank__c = l.Rank__c;
                        accBrandListToUpdate.add(ab);
                                  if (l.Market_Segment__c <> null) {
                                    ab.Market_Segment__c = l.Market_Segment__c;
                                  }                        
                    } else if(ab.Primary_Owner__c <> null && ab.Brand__c == brID_BrandMap.get(l.Brand__c).ID ) {
                        if(ab.Primary_Owner__c <> l.OwnerId) {
                             /*commented against issue : I-43887 Naresh O.(appirio off)*/
                           /* ab.Primary_Owner__c = l.OwnerId;
                            ab.Rank__c = l.Rank__c;
                            accBrandListToUpdate.add(ab);*/
                        }
                    }            
                }
            }
        } 
      }
    }    
    //calling update account brand to the list to update
    if(!accBrandListToUpdate.isEmpty()) {
        upsert accBrandListToUpdate;
    }
   
    if (convertedContactIDset.size() > 0 && contID_LeadMap.size() > 0) {
      setNverEmailonContactType(convertedContactIDset);   
    } 
    
    if (convertedContactIDForBrandType.size() > 0) setContactTypeType(convertedContactIDForBrandType);
  }
  
  //CC-940
  @future
  private static void setContactTypeType (Set<ID> contactIDset) {
    Set<ID> accountBrandIdSet = new Set<ID>();
    List<Contact_Type__c> contactTypeList = new List<Contact_Type__c>();
    List<Contact_Type__c> contactTypeListUpdate = new List<Contact_Type__c>();
    Map<ID, Lead> contID_LeadMap = new Map<ID, Lead>();    
        
    Map<ID, Account_Brand__c> abID_accountBrandMap = new Map<ID, Account_Brand__c>();

    //Querying leads which has converted contact id
    for (Lead lead : [SELECT Id, ConvertedContactId, Brand__c, Type__c FROM Lead WHERE ConvertedContactId IN : contactIDset] ) {
      
      if (!contID_LeadMap.containsKey(lead.ConvertedContactId)) contID_LeadMap.put(lead.ConvertedContactId, lead);
    }
        
    //Populating contact ID set and account brand set
    for (Contact_Type__c ct : [SELECT Account_Brand__r.Name, Name, Account_Brand__c, ID, Never_Email__c, Contact__c, Type__c FROM Contact_Type__c WHERE Contact__c IN: contactIDset]) {
      if (ct.Account_Brand__c <> null) accountBrandIdSet.add(ct.Account_Brand__c);
      contactTypeList.add(ct);
    }
    
    //getting account brands for contact types.
    for (Account_Brand__c ab : [SELECT ID, Brand__c, Brand_Name__c FROM Account_Brand__c WHERE ID IN : accountBrandIdSet]) {
      if (!abID_accountBrandMap.containsKey(ab.ID)) abID_accountBrandMap.put(ab.ID, ab);
    }
    
    for (Contact_Type__c ct : contactTypeList) {
        if (abID_accountBrandMap.containsKey(ct.Account_Brand__c) && contID_LeadMap.containsKey(ct.Contact__c) && contID_LeadMap.get(ct.Contact__c).Brand__c == abID_accountBrandMap.get(ct.Account_Brand__c).Brand_Name__c) {
            String sType = 'Other';
            if (contID_LeadMap.get(ct.Contact__c).Type__c != null) sType = contID_LeadMap.get(ct.Contact__c).Type__c;
             
            ct.Type__c = sType;
            contactTypeListUpdate.add(ct);
        }
    }
    
    if (!contactTypeListUpdate.isEmpty()) {
        update contactTypeListUpdate; 
    }
  }  
  
  //T-120993
  @future
  private static void setNverEmailonContactType (Set<ID> contactIDset) {//, Map<ID, Lead> contID_LeadMap) {
    Set<ID> accountBrandIdSet = new Set<ID>();
    List<Contact_Type__c> contactTypeList = new List<Contact_Type__c>();
    List<Contact_Type__c> contactTypeListUpdate = new List<Contact_Type__c>();
    Map<ID, Lead> contID_LeadMap = new Map<ID, Lead>();    
        
    Map<ID, Account_Brand__c> abID_accountBrandMap = new Map<ID, Account_Brand__c>();

    //Querying leads which has converted contact id
    for ( Lead lead : [SELECT Id, ConvertedContactId, Brand__c 
                             FROM Lead 
                             WHERE ConvertedContactId IN : contactIDset] ) {
      
      if (!contID_LeadMap.containsKey(lead.ConvertedContactId)) {
        contID_LeadMap.put(lead.ConvertedContactId, lead);
      }
    }
        
    //Populating contact ID set and account brand set
    for (Contact_Type__c ct : [SELECT Account_Brand__r.Name, Name, Account_Brand__c, ID, Never_Email__c, Contact__c 
                                  FROM Contact_Type__c
                                  WHERE Contact__c IN: contactIDset]) {
      if (ct.Account_Brand__c <> null) {
        accountBrandIdSet.add(ct.Account_Brand__c);
      }
      contactTypeList.add(ct);
    }
    //getting account brands for contact types.
    for (Account_Brand__c ab : [SELECT ID, Brand__c, Brand_Name__c 
                                        FROM Account_Brand__c 
                                        WHERE ID IN : accountBrandIdSet]) {
      if (!abID_accountBrandMap.containsKey(ab.ID)) {
        abID_accountBrandMap.put(ab.ID, ab);
      }
    }
    
    for (Contact_Type__c ct : contactTypeList) {
        if (abID_accountBrandMap.containsKey(ct.Account_Brand__c) && 
            contID_LeadMap.containsKey(ct.Contact__c) &&
            contID_LeadMap.get(ct.Contact__c).Brand__c == abID_accountBrandMap.get(ct.Account_Brand__c).Brand_Name__c) {
          ct.Never_Email__c = true;
          contactTypeListUpdate.add(ct);
        }
    }
    
    if (!contactTypeListUpdate.isEmpty()) {
        update contactTypeListUpdate; 
    }
    
  }
  
  //-------------------------------------------------------------------------  
  // CC-750: Find the best account for lead matching...
  //-------------------------------------------------------------------------
  private Account FindBestAccount(Lead l, List<Account> possibleMatches) {      
    //FIND the related account...
    Integer topRating = -1;
    Account bestMatch;
    Integer currentRating = 0;   
        
    for (Account a : possibleMatches) {         
        //if we're here, we automatically rate to 1000 because company and country match.
        currentRating = 1000;
        
        //Begin state comparison
        //If the Lead has a state, and it's equal, add 100 points.
        if ((l.State != null) && (l.State != '') && (l.State == a.BillingState)) currentRating +=100;
        //If the Lead has a state and it's NOT equal, subtract 10000 points  (i.e. kick it)
        else if ((l.State != null) && (l.State != '') && (a.BillingState != null) && (a.BillingState != '') && (l.State != a.BillingState)) currentRating -=10000;
        //If the Lead has a state and the account does NOT, add 50 points
        else if ((l.State != null) && (l.State != '') && ((a.BillingState == null) || (a.BillingState != ''))) currentRating +=50;
        //If both the Lead and the Account have no state, add 10 points
        else if (((l.State == null) || (l.State == '')) && ((a.BillingState == null) || (a.BillingState != ''))) currentRating +=10;
        //End state comparison
        
        //Begin city comparison
        //If the Lead has a city, and it's equal, add 10 points.
        if ((l.City != null) && (l.City != '') && (l.City == a.BillingCity)) currentRating +=10;
        //If the Lead has a city and it's NOT equal, subtract 100 points
        else if ((l.City != null) && (l.City != '') && (a.BillingCity != null) && (a.BillingCity != '') && (l.City != a.BillingCity)) currentRating -=100;
        //If the Lead has a city and the account does NOT, add 5 points
        else if ((l.City != null) && (l.City != '') && ((a.BillingCity == null) || (a.BillingCity != ''))) currentRating +=5;
        //If both the Lead and the Account have no city, add 1 point
        else if (((l.City == null) || (l.City == '')) && ((a.BillingCity == null) || (a.BillingCity != ''))) currentRating +=1;
        //End city comparison
        
        if ((currentRating >= 0) && (currentRating > topRating)) {
            topRating = currentRating;
            bestMatch = a;
        }
    }
  
    return bestMatch;
  }
  
  //-------------------------------------------------------------------------  
  // T-107110: Set Lead's related account on the basis of company name.
  //-------------------------------------------------------------------------  
  private void setRelatedAccountByCompany(List<Lead> newList, 
                                              Map<ID, Lead> oldMap) {
    
    Set<String> companyNameSet = new Set<String>();
    Set<String> relatedAccountSet = new Set<String>();
    
    Map<String, List<Account>> companyName_RelAccountMap = new Map<String, List<Account>>(); 
    Map<String, String> accID_RelAccountMap = new Map<String, String>();

    for(Lead l : newList) {
      if(l.Related_Account__c == null && l.Company <> null && l.Company <> '') companyNameSet.add(l.Company);
      else if(l.Related_Account__c <> null) relatedAccountSet.add(l.Related_Account__c);
    }
    
    //Company name = account name
    List<Account> possibleMatches = new List<Account>();
    String previousKey;
    String currentKey;
    
    //START - This for loop is for populating the Lead.Related Account field FROM the Lead.Company name field
    for(Account a : [SELECT ID, Name, BillingCountry, BillingState, BillingCity FROM Account WHERE Name IN :companyNameSet ORDER BY Name, BillingCountry]) {
        currentKey = a.Name + '~~' + a.BillingCountry;
        
        if ((currentKey != previousKey) && (previousKey != null) && ((!companyName_RelAccountMap.containsKey(currentKey))) && (possibleMatches.size() > 0)) {
            companyName_RelAccountMap.put(previousKey, possibleMatches.clone());
            possibleMatches.clear();
        }
    
        possibleMatches.add(a);
        previousKey = currentKey;  
    }
    
    if (((!companyName_RelAccountMap.containsKey(currentKey))) && (possibleMatches.size() > 0)) {
        companyName_RelAccountMap.put(previousKey, possibleMatches.clone());
        possibleMatches.clear();
    }
    //END - This for loop is for populating the Lead.Related Account field FROM the Lead.Company name field 
    
    //This for loop is for populating the Lead.Company name field FROM the Lead.Related Account field.
    for(Account a : [SELECT ID, Name FROM Account WHERE ID IN :relatedAccountSet]) {
      if(!accID_RelAccountMap.containsKey(a.ID)) {
        accID_RelAccountMap.put(a.ID, a.Name);
      }
    }
    
    //For insert
    if(oldMap.isEmpty()) {
      for(Lead l : newList) {
        if(l.Related_Account__c == null && l.Company <> null && l.Company <> '' && companyName_RelAccountMap.containsKey(l.Company + '~~' + l.Country)) {
            Account bestMatch = FindBestAccount(l, companyName_RelAccountMap.get(l.Company + '~~' + l.Country));
            if (bestMatch != null) l.Related_Account__c = bestMatch.Id; 
            
            //l.Related_Account__c = companyName_RelAccountMap.get(l.Company);
        } else if(l.Related_Account__c <> null) l.Company = accID_RelAccountMap.get(l.Related_Account__c);
      }
    } 
    else { //For update
      for(Lead l : newList) {       
        if(l.Related_Account__c == null && l.Company <> null && l.Company <> '' && l.Company <> oldMap.get(l.ID).Company && companyName_RelAccountMap.containsKey(l.Company + '~~' + l.Country)) {
            //set related account
            Account bestMatch = FindBestAccount(l, companyName_RelAccountMap.get(l.Company + '~~' + l.Country));
            if (bestMatch != null) l.Related_Account__c = bestMatch.Id;          
          
            //l.Related_Account__c = companyName_RelAccountMap.get(l.Company);
        } else if(l.Related_Account__c <> null) l.Company = accID_RelAccountMap.get(l.Related_Account__c);
      }     
    }
  }
  
  //T-110465 auto assign owner if status of lead is : Open Not connected
  //and T-123867 : Populate Lead.Account_Band__c
  private void populateFieldsOnLead (List<Lead> newList, Map<ID, Lead> oldMap) {
    Set<String> accIDset = new Set<String>();
    Set<String> brandIDset = new Set<String>();
    Map<String, String> acIDbrandID_PrimOwnerMap = new Map<String, String>();
    Map<String, Account_Brand__c> acIDbrandID_AccountBrandMap = new Map<String, Account_Brand__c>();
    
    //For update
    if(!oldMap.isEmpty()) {
        for(Lead l : newList) {
            if(l.Related_Account__c <> null && l.Brand__c <> null &&
                   brandMap.containsKey(l.Brand__c)) {
                    
               accIDset.add(l.Related_Account__c);
               brandIDset.add(brandMap.get(l.Brand__c).ID);
            }
        }
    } else { //For insert
      for(Lead l : newList) {
        if(l.Related_Account__c <> null &&
               l.Brand__c <> null && brandMap.containsKey(l.Brand__c)) {

           accIDset.add(l.Related_Account__c);
           brandIDset.add(brandMap.get(l.Brand__c).ID);
        }
      }
    }

    for(Account_Brand__c ab: [SELECT ID, Primary_Owner__c, Account__c, Brand__c 
                                 FROM Account_Brand__c 
                                 WHERE Account__c IN : accIDset 
                                 AND Brand__c IN: brandIDset]) {
        if(!acIDbrandID_PrimOwnerMap.containsKey(ab.Account__c+'-'+ab.Brand__c) && 
            ab.Primary_Owner__c <> null && ab.Account__c <> null && ab.Brand__c <> null) {
        
            acIDbrandID_PrimOwnerMap.put(ab.Account__c + '-' + ab.Brand__c, ab.Primary_Owner__c);
        }
        //As per : T-123867
        if(ab.Brand__c <> null && !acIDbrandID_AccountBrandMap.containsKey(ab.Account__c)) {
            acIDbrandID_AccountBrandMap.put(ab.Account__c + '-' + ab.Brand__c, ab);
        }
    }

    //For update
    if(!oldMap.isEmpty()) {
      for(Lead l : newList) {
        if(l.Status == Constants.LEADSTATUS_OPEN_NOTCONNECTED && 
               l.Status <> oldMap.get(l.ID).Status &&  
               l.Related_Account__c <> null &&
               l.Brand__c <> null && brandMap.containsKey(l.Brand__c) && 
               acIDbrandID_PrimOwnerMap.containsKey(l.Related_Account__c+'-'+brandMap.get(l.Brand__c).ID)) {
          //Assign owner
          l.OwnerId = acIDbrandID_PrimOwnerMap.get(l.Related_Account__c+'-'+brandMap.get(l.Brand__c).ID);
          l.AutoAssignedOwner__c = true; 
        }
        //As per : T-123867
        if (l.Related_Account__c <> null && l.Brand__c <> null && acIDbrandID_AccountBrandMap.containsKey(l.Related_Account__c+'-'+brandMap.get(l.Brand__c).ID)) {
            //if added on 2013.08.30 to account for deleting account brands
            //if this field wasn't updated, then it's equal and we want this field to be set.
            //if it is not equal, that means it was just updated from 'AccountBrandTriggerHandler' so we're good.
            if (l.Set_Account_Brand_Override__c == oldMap.get(l.Id).Set_Account_Brand_Override__c) {
                l.Account_Brand__c = acIDbrandID_AccountBrandMap.get(l.Related_Account__c+'-'+brandMap.get(l.Brand__c).ID).ID;
            }
        }
        
        //in case if the user blanked out related account and the value for account_brand still existed, clear it...
        //part of CC-750
        if ((l.Related_Account__c == null) && (l.Account_Brand__c != null)) {
            l.Account_Brand__c = null;
        }
      }
    } else { //For insert
      for(Lead l : newList) {
        if(l.Status == Constants.LEADSTATUS_OPEN_NOTCONNECTED &&              
               l.Related_Account__c <> null &&
               l.Brand__c <> null && brandMap.containsKey(l.Brand__c) &&
               acIDbrandID_PrimOwnerMap.containsKey(l.Related_Account__c+'-'+brandMap.get(l.Brand__c).ID)) {
          //Assign owner
          l.OwnerId = acIDbrandID_PrimOwnerMap.get(l.Related_Account__c+'-'+brandMap.get(l.Brand__c).ID);
          l.AutoAssignedOwner__c = true;
        }
        //As per : T-123867
        if (l.Related_Account__c <> null && l.Brand__c <> null && 
               acIDbrandID_AccountBrandMap.containsKey(l.Related_Account__c+'-'+brandMap.get(l.Brand__c).ID)) {
          l.Account_Brand__c = acIDbrandID_AccountBrandMap.get(l.Related_Account__c+'-'+brandMap.get(l.Brand__c).ID).ID;
        }
      }
    }

  }

  /*
  //T-111535
  private void sendMailToAutoAssignedOwner(List<Lead> newList, Map<ID, Lead> oldMap) {
    Set<String> userIDset = new Set<String>();
    Map<String, Lead> uid_leadMap = new Map<String, Lead>();
    List<Lead> leadsToUpdate = new List<Lead>();
    String orgUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
    String[] toAddresses;
    String emailSubject = '';
    String emailBody = '';
    EmailTemplate emailTemplate = [SELECT Subject, Name, IsActive, Id, 
                                      HtmlValue, DeveloperName, Body 
                                      From EmailTemplate 
                                      WHERE DeveloperName 
                                      =: Constants.LEADNOTIFICATIONTEMPLATE LIMIT 1];
    for(Lead l : newList) {
        if(!oldMap.isEmpty()) {
            if(l.AutoAssignedOwner__c == true && l.OwnerId <> oldMap.get(l.ID).OwnerID) {
                userIDset.add(l.OwnerId);
                uid_leadMap.put(l.OwnerId, l);
            }
        } else {
        if(l.AutoAssignedOwner__c == true) {
          userIDset.add(l.OwnerId);
          uid_leadMap.put(l.OwnerId, l);
        }
        }
    }
    Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();    

    for(User u : [SELECT ID, Email FROM User WHERE ID IN : userIDset]) {
        if (uid_leadMap.containsKey(u.ID) && System.Userinfo.getLastName() != 'Migration') {
            toAddresses = new String[] {u.Email};
            emailSubject = emailTemplate.Subject;
            emailBody = emailTemplate.Body;
        
        emailSubject = emailSubject.replace('{!Lead.Name}', (
         (uid_leadMap.get(u.ID).FirstName <> null) ? uid_leadMap.get(u.ID).FirstName : '') +
           ' '+ 
         ((uid_leadMap.get(u.ID).LastName <> null )? uid_leadMap.get(u.ID).LastName : '')
        );
        
        emailSubject = emailSubject.replace('{!Lead.Company}', ((uid_leadMap.get(u.ID).Company <> null) ? uid_leadMap.get(u.ID).Company : ''));
        
            emailBody = emailBody.replace('{!Lead.Company}', (uid_leadMap.get(u.ID).Company <> null) ? uid_leadMap.get(u.ID).Company : '');
            emailBody = emailBody.replace('{!Lead.Name}', (
             (uid_leadMap.get(u.ID).FirstName <> null) ? uid_leadMap.get(u.ID).FirstName : '') +
               ' '+ 
             ((uid_leadMap.get(u.ID).LastName <> null )? uid_leadMap.get(u.ID).LastName : '')
            );
            emailBody = emailBody.replace('{!Lead.Lead_Rating__c}', ((uid_leadMap.get(u.ID).Lead_Rating__c <> null)?uid_leadMap.get(u.ID).Lead_Rating__c : ''));
            emailBody = emailBody.replace('{!Lead.Phone}', ((uid_leadMap.get(u.ID).Phone <> null)?uid_leadMap.get(u.ID).Phone : '' ));
            emailBody = emailBody.replace('{!Lead.Email}', ((uid_leadMap.get(u.ID).Email <> null)?uid_leadMap.get(u.ID).Email : ''));
            emailBody = emailBody.replace('{!Lead.Link}', (orgUrl+uid_leadMap.get(u.ID).ID));
        mailObj.setSubject(emailSubject);
        mailObj.setPlainTextBody(emailBody);
        mailObj.setToAddresses(toAddresses);

        mailObj.setSenderDisplayName(UserInfo.getName());
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mailObj });            
        }
    }
    
    for(Lead l : newList) {
      if(!oldMap.isEmpty()) {
          if(l.AutoAssignedOwner__c == true && l.OwnerId <> oldMap.get(l.ID).OwnerID) {
            leadsToUpdate.add(new Lead(ID=l.ID, AutoAssignedOwner__c = false));
          }
      } else {
        if(l.AutoAssignedOwner__c == true) {
          leadsToUpdate.add(new Lead(ID=l.ID, AutoAssignedOwner__c = false));
        }
      }
    }
    if(!leadsToUpdate.isEmpty()) {
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerOtherEmail = false;
        Database.update(leadsToUpdate, dlo);
        //update leadsToUpdate;
    }   
  }
*/
    
  //T-110849: Lead Additional Brands to Populate Account Brand Need (AS)
  private void needsSetOnAccountBrands(Map<ID, Lead> newMap, Map<ID, Lead> oldMap) {
    
    Map<ID, Set<String>> mapLeadIDset = new Map<ID, Set<String>>();
    Set<String> brandSet;
    String additionalBrand;
    List<String> abList = new List<String>();

    //abList = new List<String>();
    List<Account_Brand__c> updateAbList = new List<Account_Brand__c>();
    Set<ID> relAccIDset = new Set<ID>();
    Map<ID, List<Account_Brand__c>> accID_AcBrandList_Map = new Map<ID, List<Account_Brand__c>>();
    Set<String> convertedAccIDset = new Set<String>();
    
    /* In mapLeadIDset the set will contains Lead.Brand and Additional Brands*/
    for(Lead l : newMap.Values()){
      if(l.IsConverted <> oldMap.get(l.ID).isConverted && l.isConverted == true) {
          brandSet = new Set<String>();
          convertedAccIDset.add(l.ConvertedAccountId);  
            if(l.Brand__c != null){
                brandSet.add(l.Brand__c);
            }
    
            for(Brand__c b : brandMap.values()){
                if(l.Additional_Brands__c <> null && l.Additional_Brands__c.contains(b.Name)) {
                    brandSet.add(b.Name);
                }
            }
    
            mapLeadIDset.put(l.Id , brandSet);
          
            if(l.ConvertedAccountId != null){
                relAccIDset.add(l.ConvertedAccountId);
            }
      }
    }
    
   //Query the set of converted accounts of leads
   if(relAccIDset.size() > 0) {
       for(Account_Brand__c ab :[Select Id, hasNeeds__c, Brand__r.Name, Account__c, 
                                    Account__r.CreatedDate
                                    from Account_Brand__c 
                                    where Account__c 
                                    IN: relAccIDset]){
                                        
            if(!accID_AcBrandList_Map.ContainsKey(ab.Account__c)){
                accID_AcBrandList_Map.put(ab.Account__c, new List<Account_Brand__c>());
            }
            accID_AcBrandList_Map.get(ab.Account__c).add(ab);
       }
   }
  //T:131678 
    Date accCreatedDate;
     
  for(Lead l : newMap.Values()){
    //Process when lead is converting.
    if((l.ConvertedAccountId != null) && (l.Brand__c != null) && 
       l.IsConverted <> oldMap.get(l.ID).isConverted && l.isConverted == true){
      for(Account_Brand__c ab : accID_AcBrandList_Map.get(l.ConvertedAccountId)){               
        //as on T:131678
       /*ab.hasNeeds__c = null;//Commented for task T:131678*/
       accCreatedDate = date.newinstance(ab.Account__r.CreatedDate.year(), ab.Account__r.CreatedDate.month(), ab.Account__r.CreatedDate.day());
       if(Date.today() == accCreatedDate) {
            //check weather the Map contains (AccountBrand)
            if(mapLeadIDset.get(l.Id).contains(ab.Brand__r.Name)){
              ab.hasNeeds__c = 'Yes';
            }
            updateAbList.add(ab);
       }
      }
    }
  }
    if(!updateAbList.isEmpty()) {
            update updateAbList; 
        }   
  }

}