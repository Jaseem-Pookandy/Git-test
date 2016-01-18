public with sharing class AccountReassignmentSearchController {

  // ApexPages.StandardSetController must be instantiated for standard list controllers       
    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(soql));
            }
            return setCon;
        }
        set;
    }
    
    // Initialize setCon and return a list of records   
    public List<AccountReassignment__c> PaginatedAccountReassignments {
         get{
            return (List<AccountReassignment__c>) setCon.getRecords();
         }
         set;
    }  

  // the soql without the order and limit
  private String soql {get;set;}
  // the collection of Account Reassignment to display

  // the current sort direction. defaults to asc
  public String sortDir {
    get  { if (sortDir == null) {  sortDir = 'asc'; } return sortDir;  }
    set;
  }

  // the current field to sort by. defaults to last name
  public String sortField {
    get  { if (sortField == null) {sortField = 'Account_Number_Assigned__c'; } return sortField;  }
    set;
  }

  // format the soql for display on the visualforce page
  public String debugSoql {
    get { return soql + ' order by ' + sortField + ' ' + sortDir; }
    set;
  }

  // init the controller and display some sample data when the page loads
  public AccountReassignmentSearchController() {
    String uploadedFileRef = Apexpages.currentPage().getParameters().get('uploadFileRef');
    soql  = 'SELECT Account_Number_Assigned__c, AHJCSR__c, AHJRep__c, Batch_Id__c, CJCSR__c, CJRep__c, DiceCSR__c, DiceRep__c,'; 
    soql += 'EFCCSR__c, EFCRep__c, Id, Name, Remark__c, RZCSR__c, RZRep__c, Status__c, Uploaded_File_Ref__c ';
    soql += 'FROM AccountReassignment__c WHERE Account_Number_Assigned__c != NULL';
    if (!''.equals(uploadedFileRef))
    {
      soql += ' and Uploaded_File_Ref__c LIKE \''; // + '\'';
      soql += uploadedFileRef;
      soql += '%\'';
    }
    else
    {
       sortField = 'CreatedDate';
       sortDir = 'desc';
    }
    runQuery();
    setCon.setpagesize(25);
  }

  // toggles the sorting of query from asc<-->desc
  public PageReference toggleSort() {
    // simply toggle the direction
    sortDir = 'asc'.equals(sortDir) ? 'desc' : 'asc';
    // run the query again
    runQuery();

    return null;
  }

  // runs the actual query
  public void runQuery() {
    try {
      //AccountReassignments = Database.query(soql + ' order by ' + sortField + ' ' + sortDir + ' NULLS LAST');
      soql += ' order by ' + sortField + ' ' + sortDir + ' NULLS LAST LIMIT 9000'; 
      setCon = new ApexPages.StandardSetController(Database.getQueryLocator(soql));
    } catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops!'));
    }
  }

  // runs the search with parameters passed via Javascript
  public PageReference runSearch() {
    String uploadedFileRef = Apexpages.currentPage().getParameters().get('uploadedFileRef');
    String accountNumber = Apexpages.currentPage().getParameters().get('accountNumber');
    String name = Apexpages.currentPage().getParameters().get('name');
    String salesRep = Apexpages.currentPage().getParameters().get('salesRep');
    String supportRep = Apexpages.currentPage().getParameters().get('supportRep');
    String status = Apexpages.currentPage().getParameters().get('status');

    soql  = 'SELECT Account_Number_Assigned__c, AHJCSR__c, AHJRep__c, Batch_Id__c, CJCSR__c, CJRep__c, DiceCSR__c, DiceRep__c,'; 
    soql += 'EFCCSR__c, EFCRep__c, Id, Name, Remark__c, RZCSR__c, RZRep__c, Status__c, Uploaded_File_Ref__c ';
    soql += 'FROM AccountReassignment__c WHERE Account_Number_Assigned__c != NULL';
    if (!uploadedFileRef.equals(''))
    {
      soql += ' and Uploaded_File_Ref__c LIKE \''; // + '\'';
      soql += uploadedFileRef;
      soql += '%\'';
    }
    if (!''.equals(accountNumber))
    {
      soql += ' and Account_Number_Assigned__c LIKE \''; // + '\'';
      soql += accountNumber;
      soql += '%\'';
    }
    if (!''.equals(name))
    {
      soql += ' and (Name LIKE \''; 
      soql += name;
      soql += '%\' OR Name Like \'AOR-' + name + '%\')';
    }
    if (!''.equals(salesRep))
    {
      soql += ' and (';
      soql += ' AHJRep__c LIKE \'';
      soql += String.escapeSingleQuotes(salesRep);
      soql += '%\'';
      soql += ' OR ';
      soql += ' CJRep__c LIKE \'';
      soql += String.escapeSingleQuotes(salesRep);
      soql += '%\'';
      soql += ' OR ';
      soql += ' DiceRep__c LIKE \'';
      soql += String.escapeSingleQuotes(salesRep);
      soql += '%\'';
      soql += ' OR ';
      soql += ' EFCRep__c LIKE \'';
      soql += String.escapeSingleQuotes(salesRep);
      soql += '%\'';
      soql += ' OR ';
      soql += ' RZRep__c LIKE \'';
      soql += String.escapeSingleQuotes(salesRep);
      soql += '%\'';
      soql += ')'; 
    }
    if (!''.equals(supportRep))
    {
      soql += ' and (';
      soql += ' AHJCSR__c LIKE \'';
      soql += String.escapeSingleQuotes(supportRep);
      soql += '%\'';  
      soql += ' OR ';
      soql += ' CJCSR__c LIKE \'';
      soql += String.escapeSingleQuotes(supportRep);
      soql += '%\'';  
      soql += ' OR ';
      soql += ' DiceCSR__c LIKE \'';
      soql += String.escapeSingleQuotes(supportRep);
      soql += '%\'';  
      soql += ' OR ';
      soql += ' EFCCSR__c LIKE \'';
      soql += ' OR ';
      soql += ' RZCSR__c LIKE \'';
      soql += ')'; 
    }
    if (!''.equals(status))
    {
      soql += ' and Status__c = \'';
      soql += status;
      soql += '\'';
    }

    // run the query again
    runQuery();
    return null;
  }

  // use apex describe to build the picklist values
  public List<String> statusLst{
    get {
      if (statusLst == null) {
        statusLst = new List<String>();
        Schema.DescribeFieldResult field = AccountReassignment__c.Status__c.getDescribe();

        for (Schema.PicklistEntry f : field.getPicklistValues())
          statusLst.add(f.getLabel());
      }
      return statusLst;          
    }
    set;
  }
}