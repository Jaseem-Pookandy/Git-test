public with sharing class CaseAssignUtils {


  //Returns LIst of Profile Names from a Custom Setting 
  public static List<String> CaseAssignmentProfiles()
  {     
  	List<String> profileNameList = new List<String>();
    //Profiles where the DoNotAssignToCSR field is TRUE
    for(CaseAssignmentSettings__c CusSet : [SELECT ProfileName__c FROM CaseAssignmentSettings__c WHERE DoNotAssigntoCSR__c = true]) {
    	profileNameList.add(CusSet.ProfileName__c);
    }
                          
    return profileNameList;
    
  }
  
}