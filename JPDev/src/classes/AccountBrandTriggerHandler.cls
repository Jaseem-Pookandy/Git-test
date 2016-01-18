/***************************************************************************
// (c) 2012 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  AccountBrandTrigger. All contexts should be in this class.
//                  
// Dec 12th, 2012  :  Naresh Ojha (Appirio Offshore)
//***************************************************************************/
public with sharing class AccountBrandTriggerHandler {
        
    private boolean m_isExecuting = false;  
    private integer BatchSize = 0;
    public Map<String, Brand__c> brandName_brandMap;
    public Map<String, Brand__c> brandId_BrandMap;
    public final String ROLE_SALES_REP = 'Sales Rep';
    public final String ROLE_CS = 'CS'; 
    private static final String BYPASS_CONSTRAINT_FOR_ADMINS = 'AB Deletion - Admins Ignore Constraint';
        
    //Constructor
    public AccountBrandTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
        brandName_brandMap = Commonutil.getBrandMap();
        brandId_BrandMap = Commonutil.getID_BrandMap();
    }
    
    //On before insert trigger method
    public void OnBeforeInsert(List<Account_Brand__c> newList) { 
        createAccountTeamMembers(newList);
        assignBrandToAccountBrand (newList);
    }  

    //On before delete trigger method, 2013.08.27
    public void OnBeforeDelete(Map<Id, Account_Brand__c> oldMap) { 
        ValidateAndFixOrphans(oldMap);
    }
    
    
    // On before update trigger method
    public void OnBeforeUpdate (Map<Id, Account_Brand__c> oldMap, Map<Id, Account_Brand__c> newMap) {
        updateAccountTeamMembers(oldMap, newMap);
        assignBrandToAccountBrand (newMap.values());
    }
    
    // On before delete trigger method
    public void OnAfterDelete (Map<Id, Account_Brand__c> oldMap) {
        Set<String> accIdSet = new Set<String>();
        for (Account_Brand__c ab : oldMap.values()) {
            accIdSet.add(ab.Account__c);
        }
        CommonUtil.recallATM(accIdSet);    
    }
    
    //On after insert trigger method
    public void OnAfterInsert(List<Account_Brand__c> newList) { 
        setActiveInactiveAccount(newList);  
        
        //byrnes, 2013.09.05
        PreventRecursiveExecution.isFirstRun = false;
        UpdateRankOnOpenTasksForNewAccountBrands(newList);


        //Before calling the 'InsertAtRiskTasks' method, validate that At Risk is checked...
        if (PreventRecursiveExecution.tasksNotYetCreated == true) {
            List<Account_Brand__c> abRecordsToAddTasks = new List<Account_Brand__c>();
            for (Account_Brand__c ab : newList) {
                if (ab.At_Risk__c == true) abRecordsToAddTasks.add(ab);
            }

            if (abRecordsToAddTasks.size() > 0) InsertAtRiskTasks(abRecordsToAddTasks);     
        }
    }  
    
    // On after update trigger method
    public void OnAfterUpdate (Map<Id, Account_Brand__c> oldMap, Map<Id, Account_Brand__c> newMap) {
                                                                
        //byrnes, 2013.09.05
        PreventRecursiveExecution.isFirstRun = false;
        UpdateRankOnOpenTasks(oldMap, newMap);                                      
                                                                
        setActiveInactiveAccount(newMap.values());
        Set<String> accIdSet = new Set<String>();
        for (Account_Brand__c ab : newMap.values()) {
                accIdSet.add(ab.Account__c);
        }
        CommonUtil.recallATM(accIdSet);          

        //Before calling the 'InsertAtRiskTasks' method, validate that At Risk was just checked and only pass applicable records....
        if (PreventRecursiveExecution.tasksNotYetCreated == true) {
            List<Account_Brand__c> abRecordsToAddTasks = new List<Account_Brand__c>();
            for (Id abID : newMap.keySet()) {
                if ((oldMap.get(abId).At_Risk__c != newMap.get(abID).At_Risk__c) && newMap.get(abID).At_Risk__c == true) abRecordsToAddTasks.add(newMap.get(abID));
            }

            if (abRecordsToAddTasks.size() > 0) InsertAtRiskTasks(abRecordsToAddTasks);
        }
    }

    //byrnes, new 2014.04.04, CC-2371
    //Not checking the contents of the list here because that was already done...
    private void InsertAtRiskTasks(List<Account_Brand__c> filteredList) {

        PreventRecursiveExecution.tasksNotYetCreated = false;

        List<Task> tasksToInsert = new List<Task>();
        Id backupUser = [SELECT UserID__c FROM Training_Backup_User__c LIMIT 1].UserID__c;
        Set<Id> accountIDs = new Set<Id>();

        for (Account_Brand__c ab : filteredList) {
            accountIDs.add(ab.Account__c);
        }

        Map<Id, Account> accountsInPlay = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id = :accountIDs]);
        Map<Id, Brand__c> brandMap = new Map<Id, Brand__c>([SELECT Id, Name, Create_At_Risk_Tasks__c FROM Brand__c WHERE Create_At_Risk_Tasks__c = true]);

        for (Account_Brand__c ab : filteredList) {

            //If the map doesn't contain the brand key then we aren't supposed to create the task for it, so skip this iteration and move on to the next...
            if (!brandMap.containsKey(ab.Brand__c)) continue;

            Task t = new Task();
            t.Subject = 'Assess At Risk Account';
            t.Brand__c = ab.Brand_Picklist__c;
            t.Type__c = 'At Risk';
            t.Due_Date__c = system.today().addDays(7);
            t.ActivityDate = system.today().addDays(7);

            if (ab.Primary_Owner__c != null) t.OwnerId = ab.Primary_Owner__c;
            else t.OwnerId = backupUser;

            t.WhatId = ab.Account__c;
            t.Status = 'Not Started';
            t.Priority = 'High';

            t.Description = accountsInPlay.get(ab.Account__c).Name + ' has been flagged as AT RISK of not renewing an annual subscription.  Please review the account and record your related AT RISK activities.';
            tasksToInsert.add(t);
        }

        if (tasksToInsert.size() > 0) insert tasksToInsert;
    }

    //byrnes, new 2013.09.05, CC-597
    private void UpdateRankOnOpenTasksForNewAccountBrands (List<Account_Brand__c> newList) {
        List<Task> tasksToUpdate = new List<Task>();
        Map<String, List<Task>> mapTasks = new Map<String, List<Task>>();   
        Set<Id> accountIDs = new Set<Id>();       
            
        for (Account_Brand__c ab : newList) {
            accountIDs.add(ab.Account__c);
        }   
        
        String currentID = '';
        List<Task> tasksForMap = new List<Task>();
        
        //Since there is not direct link between Account_Brand and Tasks we're retrieving more records than need to be updated....
        for (Task t : [SELECT Id, Account_Brand_Rank__c, Brand__c, WhatId, AccountId FROM Task WHERE IsClosed = false AND AccountId IN :accountIDs]) {
            if (currentID != String.valueOf(t.AccountId + '_' + t.Brand__c)) {
                
                if ((currentID != '') && (tasksForMap.size() > 0)) mapTasks.put(currentID, tasksForMap);
                tasksForMap.clear();
                currentID = t.AccountId + '_' + t.Brand__c;
            }
            
            tasksForMap.add(t);
        }
        //very last one to add...
        mapTasks.put(currentID, tasksForMap);
        
        for (Account_Brand__c ab : newList) {

        //Then the rank changed.  In that case, update tasks...
            List<Task> affectedTasks = mapTasks.get(ab.Account__c + '_' + ab.Brand_Picklist__c);
            if ((affectedTasks != null) && (affectedTasks.size() > 0)) {
                for (Task affectedTask : affectedTasks) {
                    affectedTask.Account_Brand_Rank__c = ab.Rank__c;
                    
                    tasksToUpdate.add(affectedTask);
                }
            }
        }
        
        if (tasksToUpdate.size() > 0) update tasksToUpdate;
    }


    //byrnes, new 2013.09.05, CC-597
    private void UpdateRankOnOpenTasks (Map<Id, Account_Brand__c> oldMap, Map<Id, Account_Brand__c> newMap) {
        List<Task> tasksToUpdate = new List<Task>();
        Map<String, List<Task>> mapTasks = new Map<String, List<Task>>();   
        Set<Id> accountIDs = new Set<Id>();       
        Map<Id, Task> mapTasksToUpdate = new Map<Id, Task>();
            
        for (Account_Brand__c ab : oldMap.values()) {
            accountIDs.add(ab.Account__c);
        }   
        
        String currentID = '';
        List<Task> tasksForMap = new List<Task>();
        
        //Since there is not direct link between Account_Brand and Tasks we're retrieving more records than need to be updated....
        for (Task t : [SELECT Id, Account_Brand_Rank__c, Brand__c, WhatId, AccountId FROM Task WHERE IsClosed = false AND AccountId IN :accountIDs AND IsRecurrence = false]) {
            if (currentID != String.valueOf(t.AccountId + '_' + t.Brand__c)) {
                
                if ((currentID != '') && (tasksForMap.size() > 0)) mapTasks.put(currentID, tasksForMap);
                tasksForMap.clear();
                currentID = t.AccountId + '_' + t.Brand__c;
            }
            
            tasksForMap.add(t);
        }
        //very last one to add...
        mapTasks.put(currentID, tasksForMap);
        
        for (Account_Brand__c ab : oldMap.values()) {
            if (ab.Rank__c != newMap.get(ab.Id).Rank__c) {
                
                //Then the rank changed.  In that case, update tasks...
                List<Task> affectedTasks = mapTasks.get(ab.Account__c + '_' + ab.Brand_Picklist__c);
                if ((affectedTasks != null) && (affectedTasks.size() > 0)) {
                    for (Task affectedTask : affectedTasks) {
                        if (!mapTasksToUpdate.containsKey(affectedTask.Id)) {
                             affectedTask.Account_Brand_Rank__c = newMap.get(ab.Id).Rank__c;
                             mapTasksToUpdate.put(affectedTask.Id, affectedTask);
                        }
                    }
                }
            }
        }
        if (mapTasksToUpdate.size() > 0) update mapTasksToUpdate.values();
    }

    //As per discussion today on chat with Joshua. Date: Feb 12th, 2013.
    private void assignBrandToAccountBrand (List<Account_Brand__c> newList) {
        for (Account_Brand__c ab : newList) {
                System.debug('--brandName_brandMap-->'+brandName_brandMap + '--Brand_Picklist__c--'+ab.Brand_Picklist__c);
                if (ab.Brand_Picklist__c <> null && brandName_brandMap.containsKey(ab.Brand_Picklist__c)) ab.Brand__c = brandName_brandMap.get(ab.Brand_Picklist__c).ID;
                else if (ab.Brand_Picklist__c == null && ab.Brand__c <> null && brandId_BrandMap.containsKey(ab.Brand__c)) ab.Brand_Picklist__c = brandId_BrandMap.get(ab.Brand__c).Name;
        }
    }
    
    //byrnes, new 2013.08.27
    public static boolean AdminsCanDeleteWillyNilly() {
        GlobalFlags__c gf = [SELECT Enabled__c FROM GlobalFlags__c WHERE Name = :BYPASS_CONSTRAINT_FOR_ADMINS LIMIT 1];
        
        if ((gf == null) || (gf.Enabled__c == false)) return false;     
        
        return true;
    }   
    
    ////////////////////////////////////////////////////////////////////////
    //CC-418: Fixing orphans
    ////////////////////////////////////////////////////////////////////////
    private void ValidateAndFixOrphans(Map<Id, Account_Brand__c> oldMap)  {
        if (oldMap.size() > 1) return;  //do nothing.  Bulk deletions will not behave any differently.
        Boolean bContinue = false;
        
        for (Account_Brand__c ab : oldMap.values()) {
            List<Account_Brand__c> redundantABs = [SELECT Id, Brand_Name__c, Rank__c, Account__c, Name, Account__r.Name, Brand_Picklist__c
                                                    FROM Account_Brand__c 
                                                    WHERE Account__c = :ab.Account__c 
                                                    AND Brand_Name__c = :ab.Brand_Name__c 
                                                    AND Id != :ab.Id];
            
            if (redundantABs.size() < 1) {
                if ((AdminsCanDeleteWillyNilly() == false) || (!CommonUtil.IsUserAdmin(UserInfo.getUserId()))) ab.addError('This Account Brand record (' + ab.Brand_Name__c + ') is not redundant for the specific account and may not be deleted.');
                return;
            }
            
            if ((redundantABs.size() > 0)) {            
                
                //If there is one redundant or 10 - we don't care.  We're grabbing the first one and using that as the record in place of the soon-to-be-purged AB record.
                Account_Brand__c newBoss = redundantABs[0];
                
                //Now we're going to reparent all of the appropriate records...
                
                //Account_Team_Members
                List<Account_Team_Member__c> atmsToUpdate = new List<Account_Team_Member__c>(); 
                for (Account_Team_Member__c mem : [SELECT Id, Account_Brand__c FROM Account_Team_Member__c WHERE Account_Brand__c = :ab.Id]) {
                    mem.Account_Brand__c = newBoss.Id;
                    atmsToUpdate.add(mem);
                }
                
                //Activities - ALL, not just opened
                //Tasks first.
                List<Task> tasksToUpdate = new List<Task>();
                for (Task t : [SELECT Id, WhatId,account_brand__c FROM Task WHERE WhatId = :ab.Id or account_brand__c =:ab.id]) {
                    t.WhatId = t.WhatId == ab.Id? newBoss.Id : t.WhatId;
                    t.account_brand__c = t.account_brand__c == ab.Id? newBoss.Id :t.account_brand__c;
                    tasksToUpdate.add(t);
                }
                
                //Tasks for Account Brand Rank...
                List<Task> differentTasksToUpdate = new List<Task>();
                for (Task tk : [SELECT Id, WhatId, Account_Brand_Rank__c FROM Task WHERE AccountId = :newBoss.Account__c AND Account_Brand_Rank__c != :newBoss.Rank__c]) {
                    PreventRecursiveExecution.isFirstRun = false;
                    tk.Account_Brand_Rank__c = newBoss.Rank__c;
                    differentTasksToUpdate.add(tk);
                }
                
                //Events next.
                List<Event> eventsToUpdate = new List<Event>();
                for (Event e : [SELECT Id, WhatId,account_brand__c FROM Event WHERE WhatId = :ab.Id or account_brand__c =:ab.id]) {
                    e.WhatId = e.WhatId == ab.Id? newBoss.Id : e.WhatId;
                    e.account_brand__c = e.account_brand__c == ab.Id? newBoss.Id :e.account_brand__c;
                    eventsToUpdate.add(e);
                }
                //Done with Activities
                
                //Campaign Members
                List<CampaignMember> cmsToUpdate = new List<CampaignMember>();
                for (CampaignMember cm : [SELECT Id, Account_Brand__c, Validation_Rule_Override__c FROM CampaignMember WHERE Account_Brand__c = :ab.Id]) {
                    cm.Validation_Rule_Override__c = Datetime.now();
                    cm.Account_Brand__c = newBoss.Id;
                    cmsToUpdate.add(cm);
                }
                
                //Opps
                List<Opportunity> oppsToUpdate = new List<Opportunity>();   
                for (Opportunity o : [SELECT Id, Account_Brand__c, Validation_Rule_Override__c FROM Opportunity WHERE Account_Brand__c = :ab.Id]) {
                    o.Validation_Rule_Override__c = Datetime.now();
                    o.Account_Brand__c = newBoss.Id;
                    oppsToUpdate.add(o);
                }
                
                //Product Users
                List<Product_User__c> pusToUpdate = new List<Product_User__c>();
                for (Product_User__c pu : [SELECT Id, Account_Brand__c FROM Product_User__c WHERE Account_Brand__c = :ab.Id]) {
                    pu.Account_Brand__c = newBoss.Id;
                    pusToUpdate.add(pu);
                }

                //Leads
                List<Lead> leadsToUpdate = new List<Lead>();
                for (Lead l : [SELECT Id, Account_Brand__c FROM Lead WHERE Account_Brand__c = :ab.Id AND IsConverted = false]) {
                    l.Account_Brand__c = newBoss.Id;
                    l.Set_Account_Brand_Override__c = System.now();
                    leadsToUpdate.add(l);
                }
                
                //Webstore Orders
                List<Webstore_Order__c> wosToUpdate = new List<Webstore_Order__c>();
                for (Webstore_Order__c wo : [SELECT Id, Account_Brand__c FROM Webstore_Order__c WHERE Account_Brand__c = :ab.Id]) {
                    wo.Account_Brand__c = newBoss.Id;
                    wosToUpdate.add(wo);
                }
                
                //Contact Types
                List<Contact_Type__c> ctsToInsert = new List<Contact_Type__c>();            
                for (Contact_Type__c ct : [SELECT   Account_Brand__c, Contact__c,
                                                    Never_Email__c, Type__c, CurrencyIsoCode
                                                    FROM Contact_Type__c 
                                                    WHERE Account_Brand__c = :ab.Id]) {
                    Contact_Type__c newContactType = new Contact_Type__c();
                    newContactType.Account_Brand__c = newBoss.Id;
                    newContactType.Contact__c       = ct.Contact__c;
                    newContactType.isMigrated__c    = false;
                    newContactType.Never_Email__c   = ct.Never_Email__c;
                    newContactType.Type__c          = ct.Type__c;
                    newContactType.CurrencyIsoCode  = ct.CurrencyIsoCode;
                    
                    ctsToInsert.add(newContactType);
                }
                
                if (atmsToUpdate.size() > 0) update atmsToUpdate;
                if (tasksToUpdate.size() > 0) update tasksToUpdate;
                if (eventsToUpdate.size() > 0) update eventsToUpdate;
                if (cmsToUpdate.size() > 0) update cmsToUpdate;
                if (oppsToUpdate.size() > 0) update oppsToUpdate;
                if (pusToUpdate.size() > 0) update pusToUpdate;
                if (leadsToUpdate.size() > 0) update leadsToUpdate;
                if (wosToUpdate.size() > 0) update wosToUpdate;
                if (differentTasksToUpdate.size() > 0) update differentTasksToUpdate;
                
                if (ctsToInsert.size() > 0) insert ctsToInsert;
                
                //recalculate the newBoss's name IF needed.
                Integer splitLocation = newBoss.Name.indexOf('@', 0);
                String newBossAccountName = newBoss.Name.substring(splitLocation + 1);
                
                if (newBossAccountName != newBoss.Account__r.Name) {
                    newBoss.Name = newBoss.Brand_Picklist__c + '@' + newBoss.Account__r.Name;
                    update newBoss; 
                }           
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////
    //T-103766: Setting account status on the basis of child records
    ////////////////////////////////////////////////////////////////////////
    private void setActiveInactiveAccount(List<Account_Brand__c> newList) {
        
        //If this logic has already executed, bug out.  
        if (PreventRecursiveExecution.activeinactiveaccountset) return;

        //Set this to true so it can't execute multiple times.
        PreventRecursiveExecution.activeinactiveaccountset = true;
        
        Map<String, Account> accID_AccountMap = new Map<String, Account>();
        Set<String> accountIDSet = new Set<String>();
        
        //Populating accountIDSet
        for (Account_Brand__c ab : newList) {
            if(ab.Account__c <> null) accountIDSet.add(ab.Account__c);
        }
        
        if (!accountIDSet.isEmpty()) {
            Boolean flagAccountSetActive = false;
            Boolean flagOneBrandInactive = false;
            
            for (Account ac : [Select Status__c, Id, (Select Id, Status__c, Account__c From Account_Brands__r) From Account WHERE ID IN : accountIDSet]) {
                flagAccountSetActive = false;
                flagOneBrandInactive = false;
                if (!accID_AccountMap.containsKey(ac.ID)) accID_AccountMap.put(ac.ID, ac);
                        
                for(Account_Brand__c ab : ac.Account_Brands__r) {
                    //If once an account is set true, skip rest record to check active
                    if (flagAccountSetActive) continue;

                    //If one brand is active, set account active and flag active
                    if (ab.Status__c == 'Active' && flagAccountSetActive == false) {
                        accID_AccountMap.get(ab.Account__c).Status__c = 'Active';
                        flagAccountSetActive = true;
                    } 
                    else if (ab.Status__c == 'InActive' ) flagOneBrandInactive = true;
                }
                //If no any account brand was active and even single was inactive
                //Setting account Inactive
                if (flagOneBrandInactive == true && flagAccountSetActive == false) accID_AccountMap.get(ac.ID).Status__c = 'InActive';
            } 
        }
        //Update call for accounts.
        if (!accID_AccountMap.isEmpty()) update accID_AccountMap.values();
    }
    
    //==========================================================================//
    // Method that creates the Account Team Members
    //==========================================================================//
    private void createAccountTeamMembers(List<Account_Brand__c> newList) {
        AccountTeamMember atmObj;
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        Set<Id> accIdSet = new Set<Id>();
        
        for (Account_Brand__c ab : newList) {

            //Primary owner as Team_member
            if (ab.Primary_Owner__c <> null) {
                accIdSet.add(ab.Account__c);
                atmObj = new AccountTeamMember();
                atmObj.UserId = ab.Primary_Owner__c;
                atmObj.AccountId = ab.Account__c;
                atmObj.TeamMemberRole = ROLE_SALES_REP;
                atmList.add(atmObj);
            }

            //CS owner is team member
            if (ab.CS__c <> null) {
                accIdSet.add(ab.Account__c);
                atmObj = new AccountTeamMember();
                atmObj.UserId = ab.CS__c;
                atmObj.AccountId = ab.Account__c;
                atmObj.TeamMemberRole = ROLE_CS;
                atmList.add(atmObj);
            }      
        }
        //Insert Team member record
        if (atmList <> null && !atmList.isEmpty()) {
            try {
                insert atmList;
            } catch(Exception e) { }
        }//EO If

    } // End of createAccountTeamMembers()
    
    //==========================================================================//
    // Mehtod that updates the AccountTeamMember Records on before Update
    //==========================================================================//  
    private void updateAccountTeamMembers(Map<Id, Account_Brand__c> oldMap, 
                                                                                Map<Id, Account_Brand__c> newMap) {
        AccountTeamMember atmObj;    
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        Set<ID> atmSet_delete = new Set<ID>();
        
        Set<Id> accIdSet = new Set<Id>();
                
        for (Account_Brand__c ab : newMap.values()) {
            //Primary Owner
            if (oldmap.get(ab.Id).Primary_Owner__c <> ab.Primary_Owner__c) {
                if (ab.Primary_Owner__c <> null) {
                    accIdSet.add(ab.Account__c);
                    atmObj = new AccountTeamMember();
                    atmObj.UserId = ab.Primary_Owner__c;
                    atmObj.AccountId = ab.Account__c;
                    atmObj.TeamMemberRole = ROLE_SALES_REP;
                    atmList.add(atmObj);
                }               
            }

            //CS Owner
            if (oldmap.get(ab.Id).CS__c <> ab.CS__c) {         
                if (ab.CS__c <> null) {
                    accIdSet.add(ab.Account__c);
                    atmObj = new AccountTeamMember();
                    atmObj.UserId = ab.CS__c;
                    atmObj.AccountId = ab.Account__c;
                    atmObj.TeamMemberRole = ROLE_CS;
                    atmList.add(atmObj);
                }           
            }       
        }    
        
        if (atmList.size() > 0) insert atmList;
    } // End of updateAccountTeamMembers()
    
//==========================================================================//
// Mehtod that updates CampaignMember.Owner_Assigned__c for Ownership Change
//==========================================================================//  
    public static void updateOnwerAssigned(String type, Set<Id> setId) {
            List<CampaignMember> lstCampMembersForLead = new List<CampaignMember>();
            List<CampaignMember> lstCampMembersForAccountBrands = new List<CampaignMember>();
            List<CampaignMember> lstCampMembers = new List<CampaignMember>();
            //String id = '';
            //List<Account_Brand__c> lstAcctBrands = new List<Account_Brand__c>();
            //if(ownerId == null || !ownerId.left(3).equals('005')){
            //    return;
            //}
            if (type.equals('Leads')) lstCampMembersForLead = [SELECT Id, Owner_Assigned__c, campaign.Overwrite_Member_Owners__c, Validation_Rule_Override__c, Lead.OwnerId FROM CampaignMember WHERE (LeadId IN :setId AND Campaign.isActive = True AND Campaign.isCall_List__c= True AND HasResponded = False)];

            if (type.equals('AccountBrands')) lstCampMembersForAccountBrands = [SELECT Id, Owner_Assigned__c, campaign.Overwrite_Member_Owners__c, Validation_Rule_Override__c, Account_Brand__r.Primary_Owner__c FROM CampaignMember WHERE (Account_Brand__c IN :setId AND Campaign.isActive = True AND Campaign.isCall_List__c= True AND HasResponded = false)];

            if (lstCampMembersForLead.size() > 0) {  
                for (CampaignMember cm : lstCampMembersForLead) {
                    String ownerId = cm.Lead.OwnerId;
                    if (cm.Owner_Assigned__c == null || cm.campaign.Overwrite_Member_Owners__c == true) {
                        cm.Validation_Rule_Override__c = datetime.now();
                        if (cm.Lead.OwnerId != null && ownerId.left(3).equals('005')) {
                            cm.Owner_Assigned__c = cm.Lead.OwnerId;
                            lstCampMembers.add(cm);
                        }
                    }  
                }                 
            }
            else if (lstCampMembersForAccountBrands.size() > 0) {  
                for (CampaignMember cm : lstCampMembersForAccountBrands) {
                    String ownerId = cm.Account_Brand__r.Primary_Owner__c;
                    if (cm.Owner_Assigned__c == null || cm.campaign.Overwrite_Member_Owners__c == true) {
                        cm.Validation_Rule_Override__c = datetime.now();
                        
                        if (cm.Account_Brand__r.Primary_Owner__c != null && ownerId.left(3).equals('005')) {
                            cm.Owner_Assigned__c = cm.Account_Brand__r.Primary_Owner__c;
                            lstCampMembers.add(cm);
                        }
                    } 
                }                  
            }
            update lstCampMembers;
    }//End of updateOnwerAssigned()
} //End of Class