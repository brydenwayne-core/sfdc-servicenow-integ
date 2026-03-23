public with sharing class SN_MetadataConfigService {
    /** Legacy configuration facade retained while callers migrate to SN_ConfigService. */
    public static SN_Org_Config__mdt getOrgConfig(String orgKey) {
        return SN_ConfigService.getOrgConfig(orgKey);
    }

    public static SN_ConfigService.ConfigBundle getConfigBundle(String orgKey, String requestTypeKey) {
        return SN_ConfigService.getBundle(orgKey, requestTypeKey);
    }
}
