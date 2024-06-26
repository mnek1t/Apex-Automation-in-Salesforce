public with sharing class ContactUpcomingBirthdayBatch implements Database.Batchable<SObject> {
    private static final Date today = Date.today();
    public static Database.QueryLocator start(Database.BatchableContext context) {
        String query = 'SELECT Id, Name, Birthdate, AccountId, Account.Name, Account.Industry, OwnerId, MailingAddress FROM Contact';
        return Database.getQueryLocator(query);
    }

    public static void execute(Database.BatchableContext context, List<Contact> scope) {
        List<Task> tasks = new List<Task>();
        Date upcomingTwoDays = today.addDays(2);
        for (Contact c : scope) {
            if(c.Birthdate == null) {
                continue;
            }

            Date nextBirthday = Date.newInstance(today.year(), c.Birthdate.month(), c.Birthdate.day());
            if (nextBirthday < today) {
                nextBirthday = Date.newInstance(today.year() + 1, c.Birthdate.month(), c.Birthdate.day());
            }

            Integer daysUntilBirthday = today.daysBetween(nextBirthday);
            if (daysUntilBirthday > 2) {
                continue;
            }
            
            tasks.add(createBirthdayTask(c));
        }

        if(tasks != null && tasks.size() > 0) {
            insert tasks;
        }
    }

    public static void finish(Database.BatchableContext context) {

    }

    private static Task createBirthdayTask(Contact c) {
        Task t = new Task(
            OwnerId = c.OwnerId,
            Subject = c.Name + ' Birthday!',
            WhatId = c.AccountId,
            WhoId = c.Id,
            Priority = 'Low',
            ActivityDate = c.Birthdate
        );
        Boolean hasAddrress = String.isNotBlank(String.valueOf(c.MailingAddress));
        if (hasAddrress) {
            t.Description = 'The Mailing Address of the Contact is: ' 
                            + (c.MailingAddress.getStreet() != null ? c.MailingAddress.getStreet() : '') + ', '
                            + (c.MailingAddress.getCity() != null ? c.MailingAddress.getCity() : '') + ' '
                            + (c.MailingAddress.getPostalCode() != null ? c.MailingAddress.getPostalCode() : '') + ', ' 
                            + (c.MailingAddress.getState() != null ? c.MailingAddress.getState() : '') + ' ' 
                            + (c.MailingAddress.getStateCode() != null ? c.MailingAddress.getStateCode() : '') + ', '
                            + (c.MailingAddress.getCountry() != null ? c.MailingAddress.getCountry() : '') + '. ';
        } else {
            t.Description = 'The mailing address is unknown. ';
        }

        Integer contactAge = today.year() - c.Birthdate.year();
        t.Description = t.Description + 'This Contact is an employee of ' + c.Account.Name
            + ', part of the ' + c.Account.Industry + ' Industry. '
            + 'Consider making an appropriate gift. Today is the Birthdate of ' + c.Name + '. '
            + 'He/She is now ' + contactAge + ' years old.';
        return t;
    }
}