public with sharing class DynamicFieldMappingService {
    private static Set<String> targetFieldSet = new Set<String>();

    public static void updateTheTargetObj(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        if (newMap.isEmpty()) return;

        try {
            // Pick first record to detect source object type
            Id firstId = newMap.keySet().iterator().next();
            Map<String, Map<String, String>> targetFieldMap = applyFieldMappings(firstId);
            if (targetFieldMap.isEmpty()) return;

            List<SObject> recordsToUpdate = new List<SObject>();

            for (Id recordId : newMap.keySet()) {
                SObject newRecord = newMap.get(recordId);
                SObject oldRecord = oldMap != null ? oldMap.get(recordId) : null;

                for (String lookupField : targetFieldMap.keySet()) {
                    Id targetId = (Id)newRecord.get(lookupField);
                    if (targetId == null) continue;

                    String targetObjectName = getObjectNameBasedId(targetId);
                    if (String.isBlank(targetObjectName)) continue;

                    SObject targetRecord = (SObject)Type.forName('Schema.' + targetObjectName).newInstance();
                    targetRecord.put('Id', targetId);

                    // Apply field mappings
                    for (String sourceField : targetFieldMap.get(lookupField).keySet()) {
                        Object newVal = newRecord.get(sourceField);
                        Object oldVal = oldRecord != null ? oldRecord.get(sourceField) : null;

                        if (newVal != oldVal) {
                            targetRecord.put(targetFieldMap.get(lookupField).get(sourceField), newVal);
                        }
                    }
                    recordsToUpdate.add(targetRecord);
                }
            }
            
            system.debug('recordToUpdate'+recordsToUpdate);

            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }

        } catch (Exception e) {
            // Log the error using LoggerUtility
            LoggerUtility.logError(
                'DynamicFieldMappingService.updateTheTargetObj failed: ' + e.getMessage(),
                'DynamicFieldMappingService'
            );
        }
    }

    private static Map<String, Map<String, String>> applyFieldMappings(Id sourceRecordId) {
        if (sourceRecordId == null) return new Map<String, Map<String,String>>();

        try {
            String sourceObject = getObjectNameBasedId(sourceRecordId);
            return getSourceToTargetFieldMap(sourceObject);
        } catch (Exception e) {
            LoggerUtility.logError(
                'DynamicFieldMappingService.applyFieldMappings failed: ' + e.getMessage(),
                'DynamicFieldMappingService'
            );
            return new Map<String, Map<String,String>>();
        }
    }

    private static String getObjectNameBasedId(Id recordId) {
        if (recordId == null) return null;
        return recordId.getSObjectType().getDescribe().getName();
    }

    // Returns field mappings grouped by target lookup field
    private static Map<String, Map<String, String>> getSourceToTargetFieldMap(String sourceObject) {
        Map<String, Map<String,String>> targetObjectFieldMap = new Map<String, Map<String,String>>();

        try {
            Map<Id, Trigger_Field_Mapping__c> fieldMap = new Map<Id, Trigger_Field_Mapping__c>(
                [
                    SELECT Id, 
                        Source_Field_Name__c, 
                        Target_Field_Name__c,
                        Mapping_Object__r.Target_Lookup_Field__c,
                        Mapping_Object__r.Target_Object_Name__c,
                        Active__c 
                    FROM Trigger_Field_Mapping__c 
                    WHERE Mapping_Object__r.Source_Object_Name__c = :sourceObject
                    AND Mapping_Object__c != null
                    AND Mapping_Object__r.Active__c = true
                    AND Active__c = true
                ]
            );

            // Final structure: { LookupFieldName => { SourceField => TargetField } }
            for (Trigger_Field_Mapping__c tfm : fieldMap.values()) {
                if (String.isNotBlank(tfm.Source_Field_Name__c) && 
                    String.isNotBlank(tfm.Mapping_Object__r.Target_Lookup_Field__c)) {
                    
                    String lookupField = tfm.Mapping_Object__r.Target_Lookup_Field__c;
                    targetFieldSet.add(lookupField);

                    if (!targetObjectFieldMap.containsKey(lookupField)) {
                        targetObjectFieldMap.put(lookupField, new Map<String,String>());
                    }

                    targetObjectFieldMap.get(lookupField).put(
                        tfm.Source_Field_Name__c, 
                        tfm.Target_Field_Name__c
                    );
                }
            }

        } catch (Exception e) {
            LoggerUtility.logError(
                'DynamicFieldMappingService.getSourceToTargetFieldMap failed: ' + e.getMessage(),
                'DynamicFieldMappingService'
            );
        }

        return targetObjectFieldMap;
    }
}