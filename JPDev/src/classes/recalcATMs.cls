global class recalcATMs implements Database.Batchable<sObject> {

	//Exexute
	//id batchinstanceid = database.executeBatch(new recalcATMs('select Id from Account'));

	public static void go() {
		id batchinstanceid = database.executeBatch(new recalcATMs('select Id from Account'));
	}

	global final String Query;

	global recalcATMs(String q) {
		Query=q;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		
		Set<String> accIdSet = new Set<String>();

		for (Sobject s : scope) {
	 		Account a = (Account)s;
	        accIdSet.add(a.id);
		}

	     CommonUtil.recallATM(accIdSet);
	}

	global void finish(Database.BatchableContext BC) {
	    //Send an email to the User after your batch completes
	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {UserInfo.getUserEmail()};
		mail.setToAddresses(toAddresses);
		mail.setSubject('Apex Batch Job (recalcATMs) is done');
		mail.setPlainTextBody('The batch Apex job processed ');
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
}