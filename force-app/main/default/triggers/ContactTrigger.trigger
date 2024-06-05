trigger ContactTrigger on Contact (before insert, after insert, after update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            ContactTriggerHandler.beforeInsert(Trigger.new);
        }
        when AFTER_INSERT {
            ContactTriggerHandler.afterInsert(Trigger.new);
        }
        when AFTER_UPDATE{
            ContactTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}