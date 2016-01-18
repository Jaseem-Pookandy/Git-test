Public with sharing class LaunchReportController {
	
	// Internally used instance variables for storing the incoming URL 
	// Parameters and path
	Private Map<String,String> urlParams;
	Private String path;
	Public String ErrorReportName {get {return urlParams.get('rpt');}}

	// Class Constructor, Returns instance of LaunchReportController
	Public LaunchReportController() {
		// Salesforce's helper method to parse the current pages
		// query string parameter into a Map<String,String> of key,value pairs
		// This allows us to persist the exact url params to the redirect URL
		urlParams = ApexPages.currentPage().getParameters();

		// Path represents the Path portion of the final URL 
		// ie <host>/<path>?<queryString>
		// In our situation this will be the Report GUID as pulled from the Report 
		// Table. However since the id field from the query is of type Id, we cast 
		// it to sting.
		// Test Shunt:
		// For testing purposes this method can be instructed to force
		// a given result based on magic input for the rpt query parameter.
		if (urlParams.get('rpt') == '____TEST_REPORT_POSTITIVE_NAME____') {
			path = '00o___FAKE_REPORT_GUID';
			urlParams.remove('rpt'); 
		} else {
			try {
				path = (string) [SELECT Id
													FROM Report 
													WHERE developerName = :urlParams.get('rpt') 
													LIMIT 1].id;
				// the rpt query key is only used for this page, so we'll remove
				// it from the map before redirecting.
				urlParams.remove('rpt'); 
			} catch (System.QueryException e) {
				// If there is not at least 1 row, we'll redirect to an error page.
				// Nb: We're leaving the rpt key in the query string so we can 
				// refrence it
				// on the error page.
				path = 'apex/UnableToFindReportByDevName';
			}
		}
	}

	/*
		autoLaunch()
		Accepts no parameters, Returns a PageReference instance to actual
			report url by guid *with* query string parameters attached.
	 */
	Public PageReference autoLaunch() {
		// Create a new PageReference varaiable initialized with our constructor 
		// derived Path variable;
		PageReference returnReference = new PageReference('/'+path);
		// At this point our new page ref url looks like this:
		// 		/00Oi0000000aubDEAQ
		// attach as query parameters all of the original URL parameters that 
		// remain as part of our Constructor created urlParams map
		returnReference.getParameters().putAll(urlParams);
		// Now our Page Ref's effective url looks like this:
		// 		/00Oi0000000aubDEAQ?colDt_q=cury&scope=user&units=m
		// 		Which is our "final" url we want to go to.
		// This will set visualforce to Redirect to our new page reference
		// Ie: to our /path url with the query params attached.
		returnReference.setRedirect(true);
		return returnReference;
	}

}