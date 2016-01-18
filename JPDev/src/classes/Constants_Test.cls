@isTest
private class Constants_Test {
    
    static testMethod void testConstants() {

    Constants c = new Constants();

    System.assertNotEquals(Constants.BRAND_DICE, null);
    System.assertNotEquals(Constants.BRAND_RZ, null);
    System.assertNotEquals(Constants.BRAND_EFC, null);
    System.assertNotEquals(Constants.BRAND_TJF, null);
    System.assertNotEquals(Constants.BRAND_HC, null);
    System.assertNotEquals(Constants.BRAND_CJ, null);
    System.assertNotEquals(Constants.CASEORIGIN_CUSTOMER, null);
    System.assertNotEquals(Constants.CASEORIGIN_CANDIDATE, null);        
                        
    System.assertNotEquals(Constants.ACCOUNT_OBJ, null); 
    System.assertNotEquals(Constants.ACESSLEVEL_READ_WRITE, null); 
    System.assertNotEquals(Constants.OPPTY_CLOSED_WON, null); 
    System.assertNotEquals(Constants.OPPTY_CLOSED_LOST, null); 
    System.assertNotEquals(Constants.TASK_STATUS_COMPLETED, null); 
    System.assertNotEquals(Constants.READONLY, null); 
    System.assertNotEquals(Constants.MIGRATION, null);
    System.assertNotEquals(Constants.LEADSTATUS_OPEN_NOTCONNECTED, null); 
    System.assertNotEquals(Constants.LEAD_NEW_ASSIGNMENT_NOTIFICATION_EMAIL_TEMPLETE, null);                                 
    System.assertNotEquals(Constants.DECISION_MAKER, null);
    System.assertNotEquals(Constants.LEADNOTIFICATIONTEMPLATE, null);
    System.assertNotEquals(Constants.VALIDATION_STATUS_VALIDATED, null);
    System.assertNotEquals(Constants.LOGO_FOLDER_DICE, null);
    
    System.assertNotEquals(Constants.QUOTE_SENT, null);
    System.assertNotEquals(Constants.ENCRYPTION_URL_NAME, null);
    System.assertNotEquals(Constants.BASE_PAYMENT_ADDRESS_URL, null);
    System.assertNotEquals(Constants.CREDITCARD_TEMPLATE_AUTOMATIC, null);
    System.assertNotEquals(Constants.CREDITCARD_TEMPLATE_MANUAL, null);

    System.assertNotEquals(Constants.QUOTE_CURRENCY_CHANGED, null);
    System.assertNotEquals(Constants.CONTACT_LANGUAGE_CHANGED, null);
    
    System.assertNotEquals(Constants.STATUS_PENDING, null);
    System.assertNotEquals(Constants.STATUS_IN_PROGESS, null);
    System.assertNotEquals(Constants.STATUS_PROVISION_HOLD, null);
    System.assertNotEquals(Constants.STATUS_PROVISIONED, null);
    System.assertNotEquals(Constants.STATUS_QA_VALIDATING, null);
    System.assertNotEquals(Constants.STATUS_QA_HOLD, null);
    System.assertNotEquals(Constants.STATUS_COMPLETE, null);
    }
}