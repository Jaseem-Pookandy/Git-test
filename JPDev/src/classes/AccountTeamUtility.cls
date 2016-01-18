public without sharing class AccountTeamUtility {

    public static void DeleteATMs(List<AccountTeamMember> ATMdelList) {
      if (!ATMdelList.isEmpty()) delete ATMdelList;
    }   
}