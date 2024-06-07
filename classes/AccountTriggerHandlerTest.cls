@isTest
public with sharing class AccountTriggerHandlerTest {
    @TestSetup
    static void makeData() {
        Account testAccount = new Account(
            Name = 'TestAccount', 
            CustomerPriority__c = 'Low', 
            OwnerId = '005Wy000000A649IAC'
        );
        insert testAccount;
    }

    @isTest
    public static void afterInsertSingleAccountTest() {
        Account testAccount = [SELECT Id, Name, CustomerPriority__c, OwnerId FROM Account];
        Case createdCase = [SELECT Id, AccountId, Priority, Subject, OwnerId, Origin 
                            FROM Case 
                            WHERE AccountId =: testAccount.Id];

        System.assertNotEquals(null, createdCase, 'Case was not created!');
        System.assertEquals('System', createdCase.Origin, 'Case Origin is not System');
        System.assertEquals(testAccount.CustomerPriority__c, createdCase.Priority, 'Priority is not the same as in Account');
        System.assertEquals(testAccount.Name + ' - Onboarding', createdCase.Subject, 'Subject is not altered with Account Name');
        System.assertEquals(testAccount.OwnerId, createdCase.OwnerId, 'Owner Id is not mapped from Account');
    }

    @isTest
    public static void afterInsertBulkAccountsTest() {
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 1000; i++) {
            testAccounts.add(new Account(
                Name='Test Account ' + i, 
                CustomerPriority__c = 'High', 
                OwnerId='005Wy000000A649IAC'
            ));
        }

        insert testAccounts;

        List<Case> createdCases = [SELECT Id, AccountId, Priority, Subject, OwnerId ,Origin FROM Case];
        Account lowPriorityAcc = [SELECT Id, CustomerPriority__c, OwnerId FROM Account WHERE CustomerPriority__c = 'Low'];

        System.assertNotEquals(null, createdCases, 'Cases were not created!');
        System.assertEquals(1001, createdCases.size());
        for (Case createdCase : createdCases) {
            System.assertEquals('System', createdCase.Origin, 'Case Origin is not System');
            System.assertEquals('005Wy000000A649IAC', createdCase.OwnerId, 'Owner Id is not mapped from Account');
            if(createdCase.Priority == 'Low') {
                System.assertEquals(lowPriorityAcc.CustomerPriority__c , createdCase.Priority, 'Priority is not the same as in Account');
            } else {
                System.assertEquals('High', createdCase.Priority, 'Priority is not the same as in Account');
            }
        }
    }
}