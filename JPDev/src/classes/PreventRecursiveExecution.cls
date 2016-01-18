public with sharing class PreventRecursiveExecution {
    public static boolean isFirstRun = true;
    public static boolean tasksNotYetCreated = true;
    public static Boolean paymentLinksProcessed = false;
    public static Boolean dummyEmailCreateInProgress = false;
    public static Boolean invoiceTemplateRecalculated = false;
    public static Boolean ultimateParentSet = false;
    
    //CCBOB 130 - lead conversion too many soql - static variable to prevent the loop
    public static Boolean accountownershiptodiceset = false;
    public static Boolean activeinactiveaccountset = false;
    
}