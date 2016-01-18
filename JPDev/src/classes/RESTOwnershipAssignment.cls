@RestResource(urlMapping='/OwnershipAssignment/*')
global without sharing class RESTOwnershipAssignment {
    
	global class ReturnClass {
		global String primaryOwnerId;		//the Id of the user that should be the Primary Owner - 18 char version
		global String supportOwnerId;		//the Id of the user that should be the Support Owner - 18 char version
		global String exactActiveMatchFound;		//a boolean indicator alerting the user if a perfect match was found or if backup/alternate users were necessary and are returned
											//This is a string to be consistent with the behavior of the RESTZuoraOperationPlugin class.  Values will only be 'false' or 'true', however.
		global String message;				//text clarifying results

		global ReturnClass(String primaryOwnerId, String supportOwnerId, String exactActiveMatchFound, String message) {
			this.primaryOwnerId = primaryOwnerId;
			this.supportOwnerId = supportOwnerId;
			this.exactActiveMatchFound = exactActiveMatchFound;
			this.message = message;
		}       
    }

    @HttpGet
    global static ReturnClass getOwnership() {
    	RestRequest req = RestContext.request; 
       	Map<String, String> parameterMap = RestContext.request.Params;
       	return OperationHandler(parameterMap);
    }
  
	public static boolean IsParameterNull(String param) {
		return param == null || ''.equals(param);
	}    

    public static ReturnClass OperationHandler(Map<String, String> requestParameterMap) {

		String brand 		    = requestParameterMap.get('Brand');         //Accepts either the full brandName (eFinancialCareers or the abbreviated external Id (as indicated in Salesforce), 'eFC')
    	String countryName 		= requestParameterMap.get('CountryName');
        String countryISO       = requestParameterMap.get('CountryISO');    //will trump CountryName if supplied (accepts 2 or 3 characters only)
    	String region 			= requestParameterMap.get('Region');		//not used (yet)
    	String product 			= requestParameterMap.get('Product');		//not used (yet)
    	String backupUserId = null;

        Boolean useCountryISO = true;

        if (countryName != null) countryName = countryName.trim();
        if (countryISO != null) countryISO = countryISO.trim();

    	//get the backup user - just in case:
    	User backupUser = [SELECT ID18__c, IsActive FROM User WHERE alias =: Label.Default_Account_Owner_User_Alias LIMIT 1];
    	if (backupUser <> null && backupUser.IsActive) backupUserId = backupUser.ID18__c;

    	if (IsParameterNull(brand)) return new ReturnClass('', '', 'false', 'Brand Missing');
    	if (IsParameterNull(countryName) && IsParameterNull(countryISO)) return new ReturnClass('', '', 'false', 'CountryISO and CountryName are missing.  At least one must be supplied.');
        if (!IsParameterNull(countryName) && IsParameterNull(countryISO)) useCountryISO = false;

    	if (IsParameterNull(region)) region = '';
    	if (IsParameterNull(product)) product = '';

        //Begin Brand validation
        List<Brand__c> brandList = new List<Brand__c>();
        brandList = [SELECT Id, Name FROM Brand__c WHERE External_Id__c = :brand OR Name = :brand];
        if (brandList.isEmpty() || brandList.size() > 1) return new ReturnClass('', '', 'false', 'Unable to determine a unique Brand based on the passed value of: ' + brand);
        //End Brand validation

        //Begin country validation
        List<pw_ccpro__CountryObject__c> CountryObjectList = new List<pw_ccpro__CountryObject__c>();

        if (useCountryISO && countryISO.length() == 2)       CountryObjectList = [SELECT Id, Name FROM pw_ccpro__CountryObject__c WHERE pw_ccpro__IsoCode_2__c = :countryISO LIMIT 1];
        else if (useCountryISO && countryISO.length() == 3)  CountryObjectList = [SELECT Id, Name FROM pw_ccpro__CountryObject__c WHERE pw_ccpro__IsoCode_3__c = :countryISO LIMIT 1];
        else                                                 CountryObjectList = [SELECT Id, Name FROM pw_ccpro__CountryObject__c WHERE Name = :countryName LIMIT 1];

        if (CountryObjectList.isEmpty() && !useCountryISO) return new ReturnClass('', '', 'false', 'Country Name of ' + countryName + ' was not found in Salesforce.');
        if (CountryObjectList.isEmpty() && useCountryISO) return new ReturnClass('', '', 'false', 'Country ISO of '+ countryISO + ' was not found in Salesforce.');
        //End country validation

        //It'd be nice to include an error if the country is on the terror blacklist here (North Korea, Iran, etc) but that data doesn't appear to exist in Salesforce (currently, anyway).

        List<Ownership_Assignment__c> ownershipRecords = [SELECT 
        															Id, 
        															Name, 
        															Primary_Owner__c, 
        															Primary_Owner__r.IsActive, 
        															Primary_Owner__r.ID18__c,
        															Support_Owner__c,
        															Support_Owner__r.IsActive,
        															Support_Owner__r.ID18__c  
        													FROM Ownership_Assignment__c 
        													WHERE Country__c = :CountryObjectList[0].Id
        														AND Brand__c = :brandList[0].Id
        														AND Region_State__c = :region
        														AND Product__c = :product
        													LIMIT 1];

        if (ownershipRecords.isEmpty() && backupUserId != null) return new ReturnClass(backupUserId, backupUserId, 'false', 'No assignment match found.  Returning backup user for both values.');
        else if (ownershipRecords.isEmpty() && backupUserId == null) return new ReturnClass('', '', 'false', 'No assignment match found and no backup user found.');

        else if (!ownershipRecords.isEmpty()) {

        	Ownership_Assignment__c ownershipFound = ownershipRecords[0];

        	if (backupUserId == null && (!ownershipFound.Support_Owner__r.IsActive || !ownershipFound.Primary_Owner__r.IsActive)) return new ReturnClass('', '', 'false', 'Assignment match found but at least one user is not active and the backup user was not found or active.');

        	else if (backupUserId != null && !ownershipFound.Support_Owner__r.IsActive && !ownershipFound.Primary_Owner__r.IsActive) return new ReturnClass(backupUserId, backupUserId, 'false', 'Assignment found but both Primary & Support are inactive.  Returning backup user for both values.');
        	else if (backupUserId != null &&  ownershipFound.Support_Owner__r.IsActive && !ownershipFound.Primary_Owner__r.IsActive) return new ReturnClass(backupUserId, ownershipFound.Support_Owner__r.ID18__c, 'false', 'Assignment found but the Primary Owner is inactive.  Returning backup user in place of Primary Owner.');
        	else if (backupUserId != null && !ownershipFound.Support_Owner__r.IsActive &&  ownershipFound.Primary_Owner__r.IsActive) return new ReturnClass(ownershipFound.Primary_Owner__r.ID18__c, backupUserId, 'false', 'Assignment found but the Support Owner is inactive.  Returning backup user in place of Support Owner.');

        	else if (ownershipFound.Support_Owner__r.IsActive && ownershipFound.Primary_Owner__r.IsActive) return new ReturnClass( ownershipFound.Primary_Owner__r.ID18__c, ownershipFound.Support_Owner__r.ID18__c, 'true', 'Perfect match.');
        }

        return new ReturnClass('', '', 'false', 'How in the world did you get here?');
    }
}