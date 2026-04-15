/**
 * @description Utility class for nearby accounts geospatial operations and data transformations
 * @author Joakim JAN
 * @date 2026-04-15
 */
public inherited sharing class NearbyAccountsMapUtil {
    
    /**
     * @description Maximum number of results that can be returned by proximity search
     */
    @TestVisible
    private static final Integer MAX_RESULTS_LIMIT = 99;
    
    /**
     * @description Buffer added to search radius to account for DISTANCE operator limitations
     * The DISTANCE function only supports < operator (not <=), so we add a small buffer
     * to ensure accounts at the exact radius edge are included in results
     */
    @TestVisible
    private static final Decimal RADIUS_BUFFER_KM = 0.1;
    
    /**
     * @description Validates user has read access to required Account fields
     * @throws AuraHandledException if field access is insufficient
     */
    private static void validateFieldAccessibility() {
        if (!Schema.sObjectType.Account.fields.Name.isAccessible() ||
            !Schema.sObjectType.Account.fields.BillingStreet.isAccessible() ||
            !Schema.sObjectType.Account.fields.BillingCity.isAccessible() ||
            !Schema.sObjectType.Account.fields.BillingState.isAccessible() ||
            !Schema.sObjectType.Account.fields.BillingPostalCode.isAccessible() ||
            !Schema.sObjectType.Account.fields.BillingCountry.isAccessible() ||
            !Schema.sObjectType.Account.fields.BillingLatitude.isAccessible() ||
            !Schema.sObjectType.Account.fields.BillingLongitude.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access Account billing address fields.');
        }
    }

    /**
     * @description Validates required search inputs
     * @param centerAccountId The ID of the center account
     * @param radiusKm The search radius in kilometers
     * @throws AuraHandledException if inputs are invalid
     */
    public static void validateInputs(Id centerAccountId, Decimal radiusKm) {
        if (centerAccountId == null) {
            throw new AuraHandledException('A center Account is required.');
        }
        if (radiusKm == null || radiusKm <= 0) {
            throw new AuraHandledException('Radius must be greater than 0 km.');
        }
    }

    /**
     * @description Resolves a safe result limit ensuring it doesn't exceed platform constraints
     * @param maxResults The requested maximum number of results
     * @return Integer The safe limit to use for the query (capped at MAX_RESULTS_LIMIT)
     */
    public static Integer resolveSafeLimit(Integer maxResults) {
        Integer safeLimit = MAX_RESULTS_LIMIT;
        if (maxResults != null && maxResults > 0) {
            safeLimit = Math.min(maxResults, MAX_RESULTS_LIMIT);
        }
        return safeLimit;
    }

    /**
     * @description Retrieves the center account with geocoded billing address
     * @param centerAccountId The ID of the account to retrieve
     * @return Account The center account with billing address and geolocation data
     * @throws AuraHandledException if account is not found or not geocoded
     */
    public static Account getCenterAccount(Id centerAccountId) {
        validateFieldAccessibility();
        
        Account center = [
            SELECT Id, Name,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                   BillingLatitude, BillingLongitude
            FROM Account
            WHERE Id = :centerAccountId
            LIMIT 1
        ];

        if (center.BillingLatitude == null || center.BillingLongitude == null) {
            throw new AuraHandledException(
                'The selected Account has no geocoded Billing Address. Populate Billing Latitude/Longitude first.'
            );
        }

        return center;
    }

    /**
     * @description Queries for accounts within specified radius of center account
     * @param center The center account with geolocation data
     * @param radiusKm The search radius in kilometers
     * @param safeLimit The maximum number of results to return
     * @return List<Account> Nearby accounts sorted by distance (closest first)
     */
    public static List<Account> getNearbyAccounts(
        Account center,
        Decimal radiusKm,
        Integer safeLimit
    ) {
        validateFieldAccessibility();
        
        Decimal centerLat = center.BillingLatitude;
        Decimal centerLon = center.BillingLongitude;
        
        // Adding buffer to radius because DISTANCE function only supports < operator (not <=)
        // This ensures accounts at the exact radius edge are included in results
        Decimal radiusBuffer = radiusKm + RADIUS_BUFFER_KM;
        
        return [
            SELECT Id, Name,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                   BillingLatitude, BillingLongitude
            FROM Account
            WHERE Id != :center.Id
              AND BillingLatitude != null
              AND BillingLongitude != null
              AND DISTANCE(BillingAddress, GEOLOCATION(:centerLat, :centerLon), 'km') < :radiusBuffer
            ORDER BY DISTANCE(BillingAddress, GEOLOCATION(:centerLat, :centerLon), 'km') ASC
            LIMIT :safeLimit
        ];
    }

    /**
     * @description Builds the search response DTO with calculated distances
     * @param center The center account
     * @param nearbyAccounts List of nearby accounts from query
     * @return NearbyAccountsMapDto.SearchResponse Complete search response with center and nearby accounts
     */
    public static NearbyAccountsMapDto.SearchResponse buildSearchResponse(
        Account center,
        List<Account> nearbyAccounts
    ) {
        Location origin = Location.newInstance(center.BillingLatitude, center.BillingLongitude);

        NearbyAccountsMapDto.SearchResponse response = new NearbyAccountsMapDto.SearchResponse();
        response.center = toPoint(center, null);
        response.accounts = new List<NearbyAccountsMapDto.AccountPoint>();

        for (Account acc : nearbyAccounts) {
            Location target = Location.newInstance(acc.BillingLatitude, acc.BillingLongitude);
            Double distanceKm = origin.getDistance(target, 'km');
            response.accounts.add(toPoint(acc, distanceKm));
        }

        return response;
    }

    /**
     * @description Converts an Account record to an AccountPoint DTO
     * @param acc The account to convert
     * @param distanceKm The distance from center in kilometers (null for center account)
     * @return NearbyAccountsMapDto.AccountPoint The account data as a DTO
     */
    public static NearbyAccountsMapDto.AccountPoint toPoint(Account acc, Double distanceKm) {
        NearbyAccountsMapDto.AccountPoint point = new NearbyAccountsMapDto.AccountPoint();
        point.id = acc.Id;
        point.name = acc.Name;
        point.latitude = acc.BillingLatitude;
        point.longitude = acc.BillingLongitude;
        point.street = acc.BillingStreet;
        point.city = acc.BillingCity;
        point.state = acc.BillingState;
        point.postalCode = acc.BillingPostalCode;
        point.country = acc.BillingCountry;
        point.distanceKm = distanceKm;
        point.addressLabel = buildAddressLabel(acc);
        return point;
    }

    /**
     * @description Builds a formatted address label from account billing address fields
     * @param acc The account with billing address data
     * @return String Formatted address string for display
     */
    public static String buildAddressLabel(Account acc) {
        List<String> parts = new List<String>();

        if (!String.isBlank(acc.BillingStreet)) {
            parts.add(acc.BillingStreet);
        }

        String postalCity = '';
        if (!String.isBlank(acc.BillingPostalCode)) {
            postalCity += acc.BillingPostalCode;
        }
        if (!String.isBlank(acc.BillingCity)) {
            postalCity += (postalCity == '' ? '' : ' ') + acc.BillingCity;
        }
        if (!String.isBlank(postalCity)) {
            parts.add(postalCity);
        }

        List<String> stateCountry = new List<String>();
        if (!String.isBlank(acc.BillingState)) {
            stateCountry.add(acc.BillingState);
        }
        if (!String.isBlank(acc.BillingCountry)) {
            stateCountry.add(acc.BillingCountry);
        }
        if (!stateCountry.isEmpty()) {
            parts.add(String.join(stateCountry, ', '));
        }

        return String.join(parts, ', ');
    }
}