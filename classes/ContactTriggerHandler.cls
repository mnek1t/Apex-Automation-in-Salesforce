public with sharing class ContactTriggerHandler {
    public static void beforeInsert(List<Contact> newContacts) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, List<Contact>> accountToContactsMap = new Map<Id, List<Contact>>();
        for (Contact newCon : newContacts) {
            if(newCon.AccountId == null || newCon.Birthdate == null) {
                continue;
            }
            if(!accountToContactsMap.containsKey(newCon.AccountId)) {
                accountToContactsMap.put(newCon.AccountId, new List<Contact>());
            }
            accountToContactsMap.get(newCon.AccountId).add(newCon);
        }

        List<Account> accounts = [SELECT Id, BillingCountry FROM Account WHERE Id IN :accountToContactsMap.keySet()];
        for (Account acc : accounts) {
            Integer legalAge = (acc.BillingCountry == 'US' || acc.BillingCountry == 'USA') ? 21 : 18;
            for (Contact con : accountToContactsMap.get(acc.Id)) {
                Integer contactAge = Date.today().year() - con.Birthdate.year();
                if (contactAge < legalAge) {
                    con.addError('All contact persons should be of legal age.');
                }
            }
        }
    }

    public static void afterInsert(List<Contact> newContacts) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Contact> primaryContacts = new Map<Id, Contact>();
        for (Contact newCon : newContacts) {
            if(newCon.AccountId == null || newCon.Level__c != 'Primary') {
                continue;
            }
            if(!accountIds.contains(newCon.AccountId)) {
                accountIds.add(newCon.AccountId);
                primaryContacts.put(newCon.AccountId, newCon);
            }
        }

        List<Case> casesToUpdate = [SELECT Id, ContactId, AccountId 
                                    FROM Case 
                                    WHERE AccountId IN :accountIds AND ContactId = null];
        for (Case c : casesToUpdate) {
            c.ContactId = primaryContacts.get(c.AccountId).Id;
        }

        if(casesToUpdate.size() > 0) {
            update casesToUpdate;
        }  
    }

    public static void afterUpdate(List<Contact> newContacts, Map<Id, Contact> oldMapContacts) {
        Set<Id> newAccountIds = new Set<Id>();
        Set<Id> oldAccountIds = new Set<Id>();
        Set<Id> contactIdsWithChangedAccount = new Set<Id>();
        Map<Id, Contact> contactsNewAccount = new Map<Id, Contact>();

        for (Contact newContact : newContacts) {
            Contact oldContact = oldMapContacts.get(newContact.Id);
            if(newContact.AccountId == oldContact.AccountId) {
                continue;
            }

            newAccountIds.add(newContact.AccountId);
            contactIdsWithChangedAccount.add(newContact.Id);
            contactsNewAccount.put(newContact.AccountId, newContact);
            oldAccountIds.add(oldContact.AccountId);
        }

        List<Case> contactCases = [SELECT Id, ContactId, AccountId 
                                    FROM Case 
                                    WHERE AccountId IN :oldAccountIds AND ContactId IN :contactIdsWithChangedAccount];
        for (Case c : contactCases) {
            c.ContactId = null;
        }
        update contactCases;
    
        List<Case> casesToUpdate = [SELECT Id, ContactId, AccountId 
                                    FROM Case 
                                    WHERE AccountId IN :newAccountIds AND ContactId = null];
        for (Case c : casesToUpdate) {
            c.ContactId = contactsNewAccount.get(c.AccountId).Id;
        }
        if(casesToUpdate.size() > 0) {
            update casesToUpdate;
        }  
    }
}
