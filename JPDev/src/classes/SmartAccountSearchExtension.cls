/*******************************************************************
Name            : SmartAccountSearchExtension
Author          : Appirio Offshore (Urminder Vohra)
Date            : July 19, 2011
Asset Added : Dec 4th, 2012 by Naresh Kr Ojha (Appirio Offshore)
Related Task:   T-93560       
*************************************************************************/
//
// Changed to without sharing so that users can see duplicates across the world
//
//public with sharing class SmartAccountSearchExtension {
public  class SmartAccountSearchExtension {
    
    //Search criteria fields
    public String accountNameToSeaarch {set;get;}
    public Boolean showGrid{get;set;}    
    public integer searchCount{set; get;}
    public string searchStatus{set; get;}
    public string sortField{set;get;}
    public integer limitRecords{set; get;} //May25-2012 by sdash@appirio.com: added limit 250 to avoid the query overflow of 50,000 records
    private string previousSortField;
    private string sortOrder;
      
    public boolean isAsc{set; get;}
    public Integer showingFrom{get;set;}
    public Integer showingTo{get;set;}
    public string query;
    
    public boolean showAccountButton{set; get;}
    public boolean hasNext{get;set;}
    public boolean hasPrevious{get;set;}
    public String requestedPage {get;set;}
    
    public integer totalResults {set; get;}
    
    public Integer totalPage {set; get;}
    
    private static final Integer DEFAULT_RESULTS_PER_PAGE = 20;  
    private static final string SEARCH_TYPE = ' and ';
    private static final string DEFAULT_SORT_ORDER = ' ASC ';
    private static final string DEFAULT_SORT_FIELD = 'Name';
        
    
    public ApexPages.StandardSetController accountResults{get;set;}
    //Constructor
    public SmartAccountSearchExtension(ApexPages.StandardController controller) {
    resetSearchStatus();
    }

    //Constructor
    public SmartAccountSearchExtension(){
        resetSearchStatus();
    }
    
    //set to default status of page
    public void resetSearchStatus(){
    //Reset account fields
    showAccountButton = false;
    accounts = new List<Account>();
    searchCount = 0;
    searchStatus = '';
    sortOrder = DEFAULT_SORT_ORDER;
    sortField = DEFAULT_SORT_FIELD;
    previousSortField = DEFAULT_SORT_FIELD;
    accountNameToSeaarch = '';
    isAsc = true;
    hasPrevious = false;
    hasNext = false; 
    showGrid = false;
    }
    
    public List<Account> accounts {
        get{
        return accounts;
    }set;
    }

    //Action method for cancel button    
    public PageReference cancel(){
        Pagereference pg = null;
        return pg;  
    }

    //Finding and composing search condition.    
    public String findSearchCondition(String query){
        accountNameToSeaarch = accountNameToSeaarch.replace('*','');
        //accountNameToSeaarch = accountNameToSeaarch.replace('\'','');
        accountNameToSeaarch = String.escapeSingleQuotes(accountNameToSeaarch);
        
        if(accountNameToSeaarch != null && accountNameToSeaarch != ''){
            if(query.toUpperCase().contains('WHERE')){
                query += ' and Name like \'%' + accountNameToSeaarch.Trim() + '%\'';
            }else{
                query += ' where Name like \'%' + accountNameToSeaarch.Trim() +  '%\'';
            }
        }
        /* if(shippingCountryToSearch != null && shippingCountryToSearch != ''){
            if(query.toUpperCase().contains('WHERE')){
                query += ' and ShippingCountry like \'%' + shippingCountryToSearch.Trim() + '%\'';
            }else{
                query += ' where ShippingCountry like \'%' + shippingCountryToSearch.Trim() + '%\'';
            }
        }*/
        return query;
    }
  
    //Search method call
    public void performSearch() {
        searchAccount();
    }
    
    //method to search account and make list according to pagesize
    private void searchAccount(){
        showAccountButton = true;
        limitRecords=250;
    query = 'Select Phone, Name, Owner.Name, BillingStreet, BillingCity, BillingState, BillingCountry, Type, Account_Number__c, Parent.Name, ParentId';
    query += ' From Account';
    query = findSearchCondition(query);
    query += ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT ' + limitRecords  ;
          
        try{
        accounts = new List<Account>();
        accountResults = new ApexPages.StandardSetController(Database.query(query));
        accountResults.setPageSize(DEFAULT_RESULTS_PER_PAGE);
        accounts = accountResults.getRecords();
        searchCount = accountResults.getResultSize();
        //May25-2012 by sdash@appirio.com: Added the if condition to check records count touching limitRecords
        if (searchCount >= limitRecords) {
            searchStatus = 'Search returned more than ' + limitRecords + ' records. Please refine your search';
        }
        if(accounts.size() > 0 ) {
            showGrid = true;
        }
        }
        catch(Exception e){
            searchCount = 0;
        }  
        if (searchCount  == 0){
            searchStatus = 'No matching results found.';
            showGrid = false;
            //searchStatus = Label.No_matching_results;
        }
        
        requestedPage = String.valueOf(accountResults.getPageNumber());
        showingFrom = 1;
        
        totalResults = 0;
        for (List<Sobject> recordBatch:Database.query(query))  {
        totalResults = totalResults + recordBatch.size();
        }
        totalPage = 0;
        totalPage = totalResults / accountResults.getPageSize() ; 
        if (totalPage * accountResults.getPageSize() < totalResults){
          totalPage++;
        }
        
        if(searchCount < accountResults.getPageSize()) {
            showingTo = searchCount;
        } else {
            showingTo = accountResults.getPageSize();
        }
        if(accountResults.getHasNext()) {
            hasNext = true;
        } else {
            hasNext = false;
        }
        hasPrevious = false;
      
    }
    
    //Moves on next page on the pagination
    public PageReference nextAccountPage(){
        
        if(accountResults.getHasNext()) {
            accounts = new List<Account>();
        accountResults.next();
        accounts = accountResults.getRecords();
        showingFrom = showingFrom + accountResults.getPageSize();
        showingTo =  showingTo + accounts.size();
        if(accountResults.getHasNext()) {
                hasNext = true;
        } else {
          hasNext = false;
        }
        hasPrevious = true; 
        }
        requestedPage = String.valueOf(accountResults.getPageNumber());
        return null;
    }
    
   
    //Moves on the previous page in pagination
  public PageReference previousAccountPage(){
        if(accountResults.getHasPrevious()) {
        showingTo =  showingTo - accounts.size();
        accounts = new List<Account>();
        accountResults.previous();
        accounts = accountResults.getRecords();
        showingFrom = showingFrom - accountResults.getPageSize();
        hasNext = true;
        if(accountResults.getHasPrevious()) {
        hasPrevious = true;
        } else {
        hasPrevious = false;
        }
        }
        requestedPage = String.valueOf(accountResults.getPageNumber());  
        return null;
    }
    
   
  //Moves on particular page.
    public PageReference requestedAccountPage(){
        
        boolean check = pattern.matches('[0-9]+',requestedPage); 
        Integer pageNo = check? Integer.valueOf(requestedPage) : 0;
        if(pageNo == 0 || pageNo > totalPage){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid page number.')); 
            return null;       
        }   
        accountResults.setPageNumber(pageNo);
        accounts = accountResults.getRecords();
        if(accountResults.getHasPrevious()) {
            hasPrevious = true;
        } else {
            hasPrevious = false;
        }
        if(accountResults.getHasNext()) {
        hasNext = true;
        } else {
        hasNext = false;
        }
    showingFrom  = (pageNo - 1) * accountResults.getPageSize() + 1;
   
    showingTo = showingFrom + accounts.size() - 1;
    if(showingTo > totalResults) {
        showingTo = totalResults;
    }
    return null;
    }
    
    //used to sort
    public void sortData(){
        if (previousSortField.equals(sortField)){
            isAsc = !isAsc;  
        }else{
            isAsc = true;
        }   

        sortOrder = isAsc ? ' ASC ' : ' DESC ';
        previousSortField = sortField;
        searchAccount();
    }
    
}