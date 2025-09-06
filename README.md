# sf-dynamic-trigger-mapping

Introduction:

The DynamicFieldMappingService class provides a dynamic, one-time deployment solution to keep Salesforce objects in sync. Instead of hardcoding field updates inside triggers or Apex classes, it uses a metadata-driven configuration model. This means administrators can define and manage source–target object relationships, lookup fields, and field mappings directly through configuration, without making additional code changes.

By leveraging this service:
  * You only deploy once — no need to modify or redeploy Apex for new mappings.
  * Administrators can add, remove, or update field mappings simply by updating configuration records.
  * The framework works across all triggers, making it reusable, scalable, and easy to maintain.

How It Works
1) Configuration Layer
   * Mapping Object (Mapping_Object__c)
   * Defines the Source Object Name (e.g., Quote)
   * Defines the Target Object Name (e.g., Opportunity or Contact)
   * Defines the Target Lookup API Name (e.g., OpportunityId, ContactId)
   * Active flag to control whether mapping is enabled
2) Trigger Field Mapping (Trigger_Field_Mapping__c)
   * Child records under Mapping Object
   * Stores Source Field API Name and Target Field API Name
   * Can be extended for multiple mappings across different objects


Runtime Execution
1) When a trigger fires (e.g., after update on Quote),
  * The service loads mappings based on the Source Object Name.
  * It checks Target Lookup API on the source record to identify the related target record.
  * It compares Source Field vs. Target Field values.
  * If differences are found → target record is updated dynamically.



How the flow works?
flowchart TD
    A[Trigger fires on Source Object] --> B[Load Mapping_Object__c]
    B --> C[Fetch active Trigger_Field_Mapping__c records]
    C --> D[Identify Target Lookup Field]
    D --> E[Find Target Object via Lookup]
    E --> F[Compare Source vs Target fields]
    F --> G{Values Different?}
    G -- Yes --> H[Prepare Target Record Update]
    G -- No --> I[Skip Update]
    H --> J[Bulk Update Target Records]


Example Use Case

🔹 Scenario: Keep Quote fields in sync with Opportunity and Contact
 
Mapping_Object__c:
 * Source Object: Quote
 * Target Object: Opportunity
 * Target Lookup Field: OpportunityId
Trigger_Field_Mapping__c Records:
 * Source Field: Quote.Stage__c → Target Field: Opportunity.StageName
 * Source Field: Quote.Amount__c → Target Field: Opportunity.Amount
When a Quote record is updated:
 * The service checks its related Opportunity via OpportunityId.
 * If Quote.Amount__c changes, it auto-updates the Opportunity.Amount.
 * The same logic applies for Contact mappings if defined.




Object Model:

 ┌────────────────────┐
 │  Trigger Map Object│
 │────────────────────│
 │ • Trigger Field Map│───┐
 │ • Object           │   │
 └────────────────────┘   │
                          ▼
               ┌───────────────────┐
               │   Mapping Object  │
               │───────────────────│
               │ • Self Lookup     │
               │ • SourceFieldAPI  │
               │ • TargetFieldAPI  │
               └───────────────────┘
                          │
                          ▼
          ┌────────────────────────────────┐
          │         Field Details           │
          │────────────────────────────────│
          │ • Source Object Name            │
          │ • Target Object Name            │
          │ • Target Lookup API Name        │
          └────────────────────────────────┘




