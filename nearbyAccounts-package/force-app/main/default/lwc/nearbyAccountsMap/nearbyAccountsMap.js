import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import findNearbyAccounts from '@salesforce/apex/NearbyAccountsController.findNearbyAccounts';

/**
 * @description Lightning Web Component for finding and mapping nearby accounts based on geolocation
 * Displays accounts within a specified radius on an interactive map with itinerary generation
 * @author Joakim JAN
 * @date 2026-04-15
 */
export default class NearbyAccountsMap extends LightningElement {
    _recordId;

    /**
     * @api
     * @type {number}
     * @description Default search radius in kilometers
     */
    @api defaultRadiusKm = 25;
    
    /**
     * @api
     * @type {number}
     * @description Maximum number of accounts that can be selected for itinerary
     */
    @api maxSelectable = 10;
    
    /**
     * @api
     * @type {number}
     * @description Maximum number of results to return from search (capped at 99)
     */
    @api resultLimit = 99;

    selectedAccountId;
    radiusKm = 25;

    centerAccount;
    results = [];
    mapMarkers = [];
    selectedMarkerValue;

    selectedAccountIds = [];

    isLoading = false;
    hasSearched = false;
    errorMessage;

    // Wire adapter to fetch account name immediately
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME_FIELD] })
    wiredAccount;

    connectedCallback() {
        this.radiusKm = Number(this.defaultRadiusKm) || 25;
        this.maxSelectable = Number(this.maxSelectable) || 10;
        this.resultLimit = Math.min(Number(this.resultLimit) || 99, 99);
    }

    /**
     * @api
     * @type {string}
     * @description The record ID of the account (when used on a record page)
     */
    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;

        if (value && value !== this.selectedAccountId) {
            this.selectedAccountId = value;
            this.hasSearched = false;
            this.search();
        }
    }

    get isStandalone() {
        return !this.recordId;
    }

    get hasResults() {
        return this.results.length > 0;
    }

    get showInitialState() {
        return !this.hasSearched && !this.isLoading;
    }

    get centerAccountName() {
        // For record pages: use wire data for immediate display
        if (this.recordId && this.wiredAccount?.data) {
            return getFieldValue(this.wiredAccount.data, ACCOUNT_NAME_FIELD) || '';
        }
        // Fallback to search result for standalone mode or after search completes
        return this.centerAccount?.name || '';
    }

    get selectionSummary() {
        return this.selectedAccountIds.length
            ? `${this.selectedAccountIds.length} / ${this.maxSelectable} selected for itinerary`
            : '';
    }

    get isItineraryDisabled() {
        return !this.itineraryUrl;
    }

    get itineraryUrl() {
        if (!this.centerAccount || !this.selectedAccountIds.length) {
            return null;
        }

        const orderedStops = this.selectedAccountIds
            .map((id) => this.results.find((acc) => acc.id === id))
            .filter(Boolean);

        if (!orderedStops.length) {
            return null;
        }

        const origin = this.toCoordString(this.centerAccount);

        if (orderedStops.length === 1) {
            const destination = this.toCoordString(orderedStops[0]);
            return `https://www.google.com/maps/dir/?api=1&origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&travelmode=driving`;
        }

        const destination = this.toCoordString(orderedStops[orderedStops.length - 1]);
        const waypoints = orderedStops
            .slice(0, -1)
            .map((acc) => this.toCoordString(acc))
            .join('|');

        let url = `https://www.google.com/maps/dir/?api=1&origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&travelmode=driving`;

        if (waypoints) {
            url += `&waypoints=${encodeURIComponent(waypoints)}`;
        }

        return url;
    }

    handleAccountSelect(event) {
        this.selectedAccountId = event.detail.recordId;
    }

    handleRadiusChange(event) {
        this.radiusKm = Number(event.target.value);
    }

    handleSearchClick() {
        this.search();
    }

    async search() {
        if (!this.selectedAccountId) {
            this.showToast('Missing account', 'Select an Account first.', 'warning');
            return;
        }

        if (!this.radiusKm || this.radiusKm <= 0) {
            this.showToast('Invalid radius', 'Radius must be greater than 0 km.', 'warning');
            return;
        }

        this.isLoading = true;
        this.errorMessage = null;

        try {
            const data = await findNearbyAccounts({
                centerAccountId: this.selectedAccountId,
                radiusKm: this.radiusKm,
                maxResults: this.resultLimit
            });

            this.centerAccount = data.center;
            this.selectedAccountIds = [];

            this.results = (data.accounts || []).map((acc) => {
                const distance = acc.distanceKm !== null && acc.distanceKm !== undefined
                    ? Number(acc.distanceKm)
                    : 0;

                return {
                    ...acc,
                    distanceLabel: `${distance.toFixed(1)} km`,
                    checked: false,
                    checkboxDisabled: false,
                    selectionOrder: '',
                    rowClass: 'result-row'
                };
            });

            this.mapMarkers = [
                this.toMarker(data.center, true),
                ...this.results.map((acc) => this.toMarker(acc, false))
            ].filter(Boolean);

            this.selectedMarkerValue = data.center?.id;
            this.hasSearched = true;

            this.refreshComputedState();
        } catch (error) {
            this.centerAccount = null;
            this.results = [];
            this.mapMarkers = [];
            this.selectedAccountIds = [];
            this.selectedMarkerValue = null;
            this.hasSearched = true;
            this.errorMessage = this.reduceError(error);

            this.showToast('Search error', this.errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleToggleSelect(event) {
        const accountId = event.target.dataset.id;
        const isChecked = event.target.checked;

        if (isChecked) {
            if (this.selectedAccountIds.length >= this.maxSelectable) {
                event.target.checked = false;
                this.showToast(
                    'Selection limit reached',
                    `You can select up to ${this.maxSelectable} accounts.`,
                    'warning'
                );
                return;
            }

            this.selectedAccountIds = [...this.selectedAccountIds, accountId];
        } else {
            this.selectedAccountIds = this.selectedAccountIds.filter((id) => id !== accountId);
        }

        this.refreshComputedState();
    }

    handleFocusMarker(event) {
        this.selectedMarkerValue = event.currentTarget.dataset.id;
        this.refreshComputedState();
    }

    handleMarkerSelect(event) {
        this.selectedMarkerValue = event.detail.selectedMarkerValue;
        this.refreshComputedState();
    }

    handleOpenGoogleMaps() {
        if (this.itineraryUrl) {
            window.open(this.itineraryUrl, '_blank');
        }
    }

    refreshComputedState() {
        const selectedSet = new Set(this.selectedAccountIds);

        this.results = this.results.map((acc) => {
            const isSelected = selectedSet.has(acc.id);
            const selectionOrder = isSelected
                ? String(this.selectedAccountIds.indexOf(acc.id) + 1)
                : '';

            return {
                ...acc,
                checked: isSelected,
                checkboxDisabled:
                    !isSelected && this.selectedAccountIds.length >= this.maxSelectable,
                selectionOrder,
                rowClass:
                    this.selectedMarkerValue === acc.id
                        ? 'result-row result-row--active'
                        : 'result-row'
            };
        });
    }

    toMarker(acc, isCenter) {
        if (!acc?.latitude || !acc?.longitude) {
            return null;
        }

        return {
            location: {
                Latitude: acc.latitude,
                Longitude: acc.longitude
            },
            title: isCenter ? `${acc.name} (Center)` : acc.name,
            description: isCenter
                ? acc.addressLabel || ''
                : `${acc.distanceLabel} • ${acc.addressLabel || ''}`,
            value: acc.id
        };
    }

    toCoordString(acc) {
        return `${acc.latitude},${acc.longitude}`;
    }

    /**
     * @description Reduces error object to user-friendly message with actionable guidance
     * @param {Object} error The error object from Apex or platform
     * @returns {string} User-friendly error message
     */
    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }

        const errorMsg = error?.body?.message || error?.message || 'Unknown error';
        
        // Geocoding errors - provide specific guidance
        if (errorMsg.includes('geocoded') || errorMsg.includes('Latitude') || errorMsg.includes('Longitude')) {
            return `${errorMsg}\n\nTo fix this: Go to the Account record → Edit → Enter a complete Billing Address → Save. Salesforce will automatically geocode the address.`;
        }
        
        // Permission errors - direct to admin
        if (errorMsg.includes('permission') || errorMsg.includes('access') || errorMsg.includes('Insufficient')) {
            return `${errorMsg}\n\nContact your Salesforce administrator to grant access to required Account fields.`;
        }
        
        // Missing prerequisites
        if (errorMsg.includes('Maps') || errorMsg.includes('location')) {
            return `${errorMsg}\n\nEnsure Maps and Location Services are enabled in Setup.`;
        }

        return errorMsg;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}