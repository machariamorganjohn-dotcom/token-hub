// rent.js - Rent Management Module Logic

let rentState = {
    properties: [],
    units: [],
    tenants: [],
    payments: [],
    stats: null
};

// Elements
const navEnergy = document.getElementById('nav-energy');
const navRent = document.getElementById('nav-rent');
const energyMain = document.getElementById('energy-main');
const rentMain = document.getElementById('rent-main');

// Event Listeners for Nav
if (navEnergy && navRent) {
    navEnergy.addEventListener('click', () => {
        navEnergy.classList.add('active');
        navRent.classList.remove('active');
        energyMain.classList.remove('hidden');
        rentMain.classList.add('hidden');
    });

    navRent.addEventListener('click', () => {
        navRent.classList.add('active');
        navEnergy.classList.remove('active');
        rentMain.classList.remove('hidden');
        energyMain.classList.add('hidden');
        loadRentData(); // Load data when switching to rent tab
    });
}

// Data Loading
async function loadRentData() {
    if (!state.isLoggedIn) return;

    try {
        const [dashRes, propsRes, unitsRes, tenantsRes, paymentsRes] = await Promise.all([
            fetch(`${API_BASE_URL}/rent/dashboard`, { headers: { 'Authorization': `Bearer ${state.token}` } }),
            fetch(`${API_BASE_URL}/rent/properties`, { headers: { 'Authorization': `Bearer ${state.token}` } }),
            // fetch units could be per property, but we might just fetch dashboard stats first
            // for MVP let's just fetch tenants and payments for the recent list
            fetch(`${API_BASE_URL}/rent/tenants`, { headers: { 'Authorization': `Bearer ${state.token}` } }),
            fetch(`${API_BASE_URL}/rent/payments`, { headers: { 'Authorization': `Bearer ${state.token}` } })
        ]);

        if (dashRes.ok) {
            rentState.stats = await dashRes.json();
            updateRentDashboardUI();
        }
        if (propsRes.ok) rentState.properties = await propsRes.json();
        if (tenantsRes.ok) rentState.tenants = await tenantsRes.json();
        if (paymentsRes.ok) {
            rentState.payments = await paymentsRes.json();
            renderRentPayments(rentState.payments);
        }

    } catch (e) {
        console.error('Failed to load rent data', e);
    }
}

function updateRentDashboardUI() {
    if (!rentState.stats) return;
    document.getElementById('rent-total-properties').textContent = rentState.stats.totalProperties;
    document.getElementById('rent-total-units').textContent = rentState.stats.totalUnits;
    document.getElementById('rent-occupied-units').textContent = rentState.stats.occupiedUnits;
    document.getElementById('rent-monthly-collected').textContent = `KES ${rentState.stats.monthlyRentCollected.toLocaleString()}`;
    document.getElementById('rent-outstanding').textContent = `KES ${rentState.stats.outstandingBalances.toLocaleString()}`;
}

function renderRentPayments(payments) {
    const list = document.getElementById('rent-transaction-list');
    if (!list) return;

    if (payments.length === 0) {
        list.innerHTML = '<div class="empty-state">No recent payments</div>';
        return;
    }

    list.innerHTML = payments.slice(0, 5).map(p => `
        <div class="tx-item">
            <div class="tx-info">
                <h4>${p.tenantId?.name || 'Unknown Tenant'}</h4>
                <p>Unit ${p.unitId?.unitNumber || ''} • ${new Date(p.date).toLocaleDateString()}</p>
                <small class="receipt-text">Receipt: ${p.receiptNumber}</small>
            </div>
            <div class="tx-amount">
                <span class="amt">KES ${p.amount}</span>
                <span class="status text-success">${p.paymentMethod}</span>
            </div>
        </div>
    `).join('');
}

// Modals
document.getElementById('btn-add-property').onclick = () => showRentModal('add-property');
document.getElementById('btn-add-rent-unit').onclick = () => showRentModal('add-unit');
document.getElementById('btn-add-tenant').onclick = () => showRentModal('add-tenant');
document.getElementById('btn-record-payment').onclick = () => showRentModal('record-payment');
document.getElementById('refresh-rent').onclick = () => loadRentData();

function showRentModal(type) {
    modalOverlay.classList.remove('hidden');

    if (type === 'add-property') {
        modalContent.innerHTML = `
            <div class="modal-header">
                <h2>Add Property</h2>
                <p>Create a new property/building</p>
            </div>
            <div class="modal-body">
                <div class="input-group">
                    <label>Property Name</label>
                    <input type="text" id="prop-name" placeholder="e.g. Sunset Apartments">
                </div>
                <div class="input-group">
                    <label>Location</label>
                    <input type="text" id="prop-loc" placeholder="e.g. Westlands, Nairobi">
                </div>
                <button class="btn-primary full-width" id="confirm-add-prop">Create Property</button>
            </div>
        `;
        document.getElementById('confirm-add-prop').onclick = handleAddProperty;
    }

    if (type === 'add-unit') {
        modalContent.innerHTML = `
            <div class="modal-header">
                <h2>Add Unit</h2>
                <p>Add a room/apartment to a property</p>
            </div>
            <div class="modal-body">
                <div class="input-group">
                    <label>Select Property</label>
                    <select id="unit-prop-id">
                        ${rentState.properties.map(p => `<option value="${p._id}">${p.name}</option>`).join('')}
                    </select>
                </div>
                <div class="input-group">
                    <label>Unit Number</label>
                    <input type="text" id="unit-num" placeholder="e.g. A1, 104">
                </div>
                <div class="input-group">
                    <label>Unit Type</label>
                    <select id="unit-type">
                        <option>Bedsitter</option>
                        <option>Single Room</option>
                        <option>1 Bedroom</option>
                        <option>2 Bedroom</option>
                        <option>3 Bedroom</option>
                    </select>
                </div>
                <div class="input-group">
                    <label>Rent Amount (KES)</label>
                    <input type="number" id="unit-rent" placeholder="15000">
                </div>
                <button class="btn-primary full-width" id="confirm-add-unit">Add Unit</button>
            </div>
        `;
        document.getElementById('confirm-add-unit').onclick = handleAddUnit;
    }

    if (type === 'add-tenant') {
        // Need to fetch units for the dropdown, but for MVP we might just do a combined fetch or an endpoint
        // To keep it simple, we'll ask user to type Unit ID or we could fetch vacant units.
        // For simplicity, let's just make a generic modal and we assume they know the unit or we fetch it.
        fetchUnitsForDropdown();
        modalContent.innerHTML = `
            <div class="modal-header">
                <h2>Add Tenant</h2>
                <p>Register a new tenant to a unit</p>
            </div>
            <div class="modal-body">
                <div class="input-group">
                    <label>Tenant Name</label>
                    <input type="text" id="t-name" placeholder="John Doe">
                </div>
                <div class="input-group">
                    <label>Phone Number</label>
                    <input type="text" id="t-phone" placeholder="07...">
                </div>
                <div class="input-group">
                    <label>Select Unit</label>
                    <select id="t-unit-id"><option>Loading units...</option></select>
                </div>
                <button class="btn-primary full-width" id="confirm-add-tenant">Save Tenant</button>
            </div>
        `;
        document.getElementById('confirm-add-tenant').onclick = handleAddTenant;
    }

    if (type === 'record-payment') {
        modalContent.innerHTML = `
            <div class="modal-header">
                <h2>Record Payment</h2>
                <p>Log a received rent payment</p>
            </div>
            <div class="modal-body">
                <div class="input-group">
                    <label>Select Tenant</label>
                    <select id="pay-tenant-id">
                        ${rentState.tenants.map(t => `<option value="${t._id}">${t.name} (${t.unitId?.unitNumber})</option>`).join('')}
                    </select>
                </div>
                <div class="input-group">
                    <label>Amount Received (KES)</label>
                    <input type="number" id="pay-amount" placeholder="15000">
                </div>
                <div class="input-group">
                    <label>Payment Method</label>
                    <select id="pay-method">
                        <option>M-Pesa</option>
                        <option>Cash</option>
                        <option>Bank Transfer</option>
                    </select>
                </div>
                <button class="btn-primary full-width" id="confirm-record-pay">Save Payment</button>
            </div>
        `;
        document.getElementById('confirm-record-pay').onclick = handleRecordPayment;
    }
}

async function fetchUnitsForDropdown() {
    try {
        // Fetching all properties, then we could fetch units. For MVP, we'll just fetch units of the first property or all
        const sel = document.getElementById('t-unit-id');
        if (!sel || rentState.properties.length === 0) return;
        
        const res = await fetch(`${API_BASE_URL}/rent/units/${rentState.properties[0]._id}`, { headers: { 'Authorization': `Bearer ${state.token}` } });
        const units = await res.json();
        sel.innerHTML = units.filter(u => u.status === 'Vacant').map(u => `<option value="${u._id}">${u.unitNumber} (${u.type})</option>`).join('');
        if (sel.innerHTML === '') sel.innerHTML = '<option disabled>No vacant units</option>';
    } catch (e) {
        console.error(e);
    }
}

// Handlers
async function handleAddProperty() {
    const name = document.getElementById('prop-name').value;
    const location = document.getElementById('prop-loc').value;
    await apiPost('/rent/properties', { name, location });
}

async function handleAddUnit() {
    const propertyId = document.getElementById('unit-prop-id').value;
    const unitNumber = document.getElementById('unit-num').value;
    const type = document.getElementById('unit-type').value;
    const rentAmount = document.getElementById('unit-rent').value;
    await apiPost('/rent/units', { propertyId, unitNumber, type, rentAmount });
}

async function handleAddTenant() {
    const name = document.getElementById('t-name').value;
    const phone = document.getElementById('t-phone').value;
    const unitId = document.getElementById('t-unit-id').value;
    await apiPost('/rent/tenants', { name, phone, unitId });
}

async function handleRecordPayment() {
    const tenantId = document.getElementById('pay-tenant-id').value;
    const amount = document.getElementById('pay-amount').value;
    const paymentMethod = document.getElementById('pay-method').value;
    await apiPost('/rent/payments', { tenantId, amount, paymentMethod });
}

async function apiPost(endpoint, body) {
    try {
        const res = await fetch(`${API_BASE_URL}${endpoint}`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${state.token}`
            },
            body: JSON.stringify(body)
        });
        if (res.ok) {
            alert('Success!');
            closeModal();
            loadRentData();
        } else {
            const err = await res.json();
            alert(err.message || 'Error occurred');
        }
    } catch (e) {
        alert('Network Error');
    }
}
