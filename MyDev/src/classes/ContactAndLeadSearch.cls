public class ContactAndLeadSearch{

  public static List<List< SObject>> searchContactsAndLeads(String first){
  
    list<list<Sobject>> sosllist = [FIND :first in NAME FIELDS RETURNING CONTACT(Name),Lead(NAME)];
    
    return sosllist;
  }
}