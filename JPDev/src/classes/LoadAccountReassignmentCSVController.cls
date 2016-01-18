public class LoadAccountReassignmentCSVController {
public Transient Blob csvFileBody {get;set;}
public string csvAsString {get;set;}
public String[] csvFileLines {get;set;}
public boolean isLoad {get;set;}
public List<AccountReassignment__c> acclist {get;set;}
public String uploadFileRef {get;set;}

public LoadAccountReassignmentCSVController(){
    csvFileLines = new String[]{};
    acclist = New List<AccountReassignment__c>();
    isLoad = false;
  }
  
// the soql without the order and limit
public String soql {
    get {
        if(soql == null){
           soql =  'SELECT Id, Uploaded_File_Ref__c, Account_Number_Assigned__c, AHJCSR__c, AHJRep__c, CJCSR__c, CJRep__c, DiceRep__c, DiceCSR__c, ';
           soql += 'EFCCSR__c, EFCRep__c, RZCSR__c, RZRep__c, Status__c ';
           soql += 'FROM accountReassignment__c WHERE Status__c = \'Pending\' LIMIT 10000';
        }
        return soql;
    }
    set;
}

// ApexPages.StandardSetController must be instantiated for standard list controllers       
public ApexPages.StandardSetController setCon {
    get {
        if(setCon == null) {
            setCon = new ApexPages.StandardSetController(Database.getQueryLocator(soql));    
            setCon.setpagesize(25);
        }
        return setCon;
    }
    set;
}

// Initialize setCon and return a list of records   
public List<AccountReassignment__c> PaginatedAcctList {
     get{
        return (List<AccountReassignment__c>) setCon.getRecords();
     }
     set;
}  

public Boolean isReassign {
    get{
        return PaginatedAcctList.size() > 0;
    }
    set;
}
  
  // indicates whether there are more records after the current page set.
  public Boolean hasNext {
        get {
            return setCon.getHasNext();
        }
        set;
  }

  // indicates whether there are more records before the current page set.
  public Boolean hasPrevious {
        get {
            return setCon.getHasPrevious();
        }
        set;
  }

  // returns the page number of the current page set
  public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
  }
  
  // returns the first page of records
  public void first() {
        setCon.first();
  }

  // returns the last page of records
  public void last() {
       setCon.last();
  }

  // returns the previous page of records
  public void previous() {
       setCon.previous();
  }

  // returns the next page of records
  public void next() {
       setCon.next();
  }
  
  public PageReference reviewList() {
    Schema.DescribeSObjectResult result = AccountReassignment__c.SObjectType.getDescribe();
    PageReference pageRef = Page.AccountReassignmentSearch;
    pageRef.getParameters().put('uploadFileRef', uploadFileRef);
    pageRef.setRedirect(true);
    return pageRef;
  }
  
  public PageReference redirectToList() {
    isLoad = false;
    PageReference pageRef = Page.AccountReassignmentSearch;
    pageRef.getParameters().put('uploadFileRef', uploadFileRef);
    pageRef.getParameters().put('status', 'Pending');
    pageRef.setRedirect(true);
    return pageRef;
  }  
  
  public void deleteCSVFile(){
     List<AccountReassignment__c> acctReasignDeleteLst = [SELECT Id FROM accountReassignment__c WHERE Uploaded_File_Ref__c = :uploadFileRef];
     delete acctReasignDeleteLst;
     uploadFileRef = null;
     isLoad = false;
     try 
     {           
       setCon = new ApexPages.StandardSetController(Database.getQueryLocator(soql));  
       setCon.setpagesize(25);
     } catch (Exception e) {
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops!'));
     }
  }
  
  public void importCSVFile(){
      DateTime dt = DateTime.now();
      String formattedDt = dt.format('yyyyMMddhhmmss');
      uploadFileRef = UserInfo.getFirstName() + '_' + UserInfo.getLastName() + '_' + formattedDt;
      try{
           csvAsString = csvFileBody.toString();
           csvFileLines = csvAsString.split('\n');
            
           for(Integer i=1;i<csvFileLines.size();i++){   
               AccountReassignment__c accReassignObj = new AccountReassignment__c() ;
               string[] csvRecordData = csvFileLines[i].split(',');
               accReassignObj.Account_Number_Assigned__c = csvRecordData[0] ;       
               accReassignObj.AHJRep__c = csvRecordData[1] ;             
               accReassignObj.AHJCSR__c = csvRecordData[2];
               accReassignObj.CJRep__c = csvRecordData[3];
               accReassignObj.CJCSR__c = csvRecordData[4];  
               accReassignObj.DiceRep__c = csvRecordData[5];      
               accReassignObj.DiceCSR__c = csvRecordData[6] ;            
               accReassignObj.EFCRep__c = csvRecordData[7];
               accReassignObj.EFCCSR__c = csvRecordData[8];
               accReassignObj.RZRep__c = csvRecordData[9];   
               accReassignObj.RZCSR__c = csvRecordData[10];    
               accReassignObj.Status__c = 'Pending';     
               accReassignObj.Uploaded_File_Ref__c = uploadFileRef;                                                               
               acclist.add(accReassignObj);                                
           }
           isLoad = acclist.size() > 0;
           insert acclist;
           csvFileLines = null;
           csvAsString = null;
           csvFileBody = null;
           soql =  'SELECT Id, Uploaded_File_Ref__c, Account_Number_Assigned__c, AHJCSR__c, AHJRep__c, CJCSR__c, CJRep__c, DiceRep__c, DiceCSR__c, ';
           soql += 'EFCCSR__c, EFCRep__c, RZCSR__c, RZRep__c, Status__c ';
           soql += 'FROM accountReassignment__c WHERE Status__c = \'Pending\' AND Uploaded_File_Ref__c = \'';
           soql +=  uploadFileRef;
           soql += '\'';
           try 
           {           
             setCon = new ApexPages.StandardSetController(Database.getQueryLocator(soql));  
             setCon.setpagesize(25);
           } catch (Exception e) {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops!'));
           }
      }
      catch (Exception e)
      {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while loading data Please make sure input csv file is correct');
            ApexPages.addMessage(errorMessage);
      } 
  }
  
  /**
* Split a string of any size, while avoiding the dreaded 'Regex too complicated'
* error, which the String.split(String) method causes on some large inputs.
*
* Note that this method does not avoid other errors, such as those related to
* excess heap size or CPU time.
*/
public List<String> safeSplit(String inStr, String delim)
{
    Integer regexFindLimit = 100;
    Integer regexFindCount = 0;
     
    List<String> output = new List<String>();
     
    Matcher m = Pattern.compile(delim).matcher(inStr);
     
    Integer lastEnd = 0;
 
    while(!m.hitEnd())
    {
        while(regexFindCount < regexFindLimit && !m.hitEnd())
        {
            if(m.find())
            {
                output.add(inStr.substring(lastEnd, m.start())); 
                lastEnd = m.end();
            }
            else
            {
                output.add(inStr.substring(lastEnd));
                lastEnd = inStr.length();
            }
             
            regexFindCount++;
        }
 
        // Note: Using region() to advance instead of substring() saves
        // drastically on heap size. Nonetheless, we still must reset the
        // (unmodified) input sequence to avoid a 'Regex too complicated'
        // error.
        m.reset(inStr);       
        m.region(lastEnd, m.regionEnd());
         
        regexFindCount = 0;
    }
    m = null; 
    return output;
}

  
}