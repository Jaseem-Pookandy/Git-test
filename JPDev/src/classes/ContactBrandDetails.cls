public with sharing class ContactBrandDetails {

	public string Brand {get; set;}
	public Opportunity LastCloseWonOpp {get; set;}	
	public Contact_Type__c ContactType {get; set;}
	public string AccountID {get; set;}
	public Boolean contactIsPrimaryRecipient {get; set;}

	
	public String PrettyAmount {
		get {
			if (LastCloseWonOpp != null && LastCloseWonOpp.Amount != null) {
				
				String sVal = String.ValueOf(LastCloseWonOpp.Amount);
				
				String s = ( Decimal.valueOf(sVal==null||sVal.trim()==''?'0':sVal).setScale(2) + 0.001 ).format();
    			return '<a href="/' + LastCloseWonOpp.Id + '" target="_blank">' + s.substring(0,s.length()-1) + '</a>';
			}
			else return '-';
		}
	}
	
	public String PrettyOppDate {
		get {
			if (LastCloseWonOpp != null && LastCloseWonOpp.CloseDate != null) return LastCloseWonOpp.CloseDate.format();
			else return '-';
		}
	}
	
	public String PrettyTitle {
		get {
			if ((ContactType == null) || (ContactType.Type__c == null) || (ContactType.Type__c == '')) return '-';
			else return '<a href="/' + ContactType.Id + '/e?retURL=%2F' + AccountID + '" target="_blank">' + ContactType.Type__c + '</a>';
		}
	}

	public ContactBrandDetails() {
		
		LastCloseWonOpp = new Opportunity();
		ContactType = new Contact_Type__c();
		contactIsPrimaryRecipient = false;

	}
}