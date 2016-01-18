public with sharing class TriggerProcessControl {
  public static boolean inRecursiveCall = false;
  public static boolean ignoreBeforeAfterUpdateCall = false;

  static testMethod void testProcessControl() {
    System.assertEquals(false,TriggerProcessControl.inRecursiveCall); 
    System.assertEquals(false,TriggerProcessControl.ignoreBeforeAfterUpdateCall);
  }
}