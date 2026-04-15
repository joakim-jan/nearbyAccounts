/**
 * @description Controller for nearbyAccountsMap Lightning Web Component
 * Provides proximity search functionality for accounts based on geolocation
 * @author Joakim JAN
 * @date 2026-04-15
 */
public with sharing class NearbyAccountsController {
    
    /**
     * @description Finds accounts within a specified radius of a center account
     * @param centerAccountId The ID of the account to use as the search center
     * @param radiusKm The search radius in kilometers
     * @param maxResults The maximum number of results to return (capped at 99)
     * @return NearbyAccountsMapDto.SearchResponse The search results including center and nearby accounts
     * @throws AuraHandledException if inputs are invalid or account is not geocoded
     */
    @AuraEnabled(cacheable=true)
    public static NearbyAccountsMapDto.SearchResponse findNearbyAccounts(
        Id centerAccountId,
        Decimal radiusKm,
        Integer maxResults
    ) {
        NearbyAccountsMapUtil.validateInputs(centerAccountId, radiusKm);

        Integer safeLimit = NearbyAccountsMapUtil.resolveSafeLimit(maxResults);
        Account center = NearbyAccountsMapUtil.getCenterAccount(centerAccountId);

        List<Account> nearbyAccounts = NearbyAccountsMapUtil.getNearbyAccounts(
            center,
            radiusKm,
            safeLimit
        );

        return NearbyAccountsMapUtil.buildSearchResponse(center, nearbyAccounts);
    }
}