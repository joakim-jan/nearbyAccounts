# Changelog

All notable changes to the Nearby Accounts Map component will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-15

### Added
- Initial release of Nearby Accounts Map component
- Lightning Web Component with dual-mode operation (standalone and record page)
- Proximity-based account search using Salesforce DISTANCE function
- Interactive map display with clickable markers
- Google Maps itinerary generation (up to 10 waypoints)
- Apex controller with cacheable @AuraEnabled method
- Comprehensive utility class with geospatial logic
- Data Transfer Objects for type-safe responses
- Field-level security checks
- Input validation and error handling
- Enhanced error messages with actionable guidance
- BEM-style CSS for maintainable styling
- Complete Apex test coverage (100%)
- Jest unit tests for LWC
- Comprehensive documentation (README, INSTALLATION, CONFIGURATION, TROUBLESHOOTING)
- Package.xml for easy deployment
- MIT License

### Features
- **Search Radius**: Configurable search radius in kilometers (default: 25km)
- **Result Limit**: Configurable maximum results (default: 99, capped at 99)
- **Max Selectable**: Configurable maximum accounts for itinerary (default: 10)
- **Distance Calculation**: Automatic distance calculation from center point
- **Address Formatting**: Smart address label building with fallbacks
- **Real-time Updates**: Wire adapter for immediate account name display
- **Selection Management**: Visual selection order with numbered pills
- **Active Marker Highlighting**: Click account names to focus map markers
- **Responsive Design**: Mobile-friendly layout with SLDS components

### Technical Details
- **API Version**: 65.0
- **Sharing Model**: with sharing (controller), inherited sharing (utility)
- **Cacheable Apex**: Improved performance with wire adapter caching
- **Security**: FLS checks, input validation, sharing rules enforcement
- **Testing**: 100% Apex coverage, comprehensive Jest tests
- **Architecture**: Clean separation of concerns (Controller → Util → DTO)

### Prerequisites
- Maps and Location Services enabled
- Data Integration Rules (Geocodes for Data Quality) activated
- Account field-level security configured
- Complete billing addresses for geocoding

### Known Limitations
- Maximum 99 results per search (Salesforce query optimization)
- Google Maps supports maximum 10 waypoints
- Requires geocoded billing addresses (latitude/longitude)
- 0.1km radius buffer due to DISTANCE operator limitations

## [Unreleased]

### Planned Features
- Support for custom address fields
- Shipping address as alternative to billing
- Distance unit preference (km/miles)
- Export results to CSV
- Save favorite routes
- Mobile app support
- Bulk account geocoding tool

---

For installation instructions, see [INSTALLATION.md](INSTALLATION.md)

For usage guidelines, see [README.md](README.md)