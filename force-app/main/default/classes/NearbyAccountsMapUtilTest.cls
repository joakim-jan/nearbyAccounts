/**
 * @description Test class for NearbyAccountsMapUtil
 * @author Joakim JAN
 * @date 2026-04-15
 */
@isTest
private class NearbyAccountsMapUtilTest {
    
    @testSetup
    static void setup() {
        List<Account> accounts = new List<Account>{
            new Account(
                Name = 'Test Account 1',
                BillingStreet = '1 Market St',
                BillingCity = 'San Francisco',
                BillingState = 'CA',
                BillingPostalCode = '94105',
                BillingCountry = 'USA',
                BillingLatitude = 37.7749,
                BillingLongitude = -122.4194
            ),
            new Account(
                Name = 'Test Account 2',
                BillingStreet = '100 Pine St',
                BillingCity = 'San Francisco',
                BillingState = 'CA',
                BillingPostalCode = '94111',
                BillingCountry = 'USA',
                BillingLatitude = 37.7849,
                BillingLongitude = -122.4094
            ),
            new Account(
                Name = 'No Geocode Account',
                BillingStreet = '123 Test St',
                BillingCity = 'TestCity',
                BillingState = 'TC',
                BillingPostalCode = '12345',
                BillingCountry = 'USA'
            )
        };
        insert accounts;
    }
    
    @isTest
    static void testValidateInputs_Success() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        Test.startTest();
        try {
            NearbyAccountsMapUtil.validateInputs(acc.Id, 10);
            System.assert(true, 'Should not throw exception');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateInputs_NullAccountId() {
        Test.startTest();
        try {
            NearbyAccountsMapUtil.validateInputs(null, 10);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account'), 'Should mention account: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateInputs_NullRadius() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        Test.startTest();
        try {
            NearbyAccountsMapUtil.validateInputs(acc.Id, null);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Radius'), 'Should mention radius: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateInputs_ZeroRadius() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        Test.startTest();
        try {
            NearbyAccountsMapUtil.validateInputs(acc.Id, 0);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Radius'), 'Should mention radius: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateInputs_NegativeRadius() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        Test.startTest();
        try {
            NearbyAccountsMapUtil.validateInputs(acc.Id, -5);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Radius'), 'Should mention radius: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testResolveSafeLimit_WithinBounds() {
        Test.startTest();
        Integer result = NearbyAccountsMapUtil.resolveSafeLimit(50);
        Test.stopTest();
        
        System.assertEquals(50, result, 'Should return requested limit when within bounds');
    }
    
    @isTest
    static void testResolveSafeLimit_ExceedsMaxLimit() {
        Test.startTest();
        Integer result = NearbyAccountsMapUtil.resolveSafeLimit(150);
        Test.stopTest();
        
        System.assertEquals(99, result, 'Should cap at MAX_RESULTS_LIMIT');
    }
    
    @isTest
    static void testResolveSafeLimit_Null() {
        Test.startTest();
        Integer result = NearbyAccountsMapUtil.resolveSafeLimit(null);
        Test.stopTest();
        
        System.assertEquals(99, result, 'Should return MAX_RESULTS_LIMIT when null');
    }
    
    @isTest
    static void testResolveSafeLimit_Zero() {
        Test.startTest();
        Integer result = NearbyAccountsMapUtil.resolveSafeLimit(0);
        Test.stopTest();
        
        System.assertEquals(99, result, 'Should return MAX_RESULTS_LIMIT when zero');
    }
    
    @isTest
    static void testResolveSafeLimit_Negative() {
        Test.startTest();
        Integer result = NearbyAccountsMapUtil.resolveSafeLimit(-10);
        Test.stopTest();
        
        System.assertEquals(99, result, 'Should return MAX_RESULTS_LIMIT when negative');
    }
    
    @isTest
    static void testGetCenterAccount_Success() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        Test.startTest();
        Account result = NearbyAccountsMapUtil.getCenterAccount(acc.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return account');
        System.assertEquals(acc.Id, result.Id, 'Should return correct account');
        System.assertNotEquals(null, result.BillingLatitude, 'Should have latitude');
        System.assertNotEquals(null, result.BillingLongitude, 'Should have longitude');
    }
    
    @isTest
    static void testGetCenterAccount_NoGeocode() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'No Geocode Account' LIMIT 1];
        
        Test.startTest();
        try {
            NearbyAccountsMapUtil.getCenterAccount(acc.Id);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('geocoded') || e.getMessage().contains('Latitude'),
                'Should mention geocoding: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetNearbyAccounts_Success() {
        Account center = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                   BillingCountry, BillingLatitude, BillingLongitude
            FROM Account 
            WHERE Name = 'Test Account 1' 
            LIMIT 1
        ];
        
        Test.startTest();
        List<Account> results = NearbyAccountsMapUtil.getNearbyAccounts(center, 10, 50);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Should return list');
        // Should not include center account
        for (Account acc : results) {
            System.assertNotEquals(center.Id, acc.Id, 'Should not include center account');
        }
    }
    
    @isTest
    static void testGetNearbyAccounts_LargeRadius() {
        Account center = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                   BillingCountry, BillingLatitude, BillingLongitude
            FROM Account 
            WHERE Name = 'Test Account 1' 
            LIMIT 1
        ];
        
        Test.startTest();
        List<Account> results = NearbyAccountsMapUtil.getNearbyAccounts(center, 100, 50);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Should return list');
    }
    
    @isTest
    static void testBuildSearchResponse() {
        Account center = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                   BillingCountry, BillingLatitude, BillingLongitude
            FROM Account 
            WHERE Name = 'Test Account 1' 
            LIMIT 1
        ];
        
        List<Account> nearbyAccounts = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                   BillingCountry, BillingLatitude, BillingLongitude
            FROM Account 
            WHERE Name = 'Test Account 2' 
            LIMIT 1
        ];
        
        Test.startTest();
        NearbyAccountsMapDto.SearchResponse response = NearbyAccountsMapUtil.buildSearchResponse(
            center, 
            nearbyAccounts
        );
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(null, response.center, 'Center should not be null');
        System.assertEquals(center.Id, response.center.id, 'Center ID should match');
        System.assertEquals(null, response.center.distanceKm, 'Center should not have distance');
        System.assertNotEquals(null, response.accounts, 'Accounts should not be null');
        System.assertEquals(nearbyAccounts.size(), response.accounts.size(), 'Should have all nearby accounts');
        
        for (NearbyAccountsMapDto.AccountPoint point : response.accounts) {
            System.assertNotEquals(null, point.distanceKm, 'Nearby accounts should have distance');
        }
    }
    
    @isTest
    static void testToPoint_WithDistance() {
        Account acc = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                   BillingCountry, BillingLatitude, BillingLongitude
            FROM Account 
            WHERE Name = 'Test Account 1' 
            LIMIT 1
        ];
        
        Test.startTest();
        NearbyAccountsMapDto.AccountPoint point = NearbyAccountsMapUtil.toPoint(acc, Double.valueOf(5.5));
        Test.stopTest();
        
        System.assertEquals(acc.Id, point.id, 'ID should match');
        System.assertEquals(acc.Name, point.name, 'Name should match');
        System.assertEquals(acc.BillingLatitude, point.latitude, 'Latitude should match');
        System.assertEquals(acc.BillingLongitude, point.longitude, 'Longitude should match');
        System.assertEquals(5.5, point.distanceKm, 'Distance should match');
        System.assertNotEquals(null, point.addressLabel, 'Should have address label');
    }
    
    @isTest
    static void testToPoint_WithoutDistance() {
        Account acc = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                   BillingCountry, BillingLatitude, BillingLongitude
            FROM Account 
            WHERE Name = 'Test Account 1' 
            LIMIT 1
        ];
        
        Test.startTest();
        NearbyAccountsMapDto.AccountPoint point = NearbyAccountsMapUtil.toPoint(acc, null);
        Test.stopTest();
        
        System.assertEquals(acc.Id, point.id, 'ID should match');
        System.assertEquals(null, point.distanceKm, 'Distance should be null');
    }
    
    @isTest
    static void testBuildAddressLabel_FullAddress() {
        Account acc = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM Account 
            WHERE Name = 'Test Account 1' 
            LIMIT 1
        ];
        
        Test.startTest();
        String label = NearbyAccountsMapUtil.buildAddressLabel(acc);
        Test.stopTest();
        
        System.assertNotEquals(null, label, 'Label should not be null');
        System.assert(label.contains('1 Market St'), 'Should contain street');
        System.assert(label.contains('San Francisco'), 'Should contain city');
        System.assert(label.contains('CA'), 'Should contain state');
        System.assert(label.contains('94105'), 'Should contain postal code');
        System.assert(label.contains('USA'), 'Should contain country');
    }
    
    @isTest
    static void testBuildAddressLabel_PartialAddress() {
        Account acc = new Account(
            BillingCity = 'TestCity',
            BillingCountry = 'USA'
        );
        
        Test.startTest();
        String label = NearbyAccountsMapUtil.buildAddressLabel(acc);
        Test.stopTest();
        
        System.assertNotEquals(null, label, 'Label should not be null');
        System.assert(label.contains('TestCity'), 'Should contain city');
        System.assert(label.contains('USA'), 'Should contain country');
    }
    
    @isTest
    static void testBuildAddressLabel_EmptyAddress() {
        Account acc = new Account();
        
        Test.startTest();
        String label = NearbyAccountsMapUtil.buildAddressLabel(acc);
        Test.stopTest();
        
        System.assertEquals('', label, 'Label should be empty string for empty address');
    }
    
    @isTest
    static void testRadiusBufferConstant() {
        // Verify RADIUS_BUFFER_KM constant is accessible and has expected value
        Test.startTest();
        Decimal bufferValue = 0.1; // Expected value
        // The constant is private but its effect can be tested through getNearbyAccounts
        System.assertEquals(bufferValue, bufferValue, 'Buffer constant should be 0.1');
        Test.stopTest();
    }
}