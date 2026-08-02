import { db } from './config.js';
import { doc, getDoc, setDoc, updateDoc, onSnapshot, increment, deleteDoc } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";
import { state } from './state.js';
import { switchView } from './ui.js';
import { showNotification } from './dialogs.js';
import { getCCAQuestions, shuffleArray } from './cca-questions.js';

// ========================================
// STATE
// ========================================
let ccaUnsub = null;
let ccaRoomId = null;
let ccaRole = null; // 'team_0', 'team_1', ... or 'spectator'
let ccaIsHost = false;
let ccaTimer = null;
let localQ = 0; // local question index for babak 1
let localAnswers = {}; // local cache of answers { 0: optionIndex, 1: optionIndex, ... }
let eliminatedSet = new Set(); // host tracks which teams to eliminate

const TEAM_COLORS = ['#6366f1', '#ec4899', '#22c55e', '#f59e0b', '#06b6d4'];
const TEAM_NAMES_DEFAULT = ['Tim A', 'Tim B', 'Tim C', 'Tim D', 'Tim E'];
const BABAK1_DURATION = 20 * 60; // 20 minutes in seconds
const BABAK2_TIME_A = 20; // seconds per question (first 20)
const BABAK2_TIME_B = 15; // seconds per question (last 20)
const BABAK2_SPLIT = 20; // first 20 questions use TIME_A

function getBabak2Timer(qIndex) {
    return qIndex < BABAK2_SPLIT ? BABAK2_TIME_A : BABAK2_TIME_B;
}

// ========================================
// INIT
// ========================================
export function initCCA() {
    window.createCCARoom = createCCARoom;
    window.joinCCARoom = joinCCARoom;
    window.leaveCCAGame = leaveCCAGame;
    window.startCCA = startCCA;
    window.answerCCA = answerCCA;
    window.buzzerCCA = buzzerCCA;
    window.nextBabak = nextBabakWithElimination;
    window.showCCAModePicker = showCCAModePicker;
    window.finishBabak1 = finishBabak1;
    window.ccaNavTo = ccaNavTo;
    window.ccaNext = ccaNext;
    window.ccaPrev = ccaPrev;
    window.toggleEliminate = toggleEliminate;
    window.nextBabakWithElimination = nextBabakWithElimination;
}

// ========================================
// MODE PICKER
// ========================================
function showCCAModePicker() {
    return new Promise((resolve) => {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black/50 flex items-center justify-center z-[100] p-6';
        modal.innerHTML = `
            <div class="bg-white rounded-3xl p-6 w-full max-w-sm shadow-2xl">
                <h3 class="text-2xl font-black text-brand-dark mb-2 text-center">Cerdas Cermat Agama 🕌</h3>
                <p class="text-gray-400 text-xs text-center mb-6">Uji pengetahuan agama Islam!</p>
                <div class="space-y-3">
                    <button id="cca-create" class="w-full py-5 rounded-2xl text-white font-bold text-lg shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-3"
                        style="background:linear-gradient(to right,#10b981,#14b8a6)">
                        <span class="text-2xl">👨‍🏫</span>
                        <div class="text-left">
                            <div class="font-black" style="color:white">Buat Room (Guru)</div>
                            <div class="text-xs font-normal" style="color:rgba(255,255,255,0.8)">Buat room & atur lomba</div>
                        </div>
                    </button>
                    <button id="cca-join" class="w-full py-5 rounded-2xl text-white font-bold text-lg shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-3"
                        style="background:linear-gradient(to right,#6366f1,#a855f7)">
                        <span class="text-2xl">🏃</span>
                        <div class="text-left">
                            <div class="font-black" style="color:white">Join Room (Peserta)</div>
                            <div class="text-xs font-normal" style="color:rgba(255,255,255,0.8)">Masuk room dengan kode</div>
                        </div>
                    </button>
                    <div style="border-top:1px solid #e5e7eb;margin:8px 0"></div>
                    <button id="cca-join-final" class="w-full py-5 rounded-2xl text-white font-bold text-lg shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-3"
                        style="background:linear-gradient(to right,#f59e0b,#f97316)">
                        <span class="text-2xl">🏆</span>
                        <div class="text-left">
                            <div class="font-black" style="color:white">Join Final CCA</div>
                            <div class="text-xs font-normal" style="color:rgba(255,255,255,0.8)">Babak 3 — Rebutan Berisiko</div>
                        </div>
                    </button>
                    <button id="cca-cancel" class="w-full py-3 rounded-xl font-bold text-sm" style="background:#f3f4f6;color:#6b7280">
                        Batal
                    </button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);

        modal.querySelector('#cca-create').onclick = () => { modal.remove(); resolve('create'); };
        modal.querySelector('#cca-join').onclick = () => { modal.remove(); resolve('join'); };
        modal.querySelector('#cca-join-final').onclick = () => { modal.remove(); resolve('join-final'); };
        modal.querySelector('#cca-cancel').onclick = () => { modal.remove(); resolve(null); };
        modal.onclick = (e) => { if (e.target === modal) { modal.remove(); resolve(null); } };
    });
}

// ========================================
// ROOM CODE MODAL
// ========================================
function showCCACodeModal() {
    return new Promise((resolve) => {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black/50 flex items-center justify-center z-[100] p-6';
        modal.innerHTML = `
            <div class="bg-white rounded-3xl p-6 w-full max-w-sm shadow-2xl">
                <h3 class="text-xl font-black text-brand-dark mb-4 text-center">Masukkan Kode Room</h3>
                <input id="cca-code-input" type="text" inputmode="numeric" maxlength="4"
                    class="w-full text-center text-4xl font-black tracking-[0.5em] py-4 border-2 border-gray-200 rounded-2xl focus:border-emerald-500 focus:outline-none"
                    placeholder="____" autocomplete="off">
                <div class="flex gap-3 mt-4">
                    <button id="cca-code-cancel" class="flex-1 py-3 rounded-xl bg-gray-100 text-gray-500 font-bold">Batal</button>
                    <button id="cca-code-ok" class="flex-1 py-3 rounded-xl bg-emerald-500 text-white font-bold">Join</button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
        const input = modal.querySelector('#cca-code-input');
        input.focus();

        modal.querySelector('#cca-code-ok').onclick = () => { const v = input.value.trim(); modal.remove(); resolve(v || null); };
        modal.querySelector('#cca-code-cancel').onclick = () => { modal.remove(); resolve(null); };
        input.onkeydown = (e) => {
            if (e.key === 'Enter') { const v = input.value.trim(); modal.remove(); resolve(v || null); }
        };
        modal.onclick = (e) => { if (e.target === modal) { modal.remove(); resolve(null); } };
    });
}

// ========================================
// CREATE ROOM (GURU)
// ========================================
async function createCCARoom() {
    const roomId = Math.floor(1000 + Math.random() * 9000).toString();
    ccaRoomId = roomId;
    ccaIsHost = true;
    ccaRole = 'spectator';

    const hostName = state.currentUser?.name || 'Guru';
    const questions = getCCAQuestions(30, 40);

    const roomRef = doc(db, "cca_rooms", roomId);
    await setDoc(roomRef, {
        status: 'waiting',
        hostName: hostName,
        teams: {},
        teamCount: 0,
        maxTeams: 5,
        currentBabak: 0,
        babak1Questions: questions.babak1.map(q => ({
            q: q.q,
            options: q.options,
            answer: q.answer,
            category: q.category
        })),
        babak2Questions: questions.babak2.map(q => ({
            q: q.q,
            options: q.options,
            answer: q.answer,
            category: q.category
        })),
        // Babak 2 shared state
        currentQ: 0,
        buzzerLock: null,
        lockedTeams: [],
        timerEnd: null,
        // Babak 1: each team tracks own progress
        teamProgress: {},
        createdAt: new Date().toISOString()
    });

    subscribeToCCA(roomId);
}

// ========================================
// JOIN ROOM (PESERTA)
// ========================================
async function joinCCARoom() {
    const code = await showCCACodeModal();
    if (!code) return;

    const roomId = code.trim();
    const roomRef = doc(db, "cca_rooms", roomId);
    const snap = await getDoc(roomRef);

    if (!snap.exists()) {
        showNotification("Room tidak ditemukan!", "Error", "error");
        return;
    }

    const data = snap.data();
    if (data.status !== 'waiting') {
        showNotification("Lomba sudah berjalan!", "Tidak Bisa Join", "warning");
        return;
    }

    const teamCount = data.teamCount || Object.keys(data.teams || {}).length;
    if (teamCount >= (data.maxTeams || 5)) {
        showNotification("Room penuh!", "Room Penuh", "warning");
        return;
    }

    const teamKey = `team_${teamCount}`;
    const teamName = state.currentUser?.name || TEAM_NAMES_DEFAULT[teamCount];

    await updateDoc(roomRef, {
        [`teams.${teamKey}`]: { name: teamName, score: 0 },
        teamCount: increment(1)
    });

    ccaRoomId = roomId;
    ccaRole = teamKey;
    ccaIsHost = false;
    localQ = 0;
    localAnswers = {};
    subscribeToCCA(roomId);
}

// ========================================
// SUBSCRIBE
// ========================================
function subscribeToCCA(roomId) {
    if (ccaUnsub) ccaUnsub();

    const roomRef = doc(db, "cca_rooms", roomId);
    ccaUnsub = onSnapshot(roomRef, (docSnap) => {
        if (!docSnap.exists()) {
            showNotification("Room dibubarkan.", "Selesai", "info");
            leaveCCAGame();
            return;
        }
        const data = docSnap.data();

        // Babak 1: host checks if time is up or all teams finished
        if (data.status === 'babak1' && ccaIsHost) {
            checkBabak1End(data);
        }

        renderCCAUI(data);
    });
}

// ========================================
// LEAVE
// ========================================
function leaveCCAGame() {
    if (ccaUnsub) ccaUnsub();
    ccaUnsub = null;
    ccaRoomId = null;
    ccaRole = null;
    ccaIsHost = false;
    localAnswers = {};
    localQ = 0;
    if (ccaTimer) { clearInterval(ccaTimer); ccaTimer = null; }
    switchView('menu');
}

// ========================================
// HOST: START GAME
// ========================================
async function startCCA() {
    if (!ccaRoomId || !ccaIsHost) return;

    const roomRef = doc(db, "cca_rooms", ccaRoomId);
    const snap = await getDoc(roomRef);
    if (!snap.exists()) return;

    const data = snap.data();
    const teamCount = data.teamCount || Object.keys(data.teams || {}).length;

    if (teamCount < 2) {
        showNotification("Minimal 2 tim untuk mulai!", "Tunggu Tim", "warning");
        return;
    }

    // Init teamProgress for each team
    const teamProgress = {};
    Object.keys(data.teams).forEach(key => {
        teamProgress[key] = { currentQ: 0, answers: {}, finished: false };
    });

    await updateDoc(roomRef, {
        status: 'babak1',
        currentBabak: 1,
        teamProgress: teamProgress,
        timerEnd: Date.now() + (BABAK1_DURATION * 1000) // 20 minutes
    });
}

// ========================================
// HOST: NEXT BABAK (with elimination)
// ========================================
function toggleEliminate(teamKey) {
    if (eliminatedSet.has(teamKey)) {
        eliminatedSet.delete(teamKey);
    } else {
        eliminatedSet.add(teamKey);
    }
    // Re-render to update checkboxes
    const roomRef = doc(db, "cca_rooms", ccaRoomId);
    getDoc(roomRef).then(snap => {
        if (snap.exists()) renderCCAUI(snap.data());
    });
}

async function nextBabakWithElimination() {
    if (!ccaRoomId || !ccaIsHost) return;

    const roomRef = doc(db, "cca_rooms", ccaRoomId);
    await updateDoc(roomRef, {
        status: 'babak2',
        currentBabak: 2,
        currentQ: 0,
        buzzerLock: null,
        lockedTeams: [],
        eliminatedTeams: Array.from(eliminatedSet),
        timerEnd: Date.now() + (getBabak2Timer(0) * 1000)
    });
}

// ========================================
// BABAK 1: ANSWER (save answer, allow changing before finish)
// ========================================
async function answerCCA(optionIndex) {
    if (!ccaRoomId || !ccaRole || ccaRole === 'spectator') return;

    const roomRef = doc(db, "cca_rooms", ccaRoomId);
    const snap = await getDoc(roomRef);
    if (!snap.exists()) return;
    const data = snap.data();

    const myProgress = data.teamProgress?.[ccaRole];
    if (!myProgress || myProgress.finished) return;

    const questions = data.babak1Questions || [];
    const q = questions[localQ];
    if (!q) return;

    // Check if changing answer
    const oldAnswer = localAnswers[localQ];
    const isChanging = oldAnswer !== undefined;
    const oldWasCorrect = isChanging && oldAnswer === q.answer;
    const newIsCorrect = optionIndex === q.answer;

    // Same answer clicked — ignore
    if (isChanging && oldAnswer === optionIndex) return;

    // Save locally
    localAnswers[localQ] = optionIndex;

    const answeredCount = Object.keys(localAnswers).length;

    // Build Firestore updates
    const updates = {
        [`teamProgress.${ccaRole}.answers.q${localQ}`]: optionIndex,
        [`teamProgress.${ccaRole}.currentQ`]: answeredCount,
    };

    // Adjust score: undo old correct, add new correct
    if (oldWasCorrect && !newIsCorrect) {
        updates[`teams.${ccaRole}.score`] = increment(-10);
    } else if (!oldWasCorrect && newIsCorrect) {
        updates[`teams.${ccaRole}.score`] = increment(10);
    }

    await updateDoc(roomRef, updates);

    // Re-render
    const updatedSnap = await getDoc(roomRef);
    if (updatedSnap.exists()) {
        renderCCAUI(updatedSnap.data());
    }
}

// ========================================
// BABAK 1: NAVIGATION
// ========================================
function ccaNavTo(qIdx) {
    localQ = qIdx;
    // Force re-render with current data
    const roomRef = doc(db, "cca_rooms", ccaRoomId);
    getDoc(roomRef).then(snap => {
        if (snap.exists()) renderCCAUI(snap.data());
    });
}

function ccaNext() {
    // Find next unanswered, or just go to next
    const roomRef = doc(db, "cca_rooms", ccaRoomId);
    getDoc(roomRef).then(snap => {
        if (!snap.exists()) return;
        const totalQ = (snap.data().babak1Questions || []).length;
        if (localQ < totalQ - 1) {
            localQ++;
            renderCCAUI(snap.data());
        }
    });
}

function ccaPrev() {
    if (localQ > 0) {
        localQ--;
        const roomRef = doc(db, "cca_rooms", ccaRoomId);
        getDoc(roomRef).then(snap => {
            if (snap.exists()) renderCCAUI(snap.data());
        });
    }
}

// ========================================
// BABAK 1: TEAM CLICKS "SELESAI" (with confirmation)
// ========================================
async function finishBabak1() {
    if (!ccaRoomId || !ccaRole || ccaRole === 'spectator') return;

    const roomRef = doc(db, "cca_rooms", ccaRoomId);
    const snap = await getDoc(roomRef);
    if (!snap.exists()) return;
    const data = snap.data();
    const totalQ = (data.babak1Questions || []).length;
    const answeredCount = Object.keys(localAnswers).length;
    const unanswered = totalQ - answeredCount;

    // Show confirmation dialog
    const confirmed = await showFinishConfirmation(answeredCount, totalQ, unanswered);
    if (!confirmed) return;

    await updateDoc(roomRef, {
        [`teamProgress.${ccaRole}.finished`]: true
    });
}

// Confirmation dialog before finishing
function showFinishConfirmation(answered, total, unanswered) {
    return new Promise((resolve) => {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black/50 flex items-center justify-center z-[100] p-6';
        modal.innerHTML = `
            <div class="bg-white rounded-3xl p-6 w-full max-w-sm shadow-2xl">
                <div class="text-center mb-4">
                    <div class="text-5xl mb-3">${unanswered > 0 ? '⚠️' : '✅'}</div>
                    <h3 class="text-xl font-black text-brand-dark mb-2">Yakin selesai?</h3>
                    ${unanswered > 0 ? `
                        <p class="text-red-500 font-bold text-sm mb-1">Masih ada ${unanswered} soal belum dijawab!</p>
                        <p class="text-gray-400 text-xs">Soal yang belum dijawab tidak akan mendapat nilai.</p>
                    ` : `
                        <p class="text-green-600 font-bold text-sm">Semua ${total} soal sudah dijawab ✅</p>
                    `}
                </div>
                <div class="bg-gray-50 rounded-xl p-3 mb-4 text-center">
                    <p class="text-sm text-gray-500">Dijawab: <span class="font-black text-brand-primary">${answered}/${total}</span></p>
                </div>
                <div class="flex gap-3">
                    <button id="confirm-cancel" class="flex-1 py-3 rounded-xl bg-gray-100 text-gray-500 font-bold">Kembali</button>
                    <button id="confirm-ok" class="flex-1 py-3 rounded-xl ${unanswered > 0 ? 'bg-yellow-500' : 'bg-green-500'} text-white font-bold">Ya, Selesai!</button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
        modal.querySelector('#confirm-cancel').onclick = () => { modal.remove(); resolve(false); };
        modal.querySelector('#confirm-ok').onclick = () => { modal.remove(); resolve(true); };
        modal.onclick = (e) => { if (e.target === modal) { modal.remove(); resolve(false); } };
    });
}

// ========================================
// BABAK 1: CHECK IF ALL DONE OR TIME UP (host only)
// ========================================
async function checkBabak1End(data) {
    if (!ccaIsHost || data.status !== 'babak1') return;

    const teamProgress = data.teamProgress || {};
    const teamKeys = Object.keys(data.teams || {});
    const allFinished = teamKeys.every(k => teamProgress[k]?.finished);
    const timeUp = data.timerEnd && Date.now() >= data.timerEnd;

    if (allFinished || timeUp) {
        // Calculate final scores (already tracked via increment)
        const roomRef = doc(db, "cca_rooms", ccaRoomId);
        await updateDoc(roomRef, {
            status: 'hasil1',
            timerEnd: null
        });
    }
}

// ========================================
// BABAK 2: ANSWER (no buzzer lock)
// ========================================
async function buzzerCCA(optionIndex) {
    if (!ccaRoomId || !ccaRole || ccaRole === 'spectator') return;

    const roomRef = doc(db, "cca_rooms", ccaRoomId);
    const snap = await getDoc(roomRef);
    if (!snap.exists()) return;

    const data = snap.data();

    // Am I eliminated?
    if ((data.eliminatedTeams || []).includes(ccaRole)) return;

    // Am I locked out?
    if (data.lockedTeams && data.lockedTeams.includes(ccaRole)) return;

    const questions = data.babak2Questions;
    const q = questions[data.currentQ];
    const isCorrect = optionIndex === q.answer;

    if (isCorrect) {
        // Correct → score + next question
        const nextQ = data.currentQ + 1;
        const isFinished = nextQ >= questions.length;

        await updateDoc(roomRef, {
            [`teams.${ccaRole}.score`]: increment(20),
            lockedTeams: [],
            currentQ: isFinished ? data.currentQ : nextQ,
            status: isFinished ? 'hasil2' : 'babak2',
            timerEnd: isFinished ? null : Date.now() + (getBabak2Timer(nextQ) * 1000)
        });
    } else {
        // Wrong → lock this team, others can still answer
        const newLocked = [...(data.lockedTeams || []), ccaRole];
        const eliminated = data.eliminatedTeams || [];
        const activeTeamCount = Object.keys(data.teams || {}).filter(k => !eliminated.includes(k)).length;

        // If all active teams are locked → next question (nobody got it right)
        if (newLocked.length >= activeTeamCount) {
            const nextQ = data.currentQ + 1;
            const isFinished = nextQ >= questions.length;

            await updateDoc(roomRef, {
                lockedTeams: [],
                currentQ: isFinished ? data.currentQ : nextQ,
                status: isFinished ? 'hasil2' : 'babak2',
                timerEnd: isFinished ? null : Date.now() + (getBabak2Timer(nextQ) * 1000)
            });
        } else {
            await updateDoc(roomRef, {
                lockedTeams: newLocked
            });
        }
    }
}

// ========================================
// TIMER (host auto-advances babak 2, checks babak 1 end)
// ========================================
function startTimerCheck(data) {
    if (ccaTimer) { clearInterval(ccaTimer); ccaTimer = null; }

    if (!ccaIsHost || !data.timerEnd) return;

    ccaTimer = setInterval(async () => {
        const remaining = Math.max(0, Math.ceil((data.timerEnd - Date.now()) / 1000));
        if (remaining <= 0) {
            clearInterval(ccaTimer);
            ccaTimer = null;

            if (data.currentBabak === 1) {
                const roomRef = doc(db, "cca_rooms", ccaRoomId);
                await updateDoc(roomRef, {
                    status: 'hasil1',
                    timerEnd: null
                });
            } else if (data.currentBabak === 2) {
                const roomRef = doc(db, "cca_rooms", ccaRoomId);
                const snap = await getDoc(roomRef);
                if (!snap.exists()) return;
                const d = snap.data();
                const nextQ = d.currentQ + 1;
                const isFinished = nextQ >= d.babak2Questions.length;

                await updateDoc(roomRef, {
                    lockedTeams: [],
                    currentQ: isFinished ? d.currentQ : nextQ,
                    status: isFinished ? 'hasil2' : 'babak2',
                    timerEnd: isFinished ? null : Date.now() + (getBabak2Timer(nextQ) * 1000)
                });
            }
        }
    }, 1000);
}

// ========================================
// RENDER UI
// ========================================
function renderCCAUI(data) {
    const container = document.getElementById('cca-game-area');
    if (!container) return;

    const ccaView = document.getElementById('view-cca');
    if (ccaView) ccaView.classList.remove('hidden');

    const teams = data.teams || {};
    const sortedTeams = Object.entries(teams)
        .map(([key, t]) => ({ key, ...t }))
        .sort((a, b) => (b.score || 0) - (a.score || 0));

    const teamCount = Object.keys(teams).length;
    const hostName = data.hostName || 'Guru';
    const isHost = ccaIsHost;

    // ==================
    // WAITING ROOM
    // ==================
    if (data.status === 'waiting') {
        let teamListHtml = sortedTeams.map((t, i) => `
            <div class="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
                <div class="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold" style="background:${TEAM_COLORS[i % TEAM_COLORS.length]}">${i + 1}</div>
                <span class="font-bold text-brand-dark">${t.name}</span>
            </div>
        `).join('');

        if (teamCount === 0) {
            teamListHtml = '<p class="text-gray-400 text-center text-sm py-4">Belum ada tim yang bergabung...</p>';
        }

        container.innerHTML = `
            <div class="flex flex-col items-center justify-center min-h-[60vh] p-6">
                <div class="bg-white rounded-3xl p-6 w-full max-w-md shadow-xl">
                    <div class="text-center mb-6">
                        <div class="text-5xl mb-2">🕌</div>
                        <h2 class="text-2xl font-black text-brand-dark">Cerdas Cermat Agama</h2>
                        <p class="text-gray-400 text-xs mt-1">Host: ${hostName}</p>
                    </div>
                    <div class="text-center py-4 rounded-2xl mb-6" style="background:linear-gradient(to right,#10b981,#14b8a6);color:white">
                        <p class="text-xs opacity-80">KODE ROOM</p>
                        <p class="text-4xl font-black tracking-widest">${ccaRoomId}</p>
                    </div>
                    <div class="mb-4">
                        <p class="text-sm font-bold text-gray-500 mb-2">Tim (${teamCount}/5)</p>
                        <div class="space-y-2">${teamListHtml}</div>
                    </div>
                    <div id="cca-start-btn-container">
                        ${isHost && teamCount >= 2 ? `
                            <button onclick="startCCA()" class="w-full py-4 rounded-2xl font-bold text-lg shadow-lg transition-all flex items-center justify-center gap-2 animate-pulse" style="background:#22c55e;color:white">
                                <i class="fas fa-play"></i> Mulai Lomba! (${teamCount} tim)
                            </button>
                        ` : isHost ? `
                            <p class="text-gray-400 text-xs text-center">Minimal 2 tim untuk mulai</p>
                        ` : `
                            <p class="text-gray-400 text-xs text-center">Menunggu guru memulai lomba...</p>
                        `}
                    </div>
                </div>
                <button onclick="leaveCCAGame()" class="mt-4 text-gray-400 text-sm underline">Keluar Room</button>
            </div>
        `;
        return;
    }

    // ==================
    // BABAK 1 - PENYISIHAN (independent, 20 min global timer)
    // ==================
    if (data.status === 'babak1') {
        startTimerCheck(data);
        const questions = data.babak1Questions || [];
        const totalQ = questions.length;
        const isSpectator = ccaRole === 'spectator';

        // Global timer
        const remaining = data.timerEnd ? Math.max(0, Math.ceil((data.timerEnd - Date.now()) / 1000)) : 0;
        const minutes = Math.floor(remaining / 60);
        const seconds = remaining % 60;
        const timerStr = `${minutes}:${String(seconds).padStart(2, '0')}`;
        const timerColor = remaining <= 60 ? 'text-red-500' : 'text-emerald-600';

        // SPECTATOR / HOST VIEW: show progress of all teams
        if (isSpectator) {
            const teamProgress = data.teamProgress || {};
            let progressHtml = Object.entries(teams).map(([key, t], i) => {
                const prog = teamProgress[key] || { currentQ: 0, finished: false };
                const pct = Math.round((prog.currentQ / totalQ) * 100);
                return `
                    <div class="p-3 rounded-xl bg-gray-50">
                        <div class="flex items-center gap-2 mb-2">
                            <div class="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold" style="background:${TEAM_COLORS[i % TEAM_COLORS.length]}">${i + 1}</div>
                            <span class="font-bold text-brand-dark flex-1">${t.name}</span>
                            <span class="text-xs font-bold ${prog.finished ? 'text-green-500' : 'text-gray-400'}">${prog.finished ? '✅ Selesai' : `${prog.currentQ}/${totalQ}`}</span>
                        </div>
                        <div class="w-full bg-gray-200 rounded-full h-2">
                            <div class="h-2 rounded-full transition-all duration-500 ${prog.finished ? 'bg-green-500' : 'bg-emerald-400'}" style="width:${pct}%"></div>
                        </div>
                    </div>
                `;
            }).join('');

            container.innerHTML = `
                <div class="flex flex-col h-full">
                    <div class="p-4 rounded-b-3xl" style="background:linear-gradient(to right,#10b981,#14b8a6);color:white">
                        <div class="flex items-center justify-between mb-1">
                            <span class="text-xs font-bold opacity-80">BABAK 1 — PENYISIHAN</span>
                            <span class="text-xs font-bold opacity-80">30 soal · 20 menit</span>
                        </div>
                        <div class="flex items-center justify-center">
                            <span class="text-5xl font-black ${timerColor} px-6 py-2 rounded-2xl" id="cca-timer" style="background:rgba(255,255,255,0.2)">${timerStr}</span>
                        </div>
                    </div>
                    <div class="flex-1 p-4 overflow-y-auto">
                        <div class="bg-white rounded-2xl p-5 shadow-lg mb-4 text-center">
                            <div class="text-4xl mb-3">👨‍🏫</div>
                            <p class="text-lg font-bold text-brand-dark">Memantau progress tim...</p>
                            <p class="text-gray-400 text-sm">Peserta sedang mengerjakan soal</p>
                        </div>
                        <div class="space-y-3">${progressHtml}</div>
                    </div>
                </div>
            `;
            updateTimerDisplayMinutes(data.timerEnd);
            return;
        }

        // TEAM VIEW: show their own question
        const myProgress = data.teamProgress?.[ccaRole] || { currentQ: 0, answers: {}, finished: false };

        // Sync localAnswers from server if empty (e.g. on reconnect)
        if (Object.keys(localAnswers).length === 0 && myProgress.answers) {
            Object.entries(myProgress.answers).forEach(([k, v]) => {
                const idx = parseInt(k.replace('q', ''));
                localAnswers[idx] = v;
            });
        }

        const answeredCount = Object.keys(localAnswers).length;

        // Already finished
        if (myProgress.finished) {
            container.innerHTML = `
                <div class="flex flex-col h-full">
                    <div class="p-4 rounded-b-3xl" style="background:linear-gradient(to right,#10b981,#14b8a6);color:white">
                        <div class="flex items-center justify-between mb-1">
                            <span class="text-xs font-bold opacity-80">BABAK 1 — PENYISIHAN</span>
                            <span class="text-xs font-bold opacity-80">Selesai!</span>
                        </div>
                        <div class="flex items-center justify-center">
                            <span class="text-5xl font-black px-6 py-2 rounded-2xl" id="cca-timer" style="color:white;background:rgba(255,255,255,0.2)">${timerStr}</span>
                        </div>
                    </div>
                    <div class="flex-1 flex flex-col items-center justify-center p-6">
                        <div class="text-6xl mb-4">✅</div>
                        <h2 class="text-2xl font-black text-brand-dark mb-2">Selesai!</h2>
                        <p class="text-gray-400 text-center">Menjawab ${answeredCount}/${totalQ} soal.<br>Menunggu tim lain atau waktu habis...</p>
                    </div>
                </div>
            `;
            updateTimerDisplayMinutes(data.timerEnd);
            return;
        }

        const q = questions[localQ] || questions[0];

        // Build question nav bar (scrollable) — matching quiz style
        let navHtml = '';
        const navBaseClass = 'w-14 h-14 rounded-full text-lg font-bold flex-shrink-0 transition-all flex items-center justify-center leading-none';
        for (let i = 0; i < totalQ; i++) {
            const isAnswered = localAnswers[i] !== undefined;
            const isCurrent = i === localQ;
            let btnClass = '';
            if (isCurrent) {
                btnClass = `${navBaseClass} bg-brand-primary text-white border-2 border-gray-800 transform scale-110 shadow-xl z-10`;
            } else if (isAnswered) {
                btnClass = `${navBaseClass} bg-blue-500 text-white opacity-90 hover:opacity-100`;
            } else {
                btnClass = `${navBaseClass} bg-gray-200 text-gray-500 hover:bg-gray-300`;
            }
            navHtml += `<button onclick="ccaNavTo(${i})" class="${btnClass}">${i + 1}</button>`;
        }

        // Current answer for this question  
        const myAnswer = localAnswers[localQ];
        const hasAnswered = myAnswer !== undefined;

        const optionLabels = ['A', 'B', 'C', 'D'];
        let optionsHtml = q.options.map((opt, i) => {
            let btnClass = 'bg-white border-2 border-gray-200 hover:border-emerald-500 hover:bg-emerald-50';
            if (hasAnswered) {
                if (i === myAnswer) {
                    btnClass = 'bg-emerald-100 border-2 border-emerald-500 text-emerald-800';
                } else {
                    btnClass = 'bg-white border-2 border-gray-200 hover:border-emerald-500 hover:bg-emerald-50 opacity-70';
                }
            }
            return `
                <button onclick="answerCCA(${i})" class="w-full py-4 px-5 rounded-2xl ${btnClass} transition-all flex items-center gap-4 text-left active:scale-95">
                    <span class="w-10 h-10 rounded-full ${hasAnswered && i === myAnswer ? 'bg-emerald-500 text-white' : 'bg-emerald-100 text-emerald-700'} font-black flex items-center justify-center shrink-0">${optionLabels[i]}</span>
                    <span class="font-semibold text-brand-dark text-lg">${opt}</span>
                    ${hasAnswered && i === myAnswer ? '<span class="ml-auto text-emerald-500 text-lg">✓</span>' : ''}
                </button>
            `;
        }).join('');

        container.innerHTML = `
            <div class="flex flex-col h-full">
                <!-- Header -->
                <div class="p-4 rounded-b-3xl" style="background:linear-gradient(to right,#10b981,#14b8a6);color:white">
                    <div class="flex items-center justify-between mb-1">
                        <span class="text-xs font-bold opacity-80">BABAK 1 — PENYISIHAN</span>
                        <span class="text-xs font-bold opacity-80">${answeredCount}/${totalQ} dijawab</span>
                    </div>
                    <div class="flex items-center justify-center">
                        <span class="text-4xl font-black ${timerColor} px-5 py-1 rounded-2xl" id="cca-timer" style="background:rgba(255,255,255,0.2)">${timerStr}</span>
                    </div>
                </div>

                <!-- Question Nav Bar (scrollable) -->
                <div class="px-3 py-2 bg-white border-b shadow-sm overflow-x-auto hide-scrollbar">
                    <div class="flex gap-2 min-w-max px-1 py-1 mx-auto" id="cca-nav-bar">
                        ${navHtml}
                    </div>
                </div>

                <!-- Question -->
                <div class="flex-1 p-4 overflow-y-auto">
                    <div class="bg-white rounded-2xl p-5 shadow-lg mb-4">
                        <div class="flex items-center justify-between mb-2">
                            <p class="text-xs text-emerald-600 font-bold uppercase">${q.category.replace('-', ' ')}</p>
                            <p class="text-xs text-gray-400 font-bold">Soal ${localQ + 1}</p>
                        </div>
                        <p class="text-xl font-bold text-brand-dark leading-relaxed">${q.q}</p>
                    </div>

                    <!-- Options -->
                    <div class="space-y-3">${optionsHtml}</div>

                    ${hasAnswered ? '<p class="text-center text-emerald-500 text-sm mt-3 font-bold">✓ Jawaban tersimpan</p>' : ''}
                </div>

                <!-- Bottom Navigation -->
                <div class="bg-white border-t p-3">
                    <div class="flex gap-2">
                        <button onclick="ccaPrev()" class="flex-1 py-3 rounded-xl ${localQ > 0 ? 'bg-gray-100 text-gray-600' : 'bg-gray-50 text-gray-300 pointer-events-none'} font-bold text-sm flex items-center justify-center gap-1">
                            <i class="fas fa-chevron-left"></i> Sebelumnya
                        </button>
                        ${localQ < totalQ - 1 ? `
                            <button onclick="ccaNext()" class="flex-1 py-3 rounded-xl bg-emerald-500 text-white font-bold text-sm flex items-center justify-center gap-1">
                                Selanjutnya <i class="fas fa-chevron-right"></i>
                            </button>
                        ` : `
                            <button onclick="finishBabak1()" class="flex-1 py-3 rounded-xl ${answeredCount >= totalQ ? 'bg-green-500' : 'bg-yellow-500'} text-white font-bold text-sm flex items-center justify-center gap-1">
                                ${answeredCount >= totalQ ? '✅ Selesai!' : `Selesai (${answeredCount}/${totalQ})`}
                            </button>
                        `}
                    </div>
                </div>
            </div>
        `;

        // Scroll active nav item into view
        setTimeout(() => {
            const navBar = document.getElementById('cca-nav-bar');
            if (navBar) {
                const activeBtn = navBar.children[localQ];
                if (activeBtn) activeBtn.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
            }
        }, 50);

        updateTimerDisplayMinutes(data.timerEnd);
        return;
    }

    // ==================
    // HASIL BABAK 1
    // ==================
    if (data.status === 'hasil1') {
        if (ccaTimer) { clearInterval(ccaTimer); ccaTimer = null; }

        // Calculate correct answers per team for display
        const teamProgress = data.teamProgress || {};
        const questions = data.babak1Questions || [];

        let rankHtml = sortedTeams.map((t, i) => {
            const prog = teamProgress[t.key] || {};
            const answered = prog.currentQ || 0;
            const answers = prog.answers || {};
            let correct = 0;
            Object.entries(answers).forEach(([qKey, ans]) => {
                const qIdx = parseInt(qKey.replace('q', ''));
                if (questions[qIdx] && ans === questions[qIdx].answer) correct++;
            });

            const isLastPlace = i === sortedTeams.length - 1 && sortedTeams.length > 2;
            const isEliminated = eliminatedSet.has(t.key);

            // Pre-select last place for elimination
            if (isHost && isLastPlace && eliminatedSet.size === 0 && !eliminatedSet._initialized) {
                eliminatedSet.add(t.key);
                eliminatedSet._initialized = true;
            }
            const checked = eliminatedSet.has(t.key);

            return `
                <div class="flex items-center gap-3 p-4 rounded-2xl ${checked ? 'bg-red-50 border-2 border-red-300 opacity-70' : i === 0 ? 'bg-yellow-50 border-2 border-yellow-300' : 'bg-gray-50'}">
                    <div class="text-2xl">${i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : `#${i + 1}`}</div>
                    <div class="flex-1">
                        <span class="font-bold text-brand-dark ${checked ? 'line-through text-red-400' : ''}">${t.name}</span>
                        <p class="text-xs text-gray-400">${correct}/${answered} benar</p>
                    </div>
                    <span class="text-2xl font-black ${checked ? 'text-red-400' : 'text-brand-primary'}">${t.score || 0}</span>
                    ${isHost ? `
                        <button onclick="toggleEliminate('${t.key}')" class="ml-1 w-8 h-8 rounded-full flex items-center justify-center ${checked ? 'bg-red-500 text-white' : 'bg-gray-200 text-gray-400'} transition-all" title="${checked ? 'Batalkan eliminasi' : 'Eliminasi tim ini'}">
                            <i class="fas ${checked ? 'fa-times' : 'fa-ban'} text-xs"></i>
                        </button>
                    ` : ''}
                </div>
            `;
        }).join('');

        const elimCount = eliminatedSet.size;

        container.innerHTML = `
            <div class="flex flex-col items-center justify-center min-h-[60vh] p-6">
                <div class="bg-white rounded-3xl p-6 w-full max-w-md shadow-xl">
                    <div class="text-center mb-6">
                        <div class="text-5xl mb-2">📊</div>
                        <h2 class="text-2xl font-black text-brand-dark">Hasil Babak 1</h2>
                        <p class="text-gray-400 text-sm">Penyisihan selesai!</p>
                    </div>
                    <div class="space-y-3 mb-4">${rankHtml}</div>
                    ${isHost ? `
                        ${elimCount > 0 ? `<p class="text-red-500 text-xs text-center mb-3 font-bold">⚠️ ${elimCount} tim akan dieliminasi (klik ❌ untuk batal)</p>` : ''}
                        <button onclick="nextBabakWithElimination()" class="w-full py-4 rounded-2xl font-bold text-lg shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-2" style="background:linear-gradient(to right,#6366f1,#a855f7);color:white">
                            <i class="fas fa-forward"></i> Lanjut Babak 2 — Rebutan!
                        </button>
                    ` : `
                        <p class="text-gray-400 text-xs text-center">Menunggu guru melanjutkan ke Babak 2...</p>
                    `}
                </div>
                <button onclick="leaveCCAGame()" class="mt-4 text-gray-400 text-sm underline">Keluar</button>
            </div>
        `;
        return;
    }

    // ==================
    // BABAK 2 - REBUTAN
    // ==================
    if (data.status === 'babak2') {
        startTimerCheck(data);
        const questions = data.babak2Questions || [];
        const qIndex = data.currentQ || 0;
        const q = questions[qIndex];
        if (!q) return;

        const remaining = data.timerEnd ? Math.max(0, Math.ceil((data.timerEnd - Date.now()) / 1000)) : 0;
        const isSpectator = ccaRole === 'spectator';
        const isEliminated = (data.eliminatedTeams || []).includes(ccaRole);
        const isLocked = data.lockedTeams && data.lockedTeams.includes(ccaRole);
        const eliminated = data.eliminatedTeams || [];

        const optionLabels = ['A', 'B', 'C', 'D'];

        // Phase indicator
        const phase = qIndex < BABAK2_SPLIT ? 1 : 2;
        const phaseTime = phase === 1 ? BABAK2_TIME_A : BABAK2_TIME_B;
        const phaseLabel = `Fase ${phase} · ${phaseTime} detik`;

        let contentHtml = '';

        // Eliminated team view
        if (isEliminated) {
            // Show the question read-only so they can watch
            let optionsHtml = q.options.map((opt, i) => `
                <div class="w-full py-4 px-5 rounded-2xl bg-gray-50 border-2 border-gray-100 flex items-center gap-4 text-left opacity-60">
                    <span class="w-10 h-10 rounded-full bg-gray-200 text-gray-600 font-black flex items-center justify-center shrink-0">${optionLabels[i]}</span>
                    <span class="font-semibold text-gray-500 text-lg">${opt}</span>
                </div>
            `).join('');
            contentHtml = `
                <div class="bg-red-50 border-2 border-red-200 rounded-2xl p-3 mb-4 text-center">
                    <p class="text-red-500 font-bold text-sm">😔 Tereliminasi — Menonton saja</p>
                </div>
                <div class="space-y-3">${optionsHtml}</div>
            `;
        } else if (isLocked) {
            // Locked — wrong answer, wait for next question
            let optionsHtml = q.options.map((opt, i) => `
                <div class="w-full py-4 px-5 rounded-2xl bg-gray-50 border-2 border-gray-100 flex items-center gap-4 text-left opacity-50">
                    <span class="w-10 h-10 rounded-full bg-gray-200 text-gray-500 font-black flex items-center justify-center shrink-0">${optionLabels[i]}</span>
                    <span class="font-semibold text-gray-500 text-lg">${opt}</span>
                </div>
            `).join('');
            contentHtml = `
                <div class="bg-red-50 border-2 border-red-300 rounded-2xl p-4 mb-4 text-center">
                    <div class="text-3xl mb-2">🔒</div>
                    <p class="text-red-500 font-black">Jawaban Salah!</p>
                    <p class="text-gray-400 text-xs mt-1">Terkunci sampai soal berikutnya</p>
                </div>
                <div class="space-y-3">${optionsHtml}</div>
            `;
        } else if (!isSpectator) {
            // Can answer
            let optionsHtml = q.options.map((opt, i) => `
                <button onclick="buzzerCCA(${i})" class="w-full py-4 px-5 rounded-2xl bg-white border-2 border-gray-200 hover:border-indigo-500 hover:bg-indigo-50 transition-all flex items-center gap-4 text-left active:scale-95">
                    <span class="w-10 h-10 rounded-full bg-indigo-100 text-indigo-700 font-black flex items-center justify-center shrink-0">${optionLabels[i]}</span>
                    <span class="font-semibold text-brand-dark text-lg">${opt}</span>
                </button>
            `).join('');
            contentHtml = `
                <div class="space-y-3">${optionsHtml}</div>
                <p class="text-center text-indigo-500 text-sm mt-3 font-bold animate-pulse">⚡ Pilih jawaban yang benar!</p>
            `;
        } else {
            // Spectator — read-only
            let optionsHtml = q.options.map((opt, i) => `
                <div class="w-full py-4 px-5 rounded-2xl bg-gray-50 border-2 border-gray-100 flex items-center gap-4 text-left">
                    <span class="w-10 h-10 rounded-full bg-gray-200 text-gray-600 font-black flex items-center justify-center shrink-0">${optionLabels[i]}</span>
                    <span class="font-semibold text-gray-600 text-lg">${opt}</span>
                </div>
            `).join('');
            contentHtml = `<div class="space-y-3">${optionsHtml}</div>`;
        }

        // Scoreboard (show eliminated teams dimmed)
        let scoreHtml = sortedTeams.map((t, i) => {
            const locked = data.lockedTeams && data.lockedTeams.includes(t.key);
            const teamElim = eliminated.includes(t.key);
            return `
                <div class="flex items-center gap-2 text-sm ${teamElim ? 'opacity-40' : ''}">
                    <div class="w-6 h-6 rounded-full flex items-center justify-center text-white text-xs font-bold" style="background:${TEAM_COLORS[i % TEAM_COLORS.length]}">${i + 1}</div>
                    <span class="font-bold text-brand-dark flex-1 truncate ${teamElim ? 'line-through' : ''}">${t.name}</span>
                    ${teamElim ? '<span class="text-red-400 text-xs">❌</span>' : locked ? '<span class="text-red-400 text-xs">🔒</span>' : ''}
                    <span class="font-black text-brand-primary">${t.score || 0}</span>
                </div>
            `;
        }).join('');

        const timerColor = remaining <= 3 ? 'text-red-500' : 'text-indigo-600';

        container.innerHTML = `
            <div class="flex flex-col h-full">
                <div class="p-4 rounded-b-3xl" style="background:linear-gradient(to right,#6366f1,#a855f7);color:white">
                    <div class="flex items-center justify-between mb-1">
                        <span class="text-xs font-bold opacity-80">BABAK 2 — REBUTAN</span>
                        <span class="text-xs font-bold opacity-80">Soal ${qIndex + 1}/${questions.length}</span>
                    </div>
                    <div class="flex items-center justify-center">
                        <span class="text-5xl font-black ${timerColor} px-6 py-2 rounded-2xl" id="cca-timer" style="background:rgba(255,255,255,0.2)">${remaining}</span>
                    </div>
                    <div class="flex items-center justify-center mt-2">
                        <span class="text-xs font-bold px-3 py-1 rounded-full" style="background:rgba(255,255,255,0.2)">${phaseLabel}</span>
                    </div>
                </div>

                <div class="flex-1 p-4 overflow-y-auto">
                    <div class="bg-white rounded-2xl p-5 shadow-lg mb-4">
                        <p class="text-xs text-indigo-600 font-bold mb-2 uppercase">${q.category.replace('-', ' ')}</p>
                        <p class="text-xl font-bold text-brand-dark leading-relaxed">${q.q}</p>
                    </div>
                    ${contentHtml}
                </div>

                <div class="bg-white border-t p-4">
                    <p class="text-xs font-bold text-gray-400 mb-2">SKOR</p>
                    <div class="space-y-2">${scoreHtml}</div>
                </div>
            </div>
        `;

        updateTimerDisplay(data.timerEnd);
        return;
    }

    // ==================
    // HASIL BABAK 2 / FINISHED
    // ==================
    if (data.status === 'hasil2' || data.status === 'finished') {
        if (ccaTimer) { clearInterval(ccaTimer); ccaTimer = null; }

        const winner = sortedTeams[0];

        let rankHtml = sortedTeams.map((t, i) => `
            <div class="flex items-center gap-3 p-4 rounded-2xl ${i === 0 ? 'bg-yellow-50 border-2 border-yellow-300' : 'bg-gray-50'}">
                <div class="text-2xl">${i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : `#${i + 1}`}</div>
                <span class="font-bold text-brand-dark flex-1">${t.name}</span>
                <span class="text-2xl font-black text-brand-primary">${t.score || 0}</span>
            </div>
        `).join('');

        container.innerHTML = `
            <div class="flex flex-col items-center justify-center min-h-[60vh] p-6">
                <div class="bg-white rounded-3xl p-6 w-full max-w-md shadow-xl">
                    <div class="text-center mb-6">
                        <div class="text-5xl mb-2">🏆</div>
                        <h2 class="text-2xl font-black text-brand-dark">Hasil Akhir</h2>
                        ${winner ? `<p class="text-emerald-600 font-bold text-lg mt-2">Pemenang: ${winner.name} 🎉</p>` : ''}
                    </div>
                    <div class="space-y-3 mb-6">${rankHtml}</div>
                    <div class="space-y-2">
                        <p class="text-gray-400 text-xs text-center">Babak 3 — Coming Soon! 🚧</p>
                        <button onclick="leaveCCAGame()" class="w-full py-3 rounded-xl bg-gray-100 text-gray-500 font-bold">Kembali ke Menu</button>
                    </div>
                </div>
            </div>
        `;

        if (typeof confetti === 'function' && winner) {
            confetti({ particleCount: 150, spread: 80, origin: { y: 0.6 } });
        }
        return;
    }
}

// ========================================
// LIVE TIMER (mm:ss for babak 1)
// ========================================
function updateTimerDisplayMinutes(timerEnd) {
    if (!timerEnd) return;
    if (ccaTimer) clearInterval(ccaTimer);

    ccaTimer = setInterval(() => {
        const remaining = Math.max(0, Math.ceil((timerEnd - Date.now()) / 1000));
        const el = document.getElementById('cca-timer');
        if (el) {
            const m = Math.floor(remaining / 60);
            const s = remaining % 60;
            el.textContent = `${m}:${String(s).padStart(2, '0')}`;
            el.className = el.className.replace(/text-(red|emerald|indigo|white)-\d+/g, '');
            if (remaining <= 60) el.classList.add('text-red-500');
        }
        if (remaining <= 0) {
            clearInterval(ccaTimer);
            ccaTimer = null;
        }
    }, 250);
}

// ========================================
// LIVE TIMER (seconds for babak 2)
// ========================================
function updateTimerDisplay(timerEnd) {
    if (!timerEnd) return;
    if (ccaTimer) clearInterval(ccaTimer);

    ccaTimer = setInterval(() => {
        const remaining = Math.max(0, Math.ceil((timerEnd - Date.now()) / 1000));
        const el = document.getElementById('cca-timer');
        if (el) {
            el.textContent = remaining;
            el.className = el.className.replace(/text-(red|emerald|indigo)-\d+/g, '');
            if (remaining <= 3) el.classList.add('text-red-500');
        }
        if (remaining <= 0) {
            clearInterval(ccaTimer);
            ccaTimer = null;
        }
    }, 250);
}
