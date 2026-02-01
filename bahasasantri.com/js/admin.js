import { db } from './config.js';
import { collection, doc, setDoc, deleteDoc, updateDoc, onSnapshot } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";
import { state } from './state.js';

export function initAdmin() {
    // Expose Tab Switcher
    window.switchAdminTab = (tab) => {
        ['ujian', 'tes', 'ranking', 'akun'].forEach(t => {
            const content = document.getElementById('admin-tab-' + t);
            const btn = document.getElementById('btn-tab-' + t);
            if (content && btn) {
                content.classList.add('hidden');
                btn.classList.remove('bg-brand-primary', 'text-white', 'shadow-md');
                btn.classList.add('text-gray-400', 'hover:bg-gray-100');
            }
        });

        const target = document.getElementById('admin-tab-' + tab);
        const targetBtn = document.getElementById('btn-tab-' + tab);
        if (target && targetBtn) {
            target.classList.remove('hidden');
            targetBtn.classList.remove('text-gray-400', 'hover:bg-gray-100');
            targetBtn.classList.add('bg-brand-primary', 'text-white', 'shadow-md');
        }
    };

    // Listen to Realtime Updates
    const unsub = onSnapshot(collection(db, "santri_users"), (snapshot) => {
        state.users = { '00': { name: 'Super Admin', role: 'admin' } }; // Reset but keep Admin
        state.userList = [];

        snapshot.forEach(doc => {

            const data = doc.data();
            state.users[doc.id] = { id: doc.id, ...data }; // Include ID in object
            state.userList.push({ id: doc.id, ...data }); // For Table display
        });

        renderUserList();
        renderRanking();
    });

    // Render Static Vocab
    renderVocabList();

    // Form Handler
    const form = document.getElementById('admin-form');
    if (form) {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            const code = document.getElementById('input-code').value.trim();
            const name = document.getElementById('input-name').value.trim();

            if (code && name) {
                if (code === '00') { alert("Kode 00 dilindungi."); return; }
                await addSantri(code, name);
                form.reset();
            }
        });
    }
}

async function addSantri(code, name) {
    try {
        await setDoc(doc(db, "santri_users", code), {
            name: name,
            role: 'student',
            highscore: 0,
            createdAt: new Date().toISOString()
        });
        alert(`Santri ${name} (${code}) berhasil ditambahkan!`);
    } catch (e) {
        console.error("Error adding:", e);
        alert("Gagal menambah santri: " + e.message);
    }
}

// Pending action state
let pendingAction = { type: null, code: null, name: null };

// Show dialog helper
function showAdminDialog(dialogId, code, name) {
    pendingAction = { type: dialogId, code, name };
    const dialog = document.getElementById(dialogId);
    if (dialog) {
        // Update user name in dialog
        const nameEl = dialog.querySelector('[id$="-user-name"]');
        if (nameEl) nameEl.textContent = `${name} (${code})`;
        dialog.classList.remove('hidden');
        dialog.classList.add('flex');
    }
}

// Close dialog helper (exposed to window)
window.closeAdminDialog = function (dialogId) {
    const dialog = document.getElementById(dialogId);
    if (dialog) {
        dialog.classList.add('hidden');
        dialog.classList.remove('flex');
    }
    pendingAction = { type: null, code: null, name: null };
}

// Delete santri - show dialog
export function deleteSantri(code) {
    const user = state.userList.find(u => u.id === code);
    const name = user?.name || 'Unknown';
    showAdminDialog('admin-delete-dialog', code, name);
}

// Confirm delete (exposed to window)
window.confirmDeleteUser = async function () {
    if (!pendingAction.code) return;
    try {
        await deleteDoc(doc(db, "santri_users", pendingAction.code));
        closeAdminDialog('admin-delete-dialog');
    } catch (e) {
        console.error("Error delete:", e);
        alert("Gagal hapus: " + e.message);
    }
}

// Reset score - show dialog
function resetUserScore(code) {
    const user = state.userList.find(u => u.id === code);
    const name = user?.name || 'Unknown';
    showAdminDialog('admin-reset-dialog', code, name);
}

// Confirm reset BAHASA score (exposed to window)
window.confirmResetBahasaScore = async function () {
    if (!pendingAction.code) return;
    try {
        await updateDoc(doc(db, "santri_users", pendingAction.code), {
            highscore: 0
        });
        closeAdminDialog('admin-reset-dialog');
    } catch (e) {
        console.error("Error reset bahasa:", e);
        alert("Gagal reset skor bahasa: " + e.message);
    }
}

// Confirm reset MATH score (exposed to window)
window.confirmResetMathScore = async function () {
    if (!pendingAction.code) return;
    try {
        await updateDoc(doc(db, "santri_users", pendingAction.code), {
            mathWins: 0
        });
        closeAdminDialog('admin-reset-dialog');
    } catch (e) {
        console.error("Error reset math:", e);
        alert("Gagal reset skor matematika: " + e.message);
    }
}

// Unlock exam - show dialog
function resetExamStatus(code) {
    const user = state.userList.find(u => u.id === code);
    const name = user?.name || 'Unknown';
    showAdminDialog('admin-unlock-dialog', code, name);
}

// Confirm unlock exam (exposed to window)
window.confirmUnlockExam = async function () {
    if (!pendingAction.code) return;
    try {
        await updateDoc(doc(db, "santri_users", pendingAction.code), {
            lastExamDate: null
        });
        closeAdminDialog('admin-unlock-dialog');
    } catch (e) {
        console.error("Error unlock:", e);
        alert("Gagal buka kunci: " + e.message);
    }
}

function renderVocabList() {
    const tbody = document.getElementById('admin-vocab-list');
    if (!tbody) return;

    tbody.innerHTML = '';
    // Use state.vocabulary which is already loaded by app.js -> fetchVocab
    state.vocabulary.forEach((v, i) => {
        const tr = document.createElement('tr');
        tr.className = "border-b border-gray-100 text-sm hover:bg-gray-50";
        tr.innerHTML = `
            <td class="p-3 text-gray-500 text-center">${i + 1}</td>
            <td class="p-3 font-bold text-brand-dark">${v.en}</td>
            <td class="p-3 text-gray-600">${v.id}</td>
        `;
        tbody.appendChild(tr);
    });
}

function renderRanking() {
    const tbody = document.getElementById('admin-ranking-list');
    if (!tbody) return;

    tbody.innerHTML = '';
    const sorted = [...state.userList].sort((a, b) => (b.highscore || 0) - (a.highscore || 0));

    sorted.forEach((u, i) => {
        const tr = document.createElement('tr');
        let badge = '';
        if (i === 0) badge = '🥇';
        else if (i === 1) badge = '🥈';
        else if (i === 2) badge = '🥉';

        tr.className = "border-b border-gray-100 hover:bg-yellow-50 transition-colors";
        tr.innerHTML = `
            <td class="p-4 font-bold text-center">${badge || (i + 1)}</td>
            <td class="p-4 font-bold text-brand-dark flex items-center gap-2">
                ${u.name} 
                <span class="text-[10px] bg-gray-100 px-2 rounded-full text-gray-500">${u.id}</span>
            </td>
            <td class="p-4 text-right font-black text-brand-primary">${u.highscore || 0}</td>
        `;
        tbody.appendChild(tr);
    });
}

// Admin Math Ranking
function renderMathRanking() {
    const tbody = document.getElementById('admin-math-ranking-list');
    if (!tbody) return;

    tbody.innerHTML = '';
    const sorted = [...state.userList]
        .filter(u => (u.mathWins || 0) > 0)
        .sort((a, b) => (b.mathWins || 0) - (a.mathWins || 0));

    if (sorted.length === 0) {
        tbody.innerHTML = '<tr><td colspan="3" class="p-4 text-center text-gray-400">Belum ada data ranking</td></tr>';
        return;
    }

    sorted.forEach((u, i) => {
        const tr = document.createElement('tr');
        let badge = '';
        if (i === 0) badge = '🥇';
        else if (i === 1) badge = '🥈';
        else if (i === 2) badge = '🥉';

        tr.className = "border-b border-gray-100 hover:bg-blue-50 transition-colors";
        tr.innerHTML = `
            <td class="p-4 font-bold text-center">${badge || (i + 1)}</td>
            <td class="p-4 font-bold text-brand-dark flex items-center gap-2">
                ${u.name} 
                <span class="text-[10px] bg-gray-100 px-2 rounded-full text-gray-500">${u.id}</span>
            </td>
            <td class="p-4 text-right font-black text-blue-500">${u.mathWins || 0} 🏆</td>
        `;
        tbody.appendChild(tr);
    });
}

// Switch Admin Ranking Tab
window.switchAdminRankingTab = function (tab) {
    const bahasaTab = document.getElementById('admin-rank-tab-bahasa');
    const mathTab = document.getElementById('admin-rank-tab-math');
    const bahasaContent = document.getElementById('admin-rank-bahasa');
    const mathContent = document.getElementById('admin-rank-math');

    if (tab === 'bahasa') {
        bahasaTab.className = 'flex-1 py-2 px-4 rounded-xl font-bold text-sm bg-brand-primary text-white transition-all';
        mathTab.className = 'flex-1 py-2 px-4 rounded-xl font-bold text-sm bg-gray-100 text-gray-500 transition-all';
        bahasaContent.classList.remove('hidden');
        mathContent.classList.add('hidden');
    } else {
        mathTab.className = 'flex-1 py-2 px-4 rounded-xl font-bold text-sm bg-blue-500 text-white transition-all';
        bahasaTab.className = 'flex-1 py-2 px-4 rounded-xl font-bold text-sm bg-gray-100 text-gray-500 transition-all';
        mathContent.classList.remove('hidden');
        bahasaContent.classList.add('hidden');

        // Render math ranking
        renderMathRanking();
    }
}

function getWeekStart() {
    const d = new Date();
    const day = d.getDay(); // 0=Sun, 1=Mon, ...
    const diff = d.getDate() - day + (day == 0 ? -6 : 1);
    const monday = new Date(d.setDate(diff));
    monday.setHours(0, 1, 0, 0);
    return monday;
}

function renderUserList() {
    const tbody = document.getElementById('admin-user-list');
    if (!tbody) return;

    tbody.innerHTML = '';
    const weekStart = getWeekStart();

    state.userList.sort((a, b) => a.id.localeCompare(b.id)).forEach(u => {
        const last = u.lastExamDate ? new Date(u.lastExamDate) : null;
        const isLocked = last && last > weekStart;

        let examStatus = '<span class="text-green-500 text-xs border border-green-200 bg-green-50 px-2 py-1 rounded-lg">Bisa Ujian ⭕</span>';
        let lockIcon = 'fa-unlock';
        let lockClass = 'text-green-400 hover:text-green-600 hover:bg-green-50';
        let lockTitle = 'Ujian Tersedia';

        if (isLocked) {
            examStatus = '<span class="text-gray-400 text-xs border border-gray-200 bg-gray-50 px-2 py-1 rounded-lg">Sudah ✅</span>';
            lockIcon = 'fa-lock';
            lockClass = 'text-blue-400 hover:text-blue-600 hover:bg-blue-50';
            lockTitle = 'Buka Kunci Ujian';
        }

        const tr = document.createElement('tr');
        tr.className = "border-b border-gray-100 hover:bg-gray-50 transition-colors";
        tr.innerHTML = `
            <td class="p-4 font-bold text-brand-dark">${u.id}</td>
            <td class="p-4 text-gray-600">
                <div class="font-bold flex items-center gap-2">
                    ${u.name}
                    ${examStatus}
                </div>
                <div class="text-xs text-gray-400">Skor: ${u.highscore || 0}</div>
            </td>
            <td class="p-4 text-right flex justify-end gap-2">
                <button class="btn-reset-exam ${lockClass} p-2 rounded-lg transition-all" data-id="${u.id}" data-locked="${isLocked}" title="${lockTitle}">
                    <i class="fas ${lockIcon}"></i>
                </button>
                <button class="btn-reset text-orange-400 hover:text-orange-600 hover:bg-orange-50 p-2 rounded-lg transition-all" data-id="${u.id}" title="Reset Skor">
                    <i class="fas fa-undo"></i>
                </button>
                <button class="btn-delete text-red-400 hover:text-red-600 hover:bg-red-50 p-2 rounded-lg transition-all" data-id="${u.id}" title="Hapus User">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        `;
        tbody.appendChild(tr);
    });

    // Re-attach listeners for dynamic buttons
    document.querySelectorAll('.btn-delete').forEach(btn => {
        btn.addEventListener('click', () => deleteSantri(btn.dataset.id));
    });

    document.querySelectorAll('.btn-reset').forEach(btn => {
        btn.addEventListener('click', () => resetUserScore(btn.dataset.id));
    });

    document.querySelectorAll('.btn-reset-exam').forEach(btn => {
        btn.addEventListener('click', () => resetExamStatus(btn.dataset.id));
    });
}
