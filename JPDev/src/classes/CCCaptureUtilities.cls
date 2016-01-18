// Byrnes
// 2015.04.17

public without sharing class CCCaptureUtilities {
    
	public static final String ENCRYPTION_METHOD = 'AES256';
	public static final String CC_PRIVATE_KEY = 'CCCapture - AES 256';		//the name of the custom setting record.

	public CCCaptureUtilities() {
		//empty constructor
	}

	public static String EncryptText(String privateKey, String textToEncrypt) {

		String sResult = null;

		try {
			Blob encryptedBlob = Crypto.encryptWithManagedIV(ENCRYPTION_METHOD, Blob.valueOf(privateKey), Blob.valueOf(textToEncrypt));
			if (encryptedBlob != null) sResult = EncodingUtil.base64Encode(encryptedBlob);
		}
		catch (Exception e) {
			system.debug('### - Error encrypting! ' + e.getMessage());
		}
		
		return sResult;		
	}

	public static Boolean IsValidId(String potentialRecordId) {
		return (potentialRecordId InstanceOf Id) ? true: false;
	}

	public static String DecryptText(String privateKey, String textToDecrypt) {
		
		String sResult = null;

		//system.debug('### privateKey: ' + privateKey);
		//system.debug('### textToDecrypt: ' + textToDecrypt);

		try {
			Blob decryptedBlob = Crypto.decryptWithManagedIV(ENCRYPTION_METHOD, Blob.valueOf(privateKey), EncodingUtil.base64Decode(textToDecrypt));	
			if (decryptedBlob != null) sResult = decryptedBlob.toString();
		}
		catch (Exception e) {
			system.debug('### - Decrypt Error!');
		}
						
		return sResult;
	}

	//If the templateId is null, this will automatically select and use the Id for the manual email template.
	//This is not bulkified for single-instance use from the Visualforce page.
	public static String SendPaymentEmail(Id paymentLinkId, Id contactId, Id templateId) {
		//returns null if everything worked perfectly, otherwise returns the error.
		String sResult = null;

		List<Messaging.SendEmailResult> listEmailResult = new List<Messaging.SendEmailResult>();    //list of results 
        List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();   //list of emails that are going to be sent...
            
        //send the email template out...
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		EmailTemplate et = new EmailTemplate();

		if (templateId == null) et = [SELECT Id FROM EmailTemplate WHERE DeveloperName =:Label.Payment_Link_Email_Template_Manual];
		else et.Id = templateId;

		List<OrgWideEmailAddress> oweaList = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'donotreply@dhigroupinc.com'];
		if (!oweaList.isEmpty()) mail.setOrgWideEmailAddressId(oweaList[0].Id);
	
		mail.setWhatId(paymentLinkId);
    	mail.setTargetObjectId(contactId);    	

    	mail.setTemplateId(et.Id);
        mail.setUseSignature(false);
        mail.setBccSender(false);
        mail.setSaveAsActivity(false);
                
        listEmails.add(mail);	       

        if (listEmails.size() > 0)  listEmailResult = Messaging.sendEmail(listEmails);
        
        for (Messaging.SendEmailResult rr : listEmailResult) {
            if (!rr.isSuccess()) sResult += 'Error sending email: ' + rr.getErrors();
        }
              
		return sResult;
	}

	public static Messaging.SingleEmailMessage CreatePaymentEmail(Id paymentLinkId, Id contactId, Id templateId) {
            
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	
		mail.setWhatId(paymentLinkId);
    	mail.setTargetObjectId(contactId);    	
    	mail.setTemplateId(templateId);
        mail.setUseSignature(false);
        mail.setBccSender(false);
        mail.setSaveAsActivity(false);
              
		return mail;
	}	

	public static void ProcessExpiredPaymentLinks(List<Payment_Link__c> listLinks) {
		//Not much is going on here - all we do is set the 'processed_by_batch__c' field to the current date/time
		//and let the paymentlinktriggerhandler do the rest...

		List<Payment_Link__c> linksToUpdate = new List<Payment_Link__c>();

		for (Payment_Link__c pl : listLinks) {

			pl.Processed_by_Batch__c = Datetime.now();
			pl.Status_Workflow__c = 'Expired';
			linksToUpdate.add(pl);
		}

		if (!linksToUpdate.isEmpty()) update linksToUpdate;
	}

	public static void PostProcessRemittanceLink(   String ccNum, 
                                                    String oppId, 
                                                    String plId, 
                                                    String ipAddy, 
                                                    String ccName, 
                                                    String ccExpMonth, 
                                                    String ccExpYear, 
                                                    String cardType, 
                                                    String ccNotes, 
                                                    Boolean userEnteredNewCard, 
                                                    String gateway, 
                                                    CCCaptureController.CreditCardObject originalCC, 
                                                    Boolean isBillingAccountActivelyBilling, 
                                                    Boolean isAutoPayCurrentlyOn, 
                                                    Boolean billingAccountHasOpenInvoices,
                                                    String billingAccountsDefaultPaymentMethodId, 
                                                    Boolean remittanceLinkWasSentManually,
                                                    List<String> accountUpdateNotes,
                                                    String zuoraPaymentMethodId) {

		String systemNotes = '';
        String twoDigitMonth = ccExpMonth;

        if (twoDigitMonth != null && twoDigitMonth.length() == 1) twoDigitMonth = '0' + twoDigitMonth;

		if (userEnteredNewCard) systemNotes = 'New card (' + ccNum.right(4) + ') entered.\r\n';
		else systemNotes = 'Existing card (' + ccNum.right(4) + ') selected.\r\n';

        //If the expiration date changed
        if ((originalCC != null) && (originalCC.expirationYear != Integer.valueOf(ccExpYear) || originalCC.expirationMonth != Integer.valueOf(ccExpMonth))) systemNotes += 'Card exp. date changed to ' + ccExpMonth + '/' + ccExpYear + '\r\n';

        if (CommonUtil.IsPaymentGatewayApproved(gateway)) systemNotes += 'Card details saved to Zuora.\r\n';
        else systemNotes += 'Card details saved to Salesforce only.\r\n';

        if (accountUpdateNotes != null) {
            for (String s : accountUpdateNotes) {
                systemNotes += s + '\r\n';
            }
        }

        systemNotes += 'Payment Gateway: ' + gateway + '\r\n';

        if (ccNotes != null && ccNotes.length() > 255) ccNotes = ccNotes.substring(0, 255);
        if (systemNotes != null && systemNotes.length() > 255) systemNotes = systemNotes.substring(0, 255);

		Opportunity o = new Opportunity();
        o.Id = oppId;
        o.Credit_Card_Number__c = ccNum;
        o.CC_Notes__c = ccNotes;
        o.Cardholder_Name__c = ccName;
        o.Card_Expiration_Month__c = twoDigitMonth;
        o.Card_Expiration_Year__c = ccExpYear;
        o.Credit_Card_Entry_Date__c = System.today();
        o.Credit_Card_Notes_System__c = systemNotes;

        //Translate card type to match Salesforce's picklists:
        if (cardType == 'Visa') o.Card_Type__c = 'VISA';
        else if (cardType == 'MasterCard') o.Card_Type__c = 'MC';
        else if (cardType == 'AmericanExpress') o.Card_Type__c = 'AMEX';
        else if (cardType == 'Discover') o.Card_Type__c = 'DISCOVER';


        //Insert the case now, if necessary...
        Map<String, PaymentLinkLogic__c> pllMap = PaymentLinkLogic__c.getAll();
        RecordType remitLinkCaseRT = new RecordType();
        Group arQueue = new Group();        

        //Get the recordType now...
        for (RecordType rt : [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Remittance_Link' LIMIT 1]) {
            remitLinkCaseRT = rt;
        }

        //Get the AR Queue now...
        for (Group gQueue : [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Accounts Receivable' LIMIT 1]) {
            arQueue = gQueue;
        }       

        Payment_Link__c pl = [SELECT    Id, 
                                        Reason__c, 
                                        Contact__c, 
                                        Status_Workflow__c,
                                        Case_Description__c,
                                        Link_Created_For__c,
                                        Opportunity__c, 
                                        Opportunity__r.Id, 
                                        Opportunity__r.ZuoraSubscription__c,
                                        Opportunity__r.Syncedquote__r.zqu__ZuoraAccountID__c,
                                        Opportunity__r.ZuoraSubscription__r.Name,
                                        Opportunity__r.AccountId, 
                                        Opportunity__r.Account.Name, 
                                        Opportunity__r.BrandTag__c, 
                                        Opportunity__r.Account_Brand__c,
                                        Opportunity__r.Primary_Brand__c 
                                    FROM Payment_Link__c 
                                    WHERE Id = :plId LIMIT 1];        

        //Update the Zuora subscription in Zuora if it already exists in Salesforce.
        if (pl != null && pl.Opportunity__c != null && pl.Opportunity__r.ZuoraSubscription__c != null) UpdateZuoraSubscription(pl.Opportunity__r.ZuoraSubscription__r.Name, ccNotes, systemNotes);

        update o;

        Case c = null;

        if ((pl.Reason__c != null) && 
            (pl.Reason__c.toLowerCase() != 'docusign quote') && 
            ((pl.Reason__c.toLowerCase() == 'for entry on behalf of customer') || (pllMap.containsKey(pl.Reason__c)) && (pllMap.get(pl.Reason__c).CreateCase_Completion__c == true)) &&
            (remitLinkCaseRT != null) &&
            (arQueue != null)) {

            String caseDescription = 'Remittance Link Reason Sent: ' + pl.Reason__c + '\r\n';
            caseDescription += 'Remittance Link Notes: ' + pl.Case_Description__c + '\r\n\r\n';
            caseDescription += '---- Below are System Notes ----\r\n';
            caseDescription += systemNotes;

            c = new Case();

            c.RecordTypeId = remitLinkCaseRT.Id;

            c.Brand__c = pl.Opportunity__r.Primary_Brand__c;
            c.Reason = 'Customer Support';
            c.Type__c = 'Customer Payment Request';
            c.Origin = 'Remittance Link';
            c.Status = 'New';
            c.ContactId = pl.Contact__c;
            c.AccountId = pl.Opportunity__r.AccountId;
            c.Opportunity__c = pl.Opportunity__c;
            c.Remittance_Link__c = pl.Id;
            c.Subject = 'Credit Card Info Received';
            c.Description = caseDescription;
            c.Account_Brand__c = pl.Opportunity__r.Account_Brand__c;

            c.OwnerId = arQueue.Id;

            c.Assign_to_CSR__c = false;             

            insert c;
        }

        //update the payment link itself now
        pl.Status_Workflow__c = 'Complete';
        pl.Zuora_Payment_Method_Id__c = zuoraPaymentMethodId;   //The paymentMethod trigger will use this field to find out if the card was provided by a sold by partner or a customer.
        if (c != null && c.Id != null) pl.Case__c = c.Id;
        update pl;

        //Write the completed history record now.
        Payment_Link_History__c plh = PaymentLinkTriggerHandler.ReturnNewLinkHistoryRecord(plId, 'Complete', ipAddy);
        insert plh;
	}

    private static void UpdateZuoraSubscription(String zuoraSub, String customerNotes, String systemNotes) {

        Http restHTTP = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        req.setEndpoint(Label.RemittanceLinkZuoraSubscriptionUpdateURI + '/' + zuoraSub);
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');

        customerNotes = customerNotes.replaceAll('\r\n', '\\\\n');
        systemNotes = systemNotes.replaceAll('\r\n', '\\\\n');

        customerNotes = customerNotes.replaceAll('\n', '\\\\n');
        systemNotes = systemNotes.replaceAll('\n', '\\\\n');        

        Blob headerValue = Blob.valueOf(Label.RemittanceLinkZuoraUser + ':' + Label.RemittanceLinkZuoraPass);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);

        if (customerNotes != null && customerNotes.length() > 255) customerNotes = customerNotes.substring(0, 255);
        if (systemNotes != null && systemNotes.length() > 255) systemNotes = systemNotes.substring(0, 255);

        String body = '{';
            body += '"Credit_Card_Notes_System__c": "' + systemNotes + '",';
            body += '"CC_Notes__c": "' + customerNotes;
        body += '"}';

        //system.debug('### - body: ' + body);

        req.setBody(body);
        req.setTimeout(80000);
        
        if (!Test.isRunningTest()) res = restHTTP.send(req);
        else res.setStatusCode(200);

        if (res.getStatusCode() != 200) {
            system.debug('### - Error 213:  Communication Error.  ' + ' Status Code: ' + res.getStatusCode() + '   Status: ' + res.getStatus());
            return;
        }

        String zuoraResponse = res.getBody();

        if (Test.isRunningTest()) zuoraResponse = '{"success" : true}';
        
        //check if success is true or false now, start by parsing the repsonse:
        Map<String, Object> zuoraParsedResponse = (Map<String, Object>) JSON.deserializeUntyped(zuoraResponse);

        if (!zuoraParsedResponse.containsKey('success') || zuoraParsedResponse.get('success') != true) system.debug('### - Error 215:  ' + zuoraResponse);
    }
}