public class ContactTriggerHandler {

    // example of a trigger handler class that enqueues a queueable class to process the contact registration
    // In a real world scenario, you would most likely have a more complex trigger handler class that handles the different trigger contexts
    // before and after insert, before and after update, before and after delete, etc.
    // This is just a simple example to demonstrate the concept.
    
    public static void handleAfterInsert(List<Contact> newContacts) {
        // Process contact registration for all inserted contacts
        processContactRegistration(newContacts);
    }
    
    private static void processContactRegistration(List<Contact> contacts) {
        // Enqueue callout for contact registration
        System.enqueueJob(new ContactRegistrationQueueable(contacts));
    }
}