public class AccountHandler{

    public static Account insertNewAccount(String accname){
    
        Account acc = new Account();
        try{
        acc.name = accname;
       
        insert acc;
        }catch(DMLException e){
        System.debug('A DML exception has occurred: ' +
                e.getMessage());
            return null;
        
        }
        
        return acc;
    }
}