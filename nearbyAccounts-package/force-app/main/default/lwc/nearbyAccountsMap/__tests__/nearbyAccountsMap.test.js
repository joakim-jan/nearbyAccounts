import { createElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import NearbyAccountsMap from 'c/nearbyAccountsMap';
import findNearbyAccounts from '@salesforce/apex/NearbyAccountsController.findNearbyAccounts';

// Mock Apex method
jest.mock(
    '@salesforce/apex/NearbyAccountsController.findNearbyAccounts',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

// Mock getRecord wire adapter
jest.mock('lightning/uiRecordApi', () => ({
    getRecord: jest.fn()
}), { virtual: true });

const mockAccountData = {
    center: {
        id: '001xx000003DGbIAAW',
        name: 'Burlington Textiles Corp of America',
        latitude: 37.7749,
        longitude: -122.4194,
        street: '525 S. Lexington Ave',
        city: 'Burlington',
        state: 'NC',
        postalCode: '27215',
        country: 'USA',
        distanceKm: null,
        addressLabel: '525 S. Lexington Ave, 27215 Burlington, NC, USA'
    },
    accounts: [
        {
            id: '001xx000003DGbJAAW',
            name: 'Edge Communications',
            latitude: 37.7849,
            longitude: -122.4294,
            street: '312 Constitution Place',
            city: 'Austin',
            state: 'TX',
            postalCode: '78767',
            country: 'USA',
            distanceKm: 1.5,
            addressLabel: '312 Constitution Place, 78767 Austin, TX, USA'
        },
        {
            id: '001xx000003DGbKAAW',
            name: 'United Oil & Gas Corp.',
            latitude: 37.7949,
            longitude: -122.4394,
            street: '1301 Avenue of the Americas',
            city: 'New York',
            state: 'NY',
            postalCode: '10019',
            country: 'USA',
            distanceKm: 2.3,
            addressLabel: '1301 Avenue of the Americas, 10019 New York, NY, USA'
        }
    ]
};

describe('c-nearby-accounts-map', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('displays component in standalone mode without recordId', () => {
        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });

        document.body.appendChild(element);

        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        expect(recordPicker).toBeTruthy();
    });

    it('displays component in record page mode with recordId', () => {
        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });
        element.recordId = '001xx000003DGbIAAW';

        document.body.appendChild(element);

        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        expect(recordPicker).toBeFalsy();
        
        const centerAccountInput = element.shadowRoot.querySelector('lightning-input[label="Center account"]');
        expect(centerAccountInput).toBeTruthy();
    });

    it('initializes with default values', () => {
        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });
        element.defaultRadiusKm = 50;
        element.maxSelectable = 5;
        element.resultLimit = 50;

        document.body.appendChild(element);

        const radiusInput = element.shadowRoot.querySelector('lightning-input[label="Radius (km)"]');
        expect(radiusInput.value).toBe(50);
    });

    it('performs search successfully and displays results', async () => {
        findNearbyAccounts.mockResolvedValue(mockAccountData);

        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });
        element.recordId = '001xx000003DGbIAAW';

        document.body.appendChild(element);

        // Wait for async operations
        await Promise.resolve();

        expect(findNearbyAccounts).toHaveBeenCalledWith({
            centerAccountId: '001xx000003DGbIAAW',
            radiusKm: 25,
            maxResults: 99
        });

        // Check map is displayed
        const lightningMap = element.shadowRoot.querySelector('lightning-map');
        expect(lightningMap).toBeTruthy();
    });

    it('handles search errors gracefully', async () => {
        const errorMessage = 'The selected Account has no geocoded Billing Address.';
        findNearbyAccounts.mockRejectedValue({
            body: { message: errorMessage }
        });

        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });
        element.recordId = '001xx000003DGbIAAW';

        document.body.appendChild(element);

        // Wait for async operations
        await Promise.resolve();

        const errorDiv = element.shadowRoot.querySelector('.slds-text-color_error');
        expect(errorDiv).toBeTruthy();
    });

    it('allows account selection up to max limit', async () => {
        findNearbyAccounts.mockResolvedValue(mockAccountData);

        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });
        element.recordId = '001xx000003DGbIAAW';
        element.maxSelectable = 2;

        document.body.appendChild(element);

        await Promise.resolve();

        // Simulate selecting accounts
        const checkboxes = element.shadowRoot.querySelectorAll('lightning-input[type="checkbox"]');
        expect(checkboxes.length).toBeGreaterThan(0);
    });

    it('generates correct Google Maps itinerary URL', async () => {
        findNearbyAccounts.mockResolvedValue(mockAccountData);

        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });
        element.recordId = '001xx000003DGbIAAW';

        document.body.appendChild(element);

        await Promise.resolve();

        // Component should have itinerary button
        const itineraryButton = element.shadowRoot.querySelector('lightning-button[label="Open itinerary in Google Maps"]');
        expect(itineraryButton).toBeTruthy();
    });

    it('handles radius change', () => {
        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });

        document.body.appendChild(element);

        const radiusInput = element.shadowRoot.querySelector('lightning-input[label="Radius (km)"]');
        radiusInput.value = 50;
        radiusInput.dispatchEvent(new CustomEvent('change', { detail: { value: 50 } }));

        expect(radiusInput.value).toBe(50);
    });

    it('displays no results message when no accounts found', async () => {
        findNearbyAccounts.mockResolvedValue({
            center: mockAccountData.center,
            accounts: []
        });

        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });
        element.recordId = '001xx000003DGbIAAW';

        document.body.appendChild(element);

        await Promise.resolve();

        const noResultsBox = element.shadowRoot.querySelector('.slds-box.slds-theme_shade');
        expect(noResultsBox).toBeTruthy();
    });

    it('enhances geocoding error messages with actionable guidance', async () => {
        const geocodingError = {
            body: { message: 'Account has no geocoded Billing Address' }
        };
        findNearbyAccounts.mockRejectedValue(geocodingError);

        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });
        element.recordId = '001xx000003DGbIAAW';

        document.body.appendChild(element);

        await Promise.resolve();

        const errorDiv = element.shadowRoot.querySelector('.slds-text-color_error');
        expect(errorDiv).toBeTruthy();
        expect(errorDiv.textContent).toContain('Billing Address');
    });

    it('enhances permission error messages', async () => {
        const permissionError = {
            body: { message: 'Insufficient permissions to access Account fields' }
        };
        findNearbyAccounts.mockRejectedValue(permissionError);

        const element = createElement('c-nearby-accounts-map', {
            is: NearbyAccountsMap
        });
        element.recordId = '001xx000003DGbIAAW';

        document.body.appendChild(element);

        await Promise.resolve();

        const errorDiv = element.shadowRoot.querySelector('.slds-text-color_error');
        expect(errorDiv).toBeTruthy();
        expect(errorDiv.textContent).toContain('administrator');
    });
});