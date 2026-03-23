public with sharing class SN_IncidentPayloadBuilder {
    public static SN_FieldMappingService.IncidentPayload buildIncidentPayload(
        String orgKey,
        String requestTypeKey,
        Case caseRecord,
        Map<String, Object> relatedData
    ) {
        return SN_FieldMappingService.buildIncidentPayload(orgKey, requestTypeKey, caseRecord, relatedData);
    }
}
