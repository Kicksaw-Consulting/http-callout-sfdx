trigger ContactTrigger on Contact (before insert,after insert,before update,after update) {
    // example of a trigger that calls a trigger handler class that enqueues a queueable class to process the contact registration
    // In a real world scenario, you would likely have a more complex trigger that handles the different trigger contexts
    // before and after insert, before and after update, before and after delete, etc.
    
    
    
    if (Trigger.isAfter && Trigger.isInsert) {
        // Calling a static method of the trigger handler class to enqueue the queueable class
        // You could also instantiate the trigger handler class and call the method directly, depending on your needs
        ContactTriggerHandler.handleAfterInsert(Trigger.new);
    }
}