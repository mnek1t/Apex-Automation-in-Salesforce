public with sharing class ContactTriggerHandler { 
    private static final Integer LEGAL_US_AGE = 21;
    private static final Integer LEGAL_EUROPE_AGE = 18;
    public static void beforeInsert(List<Contact> newContacts) {
        Map<Id, List<Contact>> accountToContactsMap = populateAccountToContactsMap(newContacts, null);

        verifyContactAge(accountToContactsMap);
    }
    public static void beforeUpdate(List<Contact> newContacts, Map<Id, Contact> oldMapContacts) {
        Map<Id, List<Contact>> accountToContactsMap = populateAccountToContactsMap(newContacts, oldMapContacts);
        verifyContactAge(accountToContactsMap);
    }

    public static void afterInsert(List<Contact> newContacts) {
        Map<Id, Contact> primaryContacts = getPrimaryContacts(newContacts);
        populateCaseContactId(primaryContacts.keySet(), primaryContacts);
    }

    public static void afterUpdate(List<Contact> newContacts, Map<Id, Contact> oldMapContacts) {
        Map<Id, Contact> contactsNewAccount = getContactsNewAccount(newContacts, oldMapContacts);
        unpopulateCaseContactId(contactsNewAccount.values());
        populateCaseContactId(contactsNewAccount.keySet(), contactsNewAccount);
    }

    private static Map<Id, List<Contact>> populateAccountToContactsMap(List<Contact> contacts, Map<Id, Contact> oldMapContacts) {
            Map<Id, List<Contact>> accountToContactsMap = new Map<Id, List<Contact>>();
            for (Contact newCon : contacts) {
                if(newCon.AccountId == null || newCon.Birthdate == null || 
                    (oldMapContacts != null && (oldMapContacts.get(newCon.Id) == null || 
                    newCon.Birthdate == oldMapContacts.get(newCon.Id).Birthdate))) {
                        continue;
                }
                if(!accountToContactsMap.containsKey(newCon.AccountId)) {
                    accountToContactsMap.put(newCon.AccountId, new List<Contact>());
                }
                accountToContactsMap.get(newCon.AccountId).add(newCon);
            }
            return accountToContactsMap;
        }
    private static void verifyContactAge(Map<Id, List<Contact>> accountToContactsMap) {
        List<Account> accounts = [SELECT Id, BillingCountry FROM Account WHERE Id IN :accountToContactsMap.keySet()];
        for (Account acc : accounts) {
            Integer legalAge = (acc.BillingCountry == 'US' || acc.BillingCountry == 'USA') ? LEGAL_US_AGE : LEGAL_EUROPE_AGE;
            for (Contact con : accountToContactsMap.get(acc.Id)) {
                Integer contactAge = Date.today().year() - con.Birthdate.year();
                if (contactAge < legalAge) {
                    con.addError('All contact persons should be of legal age.');
                }
            }
        }
    }

    private static Map<Id, Contact> getPrimaryContacts(List<Contact> contacts) {
        Map<Id, Contact> primaryContacts = new Map<Id, Contact>();
        for (Contact newCon : contacts) {
            if(newCon.AccountId == null || newCon.Level__c != 'Primary') {
                continue;
            }
            if(!primaryContacts.containsKey(newCon.AccountId)) {
                primaryContacts.put(newCon.AccountId, newCon);
            }
        }
        return primaryContacts;
    }

    private static Map<Id, Contact> getContactsNewAccount(List<Contact> newContacts, Map<Id, Contact> oldMapContacts) {
        Map<Id, Contact> contactsNewAccount = new Map<Id, Contact>();
        for (Contact newContact : newContacts) {
            Contact oldContact = oldMapContacts.get(newContact.Id);
            if(newContact.AccountId == oldContact.AccountId) {
                continue;
            }
            contactsNewAccount.put(newContact.AccountId, newContact);
        }
        return contactsNewAccount;
    }

    private static void populateCaseContactId(Set<Id> newAccountIds, Map<Id, Contact> contactsNewAccount) {
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

    private static void unpopulateCaseContactId(List<Contact> contacts) {
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : contacts) {
            contactIds.add(c.Id);
        }
        List<Case> contactCases = [SELECT Id, ContactId, AccountId 
                                    FROM Case 
                                    WHERE ContactId IN :contactIds];
        for (Case c : contactCases) {
            c.ContactId = null;
        }
        update contactCases;
    }
}