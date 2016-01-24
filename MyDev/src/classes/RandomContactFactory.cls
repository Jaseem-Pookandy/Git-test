public class RandomContactFactory{

public static list<Contact> generateRandomContacts(Integer i,String last_name){
    list<Contact> clist = new list<Contact>();
    for(integer j=0;j<i;j++){
        Contact c = new Contact();
        c.firstname = 'Test '+string.valueof(j);
        c.lastname = last_name;
        
        clist.add(c);
    
    }
    
    return clist;
}
}