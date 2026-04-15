# Installation Guide

Complete step-by-step instructions for deploying and configuring the Nearby Accounts Map component in your Salesforce org.

## Table of Contents

1. [Pre-Installation Checklist](#pre-installation-checklist)
2. [Deployment Options](#deployment-options)
3. [Post-Deployment Configuration](#post-deployment-configuration)
4. [Verification Steps](#verification-steps)
5. [Troubleshooting Installation Issues](#troubleshooting-installation-issues)

## Pre-Installation Checklist

Before deploying, ensure you have:

- [ ] Salesforce org with Lightning Experience enabled
- [ ] System Administrator or equivalent permissions
- [ ] Salesforce CLI installed (for CLI deployment)
- [ ] VS Code with Salesforce Extensions (for VS Code deployment)
- [ ] Repository cloned or downloaded locally

## Deployment Options

### Option 1: Salesforce CLI Deployment (Recommended)

#### Step 1: Install Salesforce CLI

If not already installed, download from [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli):

```bash
# Verify installation
sf --version
```

#### Step 2: Authenticate to Your Org

```bash
# For production/developer org
sf org login web --alias myOrg

# For sandbox
sf org login web --alias mySandbox --instance-url https://test.salesforce.com
```

#### Step 3: Deploy the Component

**Option A: Deploy entire force-app directory**
```bash
sf project deploy start --source-dir force-app/main/default --target-org myOrg
```

**Option B: Deploy using package.xml**
```bash
sf project deploy start --manifest manifest/package.xml --target-org myOrg
```

**Option C: Deploy with validation only (dry run)**
```bash
sf project deploy start --source-dir force-app/main/default --target-org myOrg --dry-run
```

#### Step 4: Verify Deployment

```bash
# Check deployment status
sf project deploy report --target-org myOrg

# Run Apex tests
sf apex run test --test-level RunSpecifiedTests \
  --class-names NearbyAccountsControllerTest,NearbyAccountsMapUtilTest \
  --target-org myOrg --result-format human
```

### Option 2: VS Code Deployment

#### Step 1: Open Project in VS Code

1. Launch VS Code
2. Install "Salesforce Extension Pack" if not already installed
3. Open the `nearbyAccounts-package` folder

#### Step 2: Authorize Org

1. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
2. Type: `SFDX: Authorize an Org`
3. Select org type (Production/Sandbox)
4. Complete browser authentication
5. Set an alias (e.g., "myOrg")

#### Step 3: Deploy Source

**Deploy All:**
1. Right-click on `force-app/main/default`
2. Select `SFDX: Deploy Source to Org`
3. Wait for deployment confirmation

**Deploy Specific Components:**
1. Right-click on specific file (e.g., `NearbyAccountsController.cls`)
2. Select `SFDX: Deploy This Source to Org`

### Option 3: Workbench Deployment

#### Step 1: Create Deployment Package

1. Zip the following structure:
```
package.zip
├── classes/
│   ├── NearbyAccountsController.cls
│   ├── NearbyAccountsController.cls-meta.xml
│   ├── NearbyAccountsMapDto.cls
│   ├── NearbyAccountsMapDto.cls-meta.xml
│   ├── NearbyAccountsMapUtil.cls
│   ├── NearbyAccountsMapUtil.cls-meta.xml
│   ├── NearbyAccountsControllerTest.cls
│   ├── NearbyAccountsControllerTest.cls-meta.xml
│   ├── NearbyAccountsMapUtilTest.cls
│   └── NearbyAccountsMapUtilTest.cls-meta.xml
├── lwc/
│   └── nearbyAccountsMap/
│       ├── nearbyAccountsMap.js
│       ├── nearbyAccountsMap.html
│       ├── nearbyAccountsMap.css
│       ├── nearbyAccountsMap.js-meta.xml
│       └── __tests__/
│           └── nearbyAccountsMap.test.js
└── package.xml
```

#### Step 2: Deploy via Workbench

1. Navigate to [Workbench](https://workbench.developerforce.com/)
2. Login to your org
3. Go to **migration → Deploy**
4. Upload your `package.zip`
5. Check **Single Package**
6. Check **Run All Tests** (for production)
7. Click **Next** and **Deploy**

### Option 4: Change Sets (For Org-to-Org)

#### In Source Org:

1. Navigate to **Setup → Deployment Settings**
2. Add target org to deployment connections
3. Go to **Setup → Outbound Change Sets**
4. Click **New** and create a change set
5. Add components:
   - All Apex Classes (6 total)
   - Lightning Web Component (nearbyAccountsMap)
6. **Upload** to target org

#### In Target Org:

1. Navigate to **Setup → Inbound Change Sets**
2. Find your change set
3. Click **Deploy**
4. Select **Run All Tests** if deploying to production
5. Click **Deploy**

## Post-Deployment Configuration

### Step 1: Enable Maps and Location Services

1. Navigate to **Setup**
2. In Quick Find, search: `Maps and Location Services`
3. Click **Maps and Location Services**
4. Enable **Maps and Location Services**
5. Click **Save**

> **Note:** This enables the `lightning-map` component used by the solution.

### Step 2: Enable Data Integration Rules (Geocoding)

1. Navigate to **Setup**
2. In Quick Find, search: `Data Integration Rules`
3. Click **Data Integration Rules**
4. Find **Geocodes for Data Quality**
5. Click **Activate** if not already active

> **Critical:** This automatically geocodes addresses when accounts are saved.

### Step 3: Geocode Existing Accounts

If you have existing accounts without geocoded data:

#### Option A: Manual Update (Small datasets)

1. Navigate to an Account record
2. Click **Edit**
3. Ensure complete Billing Address:
   - Billing Street
   - Billing City
   - Billing State/Province
   - Billing Zip/Postal Code
   - Billing Country
4. Click **Save**
5. Verify `BillingLatitude` and `BillingLongitude` are populated

#### Option B: Data Loader (Large datasets)

1. Export accounts using Data Loader
2. Update addresses in CSV
3. Import back using Data Loader (this triggers geocoding)

#### Option C: Apex Script

```apex
// Execute in Developer Console
List<Account> accounts = [
    SELECT Id, BillingStreet, BillingCity, BillingState, 
           BillingPostalCode, BillingCountry
    FROM Account
    WHERE BillingLatitude = null
    AND BillingStreet != null
    LIMIT 200
];

// Simply updating triggers the geocoding process
update accounts;
```

### Step 4: Configure Field-Level Security

#### Create Permission Set (Recommended):

1. Navigate to **Setup → Permission Sets**
2. Click **New**
3. Label: `Nearby Accounts Map User`
4. Click **Save**
5. Click **Object Settings**
6. Select **Account**
7. Click **Edit**
8. Enable **Read** for:
   - Billing Street
   - Billing City
   - Billing State/Province
   - Billing Zip/Postal Code
   - Billing Country
   - Billing Latitude
   - Billing Longitude
9. Click **Save**
10. Assign to users

#### Or Modify Profiles:

1. Navigate to **Setup → Profiles**
2. Select target profile
3. Click **Object Settings**
4. Select **Account**
5. Enable field-level security as above

### Step 5: Add Component to Lightning Pages

#### On Account Record Page:

1. Navigate to **Setup → Lightning App Builder**
2. Find or create an Account record page
3. Click **Edit**
4. Drag **Nearby Accounts** component from Custom section
5. Configure properties:
   - Default Radius (km): `25`
   - Max Selectable: `10`
   - Result Limit: `99`
6. Click **Save**
7. Click **Activation**
8. Assign to org default or specific apps/profiles
9. Click **Save**

#### On App Page or Home Page:

1. Navigate to **Setup → Lightning App Builder**
2. Create new App Page or Home Page
3. Drag **Nearby Accounts** component
4. Configure properties (same as above)
5. Save and activate

### Step 6: Run Apex Tests

Verify deployment with tests:

```bash
# CLI
sf apex run test --test-level RunSpecifiedTests \
  --class-names NearbyAccountsControllerTest,NearbyAccountsMapUtilTest \
  --target-org myOrg \
  --result-format human \
  --code-coverage

# Or via Developer Console
# Debug → Open Execute Anonymous Window
Test.startTest();
Test.runSpecifiedTests(new String[]{
    'NearbyAccountsControllerTest',
    'NearbyAccountsMapUtilTest'
});
Test.stopTest();
```

Expected Results:
- ✅ All tests passing
- ✅ 100% code coverage for all Apex classes

## Verification Steps

### 1. Verify Component Deployment

1. Navigate to **Setup → Lightning Components**
2. Search for `nearbyAccountsMap`
3. Confirm it appears in the list

### 2. Verify Apex Classes

1. Navigate to **Setup → Apex Classes**
2. Confirm these classes exist:
   - NearbyAccountsController
   - NearbyAccountsMapDto
   - NearbyAccountsMapUtil
   - NearbyAccountsControllerTest
   - NearbyAccountsMapUtilTest

### 3. Test Component Functionality

#### Test on Record Page:

1. Navigate to any Account with geocoded address
2. Verify component displays
3. Click **Search**
4. Verify results appear on map

#### Test in Standalone Mode:

1. Create an App Page with the component
2. Use account picker to select an account
3. Perform search
4. Verify results

### 4. Test Geocoding

1. Create a new Account
2. Enter complete billing address
3. Save
4. Edit the account again
5. Verify `BillingLatitude` and `BillingLongitude` are populated

### 5. Test Itinerary Generation

1. Perform a search with results
2. Select 2-3 accounts
3. Click **Open itinerary in Google Maps**
4. Verify new tab opens with route

## Troubleshooting Installation Issues

### Deployment Fails

**Error: "Cannot find Lightning Web Component nearbyAccountsMap"**

**Solution:**
- Ensure `nearbyAccountsMap.js-meta.xml` is included
- Verify all LWC files are in correct directory structure
- Redeploy with correct structure

**Error: "Test coverage less than 75%"**

**Solution:**
- Ensure test classes are deployed
- Run tests before deployment:
  ```bash
  sf apex run test --test-level RunLocalTests --target-org myOrg
  ```

**Error: "Field is not writeable: Account.BillingLatitude"**

**Solution:**
- These are system-managed fields
- Don't try to set them manually in code
- Let Salesforce geocoding handle them

### Maps Not Showing

**Problem:** Component displays but map is blank

**Solution:**
1. Verify Maps and Location Services is enabled
2. Check browser console for errors
3. Verify user has Lightning Experience access
4. Clear browser cache

### No Search Results

**Problem:** Search returns no results

**Solution:**
1. Verify accounts have geocoded addresses
2. Check Field-Level Security
3. Verify sharing rules allow access to accounts
4. Try increasing search radius

### Geocoding Not Working

**Problem:** Accounts saved but lat/long not populated

**Solution:**
1. Verify Data Integration Rules are active
2. Check address is complete (all fields)
3. Verify address is valid
4. Wait a few moments (geocoding may be queued)

## Next Steps

After successful installation:

1. ✅ Review [README.md](README.md) for usage instructions
2. ✅ Check [CONFIGURATION.md](CONFIGURATION.md) for advanced settings
3. ✅ Refer to [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
4. ✅ Train users on component functionality

## Support

For installation issues:
- Review this guide thoroughly
- Check Salesforce deployment logs
- Verify all prerequisites are met
- Open an issue on GitHub with deployment logs

---

**Installation complete! Ready to find nearby accounts.**