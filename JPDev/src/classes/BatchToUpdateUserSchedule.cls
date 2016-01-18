global class BatchToUpdateUserSchedule implements Schedulable {
    /*
     * execute the schedule batch
     */
     global void execute(SchedulableContext sc) {
         BatchToUpdateUser tb = new BatchToUpdateUser();
         Database.executeBatch(tb);
     }

}