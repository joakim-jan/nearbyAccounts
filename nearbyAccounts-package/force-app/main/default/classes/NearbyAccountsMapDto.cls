public class NearbyAccountsMapDto {
    public class AccountPoint {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Decimal latitude { get; set; }
        @AuraEnabled public Decimal longitude { get; set; }
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String postalCode { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public Double distanceKm { get; set; }
        @AuraEnabled public String addressLabel { get; set; }
    }

    public class SearchResponse {
        @AuraEnabled public AccountPoint center { get; set; }
        @AuraEnabled public List<AccountPoint> accounts { get; set; }
    }
}