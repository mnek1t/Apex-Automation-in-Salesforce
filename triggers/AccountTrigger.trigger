trigger AccountTrigger on Account (after insert) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            AccountTriggerHandler.afterInsert(Trigger.new);   
        }
    }
}