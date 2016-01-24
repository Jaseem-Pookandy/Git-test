public with sharing class EmailManager {
    public static void sendMail(String address,String subject,String body){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        list<string> toaddresses = new list<string>();
        toaddresses.add(address);
        mail.setToAddresses(toaddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}