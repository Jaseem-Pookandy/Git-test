/***************************************************************************
// (c) 2012 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  UserTrigger. All contexts should be in this class.
//                  
// Jan 08th, 2012  :  Naresh Ojha (Appirio Offshore)
//***************************************************************************
*Modified By    ---- Jaseem Pookandy
*Story          ---- CCBOB-189, populate department and division of task and opportunity owner when department/division changes for the owner
*Modified Date  ---- 2016.10.14
*Description    ---- Added new logic to fire onAfterUpdate
***/
public with sharing class UserTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  
  //Constructor
  public UserTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }
  
  //On before insert trigger method
  public void OnBeforeInsert(List<User> newList) { 
    SetAndPreventUserDefaults(newList, null);
    populateFederationIdentifer(newList, null);
  }  
  // On before update trigger method
  public void OnBeforeUpdate (Map<Id, User> oldMap, 
                              Map<Id, User> newMap) {
    SetAndPreventUserDefaults(newMap.values(), oldMap);
    populateFederationIdentifer(newMap.values(), oldMap);
  }
  
  public void OnAfterUpdate (Map<Id,User> oldMap,Map<Id,User> newMap){
      updOppandTasksforDeptandDivision(newMap.values(),oldMap);
  
  }
  //T-108021: Populating fedration ID from AD_UserName__c
  private void populateFederationIdentifer(List<User> newList, Map<ID, User> oldMap) {
    
    for(User u: newList) {
      //In case of update user record
      if(oldMap <> null && !oldMap.isEmpty()) {
        if(u.AD_Username__c <> null && u.AD_Username__c <> oldMap.get(u.ID).AD_Username__c) {
          u.FederationIdentifier = u.AD_Username__c;
        }
      } else { //In case of insert new user record
        if(u.AD_Username__c <> null) {
          u.FederationIdentifier = u.AD_Username__c;
        }
      }
    }
  }
  
  //T-XXXXX: Set Default User Group and Prevent Updates to Email & Username for Migration User
  private void SetAndPreventUserDefaults(List<User> newList, Map<ID, User> oldMap) {
  
  // Find Default Profile
   String DefaultProfileName=null;
   String DefaultProfileId=null;
   // getting the custom setting value from SF.
   if(Label.Default_User_Profile_Name != null && Label.Default_User_Profile_Name != '') {
       DefaultProfileName = Label.Default_User_Profile_Name;
   }   
   //Getting default profile id
    if(DefaultProfileName != null){    
      for(Profile profile : [Select Id, Name From Profile]){
        if(profile.Name == DefaultProfileName){
          DefaultProfileId = profile.Id;
          break;             
        }
      }
    }
    
    if (DefaultProfileName == null || DefaultProfileId == null) {
        list<Profile> ProfileList = [Select Id From Profile where Name =: Constants.READONLY];
        DefaultProfileId = ProfileList.get(0).Id;
    }  
    system.debug('============ DefaultProfileId'+DefaultProfileId);                                  
    
    for(User u: newList) {
      //In case of update user record
      if(oldMap <> null && !oldMap.isEmpty() && System.Userinfo.getLastName() == Constants.MIGRATION) {
        if(u.Username <> oldMap.get(u.ID).Username) {
          u.Username= oldMap.get(u.ID).Username;
        }
        if(u.Email <> oldMap.get(u.ID).Email) {
          u.Email= oldMap.get(u.ID).Email;
        }        
      } else { //In case of insert new user record
        if(u.ProfileId == null) {
          u.ProfileId = DefaultProfileId;
        }
      }
    }
  }
  //Method that populates department and division of the owner of opportunity and task when the corresponding value changes
  private void updOppandTasksforDeptandDivision(List<User>NewList,map<id,User>OldMap){
    map<id,User> MapUser = new map<id,User>();
    list<Opportunity> Opplist = new list<Opportunity>();
    list<Task> tasklist = new list<Task>();
    for(User Owner : NewList){
        //if it is a case of department change or division change or both
        if((owner.Department !=null && owner.Department != OldMap.get(owner.id).Department) || (owner.Division!=null && owner.Division != OldMap.get(owner.id).Division)){
            
            MapUser.put(owner.id,owner);
        }
    }
    
    if(!MapUser.isEmpty()){
       //query those opportunities which are open and owned by this user
        for(Opportunity opp : [select id,ownerid,Opportunity_Department_fw__c,Opportunity_Division_fw__c from Opportunity where ownerid in:MapUser.keyset() and isClosed = false]){
            opp.Opportunity_Department_fw__c = MapUser.get(opp.ownerid).Department;
            opp.Opportunity_Division_fw__c = MapUser.get(opp.ownerid).Division;
            Opplist.add(opp);
        }
        //query tasks which are open and owned by the user
        for(Task t :[select ownerid,Activity_Department_fw__c,Activity_Division_fw__c from Task where ownerid in:MapUser.keyset() and (status = 'Not Started' or status = 'In Progress') and isrecurrence = false and isdeleted =false ALL ROWS]){
            t.Activity_Department_fw__c = MapUser.get(t.ownerid).Department;
            t.Activity_Division_fw__c = MapUser.get(t.ownerid).Division;
            tasklist.add(t);
        }
    }
    //update the sobjects to make the change
    
    if(!Opplist.isEmpty()) update Opplist;
    if(!tasklist.isEmpty()) update tasklist;
    
    
   
  }  
  
  
}