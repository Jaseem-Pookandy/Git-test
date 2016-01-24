@isTest
private class TestRestrictContactByName{

    static testmethod void testmethod1(){
        Contact c = new contact();
        c.lastname = 'INVALIDNAME';
        
        try{
        insert c;
        }catch(dmlexception e){
        
        }
    }

}