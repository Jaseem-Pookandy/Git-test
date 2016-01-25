public class AccountHandler{
		// this is a new comment
		// this is second comment
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