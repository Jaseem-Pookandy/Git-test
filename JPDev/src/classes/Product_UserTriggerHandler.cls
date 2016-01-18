/***************************************************************************
// (c) 2013 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  Product_UserTrigger. All contexts are in this class.
//                  
// 14 June 2013 : Karun Gangwnani (Appirio Off)
//***************************************************************************/
public with sharing class Product_UserTriggerHandler {
	
	//On after insert trigger method
  public static void OnAfterInsert(List<Product_User__c> newList) {   
    processContacts(newList);
    
    //CC-950
    AggregatePUStatusToUserGroup(newList);
  }
  
  //On after update trigger method
  public static void OnAfterUpdate(Map<Id, Product_User__c> oldMap, Map<Id, Product_User__c> newMap) {   
    processContacts(newMap.values());
    
    //CC-950
    AggregatePUStatusToUserGroup(newMap.values());
  }
  
  //On after delete trigger method
  public static void OnAfterDelete(Map<Id, Product_User__c> oldMap) {   
    processContacts(oldMap.values());
    
    //CC-950
    AggregatePUStatusToUserGroup(oldMap.values());
  }
  
  //On after Undelete trigger method
  public static void OnAfterUndelete(Map<Id, Product_User__c> newMap) {   
    processContacts(newMap.values());
    
    //CC-950
    AggregatePUStatusToUserGroup(newMap.values());
  }
  
  private static void processContacts(List<Product_User__c> newList) {
  	Set<ID> contactIDSet = new Set<ID>();
  	for(Product_User__c pu : newList) {
  		contactIDSet.add(pu.Contact__c);
  	}
  	String csvIn = null;
  	for(ID conId : contactIDSet) {
  		if(csvIn == null) csvIn = conId;
	    else csvIn += ',' + conId;
  	}
  	if(csvIn <> null) CommonUtil.recalcContact4PUSimple(csvIn);
  }
  
  
  //CC-950
  //This rolls product user status up to the user group level for visibility.
  private static void AggregatePUStatusToUserGroup(List<Product_User__c> newList) {
  	
  	List<User_Group__c> UserGroupsToUpdate = new List<User_Group__c>();
  	
  	Set<Id> userGroupIDs = new Set<Id>();
  	Map<Id, List<Product_User__c>> mapUserGroupProductUsers = new map<Id, List<Product_User__c>>();
  	
  	for (Product_User__c pu : newList) {
  		userGroupIDs.add(pu.User_Group__c);
  	}
  	
  	for (Product_User__c pu : [SELECT Brand__c, Status__c, User_Group__c FROM Product_User__c WHERE User_Group__c IN :userGroupIDs]) {
  		if (!mapUserGroupProductUsers.containsKey(pu.User_Group__c)) mapUserGroupProductUsers.put(pu.User_Group__c, new List<Product_User__c>());
  		mapUserGroupProductUsers.get(pu.User_Group__c).add(pu);
  	}
  	
  	//We now have all the data, it's time to finagle it...
  	
  	for (List<Product_User__c> puList : mapUserGroupProductUsers.values()) {
  		
  		if (puList.size() > 0) UserGroupsToUpdate.add(ReturnUserGroup(puList));
  		  			
  	}
  	
  	if (UserGroupsToUpdate.size() > 0) update UserGroupsToUpdate;
  	
  }

  
  private static User_Group__c ReturnUserGroup(List<Product_User__c> puList) {
  	
  	User_Group__c ug = new User_Group__c(Id = puList[0].User_Group__c);
  	
  	Set<String> activeBrands = new Set<String>();
  	Set<String> inactiveBrands = new Set<String>();
  	
  	String activeResult = '';
  	String inactiveResult = '';
  	
  	for (Product_User__c pu : puList) {
  		if (pu.Status__c == 'Active') activeBrands.add(pu.Brand__c);
  		if (pu.Status__c == 'Inactive') inactiveBrands.add(pu.Brand__c);
  	}
  	
  	if (activeBrands.size() > 0) {
  		
	  	//The set has dedupped the values for us, now create a list from the set and sort it.
	  	List<String> activeBrandList = new List<String>();
	  	activeBrandList.addAll(activeBrands);
	  	activeBrandList.sort();
	  	
	  	for (String s : activeBrandList) {
	  		if (activeResult.length() > 0) activeResult += '; ';
	  		activeResult += s;
	  		
	  		//remove this brand from the inactive set if it exists there as well...
	  		if (inactiveBrands.contains(s)) inactiveBrands.remove(s);
	  	}
  	}
  	
  	if (inactiveBrands.size() > 0) {
  		
  		//This set is dedupped (because it's a set), and any active objects are removed already.  Sort, concatenate and assign it.
  		List<String> inactiveBrandList = new List<String>();
  		inactiveBrandList.addAll(inactiveBrands);
  		inactiveBrandList.sort();
  		
  		for (String s : inactiveBrandList) {
  			
  			if (inactiveResult.length() > 0) inactiveResult += '; ';
  			inactiveResult += s;  			  			
  		}
  	}
  	
  	ug.Active_Usage__c = activeResult;
  	ug.Inactive_Usage__c = inactiveResult;
  	
  	return ug;  	
  }
}