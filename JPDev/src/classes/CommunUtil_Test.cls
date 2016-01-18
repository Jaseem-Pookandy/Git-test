/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class CommunUtil_Test {

    static testMethod void UnitTest1_IsAdmin() {
        // This method should return a true or false
        boolean myUser;
        myUser = (!CommonUtil.IsUserAdmin(UserInfo.getUserId()));
        
        
    }
}