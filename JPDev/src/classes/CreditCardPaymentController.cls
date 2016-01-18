/*******************************************************************
Name            : CreditCardPaymentController
Author          : Byrnes
Date            : December 13, 2013
Related Task    : CC-1636

Two parameters are expected here:  
    id (which will be the Salesforce Id of the zqu__Quote__c object)
    mode (if 1 that indicates the user will be entering the data themselves, if 2 an email is going out to the customer)
    //modes 1 & 2 are sourced from the Opportunity.
    //the other modes, 11 & 12, are sourced from the Billing Account.
*************************************************************************/

public class CreditCardPaymentController {
    
    //Public stuff...  (referenced on the .page file)
    public zqu__Quote__c thisQuote {get; set;}
    public Zuora__CustomerAccount__c thisBillingAccount {get; set;}
    
    public List<String> errors {get; set;}
    public Integer mode {get; set;}
    public Boolean sent {get; set;}
    
    public static final Integer ENTER_CC_INFO = 1;
    public static final Integer EMAIL_CUSTOMER = 2;
    public static final Integer ENTER_CC_BILLING_ACCOUNT = 11;
    public static final Integer EMAIL_CUSTOMER_BILLING_ACCOUNT = 12;
    
    //Private stuff... (reference internally only)
    private PageReference pgReturnPage {get; set;}
    private User currentUser {get; set;}
    private String thisId {get; set;}
    private String ZuoraAccountID {get; set;}
    
    transient List<Messaging.SendEmailResult> listEmailResult {get; set;}
    
    //public CreditCardPaymentController(ApexPages.StandardController controller) {
    public CreditCardPaymentController() {
        
        //initialize the objects if necessary...
        sent = false;
        errors = new List<String>();
        listEmailResult = new List<Messaging.SendEmailResult>();
    }

    public PageReference WorkTheMagic() {
        
        PageReference pg = null;
        
        mode = Integer.valueOf(ApexPages.currentPage().getParameters().get('mode'));
        thisId = ApexPages.currentPage().getParameters().get('id');
        
        //if the page load isn't valid, render the error messages...
        if (!ValidatePageLoad()) return null;
        
        //the parameters are valid (allegedly).
        //Next, get the quote and make sure it has all the pieces valid before calling the webservice to get the address...
        if (!ValidateSource()) return null;
        else {
            
            populatePaymentAddress();
            //Call the encrypt webservice and update the quote object with the URL and timestamp.
            
            //then, send the email out if they came from the 'Send Email' button...
            if ((mode == EMAIL_CUSTOMER) || (mode == EMAIL_CUSTOMER_BILLING_ACCOUNT)) SendEmail();
            
            //if they are entering themselves, then redirect the user to the URL... 
            else if ((mode == ENTER_CC_INFO) && (thisQuote.Payment_Address__c != null)) {
                pg = new PageReference(thisQuote.Payment_Address__c);
                pg.setRedirect(true);
                return pg;
            }
            else if ((mode == ENTER_CC_BILLING_ACCOUNT) && (thisBillingAccount.Payment_Address__c != null)) {
                pg = new PageReference(thisBillingAccount.Payment_Address__c);
                pg.setRedirect(true);
                return pg;
            }
            else if ((mode == ENTER_CC_INFO) && (thisQuote.Payment_Address__c == null)) errors.add('Error retrieving encrypted Id from payments.diceholdings.com.  Unable to redirect user to payment website.');
            else if ((mode == ENTER_CC_BILLING_ACCOUNT) && (thisBillingAccount.Payment_Address__c == null)) errors.add('Error retrieving encrypted Id from payments.diceholdings.com.  Unable to redirect user to payment website.');
        }
        return null;
    }
    
  private void populatePaymentAddress() {
        
    DateTime rightNow = DateTime.Now();
    String paymentURL = [SELECT URL__c FROM CreditCardPaymentSettings__c WHERE Name = :Constants.BASE_PAYMENT_ADDRESS_URL LIMIT 1].URL__c;
    
    String encryptionResult;
    
    if ((mode == ENTER_CC_INFO) || (mode == EMAIL_CUSTOMER)) { 
	    encryptionResult = zquQuoteTriggerHandler.GetEncryptedIDForEmail(thisQuote.zqu__ZuoraAccountID__c);
	                    
	    if ((!encryptionResult.startsWith('ERROR')) && ((paymentURL + encryptionResult).length() <= 255)) {
	        //Then we're good to go!
	        thisQuote.Payment_Address__c = paymentURL + encryptionResult;   
	        thisQuote.Payment_Email_Last_Sent__c = rightNow;
	        
	        //setting this flag will make certain the automated email isn't sent AFTER this, in case if it hasn't...
	        thisQuote.Payment_Email_Automatically_Sent__c = true;
	        thisQuote.Do_Not_Send_Automated_Email__c = true;
	    }
	    else if ((!encryptionResult.startsWith('ERROR')) && ((paymentURL + encryptionResult).length() > 255)) {
	         thisQuote.Payment_Address__c = null;
	         errors.add('The result returned from the encryption webservice was too long, probably due to an error.  Here it is for debugging purposes:');
	         errors.add(encryptionResult);
	    }
	    else {
	        thisQuote.Payment_Address__c = null;
	        errors.add('An unexpected result was returned while communicating with the encryption webservice.  Here it is for debugging purposes:');
	        errors.add(encryptionResult);
	    }
	    
	    update thisQuote;
    }
    
	if ((mode == ENTER_CC_BILLING_ACCOUNT) || (mode == EMAIL_CUSTOMER_BILLING_ACCOUNT)) { 
	    encryptionResult = zquQuoteTriggerHandler.GetEncryptedIDForEmail(thisBillingAccount.Zuora__Zuora_Id__c);
	                    
	    if ((!encryptionResult.startsWith('ERROR')) && ((paymentURL + encryptionResult).length() <= 255)) {
	        //Then we're good to go!
	        thisBillingAccount.Payment_Address__c = paymentURL + encryptionResult;   
	        
	    }
	    else if ((!encryptionResult.startsWith('ERROR')) && ((paymentURL + encryptionResult).length() > 255)) {
	         thisBillingAccount.Payment_Address__c = null;
	         errors.add('The result returned from the encryption webservice was too long, probably due to an error.  Here it is for debugging purposes:');
	         errors.add(encryptionResult);
	    }
	    else {
	        thisBillingAccount.Payment_Address__c = null;
	        errors.add('An unexpected result was returned while communicating with the encryption webservice.  Here it is for debugging purposes:');
	        errors.add(encryptionResult);
	    }
	    
	    update thisBillingAccount;
    }
  } 
  
  private void SendEmail() {
    
    if (((mode == EMAIL_CUSTOMER) && (thisQuote.Payment_Address__c != null)) || ((mode == EMAIL_CUSTOMER_BILLING_ACCOUNT) && (thisBillingAccount.Payment_Address__c != null))) {

        listEmailResult = new List<Messaging.SendEmailResult>();    //list of results 
        List<Messaging.Singleemailmessage> listEmails = new List<Messaging.Singleemailmessage>();   //list of emails that are going to be sent...
            
        //send the email template out...
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
    	EmailTemplate et;
    	if (mode == EMAIL_CUSTOMER) {
    		et = [SELECT Id FROM EmailTemplate WHERE DeveloperName=:Constants.CREDITCARD_TEMPLATE_MANUAL];
    		
    		mail.setWhatId(thisQuote.Id);
        	mail.setTargetObjectId(thisQuote.zqu__SoldToContact__c);
        	
        	mail.setTemplateId(et.Id);
	        mail.setUseSignature(false);
	        mail.setBccSender(false);
	        mail.setSaveAsActivity(false);          
	                
	        listEmails.add(mail);
	        
	        if (listEmails.size() > 0)  listEmailResult = Messaging.sendEmail(listEmails);
	        
	        for (Messaging.SendEmailResult rr : listEmailResult) {
	            if (!rr.isSuccess()) errors.add('Error sending email: ' + rr.getErrors());
	        }
	        
	        sent = true;
    	}
    	
    	else if (mode == EMAIL_CUSTOMER_BILLING_ACCOUNT) {
    		et = [SELECT Id FROM EmailTemplate WHERE DeveloperName=:Constants.CREDITCARD_TEMPLATE_MANUAL_BILLING_ACCOUNT];

			//dummy contact...           
			Contact con = [SELECT Id FROM Contact LIMIT 1];

			mail.setWhatId(thisBillingAccount.Id);
        	mail.setTargetObjectId(con.Id);
        	mail.setToAddresses(new List<String>{thisBillingAccount.Zuora__BillToWorkEmail__c});
			
			mail.setTemplateId(et.Id);
	        mail.setUseSignature(false);
	        mail.setBccSender(false);
	        mail.setSaveAsActivity(false);          
	                
	        listEmails.add(mail);
	        
	        // Send the emails in a transaction, then roll it back
			Savepoint sp = Database.setSavepoint();
			if (listEmails.size() > 0)  Messaging.sendEmail(listEmails);
			Database.rollback(sp);
	        
	        // For each SingleEmailMessage that was just populated by the sendEmail() method, copy its
			// contents to a new SingleEmailMessage. Then send those new messages.
			List<Messaging.SingleEmailMessage> lstMsgsToSend = new List<Messaging.SingleEmailMessage>();
			for (Messaging.SingleEmailMessage email : listEmails) {
			   Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
			   emailToSend.setToAddresses(email.getToAddresses());
			   emailToSend.setPlainTextBody(email.getPlainTextBody());
			   emailToSend.setHTMLBody(email.getHTMLBody());
			   emailToSend.setSubject(email.getSubject());
			   lstMsgsToSend.add(emailToSend);
			}
			
			if (lstMsgsToSend.size() > 0)  listEmailResult = Messaging.sendEmail(lstMsgsToSend);
	        
	        for (Messaging.SendEmailResult rr : listEmailResult) {
	            if (!rr.isSuccess()) errors.add('Error sending email: ' + rr.getErrors());
	        }
	        
	        sent = true;
    	}
    }
    else errors.add('Error retrieving encrypted Id from payments.diceholdings.com.  Unable to send email.');
  }
    
    private Boolean ValidateSource() {
    	
    	//If they are coming from the Opportunity...
    	if ((mode == ENTER_CC_INFO) || (mode == EMAIL_CUSTOMER)) {    	
	        errors = new List<String>();
	        
	        thisQuote = [SELECT 
	                        Payment_Address__c, 
	                        Payment_Email_Last_Sent__c, 
	                        Payment_Email_Automatically_Sent__c, 
	                        OwnerId, 
	                        zqu__ZuoraAccountID__c, 
	                        zqu__Status__c,  
	                        Payment_Gateway__c, 
	                        zqu__SoldToContact__r.Name, 
	                        zqu__SoldToContact__r.Email, 
	                        zqu__SoldToContact__r.Id,
	                        zqu__SoldToContact__c,
	                        Id
	                     FROM zqu__Quote__c 
	                     WHERE Id = :thisId LIMIT 1];
	        
	        //Make sure the quote actually exists...
	        if (thisQuote == null) errors.add('Unable to find the Quote.  Close this window are try again.');
	        else {
	             
	            //Make sure the quote is in 'Sent to Z-Billing' status...
	            if (thisQuote.zqu__Status__c != Constants.QUOTE_SENT) errors.add('This functionality is not available until the order has been fully processed.  (Current value: ' + thisQuote.zqu__Status__c + ')');
	            
	            //Make sure there is a Sold To Contact and that he has an email address
	            if (thisQuote.zqu__SoldToContact__r == null) errors.add('The Sold To Contact on the Quote is missing.');
	            else if (thisQuote.zqu__SoldToContact__r.Email == null) errors.add('The Sold To Contact on the Quote is missing their email address.');
	            
	            //Make sure the payment gateway is acceptable...
	            if (!CommonUtil.IsPaymentGatewayApproved(thisQuote.Payment_Gateway__c)) errors.add('This account is in a region which cannot use the automated credit card processing method.  Please manually enter the credit card information in the Credit Card Information section of the Opportunity.  (The Payment Gateway is not approved.  Current value: ' + thisQuote.Payment_Gateway__c + ')');
	            
	            //Make sure the Zuora Account ID is populated...
	            if ((thisQuote.zqu__ZuoraAccountID__c == null) || (thisQuote.zqu__ZuoraAccountID__c.length() != 32)) errors.add('Missing (or invalid) Zuora Account Id.  Please try again in 15 to 30 minutes for the Zuora synchronization to update this field.   (Current value: ' + thisQuote.zqu__ZuoraAccountID__c + ')');
	            
        		ZuoraAccountID = thisQuote.zqu__ZuoraAccountID__c;
	        }
    	}
    	
    	//else if they are coming from the billing account...
    	else if ((mode == ENTER_CC_BILLING_ACCOUNT) || (mode == EMAIL_CUSTOMER_BILLING_ACCOUNT)) {
    		errors = new List<String>();
	        
	        thisBillingAccount = [SELECT   
	                        Payment_Gateway__c, 
	                        Zuora__BillToName__c, 
	                        Zuora__BillToWorkEmail__c,
	                        Zuora__Zuora_Id__c
	                     FROM Zuora__CustomerAccount__c 
	                     WHERE Zuora__Zuora_Id__c = :thisId LIMIT 1];
	        
	        //Make sure the quote actually exists...
	        if (thisBillingAccount == null) errors.add('Unable to find the Billing Account.  Close this window are try again.');
	        else {

	            //Make sure there is a Sold To Contact and that he has an email address
	            if (thisBillingAccount.Zuora__BillToName__c == null) errors.add('The Bill To Contact on the Billing Account is missing.');
	            if (thisBillingAccount.Zuora__BillToWorkEmail__c == null) errors.add('The Bill To Contact on the Billing Account is missing their email address.');
	            	            
	            //Make sure the payment gateway is acceptable...
	            if (!CommonUtil.IsPaymentGatewayApproved(thisBillingAccount.Payment_Gateway__c)) errors.add('This account is in a region which cannot use the automated credit card processing method.  Please manually enter the credit card information in the Credit Card Information section of the Opportunity.  (The Payment Gateway is not approved.  Current value: ' + thisBillingAccount.Payment_Gateway__c + ')');
	            
	            //Make sure the Zuora Account ID is populated...
	            if ((thisBillingAccount.Zuora__Zuora_Id__c == null) || (thisBillingAccount.Zuora__Zuora_Id__c.length() != 32)) errors.add('Missing (or invalid) Zuora Account Id.  Please try again in 15 to 30 minutes for the Zuora synchronization to update this field.   (Current value: ' + thisQuote.zqu__ZuoraAccountID__c + ')');
	            else ZuoraAccountID = thisBillingAccount.Zuora__Zuora_Id__c;
	        }
    	}
        
        if (errors.size() > 0) return false;
        return true;
    }
    
    private Boolean ValidatePageLoad() {
        errors = new List<String>();
        
        if ((mode == null) || ((mode != ENTER_CC_INFO) && (mode != EMAIL_CUSTOMER)) && (mode != ENTER_CC_BILLING_ACCOUNT) && (mode != EMAIL_CUSTOMER_BILLING_ACCOUNT)) errors.add('Unable to determine your action as the mode querystring parameter is missing or invalid.');
        
        if ((thisId == null) || (thisId.length() < 15)) errors.add('Unable to determine the Quote or Billing Account as the Id parameter is missing or invalid.');
        
        if (errors.size() > 0) return false;
        return true;
    }

}