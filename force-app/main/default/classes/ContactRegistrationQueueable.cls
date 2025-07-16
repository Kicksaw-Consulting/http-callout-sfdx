public class ContactRegistrationQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Contact> contactsToProcess;
    
    public ContactRegistrationQueueable(List<Contact> contacts) {
        this.contactsToProcess = contacts;
    }
    
    public void execute(QueueableContext context) {
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Contact con : contactsToProcess) {
            // Create a new logger for each contact, the string is the name of the integration parent integration record
            // each integration execution record is associated with a parent integration record, in this case the contact registration integration record
            // If an integration record already exists with the same name, execution records will be related to that record, if not it will create a new one
            KicksawEng.KicksawLogger logger = new KicksawEng.KicksawLogger('Contact Registration Callout');
            try {
                // Make the callout
                HttpResponse response = makeRegistrationCallout(con, logger);
                
                if (response.getStatusCode() == 200) {
                    // optionally log the success response
                    logger.log('Success: ' + response.getStatusCode() + ' - ' + response.getBody());
                    
                    // Success - parse response and create a contact variable with the external id
                    Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    String externalId = String.valueOf(responseData.get('id'));
                    
                    Contact updateContact = new Contact(
                        Id = con.Id,
                        External_id__c = externalId
                    );
                    contactsToUpdate.add(updateContact);
                    
                    // Only mark as complete if the callout was successful
                    logger.completeExecution();
                    
                } else {
                    // Failure - log the error
                    logger.log('Failure: ' + response.getStatusCode() + ' - ' + response.getBody());
                }
                
            } catch (Exception e) {
                // Exception occurred - log it
                logger.log('Exception: ' + e.getMessage());
            }
            // Always save the logs at the end of processing the callout, regardless of success or failure. This creates the integration execution record.
            logger.saveLogs();
            
        }
        
        // Update contacts with external IDs
        if (!contactsToUpdate.isEmpty()) {
            try {
                update contactsToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating contacts: ' + e.getMessage());
                
            }
        }
        
    }
    
    private HttpResponse makeRegistrationCallout(Contact con, KicksawEng.KicksawLogger logger) {
        // Create a new HTTP request object
        HttpRequest req = new HttpRequest();
        // You can reference the named credential by using 'callout:NamedCredentialName/Endpoint'
        req.setEndpoint('callout:ReqRes_API/api/register');
        // Set which HTTP method to use
        req.setMethod('POST');
        // Set the content type to JSON, you can also add other headers if needed. 
        // ReqRes uses an x-api-key header to authenticate the request, 
        // Which we have already set in the named credential so we do not need to expose it in the code
        // You could also use other auth methods like Basic Auth, OAuth, bearer token, etc. 
        // Credentials are stored in the named credential or custom metadata and are not exposed in the code for security reasons.
        req.setHeader('Content-Type', 'application/json');
        
        // Create request body - will be empty email if contact has no email
        // ReqRes API expects a JSON object properties of email and password, if either is empty, the request will fail
        // for this demo, we are using the contact id as the password and the contact email as the email
        Map<String, String> requestBodyMap = new Map<String, String>{
            'email' => con.Email != null ? con.Email : '',
            'password' => con.Id  // Using Contact ID as password
        };

        String requestBody = JSON.serialize(requestBodyMap);
        req.setBody(requestBody);
        // Save the request body to the logger, useful for debugging and troubleshooting
        logger.savePayload(requestBody);
        Http http = new Http();
        return http.send(req);
    }
    
   
        
        
    
}