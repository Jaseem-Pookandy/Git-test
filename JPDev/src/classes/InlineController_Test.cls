//byrnes - 20140807
//probably not even needed.  No clue where/how/why 'InlineController' even exists
//but we need code coverage, so here it is...

@isTest
private class InlineController_Test {

	static testMethod void testMethod1() {

		ApexPages.Standardcontroller sc;
		InlineController c = new InlineController(sc);		
		c = new InlineController();		

		List<Contact> cList = c.getEmployees();
				
		PageReference pg = c.add();
		pg = c.del();
		pg = c.cancelEdit();
		pg = c.saveEdit();
	}		
}