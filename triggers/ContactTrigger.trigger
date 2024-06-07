trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            ContactTriggerHandler.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            ContactTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            ContactTriggerHandler.afterInsert(Trigger.new);
        }
        when AFTER_UPDATE{
            ContactTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}