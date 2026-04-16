# Nearby Accounts Map Component

A Lightning Web Component for Salesforce that enables proximity-based account search and interactive mapping with Google Maps itinerary generation.

![Component Version](https://img.shields.io/badge/version-1.0.0-blue)
![Salesforce API](https://img.shields.io/badge/Salesforce%20API-v65.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## 📋 Overview

The **Nearby Accounts Map** component provides powerful geolocation-based account discovery for Salesforce users. It leverages Salesforce's native geospatial DISTANCE function to find accounts within a specified radius, displays them on an interactive map, and allows users to generate optimized Google Maps itineraries for field visits.

### Key Features

- 🗺️ **Interactive Map Display** - Visual representation of nearby accounts with clickable markers
- 📍 **Proximity Search** - Find accounts within a customizable radius (km)
- 🎯 **Dual Mode Operation** - Works standalone (with account picker) or on Account record pages
- 🚗 **Itinerary Generation** - Create multi-stop Google Maps routes with up to 10 waypoints
- ⚡ **Real-time Updates** - Immediate geocode data display via wire adapters
- 🔒 **Security-First** - Field-level security checks and sharing rules enforcement
- 📊 **Distance Calculation** - Automatic distance computation from center point
- ✅ **Selective Routing** - Choose which accounts to include in your itinerary

## 🎬 Demo

### Standalone Mode (App Page)
Users can select any account as the center point and search for nearby accounts.

### Record Page Mode
When placed on an Account record page, automatically uses the current account as the center.

### Itinerary Generation
Select up to 10 accounts and generate a Google Maps driving directions URL with optimized waypoints.

> **Note:** Add screenshots or GIFs of your component in action to this section.

## 📦 What's Included

### Lightning Web Component
- `nearbyAccountsMap.js` - Main component logic with search and itinerary features
- `nearbyAccountsMap.html` - Responsive template with SLDS styling
- `nearbyAccountsMap.css` - Custom BEM-style CSS for enhanced UI
- `nearbyAccountsMap.js-meta.xml` - Component metadata and configuration
- `__tests__/nearbyAccountsMap.test.js` - Comprehensive Jest unit tests

### Apex Classes
- `NearbyAccountsController.cls` - Main controller with @AuraEnabled method
- `NearbyAccountsMapUtil.cls` - Utility class with geospatial logic
- `NearbyAccountsMapDto.cls` - Data Transfer Objects for type safety
- `NearbyAccountsControllerTest.cls` - 100% test coverage for controller
- `NearbyAccountsMapUtilTest.cls` - Comprehensive utility class tests

## 🚀 Prerequisites

### Required Salesforce Features

1. **Maps and Location Services**
   - Navigate to: **Setup → Maps and Location Services**
   - Enable: "Maps and Location Services"
   - This enables the `lightning-map` component used by this solution

2. **Data Integration Rules (Geocoding)**
   - Navigate to: **Setup → Data Integration Rules**
   - Enable: "Geocodes for Data Quality"
   - This automatically populates `BillingLatitude` and `BillingLongitude` when addresses are saved
   - **Critical:** Without this, accounts won't be geocoded and won't appear in search results

3. **Account Geocoded Data**
   - Accounts must have complete Billing Addresses
   - When saved, Salesforce automatically geocodes and populates:
     - `BillingLatitude`
     - `BillingLongitude`
   - Accounts without these fields populated will not be found

### Field-Level Security

Users must have **Read** access to the following Account fields:
- `BillingStreet`
- `BillingCity`
- `BillingState`
- `BillingPostalCode`
- `BillingCountry`
- `BillingLatitude`
- `BillingLongitude`

### Salesforce Edition

This component works on all Salesforce editions that support:
- Lightning Experience
- Lightning Web Components
- Geolocation fields

## 📥 Installation

### Option 1: Using Salesforce CLI (Recommended)

1. **Clone or download** this repository

2. **Authenticate** to your Salesforce org:
```bash
sf org login web --alias myOrg
```

3. **Deploy** the component:
```bash
sf project deploy start --source-dir force-app/main/default --target-org myOrg
```

### Option 2: Using Package Manifest

1. **Deploy** using package.xml:
```bash
sf project deploy start --manifest manifest/package.xml --target-org myOrg
```

### Option 3: Using VS Code

1. Open the project in VS Code with Salesforce Extensions installed
2. Right-click on `force-app/main/default`
3. Select **SFDX: Deploy Source to Org**

## ⚙️ Configuration

### Component Properties

The component exposes three public properties configurable in Lightning App Builder:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `defaultRadiusKm` | Number | 25 | Default search radius in kilometers |
| `maxSelectable` | Number | 10 | Maximum accounts selectable for itinerary (Google Maps limit) |
| `resultLimit` | Number | 99 | Maximum search results (capped at 99 for performance) |

### Adding to Lightning Pages

1. **Navigate** to Lightning App Builder
2. **Edit** an Account record page, app page, or home page
3. **Drag** the "Nearby Accounts" component onto the page
4. **Configure** properties in the right panel:
   - Set your preferred default radius
   - Adjust max selectable accounts
   - Set result limit
5. **Save** and **Activate** the page

### Supported Page Types

- ✅ **Account Record Pages** - Uses current account as center
- ✅ **App Pages** - Standalone mode with account picker
- ✅ **Home Pages** - Standalone mode with account picker

## 🎯 Usage

### Basic Search

1. **Select or view** an account (depending on page type)
2. **Enter** desired search radius in kilometers
3. **Click** "Search" button
4. View results on interactive map and in list panel

### Creating Itineraries

1. **Perform** a search as described above
2. **Check** the boxes next to accounts you want to visit (up to 10)
3. **Click** "Open itinerary in Google Maps"
4. A new tab opens with Google Maps directions including all selected waypoints

### Understanding Results

- **Distance Display** - Shows distance from center account in kilometers
- **Active Marker** - Click account names to highlight markers on map
- **Selection Order** - Blue numbered pills show visit order
- **Address Labels** - Complete formatted addresses displayed

### Important Notes

> **Radius Buffer:** The component adds a 0.1km buffer to the search radius because the Salesforce DISTANCE function only supports the `<` operator (not `<=`). This ensures accounts at the exact radius edge are included.

> **Result Limit:** Maximum 99 results per search for optimal performance. If you need more, increase the radius or use multiple searches.

## 🔧 Troubleshooting

### "No geocoded Billing Address" Error

**Problem:** Selected account doesn't have latitude/longitude populated.

**Solution:**
1. Open the Account record
2. Click **Edit**
3. Enter a complete Billing Address (Street, City, State, Postal Code, Country)
4. Click **Save**
5. Salesforce automatically geocodes the address
6. Wait a moment and try your search again

### "Insufficient permissions" Error

**Problem:** User doesn't have access to required Account fields.

**Solution:**
- Contact your Salesforce administrator
- Request Read access to Account billing address fields
- Administrator should check Profile or Permission Set field-level security

### "No accounts found" Message

**Possible Causes:**
1. No accounts exist within the specified radius
2. Nearby accounts don't have geocoded addresses
3. Sharing rules prevent user from seeing nearby accounts

**Solutions:**
- Increase the search radius
- Ensure nearby accounts have complete billing addresses
- Check account sharing rules and ownership

### Map Not Displaying

**Problem:** Map component doesn't render.

**Solution:**
1. Verify Maps and Location Services is enabled
2. Check browser console for errors
3. Ensure you're in Lightning Experience (not Salesforce Classic)
4. Verify the component is added to a supported page type

### Google Maps Itinerary Doesn't Open

**Problem:** Button is disabled or nothing happens.

**Solution:**
- Ensure at least one account is selected
- Check that browser isn't blocking pop-ups
- Verify all selected accounts have valid geocode data

## 🏗️ Technical Architecture

### Component Structure

```
nearbyAccountsMap/
├── nearbyAccountsMap.js          # Component controller
├── nearbyAccountsMap.html        # Template with SLDS styling
├── nearbyAccountsMap.css         # BEM-style custom CSS
├── nearbyAccountsMap.js-meta.xml # Metadata configuration
└── __tests__/
    └── nearbyAccountsMap.test.js # Jest unit tests
```

### Apex Architecture

```
┌─────────────────────────────────┐
│ NearbyAccountsController        │
│ (with sharing)                   │
│ - @AuraEnabled(cacheable=true)  │
└───────────┬─────────────────────┘
            │
            ↓
┌─────────────────────────────────┐
│ NearbyAccountsMapUtil           │
│ (inherited sharing)              │
│ - Input validation               │
│ - FLS checks                     │
│ - Geospatial queries             │
│ - Distance calculations          │
│ - Response building              │
└───────────┬─────────────────────┘
            │
            ↓
┌─────────────────────────────────┐
│ NearbyAccountsMapDto            │
│ - AccountPoint                   │
│ - SearchResponse                 │
└─────────────────────────────────┘
```

### Key Design Patterns

- **Separation of Concerns** - Controller, Util, and DTO classes
- **Security First** - FLS checks, sharing rules, input validation
- **Cacheable Apex** - Improves performance with `@AuraEnabled(cacheable=true)`
- **Wire Adapters** - Real-time data display
- **BEM CSS** - Maintainable, scalable styling
- **Comprehensive Testing** - 100% Apex coverage, Jest tests for LWC

### Geospatial Query Logic

The component uses Salesforce's native `DISTANCE` function:

```sql
SELECT Id, Name, BillingAddress, BillingLatitude, BillingLongitude
FROM Account
WHERE BillingLatitude != null
  AND BillingLongitude != null
  AND DISTANCE(BillingAddress, GEOLOCATION(:lat, :lon), 'km') < :radius
ORDER BY DISTANCE(BillingAddress, GEOLOCATION(:lat, :lon), 'km') ASC
```

## 📊 Test Coverage

### Apex Tests

- **NearbyAccountsControllerTest** - 100% controller coverage
  - Success scenarios
  - Error handling
  - Edge cases
  - Input validation

- **NearbyAccountsMapUtilTest** - 100% utility coverage
  - All public methods
  - Field access validation
  - Distance calculations
  - Address label formatting

### LWC Tests

- **nearbyAccountsMap.test.js** - Comprehensive Jest tests
  - Component initialization
  - Search functionality
  - Selection logic
  - Error handling
  - Itinerary generation

**Run tests:**
```bash
# Apex tests
sf apex run test --test-level RunSpecifiedTests --class-names NearbyAccountsControllerTest,NearbyAccountsMapUtilTest --target-org myOrg

# LWC tests
npm run test:unit
```

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Code Standards

- Follow Salesforce best practices
- Maintain 100% Apex test coverage
- Add Jest tests for new LWC features
- Use BEM naming for CSS classes
- Document public methods with JSDoc/ApexDoc

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Lightning Web Components](https://developer.salesforce.com/docs/component-library/overview/components)
- Uses [Salesforce Lightning Design System](https://www.lightningdesignsystem.com/)
- Integrates with [Google Maps Platform](https://developers.google.com/maps)

## 📞 Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Check the [Troubleshooting](#-troubleshooting) section
- Review Salesforce documentation on Maps and Geocoding

## 👨‍💻 Author

**Joakim JAN**
- Date: 2026-04-15

---

**Made with ❤️ for the Salesforce Community**