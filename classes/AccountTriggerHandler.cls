public with sharing class AccountTriggerHandler {
    public static void afterInsert(List<Account> newAccounts) {
        createOnboradingCases(newAccounts);
    }

    private static List<Case> createOnboradingCases(List<Account> newAccounts) {
        List<Case> cases = new List<Case>();
        for (Account newAcc : newAccounts) {
            cases.add(new Case(
                    AccountId = newAcc.Id, 	
                    Origin = 'System', 
                    Priority = newAcc.CustomerPriority__c, 
                    Subject = newAcc.Name + ' - Onboarding',
                    OwnerId = newAcc.OwnerId
                )
            );
        }
        insert cases;
        return cases;
    }
}