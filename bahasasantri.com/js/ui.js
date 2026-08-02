// UI & View Management
import { state } from './state.js';
import { getWeekStart } from './quiz.js';
import { showNotification, showConfirmation } from './dialogs.js';

export function switchView(viewName) {
    const views = ['login', 'menu', 'quiz', 'result', 'review', 'admin', 'math-lobby', 'math-room', 'math-game', 'cca'];
    views.forEach(v => {
        const el = document.getElementById('view-' + v);
        if (el) {
            el.classList.add('hidden-view');
            el.classList.remove('active-view');
            // Ensure Tailwind hidden is also applied/removed if mixed usage
            // But based on HTML, it uses custom classes. We'll use the original logic style:
        }
    });

    const target = document.getElementById('view-' + viewName);
    if (target) {
        target.classList.remove('hidden-view');
        target.classList.add('active-view');
    }

    const header = document.getElementById('header-ui');
    if (header) {
        if (viewName === 'login') header.classList.add('hidden');
        else header.classList.remove('hidden');
    }

    state.currentView = viewName;

    if (viewName === 'menu') {
        updateHomeUI();
    }

    // Load Math Battle leaderboard when entering lobby
    if (viewName === 'math-lobby' && window.loadMathLeaderboard) {
        window.loadMathLeaderboard();
    }
}

export function updateHomeUI() {
    if (!state.currentUser) return;

    // Refresh User Data from Live State
    // Find key where value object ref might match OR name matches (safer: store code in currentUser)
    // Actually app.js stores 'code' in closure, not in state.currentUser. 
    // We need to find the user in state.users that matches state.currentUser.name
    // A better way: store `code` in state.currentUser when logging in.

    let currentCode = null;
    // Attempt to find by reference or name
    for (const [k, v] of Object.entries(state.users)) {
        if (v.name === state.currentUser.name) {
            currentCode = k;
            state.currentUser = v; // Update reference to live object
            break;
        }
    }

    const nameEl = document.getElementById('menu-user-name');
    const scoreEl = document.getElementById('menu-highscore');
    const rankEl = document.getElementById('menu-rank');

    if (nameEl) nameEl.textContent = state.currentUser.name;
    if (scoreEl) scoreEl.textContent = state.currentUser.highscore || 0;

    // Update Profile Info (Akun Tab)
    const profName = document.getElementById('profile-name');
    const profCode = document.getElementById('profile-code');
    if (profName) profName.textContent = state.currentUser.name;
    if (profCode) profCode.textContent = "ID: " + (state.currentUser.id || '--');

    // Calculate Rank
    if (rankEl && state.userList && state.userList.length > 0) {
        // Sort temp array
        const sorted = [...state.userList].sort((a, b) => (b.highscore || 0) - (a.highscore || 0));
        const rank = sorted.findIndex(u => u.name === state.currentUser.name) + 1;
        rankEl.textContent = rank > 0 ? `#${rank}` : '-';
    } else {
        if (rankEl) rankEl.textContent = '-';
    }

    // Update exam button status
    updateExamButton();
}

// Update exam button based on user status
function updateExamButton() {
    if (!state.currentUser || state.currentUser.role === 'admin') return;

    const icon = document.getElementById('exam-icon');
    const title = document.getElementById('exam-title');
    const subtitle = document.getElementById('exam-subtitle');
    const playIcon = document.getElementById('exam-play-icon');

    if (!icon || !title || !subtitle || !playIcon) return;

    const weekStart = getWeekStart();
    const lastExamDate = state.currentUser.lastExamDate ? new Date(state.currentUser.lastExamDate) : null;
    const tookExamThisWeek = lastExamDate && lastExamDate > weekStart;
    const score = state.currentUser.weeklyScore || state.currentUser.lastExamScore || 0;
    const remedialAvailable = state.currentUser.remedialAvailable || false;

    if (tookExamThisWeek && score >= 70) {
        // Completed with good score
        icon.textContent = '✅';
        title.textContent = 'Ujian Selesai';
        subtitle.textContent = `Nilai minggu ini: ${score} - Bagus!`;
        playIcon.className = 'fas fa-check';
    } else if (tookExamThisWeek && remedialAvailable) {
        // Eligible for remedial
        icon.textContent = '🔄';
        title.textContent = 'Remidi Tersedia';
        subtitle.textContent = `Nilai: ${score} - Klik untuk perbaiki nilai (Max: 70)`;
        playIcon.className = 'fas fa-redo';
    } else {
        // Regular exam or not taken yet
        icon.textContent = '📚';
        title.textContent = 'Ujian Pekanan';
        subtitle.textContent = 'Mode ujian dengan timer 10 menit';
        playIcon.className = 'fas fa-play';
    }
}

// Check exam status and start appropriate quiz
window.checkExamStatus = function () {
    if (!state.currentUser) return;

    const weekStart = getWeekStart();
    const lastExamDate = state.currentUser.lastExamDate ? new Date(state.currentUser.lastExamDate) : null;
    const tookExamThisWeek = lastExamDate && lastExamDate > weekStart;
    const score = state.currentUser.weeklyScore || state.currentUser.lastExamScore || 0;
    const remedialAvailable = state.currentUser.remedialAvailable || false;

    if (tookExamThisWeek && score >= 70) {
        // Already completed with good score
        showNotification('Anda sudah menyelesaikan ujian minggu ini dengan nilai bagus! Kembali lagi Senin depan.', 'Ujian Selesai', 'success');
        return;
    }

    if (tookExamThisWeek && remedialAvailable) {
        // Show remedial confirmation dialog
        const dialog = document.getElementById('remedial-confirm-dialog');
        const scoreEl = document.getElementById('remedial-current-score');

        if (dialog && scoreEl) {
            scoreEl.textContent = score;
            dialog.classList.remove('hidden');
            dialog.classList.add('flex');
        }
        return;
    }

    // Regular exam
    import('./quiz.js').then(module => {
        module.startQuiz('mixed', false);
    });
}

// Confirm remedial and start quiz
window.confirmRemedial = function () {
    closeRemedialDialog();
    import('./quiz.js').then(module => {
        module.startQuiz('mixed', true); // isRemedial = true
    });
}

// Close remedial dialog
window.closeRemedialDialog = function () {
    const dialog = document.getElementById('remedial-confirm-dialog');
    if (dialog) {
        dialog.classList.add('hidden');
        dialog.classList.remove('flex');
    }
}

// --- TAB SWITCHER ---
window.switchTab = function (tabName) {
    // Hide all tabs
    ['home', 'ranking', 'akun'].forEach(t => {
        document.getElementById('tab-' + t).classList.add('hidden');
        const nav = document.getElementById('nav-' + t);
        if (nav) {
            nav.classList.remove('text-brand-primary');
            nav.classList.add('text-gray-400');
        }
    });

    // Show target
    document.getElementById('tab-' + tabName).classList.remove('hidden');
    const activeNav = document.getElementById('nav-' + tabName);
    if (activeNav) {
        activeNav.classList.remove('text-gray-400');
        activeNav.classList.add('text-brand-primary');
    }

    if (tabName === 'ranking') renderSantriLeaderboard();
}

function renderSantriLeaderboard() {
    const list = document.getElementById('santri-leaderboard');
    if (!list) return;

    if (!state.userList || state.userList.length === 0) {
        list.innerHTML = '<div class="text-center text-gray-400">Belum ada data.</div>';
        return;
    }

    // Sort
    const sorted = [...state.userList].sort((a, b) => (b.highscore || 0) - (a.highscore || 0)).slice(0, 10);

    let html = '';
    sorted.forEach((u, index) => {
        const isMe = (state.currentUser && u.name === state.currentUser.name);

        let rankColor = 'bg-white text-gray-500';
        let medal = '';

        if (index === 0) { rankColor = 'bg-yellow-100 text-yellow-600'; medal = '🥇'; }
        else if (index === 1) { rankColor = 'bg-gray-100 text-gray-600'; medal = '🥈'; }
        else if (index === 2) { rankColor = 'bg-orange-100 text-orange-600'; medal = '🥉'; }

        html += `
        <div class="flex items-center gap-4 p-4 rounded-2xl border ${isMe ? 'border-brand-primary bg-brand-primary/5' : 'border-gray-50 bg-white'} shadow-sm">
            <div class="w-10 h-10 rounded-full ${rankColor} flex items-center justify-center font-bold text-sm">
                ${medal || '#' + (index + 1)}
            </div>
            <div class="flex-1">
                <h4 class="font-bold text-gray-800 ${isMe ? 'text-brand-primary' : ''}">${u.name} ${isMe ? '(Anda)' : ''}</h4>
                <p class="text-xs text-gray-400">Santri</p>
            </div>
            <div class="font-bold text-brand-dark">${u.highscore || 0} pts</div>
        </div>
        `;
    });

    list.innerHTML = html;
}

// Switch between Total, Weekly, and Math ranking tabs
window.switchRankingTab = function (tab) {
    const totalTab = document.getElementById('rank-tab-total');
    const weeklyTab = document.getElementById('rank-tab-weekly');
    const mathTab = document.getElementById('rank-tab-math');
    const totalContent = document.getElementById('rank-total');
    const weeklyContent = document.getElementById('rank-weekly');
    const mathContent = document.getElementById('rank-math');

    // Reset all tabs
    const inactiveClass = 'flex-1 py-2 px-3 rounded-xl font-bold text-xs bg-gray-100 text-gray-500 transition-all';
    const activeClass = 'flex-1 py-2 px-3 rounded-xl font-bold text-xs bg-brand-primary text-white transition-all';
    const mathActiveClass = 'flex-1 py-2 px-3 rounded-xl font-bold text-xs bg-blue-500 text-white transition-all';

    [totalTab, weeklyTab, mathTab].forEach(t => t.className = inactiveClass);
    [totalContent, weeklyContent, mathContent].forEach(c => c.classList.add('hidden'));

    if (tab === 'total') {
        totalTab.className = activeClass;
        totalContent.classList.remove('hidden');
    } else if (tab === 'weekly') {
        weeklyTab.className = activeClass;
        weeklyContent.classList.remove('hidden');
        // Load weekly leaderboard
        updateWeeklyLeaderboard();
    } else if (tab === 'math') {
        mathTab.className = mathActiveClass;
        mathContent.classList.remove('hidden');
        // Load math leaderboard
        updateMathLeaderboard();
    }
}

export function updateMathLeaderboard() {
    const list = document.getElementById('math-leaderboard');
    if (!list || !state.userList) return;

    // Filter users with mathWins (total victories) and sort by it
    const sortedMath = [...state.userList]
        .filter(u => (u.mathWins || 0) > 0)
        .sort((a, b) => (b.mathWins || 0) - (a.mathWins || 0));

    if (sortedMath.length === 0) {
        list.innerHTML = '<div class="text-center text-gray-400 mt-10">Belum ada data ranking matematika.<br><span class="text-xs">Main Math Battle untuk masuk ranking!</span></div>';
        return;
    }

    let html = '';

    sortedMath.forEach((u, index) => {
        let medal = '';
        let rankColor = 'bg-gray-100 text-gray-500';
        if (index === 0) { medal = '🥇'; rankColor = 'bg-yellow-400 text-white'; }
        else if (index === 1) { medal = '🥈'; rankColor = 'bg-gray-300 text-white'; }
        else if (index === 2) { medal = '🥉'; rankColor = 'bg-orange-400 text-white'; }

        const isMe = state.currentUser && u.name === state.currentUser.name;

        html += `
        <div class="flex items-center gap-4 p-4 rounded-2xl border ${isMe ? 'border-blue-500 bg-blue-50' : 'border-gray-50 bg-white'} shadow-sm">
            <div class="w-10 h-10 rounded-full ${rankColor} flex items-center justify-center font-bold text-sm">
                ${medal || '#' + (index + 1)}
            </div>
            <div class="flex-1">
                <h4 class="font-bold text-gray-800 ${isMe ? 'text-blue-600' : ''}">${u.name} ${isMe ? '(Anda)' : ''}</h4>
                <p class="text-xs text-gray-400">Total Menang</p>
            </div>
            <div class="font-bold text-blue-600">${u.mathWins || 0} 🏆</div>
        </div>
        `;
    });

    list.innerHTML = html;
}

export function updateWeeklyLeaderboard() {
    const list = document.getElementById('weekly-leaderboard');
    if (!list || !state.userList) return;

    const weekStart = getWeekStart();

    // Sort users by weeklyScore (descending), including users with existing data
    const sortedWeekly = [...state.userList]
        .filter(u => {
            // Include if has weeklyScore > 0
            if ((u.weeklyScore || 0) > 0) return true;

            // OR if has lastExamDate this week (backward compat)
            if (u.lastExamDate) {
                const examDate = new Date(u.lastExamDate);
                return examDate > weekStart;
            }
            return false;
        })
        .sort((a, b) => (b.weeklyScore || 0) - (a.weeklyScore || 0))
        .slice(0, 10);  // Top 10

    if (sortedWeekly.length === 0) {
        list.innerHTML = '<div class="text-center text-gray-400 mt-10">Belum ada ujian minggu ini.<br><span class="text-xs">Ikut ujian untuk masuk ranking!</span></div>';
        return;
    }

    let html = '';

    sortedWeekly.forEach((u, index) => {
        const isMe = (state.currentUser && u.name === state.currentUser.name);
        const weeklyScore = u.weeklyScore || 0;
        const KKM = 70;

        let rankColor = 'bg-white text-gray-500';
        let medal = '';

        if (index === 0) { rankColor = 'bg-yellow-100 text-yellow-600'; medal = '🥇'; }
        else if (index === 1) { rankColor = 'bg-gray-100 text-gray-600'; medal = '🥈'; }
        else if (index === 2) { rankColor = 'bg-orange-100 text-orange-600'; medal = '🥉'; }

        // Color based on KKM
        const scoreColor = weeklyScore >= KKM ? 'text-green-600' : 'text-orange-500';
        const scoreBg = weeklyScore >= KKM ? 'bg-green-50' : 'bg-orange-50';

        html += `
        <div class="flex items-center gap-4 p-4 rounded-2xl border ${isMe ? 'border-brand-primary bg-brand-primary/5' : 'border-gray-50 bg-white'} shadow-sm">
            <div class="w-10 h-10 rounded-full ${rankColor} flex items-center justify-center font-bold text-sm">
                ${medal || '#' + (index + 1)}
            </div>
            <div class="flex-1">
                <h4 class="font-bold text-gray-800 ${isMe ? 'text-brand-primary' : ''}">${u.name} ${isMe ? '(Anda)' : ''}</h4>
                <p class="text-xs text-gray-400">Skor Pekan Ini</p>
            </div>
            <div class="font-bold ${scoreColor} ${scoreBg} px-3 py-1 rounded-lg">${weeklyScore} pts</div>
        </div>
        `;
    });

    list.innerHTML = html;
}

window.logout = async function () {
    const confirmed = await showConfirmation('Yakin ingin keluar?', 'Logout');
    if (confirmed) {
        state.currentUser = null;
        switchView('login');
    }
}

// ========================================
// SPEECH SPEED CONTROL
// ========================================

window.setSpeechRate = function (rate) {
    state.speechRate = rate;
    localStorage.setItem('speechRate', rate);

    // Update button states
    const normalBtn = document.getElementById('speed-normal');
    const slowBtn = document.getElementById('speed-slow');
    const veryslowBtn = document.getElementById('speed-veryslow');

    const activeClass = 'bg-brand-primary text-white';
    const inactiveClass = 'bg-gray-100 text-gray-500';

    // Reset all buttons
    [normalBtn, slowBtn, veryslowBtn].forEach(btn => {
        if (btn) {
            btn.className = `flex-1 py-2 px-3 rounded-xl font-bold text-xs ${inactiveClass} transition-all`;
        }
    });

    // Set active button
    let activeBtn = null;
    if (rate === 1.0) activeBtn = normalBtn;
    else if (rate === 0.7) activeBtn = slowBtn;
    else if (rate === 0.5) activeBtn = veryslowBtn;

    if (activeBtn) {
        activeBtn.className = `flex-1 py-2 px-3 rounded-xl font-bold text-xs ${activeClass} transition-all`;
    }

    console.log("Speech rate set to:", rate);
}

// Load saved speech rate on init
const savedRate = localStorage.getItem('speechRate');
if (savedRate) {
    state.speechRate = parseFloat(savedRate);
}

export function updateTimerDisplay(m, s) {
    const disp = document.getElementById('timer-display');
    if (disp) disp.textContent = m + ":" + s;
}

export function showConfetti() {
    confetti({ particleCount: 50, spread: 60, origin: { y: 0.7 } });
}

export function setTopBarShake() {
    const el = document.getElementById('view-quiz');
    if (el) {
        el.classList.add('wrong-flash');
        el.classList.add('bg-red-50');
        setTimeout(() => {
            el.classList.remove('wrong-flash');
            el.classList.remove('bg-red-50');
        }, 500);
    }
}

// ========================================
// THEME MANAGEMENT
// ========================================

function initTheme() {
    const saved = localStorage.getItem('theme');
    if (saved === 'dark' || (!saved && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
        document.documentElement.setAttribute('data-theme', 'dark');
    }
}

window.toggleTheme = function () {
    const current = document.documentElement.getAttribute('data-theme');
    const newTheme = current === 'dark' ? 'light' : 'dark';

    document.documentElement.setAttribute('data-theme', newTheme === 'dark' ? 'dark' : '');
    localStorage.setItem('theme', newTheme);

    // Play sound
    playSound('click');
}

// Initialize theme on load
initTheme();

// ========================================
// SOUND EFFECTS
// ========================================

const sounds = {
    correct: null,
    wrong: null,
    click: null
};

let soundEnabled = true;

export function initSounds() {
    // Create audio elements with base64 encoded short sounds
    sounds.correct = new Audio('data:audio/mp3;base64,SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU4Ljc2LjEwMAAAAAAAAAAAAAAA/+M4wAAAAAAAAAAAAEluZm8AAAAPAAAAAwAAAbAAqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV//////////////////////////////////////////////////////////////////8AAAAATGF2YzU4LjEzAAAAAAAAAAAAAAAAJAAAAAAAAAAAAbD/gLdDAAAAAAAAAAAAAAAAAP/jOMAAAGT/kgAAAABJbmZv/wAAD/+M4wAAATJSKgAAAAMPAAAADQAAAbAAqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV');
    sounds.wrong = new Audio('data:audio/mp3;base64,SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU4Ljc2LjEwMAAAAAAAAAAAAAAA/+M4wAAAAAAAAAAAAEluZm8AAAAPAAAAAwAAAbAAqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV//////////////////////////////////////////////////////////////////8AAAAATGF2YzU4LjEzAAAAAAAAAAAAAAAAJAAAAAAAAAAAAbD5QDf4AAAAAAAAAAAAAAAA/+M4wAABLBCKgAAAABJbmZv/wAAD/+M4wAAATJSKgAAAAMPAAAADQAAAbAAqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV');
    sounds.click = new Audio('data:audio/mp3;base64,SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU4Ljc2LjEwMAAAAAAAAAAAAAAA/+M4wAAAAAAAAAAAAEluZm8AAAAPAAAAAwAAAbAAqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV//////////////////////////////////////////////////////////////////8AAAAATGF2YzU4LjEzAAAAAAAAAAAAAAAAJAAAAAAAAAAAAbDqAAAAAAAAAAAAAAAAAAAAAA==');

    // Load sound preference
    soundEnabled = localStorage.getItem('soundEnabled') !== 'false';
}

export function playSound(type) {
    if (!soundEnabled) return;

    const audio = sounds[type];
    if (audio) {
        audio.currentTime = 0;
        audio.volume = 0.5;
        audio.play().catch(() => { }); // Ignore autoplay errors
    }
}

export function playSoundCorrect() {
    playSound('correct');
}

export function playSoundWrong() {
    playSound('wrong');
}

window.toggleSound = function () {
    soundEnabled = !soundEnabled;
    localStorage.setItem('soundEnabled', soundEnabled);
    return soundEnabled;
}

// Initialize sounds on load
initSounds();

// ========================================
// MENU TOGGLE (Side Panel)
// ========================================

window.toggleMenu = function () {
    // Check if we're in quiz view
    if (state.currentView === 'quiz') {
        if (state.isExam) {
            // Exam mode - show exam exit dialog
            const dialog = document.getElementById('exit-exam-dialog');
            if (dialog) {
                dialog.classList.remove('hidden');
                dialog.classList.add('flex');
            }
        } else {
            // Practice mode - show practice exit dialog
            const dialog = document.getElementById('exit-practice-dialog');
            if (dialog) {
                dialog.classList.remove('hidden');
                dialog.classList.add('flex');
            }
        }
        return;
    }

    // For now, just switch to akun tab if on menu view
    if (state.currentView === 'menu') {
        switchTab('akun');
    }
}

// Exit Exam Dialog Functions
window.confirmExitExam = function () {
    import('./quiz.js').then(module => {
        // Hide dialog
        const dialog = document.getElementById('exit-exam-dialog');
        if (dialog) {
            dialog.classList.add('hidden');
            dialog.classList.remove('flex');
        }
        // Show result (calculates score based on answered questions)
        module.showResult();
    });
}

window.cancelExitExam = function () {
    const dialog = document.getElementById('exit-exam-dialog');
    if (dialog) {
        dialog.classList.add('hidden');
        dialog.classList.remove('flex');
    }
}

// Exit Practice Dialog Functions
window.confirmExitPractice = function () {
    // Hide dialog
    const dialog = document.getElementById('exit-practice-dialog');
    if (dialog) {
        dialog.classList.add('hidden');
        dialog.classList.remove('flex');
    }
    // Just go back to menu
    switchView('menu');
    switchTab('home');
}

window.cancelExitPractice = function () {
    const dialog = document.getElementById('exit-practice-dialog');
    if (dialog) {
        dialog.classList.add('hidden');
        dialog.classList.remove('flex');
    }
}

// ========================================
// LOADING STATES
// ========================================

export function showLoading(containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    container.innerHTML = `
        <div class="space-y-3">
            <div class="skeleton skeleton-card"></div>
            <div class="skeleton skeleton-card"></div>
            <div class="skeleton skeleton-card"></div>
        </div>
    `;
}

export function hideLoading(containerId, content) {
    const container = document.getElementById(containerId);
    if (!container) return;

    container.innerHTML = content;
}

