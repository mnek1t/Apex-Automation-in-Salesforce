public with sharing class AccountTriggerHandler {
    public static void afterInsert(List<Account> newAccounts) {
        List<Case> cases = new List<Case>();
        for (Account newAcc : newAccounts) {
            Case newCase = new Case(
                AccountId = newAcc.Id, 	
                Origin = 'System', 
                Priority = newAcc.CustomerPriority__c, 
                Subject = newAcc.Name + ' - Onboarding',
                OwnerId = newAcc.OwnerId);
            cases.add(newCase);
        }
        insert cases;
    }
}