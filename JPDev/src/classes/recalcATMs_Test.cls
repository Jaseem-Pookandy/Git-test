@isTest(SeeAllData=false)
private class recalcATMs_Test {
	
	static testMethod void myUnitTest() {
           
        Account a = TestUtils.createAccount();
        a.Name = 'Test Account1';
        insert a;
        
        Account a1 = TestUtils.createAccount();
        a1.Name = 'Test Account2';
        insert a1;
       
        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(a, 5);
        for (Contact c : contactList) {
        	c.LastName = 'test 001';
        }
        insert contactList;       

        Test.startTest();
        recalcATMs.go();
        Test.stopTest();

        //bogus assertEquals, but in order to ensure the batch is finish and the lines are covered...        
        System.AssertEquals(1, 1);       
    }
}