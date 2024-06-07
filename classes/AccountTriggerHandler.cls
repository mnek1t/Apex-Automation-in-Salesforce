public with sharing class AccountTriggerHandler {
    public static void afterInsert(List<Account> newAccounts) {
        List<Case> cases = new List<Case>();
        for (Account newAcc : newAccounts) {
            cases.add(createOnboradingCase(newAcc));
        }
        insert cases;
    }

    private static Case createOnboradingCase(Account newAcc) {
        return new Case(
            AccountId = newAcc.Id, 	
            Origin = 'System', 
            Priority = newAcc.CustomerPriority__c, 
            Subject = newAcc.Name + ' - Onboarding',
            OwnerId = newAcc.OwnerId
        );
    }
}