@isTest
private class Test_launchReportController {
	// Salesforce will not allow the programatic creation of a Report
	// So this package utilizes a magic report name that the controller
	// always finds, named ____TEST_REPORT_NAME____
	@isTest static void test_PostivelyRedirectOnFoundReportWithNoParams() {	
		// set the page we're going to test.
		PageReference pageRef = Page.launchReport;
		// set the current test page to our page ref.
		Test.setCurrentPage(pageRef);
		// Add the Rpt query string.
		ApexPages.currentPage().getParameters().put('rpt', '____TEST_REPORT_POSTITIVE_NAME____');

		LaunchReportController lrc = new LaunchReportController();
		PageReference results = lrc.autoLaunch();
		System.assertNotEquals(results.getUrl(), 'apex/UnableToFindReportByDevName?');
		System.assertEquals(results.getUrl(), '/00o___FAKE_REPORT_GUID');
		Test.setCurrentPage(results);
		System.assertEquals(0, ApexPages.currentpage().getParameters().size());
	}
	
	@isTest static void test_PostivelyRedirectOnFoundReportWith3Params() {
		// set the page we're going to test.
		PageReference pageRef = Page.launchReport;
		// set the current test page to our page ref.
		Test.setCurrentPage(pageRef);
		// Add the Rpt query string.
		ApexPages.currentPage().getParameters().put('rpt', '____TEST_REPORT_POSTITIVE_NAME____');
		ApexPages.currentPage().getParameters().put('foo', 'bar');
		ApexPages.currentPage().getParameters().put('Test', 'Case');
		ApexPages.currentPage().getParameters().put('Sessame', 'Street');

		LaunchReportController lrc = new LaunchReportController();
		PageReference results = lrc.autoLaunch();
		System.assertNotEquals(results.getUrl(), '/apex/UnableToFindReportByDevName?');
		System.assert(results.getUrl().startsWith('/00o___FAKE_REPORT_GUID'));
		System.assert(results.getUrl().contains('foo'));
		System.assert(results.getUrl().contains('bar'));
		System.assert(results.getUrl().contains('Test'));
		System.assert(results.getUrl().contains('Case'));
		System.assert(results.getUrl().contains('Sessame'));
		System.assert(results.getUrl().contains('Street'));
		Test.setCurrentPage(results);
		System.assertEquals(3, ApexPages.currentpage().getParameters().size());
	}
	
	@isTest static void test_NegativelyRedirectOnNotFoundReportWithNoParams() {
		// set the page we're going to test.
		PageReference pageRef = Page.launchReport;
		// set the current test page to our page ref.
		Test.setCurrentPage(pageRef);
		// Add the Rpt query string.
		ApexPages.currentPage().getParameters().put('rpt', '____TEST_REPORT_NEGATIVE_NAME____');

		LaunchReportController lrc = new LaunchReportController();
		PageReference results = lrc.autoLaunch();
		System.assertEquals(results.getUrl(), '/apex/UnableToFindReportByDevName?rpt=____TEST_REPORT_NEGATIVE_NAME____');
		Test.setCurrentPage(results);
		System.assertEquals(1, ApexPages.currentpage().getParameters().size());
	}

	@isTest static void test_NegativelyRedirectOnNotFoundReportWith3Params() {
		// set the page we're going to test.
		PageReference pageRef = Page.launchReport;
		// set the current test page to our page ref.
		Test.setCurrentPage(pageRef);
		// Add the Rpt query string.
		ApexPages.currentPage().getParameters().put('rpt', '____TEST_REPORT_NEGATIVE_NAME____');
		ApexPages.currentPage().getParameters().put('foo', 'bar');
		ApexPages.currentPage().getParameters().put('Test', 'Case');
		ApexPages.currentPage().getParameters().put('Sessame', 'Street');

		LaunchReportController lrc = new LaunchReportController();
		PageReference results = lrc.autoLaunch();
		System.assert(results.getUrl().startsWith('/apex/UnableToFindReportByDevName'));
		System.assert(results.getUrl().contains('rpt'));
		System.assert(results.getUrl().contains('____TEST_REPORT_NEGATIVE_NAME____'));
		System.assert(results.getUrl().contains('foo'));
		System.assert(results.getUrl().contains('bar'));
		System.assert(results.getUrl().contains('Test'));
		System.assert(results.getUrl().contains('Case'));
		System.assert(results.getUrl().contains('Sessame'));
		System.assert(results.getUrl().contains('Street'));
		Test.setCurrentPage(results);
		System.assertEquals(4, ApexPages.currentpage().getParameters().size());
	}

}