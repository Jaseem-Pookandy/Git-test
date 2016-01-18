/*
// 
// (c) 2012 Appirio, Inc.
//
// ObjectHierarchyAccessor
//
//
// 30 Nov 2012   gescandon@appirio.com  Original
// 
//
*/ 
public with sharing class ObjectHierarchyAccessor {

  //Declare variables
  public String currentObjId;
  public List<ObjectWrapper> wrapperList ;
  public Map<String, ObjectWrapper> wrapperMap;
  public List<Integer> maxLevel;
  public String objectName;
  public String parentFieldName {get; set;}
  public String nodeLabelFields{get; set;}
  public List<String> nodeFields;
  
  public ObjectHierarchyAccessor() {
    this.wrapperList = new List<ObjectWrapper>{};
    this.wrapperMap = new Map<String, ObjectWrapper>{};
    this.maxLevel = new List<Integer>{};
    
  }

  
  public void setCurrentObjId( String cid ){
    currentObjId = cid;
  }

  /**
  * Return ObjectWrapper to page
  * @return wrapperList
  */
  public List<ObjectWrapper> getObjectStructure(){
    wrapperList.clear();
    if ( currentObjId == null ) {
      currentObjId = System.currentPageReference().getParameters().get( 'id' );
    }
    
    wrapperList = formatObjectStructure( currentObjId );
    
    return wrapperList;
  }

  /**
  * Query Sobject from top down to build the ObjectWrapper
  * @param currentObjId
  * @return wrapperList
  */
  public List<ObjectWrapper> formatObjectStructure( String currentObjId ){
  
    List<ObjectWrapper> wrapperList = new List<ObjectWrapper>{};

    if (currentObjId == null) return wrapperList;
    
    wrapperMap.clear();
    setObjectName();
    
    List<Sobject> al = new List<Sobject>{};
    List<ID> parentList = new List<ID>{};
    Map<ID, String> nodeMap = new Map<ID, String>{};
    List<String> nodeSortList = new List<String>{};
    List<Boolean> levelFlag = new List<Boolean>{};
    List<Boolean> closeFlag = new List<Boolean>{};
    String nodeId = '0';
    String nodeType = 'child';
    Integer count = 0;
    Integer level = 0;
    Boolean endOfStructure = false;
    
    //Find highest level obejct in the structure
    parentList.add( getTopElementId() );

    //Loop though all children
    String qry;
    if (nodeLabelFields==null) nodeLabelFields = '';
    else {
        nodeFields = getFieldsForNode(nodeLabelFields);
        nodeLabelFields = ',' + nodeLabelFields;
    }

    if (nodeLabelFields.trim() == ',') nodeLabelFields = ''; //byrnes

    while (!endOfStructure) {
 
      qry = 'SELECT ' + parentFieldName + ', OwnerId, Name, Id '+ nodeLabelFields +' FROM ' + objectName;

      if( level == 0 ) qry += ' WHERE Id IN ' + getParentListString(parentList);
      else qry += ' WHERE ' + parentFieldName + ' IN ' + getParentListString(parentList);

      al = Database.query(qry + ' ORDER BY Name');

      if( al.size() == 0 ) endOfStructure = true;
      else {
        parentList.clear();
        for ( Integer i = 0 ; i < al.size(); i++ ){
          //Change below
          Sobject a = al[i];
          nodeId = String.valueOf( i );

          if (level > 0) {
            nodeId = nodeMap.get( (Id)a.get(parentFieldName)) + ',' + nodeId;
          }
          
          wrapperMap.put( nodeID, new ObjectWrapper( nodeID, levelFlag, closeFlag, nodeType, false, false, a, nodeFields ) );
          parentList.add( a.id );
          nodeMap.put( a.id, nodeId );
          nodeSortList.add( nodeId );
        }
        
        maxLevel.add( level );        
        level++;
      }
    }
    
    //Sobject structure must now be formatted
    nodeSortList.sort();
    for (Integer i = 0; i < nodeSortList.size(); i++) {

      List<String> cnl = new List<String> {};
      List<String> nnl = new List<String> {};
      String cn = nodeSortList[i];

      cnl = cn.split( ',', -1 );

      if( i < nodeSortList.size() - 1 ) {
        String nn = nodeSortList[i + 1];
        nnl = nn.split( ',', -1 );
      }
      
      ObjectWrapper objectNode = wrapperMap.get( cn );
      if ( cnl.size() < nnl.size() ){
        //Parent
        objectNode.nodeType = ( isLastNode( cnl ) ) ? 'parent_end' : 'parent';
      } else if( cnl.size() > nnl.size() ) {
        objectNode.nodeType = 'child_end';
        objectNode.closeFlag = setcloseFlag( cnl, nnl, objectNode.nodeType );
      } else {
        objectNode.nodeType = 'child';
      }
      
      objectNode.levelFlag = setlevelFlag( cnl, objectNode.nodeType ); 
      
      //Change below
      if ( objectNode.thisObject.id == currentObjId ) {
        objectNode.currentNode = true;
      }
      wrapperList.add( objectNode );
    }
    
    wrapperList[0].nodeType = 'start';
    wrapperList[wrapperList.size()-1].nodeType = 'end';
    
    return wrapperList;
  }
  /**
  * Added on june 13, 2013
  * @return list of fields to be shown as node label
  */
  public List<String> getFieldsForNode(String nodeLabelFields){
      return nodeLabelFields.split(',');
  }
  /**
  * Determin parent elements relationship to current element
  * @return flagList
  */
  public List<Boolean> setlevelFlag( List<String> nodeElements, String nodeType ){
    
    List<Boolean> flagList = new List<Boolean>{};
    String searchNode = '';
    String workNode = '';
    Integer cn = 0;
    
    for( Integer i = 0; i < nodeElements.size() - 1; i++ ){
      cn = Integer.valueOf( nodeElements[i] );
      cn++;
      searchNode = workNode + String.valueOf( cn );
      workNode = workNode + nodeElements[i] + '.';
      if ( wrapperMap.containsKey( searchNode ) ){
        flagList.add( true );
      }
      else {
        flagList.add( false );
      }
    }
    
    return flagList;
  }
  
  /**
  * Determin if the element is a closing element
  * @return flagList
  */
  public List<Boolean> setcloseFlag( List<String> cnl, List<String> nnl, String nodeType ){
    
    List<Boolean> flagList = new List<Boolean>{};
    String searchNode = '';
    String workNode = '';
    Integer cn = 0;
    
    for( Integer i = nnl.size(); i < cnl.size(); i++ ){
      flagList.add( true );
    }
    
    return flagList;
  }
  
  /**
  * Determin if Element is the bottom node  
  * @return Boolean
  */
  public Boolean isLastNode( List<String> nodeElements ){
    
    String searchNode = '';
    Integer cn = 0;
    
    for( Integer i = 0; i < nodeElements.size(); i++ ){
      if ( i == nodeElements.size()-1 ){
        cn = Integer.valueOf( nodeElements[i] );
        cn++;
        searchNode = searchNode + String.valueOf( cn );
      }
      else {
        searchNode = searchNode + nodeElements[i] + '.';
      }
    }
    if ( wrapperMap.containsKey( searchNode ) ){
      return false;
    }
    else{
      return true;
    }
  }
  
  /**
  * Find the top most element in Heirarchy  
  * @return objId
  */
  public String getTopElementId(){
    String objId = currentObjId;
    setObjectName();
    Boolean top = false;
    String qry;
    while ( !top ) {
      //Change below
      qry = 'Select Id, ' + parentFieldName + ' From ' + objectName;
      qry += ' where Id = \'' + objId + '\'limit 1';
      Sobject a = Database.query(qry);
      
      if ( a.get(parentFieldName) != null ) {
        objId = (Id)a.get(parentFieldName);
      }
      else {
        top = true;
      }
    }
    return objId ;
  }
  
  /*
   * getObjectName returns the sboject name by passing the record id
   */
  public String getObjectName(String Id){
    Schema.Sobjecttype result;
    String target = Id;
    Map<String, Schema.Sobjecttype> gd = Schema.getGlobalDescribe();
    String keyPrefix;
    for(Schema.Sobjecttype describe: gd.values()){
      keyPrefix = describe.getDescribe().getKeyPrefix();  
      if(keyPrefix != null && target.startsWith(keyPrefix)){
        result = describe;
        break;
      }
    }     
    return result.getDescribe().getName();
  } 
  
  public void setObjectName(){
    if (objectName == null) {
      objectName = getObjectName(currentObjId);
    }
  } 
  
  public String getParentListString(List<Id> plist) {
    String result = '(';
    for (Id pid : plist) {
      result += '\'' + (String)pid + '\',';
    }
    result = result.substring(0, result.length()-1); //remove trailing comma
    return result + ')';
  }
  
  /**
  * Wrapper class
  */
  public with sharing class ObjectWrapper{

    public String nodeId;
    public Boolean[] levelFlag = new Boolean[]{};
    public Boolean[] closeFlag = new Boolean[]{};
    public String nodeType;
    public Boolean currentNode;
    private List<String> nodeFields;
    
    public Sobject thisObject {get; set;}
    

    public ObjectWrapper( String nodeId, Boolean[] levelFlag, Boolean[] closeFlag , String nodeType, Boolean lastNode, Boolean currentNode, Sobject a, List<String> nodeFields ){
      
      this.nodeId = nodeId;
      this.levelFlag = levelFlag; 
      this.closeFlag = closeFlag;
      this.nodeType = nodeType;
      this.currentNode = currentNode;
      this.thisObject = a;
      this.nodeFields = nodeFields;
    }
    
    public String getnodeId() { 
      return nodeId; 
    }
    
    public Boolean[] getlevelFlag() { 
      return levelFlag; 
    }
    
    public Boolean[] getcloseFlag() { 
      return closeFlag; 
    }
    
    public String getnodeType() { 
      return nodeType; 
    }
    
    public Boolean getcurrentNode() { 
      return currentNode; 
    }


    /**
    * @Change this to your sObject
    */
    public String getObjectName() { 
      return (String)thisObject.get('Name'); 
    }
    
    public void setnodeId( String n ) { 
      this.nodeId = n; 
    }
      
    public void setlevelFlag( Boolean l ) { 
      this.levelFlag.add(l); 
    }
      
    public void setlcloseFlag( Boolean l ) { 
      this.closeFlag.add(l); 
    }
      
    public void setnodeType( String nt ) { 
      this.nodeType = nt; 
    }
      
    public void setcurrentNode( Boolean cn ) { 
      this.currentNode = cn; 
    }

    /**
    * @Change this to your sObject
    */
    public void setSobject( Sobject a ) { 
      this.thisObject = a;
    }
    /**
    * Added on june 13, 2013
    * generalize method for appending additional field values to node
    */
   /*public String getNodeLabel( ) { 
      String nodeLabel='';
      //nodeLabel = (String)thisObject.get('Name');
      if(nodeFields !=null){
          for(String fld: nodeFields )
          {
             fld = fld.trim();
             if(thisObject.get(fld)!=null)
                 nodeLabel += ' - '+(String)thisObject.get(fld);
          }
      }
      return nodeLabel;
    }*/
    
    /**
    * Added on june 14, 2013
    * customized method for appending specific Account field values to node.
    * This is customized method. For generic method un-comment method above.
    */
    public String getNodeLabel( ) { 
      String nodeLabel;
      //nodeLabel = (String)thisObject.get('Name');
      if(nodeFields !=null){
          nodeLabel = ' - '+(String)thisObject.get('BillingCity')+', '+(String)thisObject.get('BillingState')+', '+(String)thisObject.get('BillingPostalCode')+', '+(String)thisObject.get('BillingCountry');
          nodeLabel += ' - Account # '+(String)thisObject.get('Account_Number__c')+ ' ('+(String)thisObject.get('Status__c')+')';
      }
      return nodeLabel;
    }
  }
}