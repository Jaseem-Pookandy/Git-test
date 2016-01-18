/***************************************************************************
// (c) 2013 Appirio, Inc.
//
// Description    : Class to handle the updation of owner field of campMembers 
// Task           : T-121070                  
// Mar 07th, 2013  :  Naresh Ojha (Appirio Offshore)
//***************************************************************************/
public class MassUpdateCampMemberController {

  public Integer pageSize {get;set;}
  public Integer pageNumber{get;set;}
  public Integer totalRecords{get;set;}
  public Integer totalNumPages{get;set;}
  public String showCurrentState {get;set;}  
  public String CampaignID {get;set;}
  public String sortField {get;set;}
  public boolean isAsc{set; get;}
  public boolean calledSearch;
  public Integer defaultMaxSize = 10000;
  private string sortOrder; 
  private static final string DEFAULT_SORT_ORDER = ' ASC ';
  private static final string DEFAULT_SORT_FIELD = ' Contact.Name ';
  private string previousSortField;
        
  public String ownerId;
  private String baseQuery = '';
  private String mainQuery = 'SELECT Campaign.Name, CampaignID, Contact.Name, ContactId, Id, Status, Owner_Assigned__c, Owner_Assigned__r.Name FROM CampaignMember WHERE Campaign.IsActive = true AND HasResponded = false ';
    
  //Our collection of the class/wrapper objects cCampaignMember 
  public List<cCampaignMember> CampaignMemberList {get; set;}
  public List<cCampaignMember> CampaignMembers{get;set;}
  public List<CampaignMember> selected {get; set;}
  public CampaignMember camp{get;set;}
  
  
  public MassUpdateCampMemberController () {
    pageSize = 10; //Default page size.
    init();
  }

  //In it  
  private void init() {
    isAsc = true;
    sortOrder = DEFAULT_SORT_ORDER;
    sortField = DEFAULT_SORT_FIELD;
    previousSortField = DEFAULT_SORT_FIELD;
    
    calledSearch = false;
    camp = new CampaignMember();
    baseQuery = mainQuery;
    totalNumPages = 0;
    Integer currentPage = 0;

    CampaignID = ApexPages.currentPage().getParameters().get('campaignId');

    if (CampaignID <> null) {
      baseQuery = mainQuery+' AND CampaignID = \''+CampaignID+'\'';
    } 
    
    if(ApexPages.currentPage().getParameters().get('pg') <> null) currentPage = Integer.valueOf(ApexPages.currentPage().getParameters().get('pg'));

    if (currentPage > 0) pageNumber = currentPage;
    else pageNumber = 0;
    
    fetchCampaignMembers();     
  }  
  
  public Pagereference reset() {
    camp = new CampaignMember();
    return null;
  }
  
  //This method uses a simple SOQL query to return a List of CampaignMembers
  public List<cCampaignMember> fetchCampaignMembers() {
    Integer offset = pageNumber * pageSize;
    String suffixPage;    
    String countQuery = 'SELECT count() FROM '+String.valueOf(baseQuery).split('FROM')[1]+' LIMIT '+defaultMaxSize;

    totalRecords = Database.countQuery(countQuery);//countList.size();
    totalNumPages = totalRecords/pageSize;
    if(totalRecords >= defaultMaxSize) suffixPage = '+';
    else suffixPage = '';
    
    if((offset+pageSize) >= totalRecords) showCurrentState = String.valueOf(offset+1)+' - '+String.valueOf(totalRecords) + ' Of ' + String.valueOf(totalRecords)+suffixPage;
    else showCurrentState = String.valueOf(offset+1)+' - '+String.valueOf(offset+pageSize) + ' Of ' + String.valueOf(totalRecords)+suffixPage;
    
    String query = baseQuery +  ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT '+pageSize +' OFFSET '+ offset;
    
    CampaignMemberList = new List<cCampaignMember>();
    List<CampaignMember> cmList = new List<CampaignMember>();

    cmList = Database.query(query);
    
    for (CampaignMember cm : cmList) {
      CampaignMemberList.add(new cCampaignMember(cm));
    }
         
    return CampaignMemberList;
  }
  //Filter records
  public Pagereference searchByOwner() {
    pageNumber = 0;
    baseQuery = mainQuery;
    baseQuery += camp.Owner_Assigned__c <> null ?' AND Owner_Assigned__c = \'' + camp.Owner_Assigned__c + '\'' : ' AND Owner_Assigned__c = null';
    baseQuery += camp.CampaignId <> null ?' AND CampaignID = \'' + camp.CampaignId + '\'' : '  ';
    calledSearch = true;
    fetchCampaignMembers();
    return null;
  }

  //used to sort
  public void sortData(){
    if (previousSortField.equals(sortField)) isAsc = !isAsc;  
    else isAsc = true;

    sortOrder = isAsc ? ' ASC ' : ' DESC ';
    previousSortField = sortField;

    if (calledSearch) searchByOwner();
    else fetchCampaignMembers();
  }  
  
  //Set page size
  public Pagereference checkPageSize () {

    if(calledSearch) searchByOwner();
    else fetchCampaignMembers();

    return null;
  }
  
  //Proceed for selected campaign members
  public PageReference processSelected() {

    //We create a new list of CampaignMembers that we be populated only with CampaignMembers if they are selected
    List<CampaignMember> selectedCampaignMembers = new List<CampaignMember>();
    selected = new List<CampaignMember>();
    //We will cycle through our list of cCampaignMembers and will check to see if the selected property is set to true, if it is we add the CampaignMember to the selectedCampaignMembers list
    for(cCampaignMember cCon: CampaignMemberList) {
      if(cCon.selected == true) selectedCampaignMembers.add(cCon.con);
    }
    
    if(selectedCampaignMembers.isEmpty()) {
      ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please select campaign member(s)'));
      return null;
    }
    
    // Now we have our list of selected CampaignMembers and can perform any type of logic we want, sending emails, updating a field on the CampaignMember, etc
    for(CampaignMember con: selectedCampaignMembers) {
      selected.add(con);
    }
    
    return new Pagereference('/apex/MassUpdateCampaignMemberOwner2');
  }

  public Pagereference save() {

    for(CampaignMember cm : selected) {
      cm.Owner_Assigned__c = camp.Owner_Assigned__c;
    }

    if (!selected.isEmpty()) update selected;

    Pagereference pg;
    String campaignSuffix = '';
    if (CampaignID <> null) campaignSuffix = '&campaignId='+CampaignID;

    if (pageNumber > 0) pg = new Pagereference('/apex/MassUpdateCampaignMemberOwner?pg='+pageNumber+campaignSuffix);
    else pg = new Pagereference('/apex/MassUpdateCampaignMemberOwner?'+campaignSuffix);

    pg.setRedirect(true);
    return pg;
  }

  public Pagereference cancel() {
    Pagereference pg;
    String campaignSuffix = '';

    if (CampaignID <> null) campaignSuffix = '&campaignId='+CampaignID;

    if (pageNumber > 0) pg = new Pagereference('/apex/MassUpdateCampaignMemberOwner?pg='+pageNumber+campaignSuffix);
    else pg = new Pagereference('/apex/MassUpdateCampaignMemberOwner?'+campaignSuffix);

    pg.setRedirect(true);
    return pg;
  }
  // This is our wrapper/container class. A container class is a class, a data structure, or an abstract data type whose instances are collections of other objects. In this example a wrapper class contains both the standard salesforce object CampaignMember and a Boolean value
  public class cCampaignMember {
    public CampaignMember con {get; set;}
    public Boolean selected {get; set;}

    //This is the contructor method. When we create a new cCampaignMember object we pass a CampaignMember that is set to the con property. We also set the selected value to false
    public cCampaignMember(CampaignMember c) {
      con = c;
      selected = false;
    }
  }
  
   //Next page
  public PageReference next(){
        pageNumber++;
        fetchCampaignMembers();
        return null;
  }

  //Previous page
  public PageReference previous(){
        pageNumber--;

        if (pageNumber < 0) return null;

        fetchCampaignMembers();
        return null;
  }
}