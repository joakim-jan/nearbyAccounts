/**
 * @description Test class for NearbyAccountsController
 * @author Joakim JAN
 * @date 2026-04-15
 */
@isTest
private class NearbyAccountsControllerTest {
    
    @testSetup
    static void setup() {
        // Create center account with geocoded address
        Account centerAccount = new Account(
            Name = 'Center Account',
            BillingStreet = '1 Market St',
            BillingCity = 'San Francisco',
            BillingState = 'CA',
            BillingPostalCode = '94105',
            BillingCountry = 'USA',
            BillingLatitude = 37.7749,
            BillingLongitude = -122.4194
        );
        insert centerAccount;
        
        // Create nearby accounts with various distances
        List<Account> nearbyAccounts = new List<Account>{
            new Account(
                Name = 'Nearby Account 1',
                BillingStreet = '100 Pine St',
                BillingCity = 'San Francisco',
                BillingState = 'CA',
                BillingPostalCode = '94111',
                BillingCountry = 'USA',
                BillingLatitude = 37.7849,
                BillingLongitude = -122.4094
            ),
            new Account(
                Name = 'Nearby Account 2',
                BillingStreet = '200 Mission St',
                BillingCity = 'San Francisco',
                BillingState = 'CA',
                BillingPostalCode = '94112',
                BillingCountry = 'USA',
                BillingLatitude = 37.7949,
                BillingLongitude = -122.3994
            ),
            new Account(
                Name = 'Far Account',
                BillingStreet = '1600 Amphitheatre Parkway',
                BillingCity = 'Mountain View',
                BillingState = 'CA',
                BillingPostalCode = '94043',
                BillingCountry = 'USA',
                BillingLatitude = 37.4220,
                BillingLongitude = -122.0841
            )
        };
        insert nearbyAccounts;
        
        // Create account without geocoding
        Account nonGeocodedAccount = new Account(
            Name = 'Non-Geocoded Account',
            BillingStreet = '123 Test St',
            BillingCity = 'TestCity',
            BillingState = 'TC',
            BillingPostalCode = '12345',
            BillingCountry = 'USA'
        );
        insert nonGeocodedAccount;
    }
    
    @isTest
    static void testFindNearbyAccounts_Success() {
        Account centerAccount = [SELECT Id FROM Account WHERE Name = 'Center Account' LIMIT 1];
        
        Test.startTest();
        NearbyAccountsMapDto.SearchResponse response = NearbyAccountsController.findNearbyAccounts(
            centerAccount.Id,
            10,
            50
        );
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(null, response.center, 'Center account should not be null');
        System.assertEquals(centerAccount.Id, response.center.id, 'Center account ID should match');
        System.assertEquals('Center Account', response.center.name, 'Center account name should match');
        System.assertNotEquals(null, response.accounts, 'Accounts list should not be null');
        System.assert(response.accounts.size() >= 2, 'Should find at least 2 nearby accounts');
    }
    
    @isTest
    static void testFindNearbyAccounts_LargeRadius() {
        Account centerAccount = [SELECT Id FROM Account WHERE Name = 'Center Account' LIMIT 1];
        
        Test.startTest();
        NearbyAccountsMapDto.SearchResponse response = NearbyAccountsController.findNearbyAccounts(
            centerAccount.Id,
            50,
            50
        );
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.accounts.size() >= 3, 'Should find all test accounts within 50km');
    }
    
    @isTest
    static void testFindNearbyAccounts_SmallRadius() {
        Account centerAccount = [SELECT Id FROM Account WHERE Name = 'Center Account' LIMIT 1];
        
        Test.startTest();
        NearbyAccountsMapDto.SearchResponse response = NearbyAccountsController.findNearbyAccounts(
            centerAccount.Id,
            5,
            50
        );
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        // Results depend on actual calculated distances
        System.assertNotEquals(null, response.accounts, 'Accounts list should not be null');
    }
    
    @isTest
    static void testFindNearbyAccounts_WithResultLimit() {
        Account centerAccount = [SELECT Id FROM Account WHERE Name = 'Center Account' LIMIT 1];
        
        Test.startTest();
        NearbyAccountsMapDto.SearchResponse response = NearbyAccountsController.findNearbyAccounts(
            centerAccount.Id,
            50,
            2
        );
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.accounts.size() <= 2, 'Should respect result limit');
    }
    
    @isTest
    static void testFindNearbyAccounts_InvalidCenterAccount() {
        Id invalidAccountId = '001000000000000AAA';
        
        Test.startTest();
        try {
            NearbyAccountsController.findNearbyAccounts(invalidAccountId, 10, 50);
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(e instanceof QueryException, 'Should throw QueryException');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testFindNearbyAccounts_NullCenterAccountId() {
        Test.startTest();
        try {
            NearbyAccountsController.findNearbyAccounts(null, 10, 50);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account'), 'Error message should mention account: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testFindNearbyAccounts_InvalidRadius() {
        Account centerAccount = [SELECT Id FROM Account WHERE Name = 'Center Account' LIMIT 1];
        
        Test.startTest();
        try {
            NearbyAccountsController.findNearbyAccounts(centerAccount.Id, 0, 50);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Radius'), 'Error message should mention radius: ' + e.getMessage());
        }
        
        try {
            NearbyAccountsController.findNearbyAccounts(centerAccount.Id, -5, 50);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Radius'), 'Error message should mention radius: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testFindNearbyAccounts_NonGeocodedCenter() {
        Account nonGeocodedAccount = [SELECT Id FROM Account WHERE Name = 'Non-Geocoded Account' LIMIT 1];
        
        Test.startTest();
        try {
            NearbyAccountsController.findNearbyAccounts(nonGeocodedAccount.Id, 10, 50);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('geocoded') || e.getMessage().contains('Latitude'),
                'Error message should mention geocoding: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
    
    @isTest
    static void testFindNearbyAccounts_NullRadius() {
        Account centerAccount = [SELECT Id FROM Account WHERE Name = 'Center Account' LIMIT 1];
        
        Test.startTest();
        try {
            NearbyAccountsController.findNearbyAccounts(centerAccount.Id, null, 50);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Radius'), 'Error message should mention radius: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testFindNearbyAccounts_ExceedMaxLimit() {
        Account centerAccount = [SELECT Id FROM Account WHERE Name = 'Center Account' LIMIT 1];
        
        Test.startTest();
        NearbyAccountsMapDto.SearchResponse response = NearbyAccountsController.findNearbyAccounts(
            centerAccount.Id,
            100,
            150 // Exceeds max limit of 99
        );
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.accounts.size() <= 99, 'Should cap results at 99');
    }
    
    @isTest
    static void testFindNearbyAccounts_DistanceCalculation() {
        Account centerAccount = [SELECT Id FROM Account WHERE Name = 'Center Account' LIMIT 1];
        
        Test.startTest();
        NearbyAccountsMapDto.SearchResponse response = NearbyAccountsController.findNearbyAccounts(
            centerAccount.Id,
            50,
            50
        );
        Test.stopTest();
        
        for (NearbyAccountsMapDto.AccountPoint point : response.accounts) {
            System.assertNotEquals(null, point.distanceKm, 'Distance should be calculated');
            System.assert(point.distanceKm >= 0, 'Distance should be non-negative');
        }
    }
    
    @isTest
    static void testFindNearbyAccounts_AddressLabels() {
        Account centerAccount = [SELECT Id FROM Account WHERE Name = 'Center Account' LIMIT 1];
        
        Test.startTest();
        NearbyAccountsMapDto.SearchResponse response = NearbyAccountsController.findNearbyAccounts(
            centerAccount.Id,
            50,
            50
        );
        Test.stopTest();
        
        System.assertNotEquals(null, response.center.addressLabel, 'Center should have address label');
        System.assert(response.center.addressLabel.contains('San Francisco'), 'Address label should contain city');
        
        for (NearbyAccountsMapDto.AccountPoint point : response.accounts) {
            System.assertNotEquals(null, point.addressLabel, 'Each account should have address label');
        }
    }
}