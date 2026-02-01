import { db } from './config.js';
import { doc, getDoc, setDoc, updateDoc, onSnapshot, increment, collection, getDocs, query, orderBy, limit } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";
import { state } from './state.js';
import { switchView } from './ui.js';

let mathUnsub = null;
let currentRoomId = null;
let myRole = null; // Store role to avoid name-based detection issues

export function initMath() {
    // Expose functions globally for HTML buttons
    window.createMathRoom = createMathRoom;
    window.joinMathRoom = joinMathRoom;
    window.submitMathAnswer = submitMathAnswer;
    window.leaveMathGame = leaveMathGame;
    window.spectateRoom = spectateRoom;
    window.loadMathLeaderboard = loadMathLeaderboard;
}

// --- LOBBY LOGIC ---

async function createMathRoom() {
    const roomId = Math.floor(1000 + Math.random() * 9000).toString();
    currentRoomId = roomId;

    const roomRef = doc(db, "math_rooms", roomId);

    // Get player name from state
    const playerName = state.currentUser?.name || 'Player 1';
    console.log('Creating room with player:', playerName, 'state.currentUser:', state.currentUser);

    // Initial State
    await setDoc(roomRef, {
        status: 'waiting',
        players: {
            host: {
                name: playerName,
                score: 0
            }
        },
        question: generateMathQuestion(),
        createdAt: new Date().toISOString()
    });

    myRole = 'host'; // Set role for this session
    subscribeToRoom(roomId, 'host');
}

async function joinMathRoom() {
    // Show custom modal for room code input
    const code = await showRoomCodeModal();
    if (!code) return;

    const roomId = code.trim();
    const roomRef = doc(db, "math_rooms", roomId);
    const snap = await getDoc(roomRef);

    if (!snap.exists()) {
        alert("Room tidak ditemukan!");
        return;
    }

    const data = snap.data();
    if (data.status !== 'waiting') {
        alert("Game sudah berjalan atau penuh!");
        return;
    }

    // Add Guest - start countdown instead of playing immediately
    await updateDoc(roomRef, {
        "players.guest": {
            name: state.currentUser?.name || 'Player 2',
            score: 0
        },
        status: 'countdown', // Start countdown first
        countdownStart: Date.now()
    });

    currentRoomId = roomId;
    myRole = 'guest'; // Set role for this session
    subscribeToRoom(roomId, 'guest');
}

// Custom modal for room code input
function showRoomCodeModal() {
    return new Promise((resolve) => {
        // Create modal HTML
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

        // Focus input
        setTimeout(() => input.focus(), 100);

        // Handle cancel
        cancelBtn.onclick = () => {
            modal.remove();
            resolve(null);
        };

        // Handle submit
        submitBtn.onclick = () => {
            const val = input.value.trim();
            modal.remove();
            resolve(val || null);
        };

        // Handle enter key
        input.onkeydown = (e) => {
            if (e.key === 'Enter') {
                const val = input.value.trim();
                modal.remove();
                resolve(val || null);
            }
        };

        // Close on backdrop click
        modal.onclick = (e) => {
            if (e.target === modal) {
                modal.remove();
                resolve(null);
            }
        };
    });
}

function subscribeToRoom(roomId, role) {
    if (mathUnsub) mathUnsub();

    const roomRef = doc(db, "math_rooms", roomId);

    mathUnsub = onSnapshot(roomRef, (doc) => {
        if (!doc.exists()) {
            alert("Room dibubarkan.");
            leaveMathGame();
            return;
        }

        const data = doc.data();
        renderMathUI(data, role);
    });
}

function leaveMathGame() {
    if (mathUnsub) mathUnsub();
    currentRoomId = null;
    myRole = null; // Clear role
    switchView('menu');
}

// --- GAME LOGIC ---

function generateMathQuestion() {
    const a = Math.floor(Math.random() * 10) + 1;
    const b = Math.floor(Math.random() * 10) + 1;
    return { a, b, ans: a * b, id: Date.now() }; // ID to prevent double answering old q
}

async function submitMathAnswer(val) {
    if (!currentRoomId) return;

    // Optimistic UI check? No, wait for server to be safe for "Race"
    // Actually, we can check locally against DOM to give immediate feedback (red/green)
    // but actual update must be server side.

    const roomRef = doc(db, "math_rooms", currentRoomId);
    const snap = await getDoc(roomRef);
    const data = snap.data();

    // Check if correct
    if (parseInt(val) === data.question.ans) {
        // RACE CONDITION HANDLING:
        // We assume whoever's update hits server first wins. 
        // We key the update by "question.id" ideally, but simple update works for low traffic.

        // Use stored role (set when creating/joining)
        const playerRole = myRole || 'host';

        // Check if winner - need 20 points to win
        const newScore = data.players[playerRole].score + 1;
        const isWin = newScore >= 20;

        await updateDoc(roomRef, {
            [`players.${playerRole}.score`]: increment(1),
            question: generateMathQuestion(), // NEW QUESTION for both
            status: isWin ? 'finished' : 'playing',
            winner: isWin ? data.players[playerRole].name : null
        });

    }
    // No feedback for wrong answers - just let player retry
}


// --- UI RENDERING ---

let countdownTimer = null;

function renderMathUI(data, myRole) {
    if (data.status === 'waiting') {
        switchView('math-room');
        document.getElementById('math-room-code').textContent = currentRoomId;
        document.getElementById('math-player-list').innerHTML = `
            <li class="font-bold text-brand-primary">${data.players.host.name} (Host)</li>
            <li class="text-gray-400 italic">Menunggu lawan...</li>
        `;
    }
    else if (data.status === 'countdown') {
        // Show countdown screen
        switchView('math-room');
        document.getElementById('math-room-code').textContent = currentRoomId;

        // Start countdown timer if not already running
        if (!countdownTimer) {
            let countdown = 5;
            document.getElementById('math-player-list').innerHTML = `
                <li class="font-bold text-brand-primary">${data.players.host.name}</li>
                <li class="font-bold text-rose-500">${data.players.guest.name}</li>
                <li class="text-4xl font-black text-brand-primary mt-4 animate-pulse">${countdown}</li>
            `;

            countdownTimer = setInterval(async () => {
                countdown--;
                if (countdown > 0) {
                    document.getElementById('math-player-list').innerHTML = `
                        <li class="font-bold text-brand-primary">${data.players.host.name}</li>
                        <li class="font-bold text-rose-500">${data.players.guest.name}</li>
                        <li class="text-4xl font-black text-brand-primary mt-4 animate-pulse">${countdown}</li>
                    `;
                } else {
                    clearInterval(countdownTimer);
                    countdownTimer = null;
                    // Start the game!
                    const roomRef = doc(db, "math_rooms", currentRoomId);
                    await updateDoc(roomRef, { status: 'playing' });
                }
            }, 1000);
        }
    }
    else if (data.status === 'playing') {
        // Clear countdown timer if still running
        if (countdownTimer) {
            clearInterval(countdownTimer);
            countdownTimer = null;
        }

        switchView('math-game');

        // Scoreboard
        document.getElementById('score-p1').textContent = data.players.host.score;
        document.getElementById('score-p2').textContent = data.players.guest.score;
        document.getElementById('name-p1').textContent = data.players.host.name;
        document.getElementById('name-p2').textContent = data.players.guest.name;

        // Question
        const qEl = document.getElementById('math-question');
        qEl.textContent = `${data.question.a} x ${data.question.b}`;
        qEl.dataset.qid = data.question.id; // Store ID to track changes

        // Reset inputs if question changed
        const inputDisplay = document.getElementById('math-input-display');
        // Logic: if question ID changed, clear input
        if (inputDisplay.dataset.lastQ !== data.question.id.toString()) {
            inputDisplay.textContent = '?';
            inputDisplay.dataset.lastQ = data.question.id;
            inputDisplay.classList.remove('text-green-500', 'text-red-500');
            inputDisplay.classList.add('text-gray-700');
        }
        // Hide keypad for spectators
        const keypad = document.querySelector('#view-math-game .grid.grid-cols-4');
        if (keypad) {
            keypad.style.display = myRole === 'spectator' ? 'none' : 'grid';
        }

        // Show spectator badge
        const specBadge = document.getElementById('spectator-badge');
        if (myRole === 'spectator' && !specBadge) {
            const badge = document.createElement('div');
            badge.id = 'spectator-badge';
            badge.className = 'absolute top-20 left-1/2 -translate-x-1/2 bg-gray-800 text-white px-4 py-1 rounded-full text-xs font-bold z-50';
            badge.textContent = '👀 Spectator Mode';
            document.getElementById('view-math-game').appendChild(badge);
        }
    }
    else if (data.status === 'finished') {
        if (countdownTimer) {
            clearInterval(countdownTimer);
            countdownTimer = null;
        }

        // Record win to leaderboard (only if I am the winner, not spectator)
        const myName = state.currentUser?.name;
        if (data.winner && myRole !== 'spectator' && data.winner === myName) {
            recordMathWin(data.winner);
        }

        alert(`Game Selesai! Pemenang: ${data.winner}`);
        leaveMathGame();
    }
}

// Keypad Handler - Auto-submit when answer is correct
window.pressMathKey = async (num) => {
    const disp = document.getElementById('math-input-display');
    if (disp.textContent === '?') disp.textContent = '';

    disp.textContent += num;
    const currentVal = disp.textContent;

    // Auto-check if answer is correct and submit automatically
    if (currentRoomId) {
        const roomRef = doc(db, "math_rooms", currentRoomId);
        const snap = await getDoc(roomRef);
        if (snap.exists()) {
            const data = snap.data();
            const correctAns = data.question.ans;

            if (parseInt(currentVal) === correctAns) {
                // Correct! Auto-submit and next question
                disp.classList.remove('text-gray-700');
                disp.classList.add('text-green-500');
                submitMathAnswer(currentVal);
            }
            // No feedback for wrong answers - just wait for correct input
        }
    }
};

window.clearMathInput = () => {
    document.getElementById('math-input-display').textContent = '?';
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
    const container = document.getElementById('math-leaderboard');
    if (!container) return;

    try {
        let users = [];

        // Try to use state.userList first (already loaded)
        if (state.userList && state.userList.length > 0) {
            users = [...state.userList]
                .filter(u => (u.mathWins || 0) > 0)
                .sort((a, b) => (b.mathWins || 0) - (a.mathWins || 0))
                .slice(0, 5);
        } else {
            // Fallback: fetch all users and sort client-side (no index needed)
            const usersRef = collection(db, "santri_users");
            const snap = await getDocs(usersRef);

            snap.forEach(d => {
                const data = d.data();
                if (data.mathWins && data.mathWins > 0) {
                    users.push({ id: d.id, ...data });
                }
            });

            // Sort client-side
            users.sort((a, b) => (b.mathWins || 0) - (a.mathWins || 0));
            users = users.slice(0, 5);
        }

        renderMathLeaderboard(users);
    } catch (e) {
        console.error("Leaderboard error:", e);
        container.innerHTML = '<p class="text-gray-400 text-center text-sm">Belum ada data</p>';
    }
}

function renderMathLeaderboard(users) {
    const container = document.getElementById('math-leaderboard');
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
    // Find user by name in state.userList
    const winner = state.userList?.find(u => u.name === winnerName);
    if (!winner || !winner.id) {
        console.log("Winner not found in userList:", winnerName);
        return;
    }

    try {
        const userRef = doc(db, "santri_users", winner.id);
        await updateDoc(userRef, {
            mathWins: increment(1)
        });
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
        alert("Room tidak ditemukan!");
        return;
    }

    const data = snap.data();
    if (data.status === 'waiting') {
        alert("Game belum dimulai, tunggu sampai ada 2 pemain!");
        return;
    }

    currentRoomId = roomId;
    myRole = 'spectator'; // Set as spectator
    subscribeToRoom(roomId, 'spectator');
}

