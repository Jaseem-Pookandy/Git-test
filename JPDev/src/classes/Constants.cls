/***************************************************************************
// (c) 2012 Appirio, Inc.
//
// To define various constants to be used in vairous classes.
//
// Dec 11th, 2012    Naresh Ojha(Appirio Off)    Original
//  
//***************************************************************************/

public with sharing class Constants {

  public static final String ACCOUNT_OBJ = 'Account';
  public static final String ACESSLEVEL_READ_WRITE = 'Edit';  
  public static final String OPPTY_CLOSED_WON = 'Closed Won';
  public static final String OPPTY_CLOSED_LOST = 'Closed Lost';
  public static final String TASK_STATUS_COMPLETED = 'Completed';
  public static final String READONLY = 'Read Only';
  public static final String MIGRATION = 'Migration';
  public static final String LEADSTATUS_OPEN_NOTCONNECTED = 'Open - Not Contacted';
  public static final String LEAD_NEW_ASSIGNMENT_NOTIFICATION_EMAIL_TEMPLETE = 'Leads_New_Assignment_Notification';
  public static final String DECISION_MAKER = 'Decision Maker';
  public static final String LEADNOTIFICATIONTEMPLATE = 'Lead_Assignment_Notification';
  public static final String VALIDATION_STATUS_VALIDATED = 'Validated';
  public static final String LOGO_FOLDER_DICE = 'Company Logos';

  public static final String BRAND_DICE = 'Dice';
  public static final String BRAND_RZ = 'Rigzone';
  public static final String BRAND_EFC = 'eFinancialCareers';
  public static final String BRAND_TJF = 'TargetJobsFairs';
  public static final String BRAND_HC = 'HealthCallings';
  public static final String BRAND_CJ = 'ClearanceJobs';
  
  public static final String CASEORIGIN_CUSTOMER = 'Email - Customer';
  public static final String CASEORIGIN_CANDIDATE = 'Email - Candidate';    
        
  public static final String QUOTE_SENT = 'Sent to Z-Billing';
  public static final String ENCRYPTION_URL_NAME = 'EncryptionURL';
  public static final String BASE_PAYMENT_ADDRESS_URL = 'Base Address for Payment';
  public static final String CREDITCARD_TEMPLATE_AUTOMATIC = 'Request_Credit_Card_Automatic';
  public static final String CREDITCARD_TEMPLATE_MANUAL = 'Request_Credit_Card_Manual';
  public static final String CREDITCARD_TEMPLATE_MANUAL_BILLING_ACCOUNT = 'Request_Credit_Card_Billing_Account';
  
  public static final String QUOTE_CURRENCY_CHANGED = 'Error: Currency was changed. : Billing Account needs to be recalculated as currency was changed.  Edit and Save this Quote to correct.';
  public static final String CONTACT_LANGUAGE_CHANGED = 'Error: Sold To Contact Language was changed. : Billing Account needs to be recalculated as language was changed.  Edit and Save this Quote to correct.';
  
  public static final String STATUS_PENDING = 'Provisioning Pending';
  public static final String STATUS_IN_PROGESS = 'In Progress';
  public static final String STATUS_PROVISION_HOLD = 'Provisioning Hold';
  public static final String STATUS_PROVISIONED = 'Provisioned';
  public static final String STATUS_QA_VALIDATING = 'QA Validating';
  public static final String STATUS_QA_HOLD = 'QA Hold';
  public static final String STATUS_COMPLETE = 'Sent to Billing';
  public static final String STATUS_SENT_TO_BILLING = 'Sent to Billing';
    
  public Constants() {

  }
   
}