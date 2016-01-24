public class NewCaseListController {

    public list<Case> getNewCases(){
        
        list<Case> caseresult = [select id,CaseNumber from Case where status='New'];
        return caseresult;
    }
}