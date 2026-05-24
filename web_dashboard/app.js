const API_BASE_URL = 'https://token-hub-backend.onrender.com/api';

const state = {
    user: null,
    token: null,
    balance: 0,
    meters: [],
    transactions: [],
    isLoggedIn: false
};

// ── DOM Elements ─────────────────────────────────────────────────────────────
const authView = document.getElementById('auth-view');
const dashboardView = document.getElementById('dashboard-view');
const loginForm = document.getElementById('login-form');
const logoutBtn = document.getElementById('logout-btn');
const modalOverlay = document.getElementById('modal-overlay');
const modalContent = document.getElementById('modal-content');
const closeModalBtn = document.querySelector('.close-modal');

// ── Initialization ────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    setupEventListeners();
});

function checkAuth() {
    const savedToken = localStorage.getItem('token');
    const savedUser = JSON.parse(localStorage.getItem('user'));

    if (savedToken && savedUser) {
        state.token = savedToken;
        state.user = savedUser;
        state.isLoggedIn = true;
        showView('dashboard');
        loadDashboardData();
        startConsumptionSimulation();
    } else {
        showView('auth');
    }
}

function showView(viewName) {
    authView.classList.add('hidden');
    dashboardView.classList.add('hidden');
    
    if (viewName === 'auth') authView.classList.remove('hidden');
    if (viewName === 'dashboard') dashboardView.classList.remove('hidden');
}

// ── Auth Logic ────────────────────────────────────────────────────────────────
async function handleLogin(e) {
    e.preventDefault();
    const phone = document.getElementById('login-phone').value;
    const password = document.getElementById('login-password').value;
    const loginBtn = document.getElementById('login-btn');
    const btnText = loginBtn.querySelector('.btn-text');
    const loader = loginBtn.querySelector('.loader');

    // UI Loading state
    btnText.classList.add('hidden');
    loader.classList.remove('hidden');
    loginBtn.disabled = true;

    try {
        const response = await fetch(`${API_BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ phone, password })
        });

        const data = await response.json();

        if (response.ok) {
            localStorage.setItem('token', data.token);
            localStorage.setItem('user', JSON.stringify({
                id: data._id,
                name: data.name,
                phone: data.phone
            }));
            checkAuth();
        } else {
            alert(data.message || 'Login failed');
        }
    } catch (error) {
        alert('Network error. Is the server online?');
    } finally {
        btnText.classList.remove('hidden');
        loader.classList.add('hidden');
        loginBtn.disabled = false;
    }
}

function handleLogout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    state.isLoggedIn = false;
    location.reload();
}

// ── Data Loading ─────────────────────────────────────────────────────────────
async function loadDashboardData() {
    if (!state.isLoggedIn) return;

    document.getElementById('user-name').textContent = state.user.name;

    // Parallel Fetching
    try {
        const [balanceRes, metersRes, txRes] = await Promise.all([
            fetch(`${API_BASE_URL}/auth/sync-balance`, {
                method: 'POST',
                headers: { 
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${state.token}`
                },
                body: JSON.stringify({ userId: state.user.id })
            }),
            fetch(`${API_BASE_URL}/meters`, {
                headers: { 'Authorization': `Bearer ${state.token}` }
            }),
            fetch(`${API_BASE_URL}/transactions`, {
                headers: { 'Authorization': `Bearer ${state.token}` }
            })
        ]);

        const balanceData = await balanceRes.json();
        const metersData = await metersRes.json();
        const txData = await txRes.json();

        if (balanceRes.ok) {
            state.balance = balanceData.balance;
            updateBalanceUI();
        }
        
        if (metersRes.ok) state.meters = metersData;
        if (txRes.ok) renderTransactions(txData);

    } catch (error) {
        console.error('Data sync failed', error);
    }
}

function updateBalanceUI() {
    const el = document.getElementById('balance-value');
    if (el) el.textContent = state.balance.toFixed(2);
}

function renderTransactions(transactions) {
    const list = document.getElementById('transaction-list');
    if (!list) return;

    if (transactions.length === 0) {
        list.innerHTML = '<div class="empty-state">No recent transactions</div>';
        return;
    }

    list.innerHTML = transactions.slice(0, 5).map(tx => `
        <div class="tx-item">
            <div class="tx-info">
                <h4>${tx.title || 'Token Purchase'}</h4>
                <p>${new Date(tx.timestamp).toLocaleString()}</p>
            </div>
            <div class="tx-amount">
                <span class="amt">KES ${tx.amount}</span>
                <span class="status text-success">${tx.isSuccess ? 'SUCCESS' : 'FAILED'}</span>
            </div>
        </div>
    `).join('');
}

// ── Real-time Simulation ─────────────────────────────────────────────────────
function startConsumptionSimulation() {
    setInterval(() => {
        if (state.balance > 0.01) {
            state.balance -= 0.0005; // slow drip for web demo
            updateBalanceUI();
            
            // Randomize live stats
            document.getElementById('live-voltage').textContent = (229 + Math.random() * 3).toFixed(1) + 'V';
            document.getElementById('live-load').textContent = (0.3 + Math.random() * 0.5).toFixed(2) + 'kW';
        }
    }, 2000);
}

// ── Modals & Actions ──────────────────────────────────────────────────────────
function showModal(type) {
    modalOverlay.classList.remove('hidden');
    
    if (type === 'buy') {
        modalContent.innerHTML = `
            <div class="modal-header">
                <h2>Buy Token</h2>
                <p>Instant M-Pesa STK Push</p>
            </div>
            <div class="modal-body">
                <div class="input-group">
                    <label>Meter Number</label>
                    <select id="buy-meter-select">
                        ${state.meters.map(m => `<option value="${m.number}">${m.name} (${m.number})</option>`).join('')}
                    </select>
                </div>
                <div class="input-group">
                    <label>Amount (KES)</label>
                    <input type="number" id="buy-amount" value="500" min="50">
                </div>
                <button class="btn-primary full-width" id="confirm-purchase">Initialize Payment</button>
            </div>
        `;
        
        document.getElementById('confirm-purchase').onclick = handlePurchase;
    }

    if (type === 'add-meter') {
        modalContent.innerHTML = `
            <div class="modal-header">
                <h2>Add Meter</h2>
                <p>Register a new KPLC meter</p>
            </div>
            <div class="modal-body">
                <div class="input-group">
                    <label>Meter Number</label>
                    <input type="text" id="new-meter-num" placeholder="14xxxxxxxx">
                </div>
                <div class="input-group">
                    <label>Nickname</label>
                    <input type="text" id="new-meter-name" placeholder="e.g. My Home">
                </div>
                <button class="btn-primary full-width" id="confirm-add-meter">Link Meter</button>
            </div>
        `;
        document.getElementById('confirm-add-meter').onclick = handleAddMeter;
    }
}

async function handlePurchase() {
    const meterNumber = document.getElementById('buy-meter-select').value;
    const amount = document.getElementById('buy-amount').value;
    const btn = document.getElementById('confirm-purchase');

    btn.textContent = 'Processing...';
    btn.disabled = true;

    try {
        const response = await fetch(`${API_BASE_URL}/transactions/stk-push`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${state.token}`
            },
            body: JSON.stringify({ 
                amount: parseFloat(amount), 
                meterNumber, 
                phoneNumber: state.user.phone 
            })
        });

        if (response.ok) {
            alert('STK Push sent to your phone! Please complete the payment.');
            closeModal();
            loadDashboardData();
        } else {
            const err = await response.json();
            alert(err.message || 'Payment initiation failed');
        }
    } catch (e) {
        alert('Payment error');
    } finally {
        btn.textContent = 'Initialize Payment';
        btn.disabled = false;
    }
}

async function handleAddMeter() {
    const number = document.getElementById('new-meter-num').value;
    const name = document.getElementById('new-meter-name').value;

    try {
        const response = await fetch(`${API_BASE_URL}/meters`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${state.token}`
            },
            body: JSON.stringify({ name, number })
        });

        if (response.ok) {
            alert('Meter linked successfully!');
            closeModal();
            loadDashboardData();
        } else {
            const err = await response.json();
            alert(err.message || 'Failed to link meter');
        }
    } catch (e) {
        alert('Network error');
    }
}

function closeModal() {
    modalOverlay.classList.add('hidden');
}

// ── Event Listeners ───────────────────────────────────────────────────────────
function setupEventListeners() {
    loginForm.addEventListener('submit', handleLogin);
    logoutBtn.addEventListener('click', handleLogout);
    closeModalBtn.addEventListener('click', closeModal);
    
    document.getElementById('btn-buy-token').onclick = () => showModal('buy');
    document.getElementById('btn-add-meter').onclick = () => showModal('add-meter');
    
    // Toggle password visibility
    document.querySelectorAll('.toggle-password').forEach(btn => {
        btn.onclick = () => {
            const input = btn.previousElementSibling;
            const type = input.type === 'password' ? 'text' : 'password';
            input.type = type;
            btn.innerHTML = `<i class="fas fa-eye${type === 'password' ? '' : '-slash'}"></i>`;
        };
    });
}
