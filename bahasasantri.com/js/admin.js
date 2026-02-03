import { db } from './config.js';
import { collection, doc, setDoc, deleteDoc, updateDoc, onSnapshot, getDocs } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";
import { state } from './state.js';
import { showNotification } from './dialogs.js';

export function initAdmin() {
    // Show skeleton loading initially
    showAdminSkeleton();

    // Auto-reset weekly scores if new week started
    checkAndResetWeeklyScores();
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

            // BACKWARD COMPATIBILITY: Set missing fields for existing users
            const now = new Date();
            const weekStart = getWeekStart();

            // If weeklyScore is missing, check if lastExamDate is within this week
            if (typeof data.weeklyScore === 'undefined' && data.lastExamDate) {
                const lastExamDate = new Date(data.lastExamDate);
                if (lastExamDate > weekStart) {
                    // Exam was this week, use the score
                    data.weeklyScore = data.lastExamScore || data.highscore || 0;
                } else {
                    data.weeklyScore = 0; // Exam was before this week
                }
            }

            // If remedialAvailable is missing, check if eligible
            if (typeof data.remedialAvailable === 'undefined') {
                // Check if last exam was this week AND score < 70
                if (data.lastExamDate) {
                    const lastExamDate = new Date(data.lastExamDate);
                    const lastScore = data.lastExamScore || data.weeklyScore || 0;

                    if (lastExamDate > weekStart && lastScore < 70) {
                        // Hasn't done remedial this week, eligible
                        const lastRemedial = data.lastRemedialDate ? new Date(data.lastRemedialDate) : null;
                        data.remedialAvailable = !lastRemedial || lastRemedial < weekStart;
                    } else {
                        data.remedialAvailable = false;
                    }
                } else {
                    data.remedialAvailable = false;
                }
            }

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
                if (code === '00') { showNotification("Kode 00 dilindungi.", "Tidak Diizinkan", "error"); return; }
                await addSantri(code, name);
                form.reset();
            }
        });
    }
}

// ========================================
// AUTO-RESET WEEKLY SCORES
// ========================================

async function checkAndResetWeeklyScores() {
    const lastResetKey = 'lastWeeklyReset';
    const lastReset = localStorage.getItem(lastResetKey);
    const now = new Date();
    const weekStart = getWeekStart();

    // First time initialization - don't reset, just save timestamp
    if (!lastReset) {
        localStorage.setItem(lastResetKey, now.toISOString());
        console.log('✓ Auto-reset initialized (first time, no reset needed)');
        return;
    }

    // Check if we crossed into a NEW week since last reset
    const lastResetDate = new Date(lastReset);

    // Only reset if:
    // 1. Last reset was BEFORE this week's Monday (weekStart)
    // 2. AND we are now ON or AFTER this week's Monday
    if (lastResetDate < weekStart && now >= weekStart) {
        console.log('🔄 Auto-resetting weekly scores (new week detected)...');

        try {
            // Get all users
            const usersRef = collection(db, "santri_users");
            const snapshot = await getDocs(usersRef);

            const resetPromises = [];
            snapshot.forEach(doc => {
                const userRef = doc.ref;
                resetPromises.push(
                    updateDoc(userRef, {
                        weeklyScore: 0,
                        lastExamDate: null,
                        remedialAvailable: false,
                        lastRemedialDate: null
                    })
                );
            });

            // Execute all resets in parallel
            await Promise.all(resetPromises);

            // Update last reset timestamp to current time
            localStorage.setItem(lastResetKey, now.toISOString());
            console.log(`✅ Reset ${resetPromises.length} users successfully!`);

        } catch (error) {
            console.error('❌ Error auto-resetting weekly scores:', error);
        }
    } else {
        console.log('✓ Weekly scores already reset for this week');
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
        showNotification(`Santri ${name} (${code}) berhasil ditambahkan!`, "Berhasil", "success");
    } catch (e) {
        console.error("Error adding:", e);
        showNotification("Gagal menambah santri: " + e.message, "Error", "error");
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
        showNotification("Gagal hapus: " + e.message, "Error", "error");
    }
}

// ========================================
// RESET SCORE FUNCTIONS (3 types)
// ========================================

// Reset Weekly Score (weeklyScore + lastExamScore)
async function resetWeeklyScore(code) {
    const user = state.userList.find(u => u.id === code);
    const name = user?.name || 'Unknown';

    const confirmed = await showConfirmation(
        `Reset skor pekan ini untuk ${name}?\n\nIni akan reset:\n- Skor Pekan Ini\n- Skor Ujian Terakhir\n\n(Total akumulasi tidak terpengaruh)`,
        'Reset Pekan Ini',
        'Ya, Reset',
        'Batal'
    );

    if (!confirmed) return;

    try {
        await updateDoc(doc(db, "santri_users", code), {
            weeklyScore: 0,
            lastExamScore: 0
        });
        showNotification(`✅ Skor pekan ini ${name} sudah direset!`, "Berhasil", "success");
    } catch (e) {
        console.error("Error reset weekly:", e);
        showNotification("Gagal reset skor pekan ini: " + e.message, "Error", "error");
    }
}

// Reset Total Akumulasi (highscore)
async function resetTotalScore(code) {
    const user = state.userList.find(u => u.id === code);
    const name = user?.name || 'Unknown';

    const confirmed = await showConfirmation(
        `Reset TOTAL AKUMULASI untuk ${name}?\n\n⚠️ WARNING: Ini akan menghapus SEMUA progress sepanjang waktu!\n\n(Skor pekan ini tidak terpengaruh)`,
        'Reset Total Akumulasi',
        'Ya, Reset',
        'Batal'
    );

    if (!confirmed) return;

    try {
        await updateDoc(doc(db, "santri_users", code), {
            highscore: 0
        });
        showNotification(`✅ Total akumulasi ${name} sudah direset!`, "Berhasil", "success");
    } catch (e) {
        console.error("Error reset total:", e);
        showNotification("Gagal reset total akumulasi: " + e.message, "Error", "error");
    }
}

// Reset Math Score (mathWins)
async function resetMathScore(code) {
    const user = state.userList.find(u => u.id === code);
    const name = user?.name || 'Unknown';

    const confirmed = await showConfirmation(
        `Reset skor matematika untuk ${name}?`,
        'Reset Skor MTK',
        'Ya, Reset',
        'Batal'
    );

    if (!confirmed) return;

    try {
        await updateDoc(doc(db, "santri_users", code), {
            mathWins: 0
        });
        showNotification(`✅ Skor matematika ${name} sudah direset!`, "Berhasil", "success");
    } catch (e) {
        console.error("Error reset math:", e);
        showNotification("Gagal reset skor matematika: " + e.message, "Error", "error");
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
        showNotification("Gagal buka kunci: " + e.message, "Error", "error");
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
    // Sort by weekly score (current week performance)
    const sorted = [...state.userList].sort((a, b) => (b.weeklyScore || 0) - (a.weeklyScore || 0));
    const KKM = 70; // Minimum passing score

    sorted.forEach((u, i) => {
        const tr = document.createElement('tr');
        const weeklyScore = u.weeklyScore || 0;
        const highscore = u.highscore || 0;

        let badge = '';
        if (i === 0) badge = '🥇';
        else if (i === 1) badge = '🥈';
        else if (i === 2) badge = '🥉';

        // Color based on KKM
        const scoreColor = weeklyScore >= KKM ? 'text-green-600' : 'text-orange-500';
        const scoreBg = weeklyScore >= KKM ? 'bg-green-50' : 'bg-orange-50';
        const statusIcon = weeklyScore >= KKM ? '✓' : '↓';

        tr.className = "border-b border-gray-100 hover:bg-yellow-50 transition-colors";
        tr.innerHTML = `
            <td class="p-4 font-bold text-center">${badge || (i + 1)}</td>
            <td class="p-4 font-bold text-brand-dark flex items-center gap-2">
                ${u.name} 
                <span class="text-[10px] bg-gray-100 px-2 rounded-full text-gray-500">${u.id}</span>
            </td>
            <td class="p-4 text-right">
                <span class="font-black ${scoreColor} ${scoreBg} px-2 py-1 rounded-lg">${weeklyScore} ${statusIcon}</span>
                <span class="text-xs text-gray-400 ml-2">Best: ${highscore}</span>
            </td>
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
                <button class="btn-reset-weekly text-blue-400 hover:text-blue-600 hover:bg-blue-50 p-2 rounded-lg transition-all" data-id="${u.id}" title="Reset Pekan Ini">
                    <i class="fas fa-calendar-week"></i>
                </button>
                <button class="btn-reset-total text-orange-400 hover:text-orange-600 hover:bg-orange-50 p-2 rounded-lg transition-all" data-id="${u.id}" title="Reset Total Akumulasi">
                    <i class="fas fa-chart-line"></i>
                </button>
                <button class="btn-reset-math text-purple-400 hover:text-purple-600 hover:bg-purple-50 p-2 rounded-lg transition-all" data-id="${u.id}" title="Reset Skor MTK">
                    <i class="fas fa-calculator"></i>
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

    document.querySelectorAll('.btn-reset-weekly').forEach(btn => {
        btn.addEventListener('click', () => resetWeeklyScore(btn.dataset.id));
    });

    document.querySelectorAll('.btn-reset-total').forEach(btn => {
        btn.addEventListener('click', () => resetTotalScore(btn.dataset.id));
    });

    document.querySelectorAll('.btn-reset-math').forEach(btn => {
        btn.addEventListener('click', () => resetMathScore(btn.dataset.id));
    });

    document.querySelectorAll('.btn-reset-exam').forEach(btn => {
        btn.addEventListener('click', () => resetExamStatus(btn.dataset.id));
    });
}

// ========================================
// SKELETON LOADING HELPER
// ========================================
function showAdminSkeleton() {
    // Generate skeleton rows for tables
    const skeletonRow = `
        <tr class="border-b border-gray-100">
            <td class="p-4"><div class="skeleton h-4 w-12"></div></td>
            <td class="p-4"><div class="skeleton h-4 w-40"></div></td>
            <td class="p-4"><div class="skeleton h-4 w-16"></div></td>
        </tr>
    `;

    const skeletonRows = skeletonRow.repeat(5); // 5 skeleton rows

    // User List Skeleton
    const userList = document.getElementById('admin-user-list');
    if (userList) {
        userList.innerHTML = skeletonRows;
    }

    // Ranking List Skeleton  
    const rankingList = document.getElementById('admin-ranking-list');
    if (rankingList) {
        rankingList.innerHTML = skeletonRows;
    }

    // Math Ranking Skeleton
    const mathRanking = document.getElementById('admin-math-ranking-list');
    if (mathRanking) {
        mathRanking.innerHTML = skeletonRows;
    }
}
