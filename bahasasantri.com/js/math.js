import { db } from './config.js';
import { doc, getDoc, setDoc, updateDoc, onSnapshot, increment, collection, getDocs, deleteField } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";
import { state } from './state.js';
import { switchView } from './ui.js';
import { showNotification } from './dialogs.js';

let mathUnsub = null;
let currentRoomId = null;
let myRole = null; // 'player_0', 'player_1', ... or 'spectator'
let gameMode = '1v1'; // '1v1' or 'ffa'
let isHostSpectator = false; // true when guru creates room as spectator
let localQuestion = null; // Cached question for local checking (optimization)
let roomLevel = 1; // 1 or 2
let roomTargetScore = 20; // 20, 30, 40, 50
let mathBacksound = null; // background music (host only)

const PLAYER_COLORS = [
    'text-brand-primary',  // player_0 (orange)
    'text-rose-500',       // player_1
    'text-blue-500',       // player_2
    'text-green-500',      // player_3
    'text-purple-500',     // player_4
];

const PLAYER_BG_COLORS = [
    'bg-brand-primary/10',
    'bg-rose-50',
    'bg-blue-50',
    'bg-green-50',
    'bg-purple-50',
];

export function initMath() {
    window.createMathRoom = createMathRoom;
    window.joinMathRoom = joinMathRoom;
    window.submitMathAnswer = submitMathAnswer;
    window.leaveMathGame = leaveMathGame;
    window.spectateRoom = spectateRoom;
    window.loadMathLeaderboard = loadMathLeaderboard;
    window.showMathModePicker = showMathModePicker;
    window.startFFAGame = startFFAGame;
    window.setMathGameMode = (mode) => { gameMode = mode; };
    window.setMathHostSpectator = (val) => { isHostSpectator = val; };
}

// ========================================
// MODE PICKER
// ========================================

function showMathModePicker() {
    return new Promise((resolve) => {
        const modal = document.createElement('div');
        modal.id = 'math-mode-modal';
        modal.className = 'fixed inset-0 bg-black/50 flex items-center justify-center z-[100] p-6';
        modal.innerHTML = `
            <div class="bg-white rounded-3xl p-6 w-full max-w-sm shadow-2xl">
                <h3 class="text-2xl font-black text-brand-dark mb-2 text-center">Math Battle ⚔️</h3>
                <p class="text-gray-400 text-xs text-center mb-6">Pilih mode pertandingan</p>
                <div class="space-y-3">
                    <button id="mode-1v1" class="w-full py-5 rounded-2xl bg-gradient-to-r from-brand-primary to-orange-400 text-white font-bold text-lg shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-3">
                        <span class="text-2xl">🥊</span>
                        <div class="text-left">
                            <div class="font-black">Duel 1 vs 1</div>
                            <div class="text-white/80 text-xs font-normal">Tantang 1 lawan!</div>
                        </div>
                    </button>
                    <button id="mode-ffa" class="w-full py-5 rounded-2xl bg-gradient-to-r from-pink-500 to-rose-500 text-white font-bold text-lg shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-3">
                        <span class="text-2xl">🏟️</span>
                        <div class="text-left">
                            <div class="font-black">Free-for-All</div>
                            <div class="text-white/80 text-xs font-normal">2-5 pemain, siapa cepat menang!</div>
                        </div>
                    </button>
                    <button id="mode-guru" class="w-full py-5 rounded-2xl text-white font-bold text-lg shadow-lg transition-all flex items-center justify-center gap-3" style="background:linear-gradient(to right,#10b981,#14b8a6)">
                        <span class="text-2xl">🧑‍🏫</span>
                        <div class="text-left">
                            <div class="font-black">Mode Guru</div>
                            <div class="text-white/80 text-xs font-normal">Buat room & pantau tanpa ikut main</div>
                        </div>
                    </button>
                    <button id="mode-spectate" class="w-full py-3 rounded-xl bg-gray-100 text-gray-500 font-bold text-sm flex items-center justify-center gap-2">
                        <span>👀</span> Nonton Game (Spectator)
                    </button>
                    <button id="mode-cancel" class="w-full py-3 rounded-xl bg-gray-100 text-gray-500 font-bold text-sm">
                        Batal
                    </button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);

        modal.querySelector('#mode-1v1').onclick = () => { modal.remove(); resolve('1v1'); };
        modal.querySelector('#mode-ffa').onclick = () => { modal.remove(); resolve('ffa'); };
        modal.querySelector('#mode-guru').onclick = () => { modal.remove(); resolve('guru'); };
        modal.querySelector('#mode-spectate').onclick = () => { modal.remove(); resolve('spectate'); };
        modal.querySelector('#mode-cancel').onclick = () => { modal.remove(); resolve(null); };
        modal.onclick = (e) => { if (e.target === modal) { modal.remove(); resolve(null); } };
    });
}

// ========================================
// ROOM SETTINGS MODAL (Level + Target Score)
// ========================================

function showRoomSettings() {
    return new Promise((resolve) => {
        const modal = document.createElement('div');
        modal.id = 'room-settings-modal';
        modal.className = 'fixed inset-0 bg-black/50 flex items-center justify-center z-[100] p-6';
        modal.innerHTML = `
            <div class="bg-white rounded-3xl p-6 w-full max-w-sm shadow-2xl">
                <h3 class="text-xl font-black text-brand-dark mb-1 text-center">Pengaturan Room ⚙️</h3>
                <p class="text-gray-400 text-xs text-center mb-5">Atur level dan jumlah soal</p>

                <div class="mb-5">
                    <label class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2 block">Level Soal</label>
                    <div class="grid grid-cols-2 gap-2">
                        <button data-level="1" class="level-btn py-3 rounded-xl border-2 border-brand-primary bg-brand-primary/10 text-brand-primary font-bold text-sm transition-all">
                            ⭐ Level 1<br><span class="text-[10px] font-normal">+ − × ÷</span>
                        </button>
                        <button data-level="2" class="level-btn py-3 rounded-xl border-2 border-gray-200 bg-white text-gray-600 font-bold text-sm transition-all">
                            ⭐⭐ Level 2<br><span class="text-[10px] font-normal">+ − × ÷ √ ²</span>
                        </button>
                    </div>
                </div>

                <div class="mb-6">
                    <label class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2 block">Jumlah Soal (Target Poin)</label>
                    <div class="grid grid-cols-4 gap-2">
                        <button data-target="20" class="target-btn py-3 rounded-xl border-2 border-brand-primary bg-brand-primary/10 text-brand-primary font-black text-lg transition-all">20</button>
                        <button data-target="30" class="target-btn py-3 rounded-xl border-2 border-gray-200 bg-white text-gray-600 font-black text-lg transition-all">30</button>
                        <button data-target="40" class="target-btn py-3 rounded-xl border-2 border-gray-200 bg-white text-gray-600 font-black text-lg transition-all">40</button>
                        <button data-target="50" class="target-btn py-3 rounded-xl border-2 border-gray-200 bg-white text-gray-600 font-black text-lg transition-all">50</button>
                    </div>
                </div>

                <div class="flex gap-3">
                    <button id="settings-cancel" class="flex-1 py-4 rounded-2xl bg-gray-100 text-gray-500 font-bold">Batal</button>
                    <button id="settings-ok" class="flex-1 py-4 rounded-2xl bg-brand-primary text-white font-bold">Buat Room</button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);

        let selectedLevel = 1;
        let selectedTarget = 20;

        // Level button selection
        modal.querySelectorAll('.level-btn').forEach(btn => {
            btn.onclick = () => {
                modal.querySelectorAll('.level-btn').forEach(b => {
                    b.className = 'level-btn py-3 rounded-xl border-2 border-gray-200 bg-white text-gray-600 font-bold text-sm transition-all';
                });
                btn.className = 'level-btn py-3 rounded-xl border-2 border-brand-primary bg-brand-primary/10 text-brand-primary font-bold text-sm transition-all';
                selectedLevel = parseInt(btn.dataset.level);
            };
        });

        // Target button selection
        modal.querySelectorAll('.target-btn').forEach(btn => {
            btn.onclick = () => {
                modal.querySelectorAll('.target-btn').forEach(b => {
                    b.className = 'target-btn py-3 rounded-xl border-2 border-gray-200 bg-white text-gray-600 font-black text-lg transition-all';
                });
                btn.className = 'target-btn py-3 rounded-xl border-2 border-brand-primary bg-brand-primary/10 text-brand-primary font-black text-lg transition-all';
                selectedTarget = parseInt(btn.dataset.target);
            };
        });

        modal.querySelector('#settings-cancel').onclick = () => { modal.remove(); resolve(null); };
        modal.querySelector('#settings-ok').onclick = () => { modal.remove(); resolve({ level: selectedLevel, target: selectedTarget }); };
        modal.onclick = (e) => { if (e.target === modal) { modal.remove(); resolve(null); } };
    });
}

// ========================================
// QUESTION GENERATION (Mixed Operations)
// ========================================

function generateMathQuestion(level) {
    level = level || roomLevel || 1;

    // Practice mode: multiplication only
    if (state.appSettings?.mathMode === 'practice') {
        const a = Math.floor(Math.random() * 12) + 1;
        const b = Math.floor(Math.random() * 12) + 1;
        return { a, b, ans: a * b, op: '\u00d7', display: `${a} \u00d7 ${b}`, id: Date.now() };
    }

    let ops = ['+', '-', '\u00d7', '\u00f7'];

    // Level 2 adds square root and square
    if (level >= 2) {
        ops.push('\u221a', '\u00b2');
    }

    const op = ops[Math.floor(Math.random() * ops.length)];
    let a, b, ans, display;

    switch (op) {
        case '+':
            a = Math.floor(Math.random() * 50) + 1;
            b = Math.floor(Math.random() * 50) + 1;
            ans = a + b;
            display = `${a} + ${b}`;
            break;
        case '-':
            a = Math.floor(Math.random() * 41) + 10;
            b = Math.floor(Math.random() * a) + 1;
            ans = a - b;
            display = `${a} - ${b}`;
            break;
        case '\u00d7':
            a = Math.floor(Math.random() * 12) + 1;
            b = Math.floor(Math.random() * 12) + 1;
            ans = a * b;
            display = `${a} \u00d7 ${b}`;
            break;
        case '\u00f7':
            b = Math.floor(Math.random() * 12) + 1;
            ans = Math.floor(Math.random() * 12) + 1;
            a = ans * b;
            display = `${a} \u00f7 ${b}`;
            break;
        case '\u221a': // Square root
            const squares = [1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144];
            a = squares[Math.floor(Math.random() * squares.length)];
            ans = Math.sqrt(a);
            display = `\u221a${a}`;
            break;
        case '\u00b2': // Square
            a = Math.floor(Math.random() * 12) + 1;
            ans = a * a;
            display = `${a}\u00b2`;
            break;
    }

    return { a, b: b || 0, ans, op, display, id: Date.now() };
}

// ========================================
// LOBBY LOGIC
// ========================================

async function createMathRoom() {
    // Show room settings modal
    const settings = await showRoomSettings();
    if (!settings) return;

    roomLevel = settings.level;
    roomTargetScore = settings.target;

    const roomId = Math.floor(1000 + Math.random() * 9000).toString();
    currentRoomId = roomId;

    const playerName = state.currentUser?.name || 'Player 1';
    const maxPlayers = (gameMode === 'ffa' || gameMode === 'guru') ? 5 : 2;

    const roomData = {
        mode: gameMode === 'guru' ? 'ffa' : gameMode,
        maxPlayers: maxPlayers,
        level: roomLevel,
        targetScore: roomTargetScore,
        status: 'waiting',
        hostName: playerName,
        question: generateMathQuestion(roomLevel),
        createdAt: new Date().toISOString()
    };

    if (isHostSpectator) {
        // Guru mode: host doesn't play, no player slot
        roomData.players = {};
        roomData.playerCount = 0;
        roomData.hostSpectator = true;
    } else {
        // Normal mode: host is player_0
        roomData.players = { player_0: { name: playerName, score: 0 } };
        roomData.playerCount = 1;
    }

    const roomRef = doc(db, "math_rooms", roomId);
    await setDoc(roomRef, roomData);

    myRole = isHostSpectator ? 'spectator' : 'player_0';
    subscribeToRoom(roomId);
}

async function joinMathRoom() {
    const code = await showRoomCodeModal();
    if (!code) return;

    const roomId = code.trim();
    const roomRef = doc(db, "math_rooms", roomId);
    const snap = await getDoc(roomRef);

    if (!snap.exists()) {
        showNotification("Room tidak ditemukan!", "Error", "error");
        return;
    }

    const data = snap.data();
    if (data.status !== 'waiting') {
        showNotification("Game sudah berjalan atau selesai!", "Tidak Bisa Join", "warning");
        return;
    }

    // Check max players
    const playerCount = data.playerCount || Object.keys(data.players).length;
    const maxPlayers = data.maxPlayers || 2;

    if (playerCount >= maxPlayers) {
        showNotification(`Room penuh! (${playerCount}/${maxPlayers})`, "Room Penuh", "warning");
        return;
    }

    // Assign next available slot
    const slotIndex = playerCount;
    const playerKey = `player_${slotIndex}`;
    const playerName = state.currentUser?.name || `Player ${slotIndex + 1}`;

    // Set the game mode from room data
    gameMode = data.mode || '1v1';
    roomLevel = data.level || 1;
    roomTargetScore = data.targetScore || 20;

    const updateData = {
        [`players.${playerKey}`]: { name: playerName, score: 0 },
        playerCount: increment(1)
    };

    // Auto-start for 1v1 (when 2nd player joins)
    if (gameMode === '1v1' && slotIndex === 1) {
        updateData.status = 'countdown';
        updateData.countdownStart = Date.now();
    }

    await updateDoc(roomRef, updateData);

    currentRoomId = roomId;
    myRole = playerKey;
    subscribeToRoom(roomId);
}

// Custom modal for room code input
function showRoomCodeModal() {
    return new Promise((resolve) => {
        const modal = document.createElement('div');
        modal.id = 'room-code-modal';
        modal.className = 'fixed inset-0 bg-black/50 flex items-center justify-center z-[100] p-6';
        modal.innerHTML = `
            <div class="bg-white rounded-3xl p-8 w-full max-w-sm shadow-2xl">
                <h3 class="text-2xl font-black text-brand-dark mb-4 text-center">Masukkan Kode Room</h3>
                <input type="text" id="room-code-input" maxlength="4" 
                    class="w-full text-center text-4xl font-black tracking-widest py-4 border-2 border-gray-200 rounded-2xl focus:border-brand-primary focus:outline-none mb-6"
                    placeholder="0000" autofocus>
                <div class="flex gap-3">
                    <button id="room-code-cancel" class="flex-1 py-4 rounded-2xl bg-gray-100 text-gray-600 font-bold">Batal</button>
                    <button id="room-code-submit" class="flex-1 py-4 rounded-2xl bg-brand-primary text-white font-bold">Join</button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);

        const input = modal.querySelector('#room-code-input');
        const cancelBtn = modal.querySelector('#room-code-cancel');
        const submitBtn = modal.querySelector('#room-code-submit');

        setTimeout(() => input.focus(), 100);

        cancelBtn.onclick = () => { modal.remove(); resolve(null); };
        submitBtn.onclick = () => { const val = input.value.trim(); modal.remove(); resolve(val || null); };
        input.onkeydown = (e) => {
            if (e.key === 'Enter') { const val = input.value.trim(); modal.remove(); resolve(val || null); }
        };
        modal.onclick = (e) => { if (e.target === modal) { modal.remove(); resolve(null); } };
    });
}

function subscribeToRoom(roomId) {
    if (mathUnsub) mathUnsub();

    const roomRef = doc(db, "math_rooms", roomId);

    mathUnsub = onSnapshot(roomRef, (docSnap) => {
        if (!docSnap.exists()) {
            showNotification("Room dibubarkan.", "Game Berakhir", "info");
            leaveMathGame();
            return;
        }

        const data = docSnap.data();

        // Cache question locally for optimized keypad checking
        if (data.question) {
            localQuestion = data.question;
        }

        renderMathUI(data);
    });
}

function leaveMathGame() {
    if (mathUnsub) mathUnsub();
    stopMathBacksound();
    currentRoomId = null;
    myRole = null;
    localQuestion = null;
    switchView('menu');
}

function playMathBacksound() {
    if (mathBacksound) return;
    try {
        mathBacksound = new Audio('/sounds/backsound.mp3');
        mathBacksound.loop = true;
        mathBacksound.volume = 0.3;
        mathBacksound.play().catch(() => { });
    } catch (e) { console.warn('Math backsound error:', e); }
}

function stopMathBacksound() {
    if (mathBacksound) {
        mathBacksound.pause();
        mathBacksound.currentTime = 0;
        mathBacksound = null;
    }
}

// Host starts FFA game manually
async function startFFAGame() {
    const hostName = state.currentUser?.name;
    if (!currentRoomId) return;

    // Allow both player_0 host and spectator host to start
    if (myRole !== 'player_0' && myRole !== 'spectator') return;

    const roomRef = doc(db, "math_rooms", currentRoomId);
    const snap = await getDoc(roomRef);
    if (!snap.exists()) return;

    const data = snap.data();

    // Verify this user is the host
    if (data.hostName && data.hostName !== hostName) return;

    const playerCount = data.playerCount || Object.keys(data.players || {}).length;

    if (playerCount < 2) {
        showNotification("Minimal 2 pemain untuk mulai!", "Tunggu Pemain", "warning");
        return;
    }

    await updateDoc(roomRef, {
        status: 'countdown',
        countdownStart: Date.now()
    });
}

// ========================================
// GAME LOGIC
// ========================================

async function submitMathAnswer(val) {
    if (!currentRoomId || !myRole || myRole === 'spectator') return;

    // Use local cached question for checking
    if (!localQuestion || parseInt(val) !== localQuestion.ans) return;

    const roomRef = doc(db, "math_rooms", currentRoomId);
    const snap = await getDoc(roomRef);
    if (!snap.exists()) return;
    const data = snap.data();

    // Verify against server data (race condition safety)
    if (parseInt(val) !== data.question.ans) return;

    const target = data.targetScore || 20;
    const level = data.level || 1;
    const newScore = (data.players[myRole]?.score || 0) + 1;
    const isWin = newScore >= target;

    await updateDoc(roomRef, {
        [`players.${myRole}.score`]: increment(1),
        question: generateMathQuestion(level),
        status: isWin ? 'finished' : 'playing',
        winner: isWin ? data.players[myRole].name : null
    });
}

// ========================================
// UI RENDERING
// ========================================

let countdownTimer = null;

function renderMathUI(data) {
    const mode = data.mode || '1v1';
    const players = data.players || {};
    const playerKeys = Object.keys(players).sort();
    const playerCount = playerKeys.length;

    if (data.status === 'waiting') {
        switchView('math-room');
        document.getElementById('math-room-code').textContent = currentRoomId;

        const maxPlayers = data.maxPlayers || 2;
        const modeLabel = mode === 'ffa' ? 'Free-for-All' : '1 vs 1';
        const levelLabel = (data.level || 1) === 2 ? 'Lv.2 (√²)' : 'Lv.1';
        const targetLabel = data.targetScore || 20;

        let listHtml = `<li class="text-xs text-gray-400 uppercase tracking-wider font-bold mb-2">${modeLabel} • ${levelLabel} • ${targetLabel} soal<br>${playerCount}/${maxPlayers} pemain</li>`;

        playerKeys.forEach((key, i) => {
            const p = players[key];
            const isMe = key === myRole;
            listHtml += `<li class="font-bold ${PLAYER_COLORS[i]} ${isMe ? 'underline' : ''}">${p.name} ${i === 0 ? '(Host)' : ''} ${isMe ? '← Kamu' : ''}</li>`;
        });

        // Show empty slots
        for (let i = playerCount; i < maxPlayers; i++) {
            listHtml += `<li class="text-gray-400 italic">Menunggu pemain ${i + 1}...</li>`;
        }

        document.getElementById('math-player-list').innerHTML = listHtml;

        // Is this user the host? (could be player_0 or spectator host)
        const isHost = (data.hostName && data.hostName === (state.currentUser?.name));
        const isFFA = mode === 'ffa';

        // Show Start button for host (player or spectator) in FFA when >= 2 players
        const startBtnContainer = document.getElementById('math-start-btn-container');
        if (startBtnContainer) {
            if (isFFA && isHost && playerCount >= 2) {
                startBtnContainer.innerHTML = `
                    <button onclick="startFFAGame()" class="w-full py-4 rounded-2xl bg-green-500 text-white font-bold text-lg shadow-lg hover:bg-green-600 transition-all flex items-center justify-center gap-2 animate-pulse">
                        <i class="fas fa-play"></i> Mulai Game! (${playerCount} pemain)
                    </button>
                `;
            } else if (isFFA && isHost) {
                startBtnContainer.innerHTML = `<p class="text-gray-400 text-xs text-center">Minimal 2 pemain untuk mulai</p>`;
            } else if (isFFA) {
                startBtnContainer.innerHTML = `<p class="text-gray-400 text-xs text-center">Menunggu host memulai game...</p>`;
            } else {
                startBtnContainer.innerHTML = ''; // 1v1 auto starts
            }
        }
    }
    else if (data.status === 'countdown') {
        switchView('math-room');
        document.getElementById('math-room-code').textContent = currentRoomId;

        if (!countdownTimer) {
            let countdown = 5;
            const renderCountdown = () => {
                let listHtml = '';
                playerKeys.forEach((key, i) => {
                    listHtml += `<li class="font-bold ${PLAYER_COLORS[i]}">${players[key].name}</li>`;
                });
                listHtml += `<li class="text-4xl font-black text-brand-primary mt-4 animate-pulse">${countdown}</li>`;
                document.getElementById('math-player-list').innerHTML = listHtml;

                const startBtnContainer = document.getElementById('math-start-btn-container');
                if (startBtnContainer) startBtnContainer.innerHTML = '';
            };

            renderCountdown();

            countdownTimer = setInterval(async () => {
                countdown--;
                if (countdown > 0) {
                    renderCountdown();
                } else {
                    clearInterval(countdownTimer);
                    countdownTimer = null;
                    if (myRole === 'player_0' || (data.hostName && data.hostName === (state.currentUser?.name))) {
                        const roomRef = doc(db, "math_rooms", currentRoomId);
                        await updateDoc(roomRef, { status: 'playing' });
                    }
                }
            }, 1000);
        }
    }
    else if (data.status === 'playing') {
        if (countdownTimer) {
            clearInterval(countdownTimer);
            countdownTimer = null;
        }
        if (isHostSpectator) playMathBacksound();

        switchView('math-game');

        // ===================================
        // SPECTATOR MODE UI (Projector View)
        // ===================================
        if (myRole === 'spectator') {
            // 1. Hide Player Controls (null-safe: elements may be destroyed after first render)
            const keypadEl = document.getElementById('math-keypad-container');
            const questionEl = document.getElementById('math-question');
            const inputEl = document.getElementById('math-input-display');
            if (keypadEl) keypadEl.style.display = 'none';
            if (questionEl) questionEl.style.display = 'none';
            if (inputEl) inputEl.style.display = 'none';

            // 2. Hide Mini Scoreboard (we will replace main area with Giant one)
            const scoreboardEl = document.getElementById('math-scoreboard');
            if (scoreboardEl) scoreboardEl.style.display = 'none';

            // 3. Render Giant Leaderboard in the Main Area
            const mainArea = document.querySelector('#view-math-game .flex-1');
            mainArea.innerHTML = `
                <div class="w-full max-w-4xl mx-auto px-6">
                    <div class="mb-8 text-center">
                        <div class="inline-block px-6 py-2 rounded-full bg-brand-dark/10 text-brand-dark font-black tracking-widest text-sm mb-2">
                            LIVE BATTLE 🔴
                        </div>
                        <h2 class="text-3xl font-black text-brand-dark">Leaderboard</h2>
                        <p class="text-gray-500">Target: ${data.targetScore || 20} poin</p>
                    </div>
                    
                    <div class="space-y-4">
                        ${renderSpectatorLeaderboard(data)}
                    </div>
                </div>
            `;
            return; // Stop here for spectator
        }

        // ===================================
        // PLAYER MODE UI (Standard)
        // ===================================

        // Ensure standard UI elements are visible for players
        document.getElementById('math-keypad-container').style.display = 'block';
        document.getElementById('math-question').style.display = 'block';
        document.getElementById('math-input-display').style.display = 'flex';
        document.getElementById('math-scoreboard').style.display = 'block';

        // ---- RENDER DYNAMIC MINI SCOREBOARD ----
        const scoreboardEl = document.getElementById('math-scoreboard');
        if (scoreboardEl) {
            // Sort players by score (descending) for display
            const sortedPlayers = playerKeys.map((key, i) => ({
                key,
                name: players[key].name,
                score: players[key].score || 0,
                colorIdx: parseInt(key.split('_')[1]),
                isMe: key === myRole
            })).sort((a, b) => b.score - a.score);

            let scoreHtml = '';
            sortedPlayers.forEach((p, rank) => {
                const colorClass = PLAYER_COLORS[p.colorIdx] || 'text-gray-500';
                const bgClass = PLAYER_BG_COLORS[p.colorIdx] || 'bg-gray-50';
                const meMarker = p.isMe ? ' ★' : '';
                const target = data.targetScore || 20;
                const progress = Math.min((p.score / target) * 100, 100);

                scoreHtml += `
                    <div class="flex items-center gap-3 p-2 rounded-xl ${p.isMe ? bgClass + ' ring-2 ring-offset-1 ring-brand-primary/30' : 'bg-white'}">
                        <div class="w-7 h-7 rounded-full ${bgClass} flex items-center justify-center font-black text-sm ${colorClass}">${rank + 1}</div>
                        <div class="flex-1 min-w-0">
                            <div class="flex justify-between items-center">
                                <span class="font-bold text-xs ${colorClass} truncate">${p.name}${meMarker}</span>
                                <span class="font-black text-sm ${colorClass}">${p.score}</span>
                            </div>
                            <div class="h-1.5 bg-gray-100 rounded-full mt-1 overflow-hidden">
                                <div class="h-full rounded-full transition-all duration-300 ${p.colorIdx === 0 ? 'bg-brand-primary' : p.colorIdx === 1 ? 'bg-rose-500' : p.colorIdx === 2 ? 'bg-blue-500' : p.colorIdx === 3 ? 'bg-green-500' : 'bg-purple-500'}" style="width: ${progress}%"></div>
                            </div>
                        </div>
                    </div>
                `;
            });

            scoreboardEl.innerHTML = scoreHtml;
        }

        // ---- RENDER QUESTION ----
        const qEl = document.getElementById('math-question');
        if (qEl) {
            qEl.textContent = data.question.display || `${data.question.a} × ${data.question.b}`;
            qEl.dataset.qid = data.question.id;
        }

        // Reset input if question changed
        const inputDisplay = document.getElementById('math-input-display');
        if (inputDisplay && inputDisplay.dataset.lastQ !== data.question.id.toString()) {
            inputDisplay.textContent = '?';
            inputDisplay.dataset.lastQ = data.question.id;
            inputDisplay.classList.remove('text-green-500', 'text-red-500');
            inputDisplay.classList.add('text-gray-700');
        }

        // Hide keypad for spectators
        const keypadContainer = document.getElementById('math-keypad-container');
        if (keypadContainer) {
            keypadContainer.style.display = myRole === 'spectator' ? 'none' : 'block';
        }

        // Show spectator badge
        if (myRole === 'spectator') {
            let specBadge = document.getElementById('spectator-badge');
            if (!specBadge) {
                specBadge = document.createElement('div');
                specBadge.id = 'spectator-badge';
                specBadge.className = 'absolute top-20 left-1/2 -translate-x-1/2 bg-gray-800 text-white px-4 py-1 rounded-full text-xs font-bold z-50';
                specBadge.textContent = '👀 Spectator Mode';
                document.getElementById('view-math-game').appendChild(specBadge);
            }
        }


    }
    else if (data.status === 'finished') {
        stopMathBacksound();
        if (countdownTimer) {
            clearInterval(countdownTimer);
            countdownTimer = null;
        }

        const myName = state.currentUser?.name;
        if (data.winner && myRole !== 'spectator' && data.winner === myName) {
            recordMathWin(data.winner);
        }

        showNotification(`Game Selesai! Pemenang: ${data.winner} 🏆`, "Selamat!", "success");
        leaveMathGame();
    }
}

// ========================================
// KEYPAD HANDLER - Uses local cached question
// ========================================

window.pressMathKey = async (num) => {
    const disp = document.getElementById('math-input-display');
    if (disp.textContent === '?') disp.textContent = '';
    disp.textContent += num;

    const currentVal = disp.textContent;

    // Check against locally cached question (no server read!)
    if (localQuestion && parseInt(currentVal) === localQuestion.ans) {
        disp.classList.remove('text-gray-700');
        disp.classList.add('text-green-500');
        submitMathAnswer(currentVal);
    }
};

window.clearMathInput = () => {
    const disp = document.getElementById('math-input-display');
    disp.textContent = '?';
    disp.classList.remove('text-green-500', 'text-red-500');
    disp.classList.add('text-gray-700');
}

window.backspaceMathInput = () => {
    const disp = document.getElementById('math-input-display');
    if (disp.textContent !== '?' && disp.textContent.length > 0) {
        disp.textContent = disp.textContent.slice(0, -1) || '?';
    }
}

window.submitMathInput = () => {
    const disp = document.getElementById('math-input-display');
    const val = disp.textContent;
    if (val !== '?') submitMathAnswer(val);
}

// ========================================
// MATH BATTLE LEADERBOARD
// ========================================

async function loadMathLeaderboard() {
    const container = document.getElementById('math-lobby-leaderboard');
    if (!container) return;

    try {
        let users = [];

        if (state.userList && state.userList.length > 0) {
            users = [...state.userList]
                .filter(u => (u.mathWins || 0) > 0)
                .sort((a, b) => (b.mathWins || 0) - (a.mathWins || 0))
                .slice(0, 5);
        } else {
            const usersRef = collection(db, "santri_users");
            const snap = await getDocs(usersRef);

            snap.forEach(d => {
                const data = d.data();
                if (data.mathWins && data.mathWins > 0) {
                    users.push({ id: d.id, ...data });
                }
            });

            users.sort((a, b) => (b.mathWins || 0) - (a.mathWins || 0));
            users = users.slice(0, 5);
        }

        renderMathLobbyLeaderboard(users);
    } catch (e) {
        console.error("Leaderboard error:", e);
        container.innerHTML = '<p class="text-gray-400 text-center text-sm">Belum ada data</p>';
    }
}

function renderMathLobbyLeaderboard(users) {
    const container = document.getElementById('math-lobby-leaderboard');
    if (!container) return;

    if (users.length === 0) {
        container.innerHTML = '<p class="text-gray-400 text-center text-sm">Belum ada champion</p>';
        return;
    }

    let html = '';
    users.forEach((u, i) => {
        const medal = i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : '';
        const isMe = state.currentUser && state.currentUser.name === u.name;

        html += `
            <div class="flex items-center gap-3 p-3 rounded-xl ${isMe ? 'bg-brand-primary/10 border border-brand-primary/20' : 'bg-gray-50'}">
                <div class="w-8 h-8 rounded-full bg-white shadow-sm flex items-center justify-center font-bold text-sm">
                    ${medal || (i + 1)}
                </div>
                <div class="flex-1">
                    <p class="font-bold text-brand-dark text-sm ${isMe ? 'text-brand-primary' : ''}">${u.name}</p>
                </div>
                <div class="text-right">
                    <p class="font-black text-brand-primary">${u.mathWins || 0}</p>
                    <p class="text-[10px] text-gray-400">wins</p>
                </div>
            </div>
        `;
    });

    container.innerHTML = html;
}

// Record win to user's mathWins field
async function recordMathWin(winnerName) {
    const winner = state.userList?.find(u => u.name === winnerName);
    if (!winner || !winner.id) return;

    try {
        const userRef = doc(db, "santri_users", winner.id);
        await updateDoc(userRef, { mathWins: increment(1) });
        console.log("Math win recorded for:", winnerName);
    } catch (e) {
        console.error("Error recording math win:", e);
    }
}

// ========================================
// SPECTATOR MODE
// ========================================

async function spectateRoom() {
    const code = await showRoomCodeModal();
    if (!code) return;

    const roomId = code.trim();
    const roomRef = doc(db, "math_rooms", roomId);
    const snap = await getDoc(roomRef);

    if (!snap.exists()) {
        showNotification("Room tidak ditemukan!", "Error", "error");
        return;
    }

    const data = snap.data();
    // Allow spectators to watch at any stage (including waiting)
    currentRoomId = roomId;
    myRole = 'spectator';
    gameMode = data.mode || '1v1';
    roomLevel = data.level || 1;
    roomTargetScore = data.targetScore || 20;
    subscribeToRoom(roomId);
}

function renderSpectatorLeaderboard(data) {
    const players = data.players || {};
    const playerKeys = Object.keys(players).sort();
    const target = data.targetScore || 20;

    // Sort by score
    const sortedPlayers = playerKeys.map((key, i) => ({
        key,
        name: players[key].name,
        score: players[key].score || 0,
        colorIdx: parseInt(key.split('_')[1])
    })).sort((a, b) => b.score - a.score);

    let html = '';
    sortedPlayers.forEach((p, index) => {
        const rank = index + 1;
        const progress = Math.min((p.score / target) * 100, 100);

        // Colors
        let rankColor = 'bg-white border-gray-100';
        let medal = '';
        let scale = 'scale-100';
        let shadow = 'shadow-sm';

        // Top 3 Styling
        if (rank === 1) {
            rankColor = 'bg-yellow-50 border-yellow-200 ring-4 ring-yellow-100';
            medal = '👑';
            scale = 'scale-105 z-10';
            shadow = 'shadow-xl';
        } else if (rank === 2) {
            rankColor = 'bg-gray-50 border-gray-200';
            medal = '🥈';
            scale = 'scale-100';
            shadow = 'shadow-md';
        } else if (rank === 3) {
            rankColor = 'bg-orange-50 border-orange-200';
            medal = '🥉';
            shadow = 'shadow-md';
        }

        const barColor = p.colorIdx === 0 ? 'bg-brand-primary' :
            p.colorIdx === 1 ? 'bg-rose-500' :
                p.colorIdx === 2 ? 'bg-blue-500' :
                    p.colorIdx === 3 ? 'bg-green-500' : 'bg-purple-500';

        html += `
            <div class="relative transition-all duration-500 transform ${scale}">
                <div class="w-full p-4 rounded-3xl border ${rankColor} ${shadow} flex items-center gap-6">
                    <div class="w-16 h-16 rounded-2xl flex items-center justify-center bg-white shadow-sm font-black text-3xl text-brand-dark border border-gray-100 relative">
                        ${rank}
                        <div class="absolute -top-3 -right-3 text-2xl filter drop-shadow-md animate-bounce" style="animation-duration: 2s">${medal}</div>
                    </div>
                    
                    <div class="flex-1">
                        <div class="flex justify-between items-end mb-2">
                            <h3 class="text-2xl font-bold text-brand-dark truncate max-w-[300px]">${p.name}</h3>
                            <div class="text-right">
                                <span class="text-4xl font-black text-brand-primary">${p.score}</span>
                                <span class="text-gray-400 font-bold ml-1">/ ${target}</span>
                            </div>
                        </div>
                        
                        <div class="h-6 w-full bg-gray-200 rounded-full overflow-hidden shadow-inner">
                            <div class="h-full rounded-full transition-all duration-700 ease-out ${barColor} relative overflow-hidden" style="width: ${progress}%">
                                <div class="absolute inset-0 bg-white/20 animate-pulse"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    });
    return html;
}
