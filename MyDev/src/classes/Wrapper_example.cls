public class Wrapper_example {
    public Account acc{get;set;}
    public list<wrapper> wrapper1{get;set;}
    public wrapper_example(Apexpages.StandardController stdcontroller){
        Account acc =(Account)stdcontroller.getRecord(); 
        wrapper1 = new list<wrapper>();
        list<Contact> contactlist = [select id,name from Contact where accountid =: acc.id];
        
        for(Contact c : contactlist){
            
            wrapper1.add(new wrapper(c));
        }
    }
    public void processselected(){
        list<contact> contactlist = new list<contact>();
        for(wrapper w : wrapper1){
            if(w.selected == true){
                w.contactex.level__C = 'primary';
                contactlist.add(w.contactex);
            }
        }
        update contactlist;
    }
    
}