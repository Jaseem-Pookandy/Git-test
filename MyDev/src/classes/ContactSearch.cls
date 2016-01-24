public class ContactSearch{
    public static list<Contact> searchForContacts(String first,string second){
        list<Contact> contactlist = [select id,name from Contact where LastName=:first and MailingPostalCode=:second];
        
        return contactlist;
        
    
    }

}