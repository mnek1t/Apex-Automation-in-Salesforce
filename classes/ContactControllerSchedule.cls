public with sharing class ContactControllerSchedule implements Schedulable {
    public static final String CRON_EXP  = ' 0 0 3 * * ?';
    
    public static void execute(SchedulableContext context) {
        ContactUpcomingBirthdayBatch batch = new ContactUpcomingBirthdayBatch();
        Database.executeBatch(batch, 100);
    }
}