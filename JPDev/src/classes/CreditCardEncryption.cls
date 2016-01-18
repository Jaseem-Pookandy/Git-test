//Byrnes
//Needed because callouts cannot happen from Triggers
//2013.12.19

public class CreditCardEncryption {

    @future (callout=true)
    public static void EncryptAndSendNotificationEmail(String quoteId) {
        
        zqu__Quote__c q = [SELECT Id, Payment_Address__c, Payment_Email_Last_Sent__c, Payment_Email_Automatically_Sent__c, zqu__ZuoraAccountID__c FROM zqu__Quote__c WHERE Id = :quoteId LIMIT 1];
        
        DateTime rightNow = DateTime.Now();
        String paymentURL = [SELECT URL__c FROM CreditCardPaymentSettings__c WHERE Name = :Constants.BASE_PAYMENT_ADDRESS_URL LIMIT 1].URL__c;
        
        // CC-2140 Credit Card Capture Overhaul - adding quote ID to encrypted id
        //String AccountId = q.zqu__ZuoraAccountID__c+'|'+q.Id;
        
        String encryptionResult;
        if (!test.isRunningTest()) encryptionResult = zquQuoteTriggerHandler.GetEncryptedIDForEmail(q.zqu__ZuoraAccountID__c);
        else encryptionResult = '1234567890abcdefghijklmnopqrstuvwxyz';        
        
        if (!encryptionResult.startsWith('ERROR')) {
            q.Payment_Address__c = paymentURL + encryptionResult;   
            q.Payment_Email_Last_Sent__c = rightNow;
            q.Payment_Email_Automatically_Sent__c = true;
        }
        else q.Payment_Address__c = null;
            
        update q;
    }
}