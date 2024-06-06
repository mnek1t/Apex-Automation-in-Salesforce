@isTest
public with sharing class ContactTriggerHandlerTest {
    @TestSetup
    private static void makeData(){
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Test LV Account', BillingCountry = 'Latvia'));
        testAccounts.add(new Account(Name = 'Test US Account', BillingCountry = 'USA'));
        insert testAccounts;

        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(
            LastName = 'Test Contact 1', 
            Birthdate = Date.newInstance(2004, 10, 28), 
            AccountId = testAccounts[0].Id
        ));
        testContacts.add(new Contact(
            LastName = 'Test Contact 2', 
            Birthdate = Date.newInstance(2000, 10, 28), 
            AccountId = testAccounts[1].Id
        ));
        testContacts.add(new Contact(
            LastName = 'Test Contact 3', 
            Birthdate = Date.newInstance(2000, 10, 28) 
        ));
        insert testContacts;
    }
    @isTest
    public static void beforeInsertTest() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test US Account'];
        Contact prohibitedContact = new Contact(
            LastName = 'Test Contact 4', 
            Birthdate = Date.newInstance(2004, 10, 28), 
            AccountId = testAccount.Id
        );
        Database.SaveResult resultUS = Database.insert(prohibitedContact, false);
        for (Database.Error error : resultUS.getErrors()) {
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, error.getStatusCode());
        }

        List<Contact> receivedContacts = [SELECT Id FROM Contact];
        System.assertEquals(3, receivedContacts.size());

        testAccount = [SELECT Id FROM Account WHERE Name = 'Test LV Account'];
        prohibitedContact.AccountId = testAccount.Id;
        Database.SaveResult resultLV = Database.insert(prohibitedContact, false);
        receivedContacts = [SELECT Id FROM Contact];
        System.assertEquals(4, receivedContacts.size());
    }

    @isTest
    public static void beforeInsertBulkTest() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test US Account'];
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            testContacts.add(new Contact(
                LastName = 'Test Contact' + i, 
                Birthdate = Date.newInstance(2004, 10, 28), 
                AccountId = testAccount.Id
            ));
        }
        List<Database.SaveResult> resultUS = Database.insert(testContacts, false);
        for (Database.SaveResult sr : resultUS) {
            if (!sr.isSuccess()) {
                for (Database.Error error : sr.getErrors()) {
                    System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, error.getStatusCode());
                }
            }
        }

        List<Contact> receivedContacts = [SELECT Id FROM Contact];
        System.assertEquals(3, receivedContacts.size());

        testAccount = [SELECT Id FROM Account WHERE Name = 'Test LV Account'];
        for (Contact testContact : testContacts ) {
            testContact.AccountId = testAccount.Id;
        }

        Database.insert(testContacts, false);
        receivedContacts = [SELECT Id FROM Contact];
        System.assertEquals(203, receivedContacts.size(), 'Proper accounts should be inserted for LV Account');
    }

    @isTest 
    public static void afterInsertTest() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test LV Account'];
        Contact primaryContact = new Contact(
            LastName = 'Test Contact 5', 
            Birthdate = Date.newInstance(2004, 10, 28), 
            AccountId = testAccount.Id,
            Level__c = 'Primary'
        );
        insert primaryContact;
        
        List<Case> testCases = [SELECT Id, ContactId FROM Case WHERE AccountId = :testAccount.Id];
        for (Case c : testCases) {
            System.assertEquals(primaryContact.Id, c.ContactId, 'Contact Id should have been populated!');
        }
    }
    @isTest 
    public static void afterInsertBulkTest() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test LV Account'];
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 1000; i++) {
            testCases.add(new Case(
                Subject = 'Test Case' + i,
                AccountId = testAccount.Id
            ));
        }
        insert testCases;

        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 1000; i++) {
            testContacts.add(new Contact(
                LastName = 'Test Contact' + i, 
                Birthdate = Date.newInstance(2004, 10, 28), 
                AccountId = testAccount.Id,
                Level__c = 'Secondary'
            ));
        }

        Contact primaryContact1 = new Contact(
            LastName = 'Test Contact1001', 
            Birthdate = Date.newInstance(2004, 10, 28), 
            AccountId = testAccount.Id,
            Level__c = 'Primary'
        );
        Contact primaryContact2 = new Contact(
            LastName = 'Test Contact1002', 
            Birthdate = Date.newInstance(2004, 10, 28), 
            AccountId = testAccount.Id,
            Level__c = 'Primary'
        );
        testContacts.add(primaryContact1);
        testContacts.add(primaryContact2);
        insert testContacts;

        List<Case> receivedTestCases = [SELECT Id, ContactId FROM Case WHERE AccountId = :testAccount.Id];
        System.assertEquals(1001, receivedTestCases.size(), 'Cases are not inserted!');
        for (Case c : receivedTestCases) {
            System.assertEquals(primaryContact1.Id, c.ContactId, 'Primary Contact Id should have been populated for Case!');
        }
    }

    @isTest 
    public static void afterUpdateTest() {
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Contact> testContact = new List<Contact>();
        String usAccountId;
        for (Account testAccount : testAccounts) {
            if(testAccount.Name == 'Test LV Account'){
                testContact.add(new Contact(
                    LastName = 'Test Contact 5', 
                    Birthdate = Date.newInstance(2004, 10, 28), 
                    AccountId = testAccount.Id,
                    Level__c = 'Primary'
                ));
            } else {
                usAccountId = testAccount.Id;
            }
        }
        insert testContact;

        Contact contactToUpdate = testContact[0];
        List<Case> testCases = [SELECT Id, ContactId, AccountId, Account.Name FROM Case];
        for(Case c: testCases) {
            if(c.Account.Name == 'Test LV Account') {
                System.assertEquals(contactToUpdate.Id, c.ContactId, 'Contact Id should have been populated!');
            }
        }
        
        contactToUpdate.AccountId = usAccountId;
        update contactToUpdate;
        testCases = [SELECT Id, ContactId, Account.Name FROM Case];
        for(Case c: testCases) {
            if(c.Account.Name == 'Test LV Account') {
                System.assertEquals(null, c.ContactId, 'Contact Id should be nulled!');
            }
            if(c.Account.Name == 'Test US Account') {
                System.assertEquals(contactToUpdate.Id, c.ContactId, 'Contact Id should populated for US Account!');
            }
        }
    }
    
    @isTest 
    public static void afterUpdateBulkTest() {
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        List<Case> testCases = new List<Case>();
        List<Contact> testContacts = new List<Contact>();
        String usAccountId;
        for (Account testAccount : testAccounts) {
            if(testAccount.Name == 'Test LV Account') {
                for (Integer i = 0; i < 500; i++) {
                    testCases.add(new Case(
                        Subject = 'Test Case LV' + i,
                        AccountId = testAccount.Id
                    ));
                    testContacts.add(new Contact(
                        LastName = 'Test Contact' + i, 
                        Birthdate = Date.newInstance(2004, 10, 28), 
                        AccountId = testAccount.Id,
                        Level__c = 'Primary'
                    ));
                }
            }
            else {
                usAccountId = testAccount.Id;
                for (Integer i = 0; i < 500; i++) {
                    testCases.add(new Case(
                        Subject = 'Test Case US' + i,
                        AccountId = testAccount.Id
                    ));
                }
            }
        }
        insert testCases;
        insert testContacts;

        List<Case> receivedTestCases = [SELECT Id, ContactId, Account.Name FROM Case];
        for(Case c: receivedTestCases) {
            if(c.Account.Name == 'Test LV Account') {
                System.assertEquals(testContacts[0].Id, c.ContactId, 'Contact Id should have been populated!');
            }
        }
        for(Contact updCon: testContacts) {
            updCon.AccountId = usAccountId;
        }

        update testContacts;

        receivedTestCases = [SELECT Id, ContactId, Account.Name FROM Case];
        for(Case c: testCases) {
            if(c.Account.Name == 'Test LV Account') {
                System.assertEquals(null, c.ContactId, 'Contact Id should be nulled!');
            } else if(c.Account.Name == 'Test US Account') {
                System.assertEquals(testContacts[0].Id, c.ContactId, 'Contact Id should populated for US Account!');
            }
        }
    }
}