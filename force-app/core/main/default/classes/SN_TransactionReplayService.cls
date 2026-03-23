public with sharing class SN_TransactionReplayService {
    public class ReplayResult { public Id transactionId; public String status; public Boolean submitted; }
    public static Boolean isReplayEligible(Integration_Transaction__c transactionRecord) {
        return transactionRecord != null && transactionRecord.Replay_Eligible__c == true && (transactionRecord.Status__c == 'Failed' || transactionRecord.Status__c == 'Abandoned' || transactionRecord.Status__c == 'Retrying');
    }
    public static ReplayResult replay(Id transactionId) {
        Integration_Transaction__c transactionRecord = [SELECT Id, Status__c, Replay_Eligible__c FROM Integration_Transaction__c WHERE Id = :transactionId LIMIT 1];
        if (!isReplayEligible(transactionRecord)) {
            throw new SN_ExceptionTaxonomy.UnsupportedBusinessException('REPLAY_NOT_ALLOWED', 'Replay is not allowed for transaction ' + transactionId + '.');
        }
        SN_IntegrationOrchestrator.OrchestrationResult result = SN_IntegrationOrchestrator.retryExistingTransaction(transactionId);
        ReplayResult replayResult = new ReplayResult(); replayResult.transactionId = result.transactionId; replayResult.status = result.status; replayResult.submitted = true; return replayResult;
    }
}
