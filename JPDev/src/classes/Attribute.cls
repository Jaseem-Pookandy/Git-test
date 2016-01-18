public class Attribute {

    public String labelText {get; set;}
    public String APIName {get; set;}
    public String control {get; set;}
    public String soqlSelect {

    	get; 

    	set {
    		soqlSelect = value;
/*    		this.picklistObjects = new List<SelectOption>();

    		if (((control == 'selectList') || (control == 'Country')) && (soqlSelect != null)) {
	    		List<SObject> result = Database.query(soqlSelect);	    		

                //Add '-none-' as an option if salesRep only
                if (APIName == 'SalesRepId__c') this.picklistObjects.add(new SelectOption('', '--None--'));

	    		if ((result != null) && (!result.isEmpty())) {
		    		for (SObject so : result) {
		    			this.picklistObjects.add(new SelectOption(String.valueOf(so.get(picklist_IDField)), String.valueOf(so.get(picklist_ValueField))));
		    		}
	    		}
	    		else this.picklistObjects.add(new SelectOption('', 'D\'oh! None found'));
    		} */
    	}
   	}

    public Boolean HasPostbackAction {
        get {
            if ((postbackAction != null) && (postbackAction != '')) return true;
            return false;
        }
    }

    public String picklist_IDField {get; set;}
    public String picklist_ValueField {get; set;}
    public String postbackAction {get; set;}
    public String defaultValue {get; set;}
    public QCAttributeLogic renderingLogic {get; set;}
    public List<SelectOption> picklistObjects {get; set;}

    public Attribute() {
        renderingLogic = new QCAttributeLogic(true, true);
    }        

    //Because of all sorts of dynamic requirements, I haven't been able to successfully streamline the code to use only one setter...  Maybe later...
    public void FixCustomSelectListOptions(zqu__Quote__c q) {        

        if ((control == 'selectListEvent') && (soqlSelect != null)) {

            this.picklistObjects = new List<SelectOption>();
            this.picklistObjects.add(new SelectOption('', ''));
            String soql = soqlSelect;

            if ((q != null) && (q.zqu__StartDate__c != null) && (q.Service_End_Date__c != null)) {

                Date dtStart = q.zqu__StartDate__c;
                Date dtEnd = q.Service_End_Date__c;

                soql += ' WHERE ((Event_Date__c >=  :dtStart AND Event_Date__c <= :dtEnd) OR Event_Date__c = null) AND (NOT(Status__c like \'cancel%\')) ORDER BY Display_Name__c ASC';  
            } 

            List<SObject> result = Database.query(soql);              

            if ((result != null) && (!result.isEmpty())) {
                for (SObject so : result) {
                    this.picklistObjects.add(new SelectOption(String.valueOf(so.get(picklist_IDField)), String.valueOf(so.get(picklist_ValueField))));
                }
            }
            else this.picklistObjects.add(new SelectOption('', 'D\'oh! None found'));
        }
    }
}