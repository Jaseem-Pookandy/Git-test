/*******************************************************************
Name            : EnterpriseServicesController
Author          : Byrnes
Date            : February 28, 2014
Related Task    : DW-3068
*************************************************************************/
public class EnterpriseServicesController {

	//public stuff...
	public List<String> errors {get; set;}
	public Integer daysToConsider {get; set;}	//stupid name, but this is the number of days prior to today that is the minimum day to get for address changes
												//from the ContactHistory table.  So, if this value is 7 - we will get all address changes for contacts
												//that are BillTo contacts on at least one quote that were made greater than or equal to 7 days ago.
	public List<SelectOption> daysOptions {get; set;}

	//private stuff...
	private PageReference pgReturnPage {get; set;}
	//I shouldn't need a property for currentUser - I'll just use UserInfo.getUserId() where necessary...

	public EnterpriseServicesController() {
		daysToConsider = 7;	//initially set this to 7
		errors = new List<String>();
		daysOptions = GetAvailableDays();
	}

	private List<SelectOption> GetAvailableDays() {
		daysOptions = new List<SelectOption>();
		Integer iTop = 90;
		Integer iCurrent = 1;

		while (iCurrent <= iTop) {
			daysOptions.add(new SelectOption(String.valueOf(iCurrent), String.valueOf(iCurrent)));
			iCurrent++;
		}

		return daysOptions;
	}

	public PageReference BeginTheAudit() {

		//Reset the errors list.
		errors = new List<String>();

		PrepareTheData(daysToConsider);

		Id reportId = null;
		List<Report> reports = [SELECT Id, DeveloperName FROM Report WHERE DeveloperName = 'BillTo_Contact_Address_Changes'];

		if (reports != null && reports.size() > 0) reportId = reports[0].Id;
		else errors.add('D\'oh!  Unable to find the custom report \'Bill To Contact Address Changes\'');

		String reportURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + reportId;

		if (errors.size() > 0) return null;
		else return new PageReference(reportURL);
	}

	private void PrepareTheData(Integer daysBack) {

		final String SOQL_Field_Appendage = 'Field IN (\'MailingCity\', \'MailingPostalCode\', \'MailingState\', \'MailingStreet\', \'MailingCountry\')';

		List<Account> accountsToIgnore = [SELECT Id, Name, (SELECT Id, Name FROM Contacts) FROM Account WHERE Name = 'EmailTgrHandler' LIMIT 1];
		List<Id> ContactIdsToIgnore = new List<Id>();

		if ((accountsToIgnore != null) && (accountsToIgnore.size() > 0)) {
			for (Contact c : accountsToIgnore[0].Contacts) {
				ContactIdsToIgnore.add(c.Id);
			}
		}

		//First, purge all existing records for said user.
		List<ContactHistoryCache__c> purgeList = [SELECT Id FROM ContactHistoryCache__c WHERE OwnerId = :UserInfo.getUserId()];
		delete purgeList;

		//Now we get to populate this...

		//Start by getting all ContactHistory records within the selected timeframe where field like 'Mailing%' and ContactId is NOT the fake Apirio record.
		//Load them into a Map of type <ContactId, List<Changes>>
		Map<Id, List<ContactHistory>> mapContactEdits = new Map<Id, List<ContactHistory>>();

		String soql = 'SELECT Field, ContactId, CreatedById, CreatedDate, NewValue, OldValue FROM ContactHistory WHERE CreatedDate >= LAST_N_DAYS:' + daysBack + ' AND ' + SOQL_Field_Appendage;

		for (ContactHistory ch : Database.query(soql)) {
			if (!mapContactEdits.containsKey(ch.ContactId)) mapContactEdits.put(ch.ContactId, new List<ContactHistory>());
			mapContactEdits.get(ch.ContactId).add(ch);
		}

		//Populate another Map of <ContactId, QuoteId> that will hold contacts that are in the first map AND also bill-to on a quote.
		//If multiple quotes are found, always use the most recently modified.
		//If no quotes are found for said contact, remove it from the initial map.
		Map<Id, zqu__Quote__c> mapContactQuote = new Map<Id, zqu__Quote__c>();

		for (zqu__Quote__c qt : [SELECT 
									zqu__BillToContact__c, 
									zqu__Opportunity__c, 
									zqu__Opportunity__r.IsClosed, 
									zqu__Opportunity__r.IsWon, 
									zqu__Opportunity__r.StageName,
									Contract_End_Date_Apex__c,
									LastModifiedDate,
									Id
								FROM zqu__Quote__c 
								WHERE zqu__BillToContact__c IN :mapContactEdits.keySet()]) {

			//This is Glen's further filtering, per his email received on 2014.03.03
			if ( (qt.zqu__Opportunity__r.IsWon == true && qt.zqu__Opportunity__r.IsClosed == true) ||
				 (qt.Contract_End_Date_Apex__c >= System.today().addDays(-1 * daysBack)) ||
				 (qt.zqu__Opportunity__r.IsClosed == false) ) {
				if (!mapContactQuote.containsKey(qt.zqu__BillToContact__c)) mapContactQuote.put(qt.zqu__BillToContact__c, qt);
				else if ((mapContactQuote.get(qt.zqu__BillToContact__c).LastModifiedDate) < qt.LastModifiedDate) mapContactQuote.put(qt.zqu__BillToContact__c, qt);
			}

		}

		//Now loop through the initial map and insert all accopanying records & matching quotes from the second map.
		List<ContactHistoryCache__c> insertList = new List<ContactHistoryCache__c>();

		for (List<ContactHistory> chList : mapContactEdits.values()) {
			for (ContactHistory cHistory : chList) {

				if (mapContactQuote.containsKey(cHistory.ContactId)) {

					ContactHistoryCache__c ch = new ContactHistoryCache__c();
					ch.OwnerId = UserInfo.getUserId();
					ch.ChangeMadeOn__c = cHistory.CreatedDate;
					ch.Contact__c = cHistory.ContactId;
					ch.Field_Changed__c = cHistory.Field;
					ch.New_Value__c = String.valueOf(cHistory.NewValue);
					ch.Old_Value__c = String.valueOf(cHistory.OldValue);
					ch.Quote__c = mapContactQuote.get(cHistory.ContactId).Id;
					ch.User_Instigating_Change__c = cHistory.CreatedById;

					insertList.add(ch);					
				}				
			}
		}		
		if (insertList.size() > 0) insert insertList;
		else errors.add('No matching records found.');
	}
}