@isTest
public with sharing class ContactUpcomingBirthdayBatchTest {
    @TestSetup
    static void makeData() {
        Account testAccount = new Account(
            Name = 'TestAccount', 
            Industry = 'Energy', 
            CustomerPriority__c = 'Low', 
            OwnerId = '005Wy000000A649IAC',
            BillingCountry = 'Latvia',
            BillingCity = 'Riga',
            BillingStreet = 'Brivibas'
        );
        insert testAccount;
    }

    @isTest
    public static void testUpcomingBirthdayCreateTask() {
        Account testAccount = [SELECT Id FROM Account];
        Date today = Date.today();
        Date contactBirthdateUpcoming = Date.newInstance(today.year() - 40, today.month(), today.day() + 2);
        Date contactBirthdatePast = Date.newInstance(today.year() - 40, today.month(), today.day() - 2);

        Contact testContact1 = new Contact(
            LastName = 'Test Contact 1',
            Birthdate = contactBirthdateUpcoming,
            AccountId = testAccount.Id,
            MailingCity = 'Riga',
            MailingCountry = 'Latvia',
            MailingStreet = 'Brivibas 123'
        );
        
        Contact testContact2 = new Contact(
            LastName = 'Test Contact 2',
            Birthdate = contactBirthdateUpcoming,
            AccountId = testAccount.Id
        );

        Contact testContact3 = new Contact(
            LastName = 'Test Contact 3',
            Birthdate = contactBirthdatePast,
            AccountId = testAccount.Id
        );

        insert new List<Contact>{testContact1, testContact2, testContact3};
        Test.startTest();
        ContactControllerSchedule.execute(null);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject, Description FROM Task WHERE Subject LIKE '%Birthday!%'];
        System.assertEquals(2, tasks.size(), 'Expected two tasks to be created');

        for (Task t : tasks) {
            if (t.Subject.contains('Test Contact 1')) {
                System.assert(t.Description.contains('The Mailing Address of the Contact is:'), 'Description should include mailing address details');
            } else if (t.Subject.contains('Test Contact 2')) {
                System.assert(t.Description.contains('The mailing address is unknown.'), 'Description should state that the mailing address is unknown');
            }
        }
    }

    @isTest
    public static void testUpcomingBirthdayNotCreateTask() {
        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(
            LastName = 'Test Contact 4', 
            MailingCity = 'Riga',
            MailingCountry = 'Latvia',
            MailingStreet = 'Burtnieku'
        ));
        testContacts.add(new Contact(
            LastName = 'Test Contact 5', 
            Birthdate = Date.newInstance(2004, 4, 1)
        ));
        insert testContacts;

        Test.startTest();
        ContactControllerSchedule.execute(null);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE Subject LIKE '%Birthday!%'];
        System.assertEquals(0, tasks.size(), 'Task should not be created');
    }
}
