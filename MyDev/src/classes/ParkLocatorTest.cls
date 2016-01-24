@isTest
private class ParkLocatorTest {
    @istest static void testwebservice(){
        Test.setMock(webservicemock.class, new ParkServiceMock());
        list<string> strinlist = parklocator.country('India');
        system.assertequals('balgotti',strinlist[0]);
    }
}