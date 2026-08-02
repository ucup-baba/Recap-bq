// ========================================
// CCA FINAL — BABAK 3 REBUTAN BERISIKO
// ========================================
// Separate mode from CCA babak 1+2. Host inputs initial scores manually.
// Scoring: Correct +20, Wrong -10 (lock wrong team, others can still answer)
// Timer: 15s first 25 questions, 10s last 25 questions

import { db } from './config.js';
import { doc, getDoc, setDoc, updateDoc, onSnapshot, increment, deleteDoc } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";
import { state } from './state.js';
import { switchView } from './ui.js';
import { showNotification } from './dialogs.js';
import { getFinalCCAQuestions, shuffleArray } from './cca-questions.js';

// ========================================
// STATE
// ========================================
let finalUnsub = null;
let finalRoomId = null;
let finalRole = null; // 'team_0', 'team_1', ... or 'spectator'
let finalIsHost = false;
let finalHostTimer = null;   // host auto-advance timer
let finalDisplayTimer = null; // UI countdown display timer
let finalBacksound = null;   // background music (host only)

const TEAM_COLORS = ['#6366f1', '#ec4899', '#22c55e', '#f59e0b', '#06b6d4'];
const FINAL_TIME_A = 15; // seconds per question (first 25)
const FINAL_TIME_B = 10; // seconds per question (last 25)
const FINAL_SPLIT = 25;
const CORRECT_POINTS = 20;
const WRONG_PENALTY = -10;

function getFinalTimer(qIndex) {
    return qIndex < FINAL_SPLIT ? FINAL_TIME_A : FINAL_TIME_B;
}

// ========================================
// INIT
// ========================================
export function initCCAFinal() {
    window.createFinalCCARoom = createFinalCCARoom;
    window.startFinalCCA = startFinalCCA;
    window.buzzerFinal = buzzerFinal;
    window.leaveFinalGame = leaveFinalGame;
    window.joinFinalCCARoom = joinFinalCCARoom;
    window.showFinalCCASetup = showFinalCCASetup;
    console.log("CCA Final module loaded");
}

// ========================================
// SHOW SETUP UI (from admin settings)
// ========================================
function showFinalCCASetup() {
    switchView('cca');
    const container = document.getElementById('cca-game-area');
    if (!container) return;

    container.innerHTML = `
        <div class="flex flex-col items-center justify-center min-h-[60vh] p-6">
            <div class="bg-white rounded-3xl p-6 w-full max-w-md shadow-xl">
                <div class="text-center mb-6">
                    <div class="text-5xl mb-2">🏆</div>
                    <h2 class="text-2xl font-black text-brand-dark">Final CCA</h2>
                    <p class="text-gray-400 text-xs mt-1">50 soal rebutan · Benar +20 · Salah -10</p>
                </div>

                <div class="mb-4">
                    <label class="text-sm font-bold text-gray-600 mb-2 block">Jumlah Tim</label>
                    <div class="flex gap-2" id="final-team-count-btns">
                        ${[2, 3, 4, 5].map(n => `
                            <button onclick="setFinalTeamCount(${n})" class="flex-1 py-3 rounded-xl font-bold text-sm transition-all" 
                                style="background:${n === 2 ? '#6366f1' : '#f3f4f6'};color:${n === 2 ? 'white' : '#6b7280'}"
                                data-count="${n}">${n} Tim</button>
                        `).join('')}
                    </div>
                </div>

                <div id="final-team-inputs" class="space-y-3 mb-6">
                    <!-- Generated dynamically -->
                </div>

                <button onclick="createFinalCCARoom()" class="w-full py-4 rounded-2xl font-bold text-lg shadow-lg transition-all flex items-center justify-center gap-2"
                    style="background:linear-gradient(to right,#f59e0b,#f97316);color:white">
                    🏆 Buat Room Final
                </button>
                <button onclick="leaveFinalGame()" class="w-full py-3 mt-3 rounded-xl font-bold text-sm" style="background:#f3f4f6;color:#6b7280">
                    Batal
                </button>
            </div>
        </div>
    `;

    // Initialize with 2 teams
    window.setFinalTeamCount = setFinalTeamCount;
    setFinalTeamCount(2);
}

function setFinalTeamCount(count) {
    // Update button styles
    document.querySelectorAll('#final-team-count-btns button').forEach(btn => {
        const n = parseInt(btn.dataset.count);
        btn.style.background = n === count ? '#6366f1' : '#f3f4f6';
        btn.style.color = n === count ? 'white' : '#6b7280';
    });

    const container = document.getElementById('final-team-inputs');
    if (!container) return;

    const defaultNames = ['Tim A', 'Tim B', 'Tim C', 'Tim D', 'Tim E'];
    let html = '';
    for (let i = 0; i < count; i++) {
        html += `
            <div class="flex items-center gap-3 p-3 rounded-2xl" style="background:${TEAM_COLORS[i]}15;border:1px solid ${TEAM_COLORS[i]}40">
                <div class="w-8 h-8 rounded-lg flex items-center justify-center text-white text-sm font-bold" style="background:${TEAM_COLORS[i]}">${i + 1}</div>
                <input type="text" id="final-team-name-${i}" placeholder="${defaultNames[i]}" value="${defaultNames[i]}"
                    class="flex-1 bg-transparent font-bold text-brand-dark text-sm outline-none" style="border:none">
                <div class="flex items-center gap-1">
                    <span class="text-xs text-gray-400">Skor:</span>
                    <input type="number" id="final-team-score-${i}" value="0" min="0" 
                        class="w-16 text-center font-bold text-sm rounded-lg py-1 px-2" style="background:white;border:1px solid #e5e7eb;color:#1f2937">
                </div>
            </div>
        `;
    }
    container.innerHTML = html;
    container.dataset.count = count;
}

// ========================================
// CREATE ROOM
// ========================================
async function createFinalCCARoom() {
    const countEl = document.getElementById('final-team-inputs');
    if (!countEl) return;
    const teamCount = parseInt(countEl.dataset.count) || 2;

    const teams = {};
    for (let i = 0; i < teamCount; i++) {
        const nameEl = document.getElementById(`final-team-name-${i}`);
        const scoreEl = document.getElementById(`final-team-score-${i}`);
        teams[`team_${i}`] = {
            name: nameEl?.value || `Tim ${String.fromCharCode(65 + i)}`,
            initialScore: parseInt(scoreEl?.value) || 0,
            score: parseInt(scoreEl?.value) || 0,
            color: TEAM_COLORS[i]
        };
    }

    const roomId = String(Math.floor(1000 + Math.random() * 9000));
    finalRoomId = roomId;
    finalIsHost = true;
    finalRole = 'spectator';

    const hostName = state.currentUser?.name || 'Guru';
    const questions = getFinalCCAQuestions(50);

    const roomRef = doc(db, "cca_final_rooms", roomId);
    await setDoc(roomRef, {
        hostName,
        status: 'waiting',
        teamCount,
        teams,
        questions,
        currentQ: 0,
        lockedTeams: [],
        claimedTeams: [],
        timerEnd: null,
        createdAt: Date.now()
    });

    listenFinalRoom(roomId);
    showNotification("Room Final CCA dibuat!", `Kode: ${roomId}`, "success");
}

// ========================================
// JOIN ROOM (for teams)
// ========================================
async function joinFinalCCARoom() {
    switchView('cca');
    const container = document.getElementById('cca-game-area');
    if (!container) return;

    container.innerHTML = `
        <div class="flex flex-col items-center justify-center min-h-[60vh] p-6">
            <div class="bg-white rounded-3xl p-6 w-full max-w-sm shadow-xl text-center">
                <div class="text-5xl mb-3">🏆</div>
                <h2 class="text-2xl font-black text-brand-dark mb-4">Join Final CCA</h2>
                <input type="text" id="final-room-code" placeholder="Kode Room" maxlength="4" 
                    class="w-full text-center text-3xl font-black tracking-widest py-4 rounded-2xl mb-4"
                    style="border:2px solid #e5e7eb;color:#1f2937">
                <button onclick="submitFinalJoin()" class="w-full py-4 rounded-2xl font-bold text-lg shadow-lg"
                    style="background:linear-gradient(to right,#f59e0b,#f97316);color:white">
                    🔍 Cari Room
                </button>
                <button onclick="leaveFinalGame()" class="w-full py-3 mt-3 rounded-xl font-bold text-sm" style="background:#f3f4f6;color:#6b7280">
                    Batal
                </button>
            </div>
        </div>
    `;

    window.submitFinalJoin = async () => {
        const code = document.getElementById('final-room-code')?.value?.trim();
        if (!code) return;

        const roomRef = doc(db, "cca_final_rooms", code);
        const snap = await getDoc(roomRef);
        if (!snap.exists()) {
            showNotification("Room tidak ditemukan!", "Periksa kode", "error");
            return;
        }

        const data = snap.data();
        // Show team selection
        showFinalTeamPicker(code, data);
    };
}

function showFinalTeamPicker(roomId, data) {
    const container = document.getElementById('cca-game-area');
    if (!container) return;

    const teams = data.teams || {};
    const claimed = data.claimedTeams || [];
    let teamHtml = Object.entries(teams).map(([key, t]) => {
        const isClaimed = claimed.includes(key);
        return `
            <button onclick="${isClaimed ? '' : `selectFinalTeam('${roomId}','${key}')`}" 
                class="w-full py-4 rounded-2xl font-bold text-lg shadow-lg transition-all flex items-center justify-center gap-3"
                style="background:${isClaimed ? '#d1d5db' : t.color};color:${isClaimed ? '#9ca3af' : 'white'};cursor:${isClaimed ? 'not-allowed' : 'pointer'}"
                ${isClaimed ? 'disabled' : ''}>
                ${t.name} (Skor awal: ${t.initialScore}) ${isClaimed ? '✅ Sudah dipilih' : ''}
            </button>
        `;
    }).join('');

    container.innerHTML = `
        <div class="flex flex-col items-center justify-center min-h-[60vh] p-6">
            <div class="bg-white rounded-3xl p-6 w-full max-w-sm shadow-xl text-center">
                <div class="text-5xl mb-3">🏆</div>
                <h2 class="text-2xl font-black text-brand-dark mb-2">Pilih Tim</h2>
                <p class="text-gray-400 text-xs mb-4">Room: ${roomId} · Host: ${data.hostName}</p>
                <div class="space-y-3">${teamHtml}</div>
            </div>
        </div>
    `;

    window.selectFinalTeam = async (rid, teamKey) => {
        // Re-check claimed status before joining
        const roomRef = doc(db, "cca_final_rooms", rid);
        const snap = await getDoc(roomRef);
        if (!snap.exists()) return;
        const freshData = snap.data();
        const freshClaimed = freshData.claimedTeams || [];
        if (freshClaimed.includes(teamKey)) {
            showNotification('Tim sudah dipilih!', 'Pilih tim lain', 'error');
            showFinalTeamPicker(rid, freshData);
            return;
        }
        // Claim the team
        await updateDoc(roomRef, {
            claimedTeams: [...freshClaimed, teamKey]
        });
        finalRoomId = rid;
        finalRole = teamKey;
        finalIsHost = false;
        listenFinalRoom(rid);
    };
}

// ========================================
// LISTEN TO ROOM
// ========================================
function listenFinalRoom(roomId) {
    if (finalUnsub) finalUnsub();

    const roomRef = doc(db, "cca_final_rooms", roomId);
    finalUnsub = onSnapshot(roomRef, (snap) => {
        if (!snap.exists()) {
            leaveFinalGame();
            return;
        }
        const data = snap.data();
        renderFinalUI(data);
        startFinalTimerCheck(data);
    });
}

// ========================================
// START GAME (host only)
// ========================================
async function startFinalCCA() {
    if (!finalRoomId || !finalIsHost) return;

    const roomRef = doc(db, "cca_final_rooms", finalRoomId);
    const snap = await getDoc(roomRef);
    if (!snap.exists()) return;
    const data = snap.data();

    await updateDoc(roomRef, {
        status: 'playing',
        currentQ: 0,
        lockedTeams: [],
        timerEnd: Date.now() + (getFinalTimer(0) * 1000)
    });
}

// ========================================
// BUZZER ANSWER
// ========================================
async function buzzerFinal(optionIndex) {
    if (!finalRoomId || !finalRole || finalRole === 'spectator') return;

    const roomRef = doc(db, "cca_final_rooms", finalRoomId);
    const snap = await getDoc(roomRef);
    if (!snap.exists()) return;
    const data = snap.data();

    // Am I locked out?
    if (data.lockedTeams && data.lockedTeams.includes(finalRole)) return;

    const questions = data.questions;
    const q = questions[data.currentQ];
    const isCorrect = optionIndex === q.answer;

    if (isCorrect) {
        const nextQ = data.currentQ + 1;
        const isFinished = nextQ >= questions.length;

        await updateDoc(roomRef, {
            [`teams.${finalRole}.score`]: increment(CORRECT_POINTS),
            lockedTeams: [],
            currentQ: isFinished ? data.currentQ : nextQ,
            status: isFinished ? 'finished' : 'playing',
            timerEnd: isFinished ? null : Date.now() + (getFinalTimer(nextQ) * 1000)
        });
    } else {
        // Wrong → penalty + lock
        const newLocked = [...(data.lockedTeams || []), finalRole];
        const activeTeamCount = Object.keys(data.teams || {}).length;

        await updateDoc(roomRef, {
            [`teams.${finalRole}.score`]: increment(WRONG_PENALTY),
            lockedTeams: newLocked
        });

        // If all teams locked → next question
        if (newLocked.length >= activeTeamCount) {
            const nextQ = data.currentQ + 1;
            const isFinished = nextQ >= questions.length;

            await updateDoc(roomRef, {
                lockedTeams: [],
                currentQ: isFinished ? data.currentQ : nextQ,
                status: isFinished ? 'finished' : 'playing',
                timerEnd: isFinished ? null : Date.now() + (getFinalTimer(nextQ) * 1000)
            });
        }
    }
}

// ========================================
// TIMER CHECK (host auto-advances)
// ========================================
function startFinalTimerCheck(data) {
    if (finalHostTimer) { clearInterval(finalHostTimer); finalHostTimer = null; }
    if (!finalIsHost || !data.timerEnd || data.status !== 'playing') return;

    finalHostTimer = setInterval(async () => {
        const remaining = Math.max(0, Math.ceil((data.timerEnd - Date.now()) / 1000));
        if (remaining <= 0) {
            clearInterval(finalHostTimer);
            finalHostTimer = null;

            const roomRef = doc(db, "cca_final_rooms", finalRoomId);
            const snap = await getDoc(roomRef);
            if (!snap.exists()) return;
            const d = snap.data();
            const nextQ = d.currentQ + 1;
            const isFinished = nextQ >= d.questions.length;

            await updateDoc(roomRef, {
                lockedTeams: [],
                currentQ: isFinished ? d.currentQ : nextQ,
                status: isFinished ? 'finished' : 'playing',
                timerEnd: isFinished ? null : Date.now() + (getFinalTimer(nextQ) * 1000)
            });
        }
    }, 1000);
}

// ========================================
// LEAVE GAME
// ========================================
function leaveFinalGame() {
    if (finalUnsub) { finalUnsub(); finalUnsub = null; }
    if (finalHostTimer) { clearInterval(finalHostTimer); finalHostTimer = null; }
    if (finalDisplayTimer) { clearInterval(finalDisplayTimer); finalDisplayTimer = null; }
    stopFinalBacksound();
    finalRoomId = null;
    finalRole = null;
    finalIsHost = false;
    switchView('admin');
}

function playFinalBacksound() {
    if (finalBacksound) return; // already playing
    try {
        finalBacksound = new Audio('/sounds/backsound.mp3');
        finalBacksound.loop = true;
        finalBacksound.volume = 0.3;
        finalBacksound.play().catch(() => { });
    } catch (e) { console.warn('Backsound error:', e); }
}

function stopFinalBacksound() {
    if (finalBacksound) {
        finalBacksound.pause();
        finalBacksound.currentTime = 0;
        finalBacksound = null;
    }
}

// ========================================
// LIVE TIMER DISPLAY
// ========================================
function updateFinalTimerDisplay(timerEnd) {
    if (!timerEnd) return;
    if (finalDisplayTimer) clearInterval(finalDisplayTimer);

    finalDisplayTimer = setInterval(() => {
        const remaining = Math.max(0, Math.ceil((timerEnd - Date.now()) / 1000));
        const el = document.getElementById('final-timer');
        if (el) {
            el.textContent = remaining;
            if (remaining <= 3) {
                el.style.color = '#ef4444';
            } else {
                el.style.color = '#1f2937';
            }
        }
        if (remaining <= 0) {
            clearInterval(finalDisplayTimer);
            finalDisplayTimer = null;
        }
    }, 250);
}

// ========================================
// RENDER UI
// ========================================
function renderFinalUI(data) {
    const container = document.getElementById('cca-game-area');
    if (!container) return;

    const ccaView = document.getElementById('view-cca');
    if (ccaView) ccaView.classList.remove('hidden');

    const teams = data.teams || {};
    const sortedTeams = Object.entries(teams)
        .map(([key, t]) => ({ key, ...t }))
        .sort((a, b) => (b.score || 0) - (a.score || 0));

    const isHost = finalIsHost;

    // ==================
    // WAITING ROOM
    // ==================
    if (data.status === 'waiting') {
        const teamCount = Object.keys(teams).length;
        let teamListHtml = Object.entries(teams).map(([key, t]) => `
            <div class="flex items-center gap-3 p-3 rounded-xl" style="background:${t.color}15;border:1px solid ${t.color}40">
                <div class="w-8 h-8 rounded-lg flex items-center justify-center text-white text-sm font-bold" style="background:${t.color}">
                    ${t.name.charAt(0)}
                </div>
                <span class="font-bold text-brand-dark flex-1 text-sm">${t.name}</span>
                <span class="text-xs font-bold px-2 py-1 rounded-lg" style="background:${t.color}20;color:${t.color}">
                    Skor awal: ${t.initialScore}
                </span>
            </div>
        `).join('');

        container.innerHTML = `
            <div class="flex flex-col items-center justify-center min-h-[60vh] p-6">
                <div class="bg-white rounded-3xl p-6 w-full max-w-md shadow-xl">
                    <div class="text-center mb-6">
                        <div class="text-5xl mb-2">🏆</div>
                        <h2 class="text-2xl font-black text-brand-dark">Final CCA</h2>
                        <p class="text-gray-400 text-xs mt-1">Host: ${data.hostName}</p>
                    </div>
                    <div class="text-center py-4 rounded-2xl mb-6" style="background:linear-gradient(to right,#f59e0b,#f97316);color:white">
                        <p class="text-xs opacity-80">KODE ROOM</p>
                        <p class="text-4xl font-black tracking-widest">${finalRoomId}</p>
                    </div>
                    <div class="mb-4">
                        <p class="text-sm font-bold text-gray-500 mb-2">Tim (${teamCount})</p>
                        <div class="space-y-2">${teamListHtml}</div>
                    </div>
                    <div class="rounded-xl p-3 mb-4 text-center" style="background:#fef3c7;border:1px solid #fbbf24">
                        <p class="text-xs font-bold" style="color:#92400e">📋 50 soal · Benar +20 · Salah -10</p>
                        <p class="text-xs" style="color:#92400e">15 detik (soal 1-25) → 10 detik (soal 26-50)</p>
                    </div>
                    ${isHost ? `
                        <button onclick="startFinalCCA()" class="w-full py-4 rounded-2xl font-bold text-lg shadow-lg transition-all flex items-center justify-center gap-2 animate-pulse"
                            style="background:linear-gradient(to right,#f59e0b,#f97316);color:white">
                            <i class="fas fa-play"></i> Mulai Final!
                        </button>
                    ` : `
                        <p class="text-gray-400 text-xs text-center">Menunggu guru memulai...</p>
                    `}
                    <button onclick="leaveFinalGame()" class="w-full mt-3 py-2 text-gray-400 text-sm underline text-center">Keluar Room</button>
                </div>
            </div>
        `;
        return;
    }

    // ==================
    // PLAYING
    // ==================
    if (data.status === 'playing') {
        if (finalIsHost) playFinalBacksound();
        const questions = data.questions || [];
        const qIndex = data.currentQ || 0;
        const q = questions[qIndex];
        if (!q) return;

        const remaining = data.timerEnd ? Math.max(0, Math.ceil((data.timerEnd - Date.now()) / 1000)) : 0;
        const phaseNum = qIndex < FINAL_SPLIT ? 1 : 2;
        const phaseSec = qIndex < FINAL_SPLIT ? 15 : 10;
        const isLocked = (data.lockedTeams || []).includes(finalRole);

        // Leaderboard
        const sortedTeams = Object.entries(teams)
            .map(([key, t]) => ({ key, ...t }))
            .sort((a, b) => (b.score || 0) - (a.score || 0));

        let leaderHtml = sortedTeams.map((t, i) => `
            <div style="display:flex;align-items:center;justify-content:space-between;padding:10px 14px;border-radius:12px;margin-bottom:6px;background:${t.color}10;border-left:4px solid ${t.color}">
                <div style="display:flex;align-items:center;gap:8px">
                    <div style="width:24px;height:24px;border-radius:50%;background:${t.color};color:white;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800">${i + 1}</div>
                    <span style="font-weight:700;font-size:14px;color:#1e293b">${t.name}</span>
                </div>
                <span style="font-weight:900;font-size:18px;color:${t.color}">${t.score || 0}</span>
            </div>
        `).join('');

        const headerHtml = `
            <div style="background:linear-gradient(135deg,#f59e0b,#ea580c);padding:20px 20px 50px 20px;border-radius:0 0 32px 32px;position:relative;box-shadow:0 10px 30px -10px rgba(249,115,22,0.4)">
                <div style="display:flex;justify-content:space-between;align-items:center">
                    <div>
                        <div style="color:rgba(255,255,255,0.7);font-size:11px;font-weight:700;letter-spacing:1px">🏆 BABAK FINAL</div>
                        <div style="color:white;font-size:12px;font-weight:600;margin-top:2px">Fase ${phaseNum} · ${phaseSec} detik</div>
                    </div>
                    <div style="text-align:right">
                        <div style="color:rgba(255,255,255,0.7);font-size:11px;font-weight:700;letter-spacing:1px">SOAL</div>
                        <div style="color:white;font-size:24px;font-weight:900;line-height:1">${qIndex + 1}<span style="color:rgba(255,255,255,0.5);font-size:14px">/${questions.length}</span></div>
                    </div>
                </div>
                <!-- Timer Circle -->
                <div style="position:absolute;left:50%;transform:translateX(-50%);bottom:-28px;width:56px;height:56px;background:white;border-radius:50%;display:flex;align-items:center;justify-content:center;box-shadow:0 4px 20px rgba(0,0,0,0.15);z-index:10;border:3px solid #fed7aa">
                    <span id="final-timer" style="font-size:24px;font-weight:900;color:#1f2937">${remaining}</span>
                </div>
            </div>
        `;

        // HOST / SPECTATOR VIEW
        if (finalRole === 'spectator') {
            container.innerHTML = `
                <div style="display:flex;flex-direction:column;height:100%;background:#f8fafc;overflow:hidden">
                    ${headerHtml}
                    <div style="flex:1;overflow-y:auto;padding:40px 16px 16px 16px">
                        <!-- Question Only (no answers for host) -->
                        <div style="background:white;border-radius:16px;padding:24px;margin-bottom:20px;box-shadow:0 2px 12px rgba(0,0,0,0.04);border:1px solid #f1f5f9">
                            <div style="display:inline-block;padding:3px 10px;border-radius:6px;background:#fff7ed;color:#c2410c;font-size:10px;font-weight:700;letter-spacing:0.5px;text-transform:uppercase;margin-bottom:12px">${q.category}</div>
                            <p style="font-size:20px;font-weight:700;color:#1e293b;line-height:1.5;text-align:center">${q.q}</p>
                        </div>

                        <!-- Scoreboard -->
                        <div style="background:white;border-radius:16px;padding:16px;box-shadow:0 1px 4px rgba(0,0,0,0.03);border:1px solid #f1f5f9">
                            <p style="font-size:10px;font-weight:800;color:#94a3b8;letter-spacing:2px;text-transform:uppercase;margin-bottom:10px;text-align:center">KLASEMEN</p>
                            ${leaderHtml}
                        </div>
                    </div>
                </div>
            `;
            updateFinalTimerDisplay(data.timerEnd);
            return;
        }

        // TEAM VIEW
        container.innerHTML = `
            <div style="display:flex;flex-direction:column;height:100%;background:#f8fafc;overflow:hidden">
                ${headerHtml}
                <div style="flex:1;overflow-y:auto;padding:40px 16px 16px 16px">
                    <!-- Question -->
                    <div style="background:white;border-radius:16px;padding:20px;margin-bottom:16px;box-shadow:0 2px 12px rgba(0,0,0,0.04);border:1px solid #f1f5f9">
                        <div style="display:inline-block;padding:3px 10px;border-radius:6px;background:#fff7ed;color:#c2410c;font-size:10px;font-weight:700;letter-spacing:0.5px;text-transform:uppercase;margin-bottom:10px">${q.category}</div>
                        <p style="font-size:18px;font-weight:700;color:#1e293b;line-height:1.5">${q.q}</p>
                    </div>

                    ${isLocked ? `
                        <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;padding:40px 0">
                            <div style="width:56px;height:56px;background:#fee2e2;color:#ef4444;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:28px;margin-bottom:12px">🔒</div>
                            <p style="color:#ef4444;font-weight:700;font-size:16px">Terkunci!</p>
                            <p style="color:#94a3b8;font-size:12px;margin-top:4px">Tunggu soal berikutnya...</p>
                        </div>
                    ` : `
                        <!-- 2x2 Grid Answers -->
                        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:16px">
                            ${q.options.map((opt, i) => `
                                <button onclick="buzzerFinal(${i})" style="padding:16px 12px;border-radius:14px;font-weight:700;font-size:14px;text-align:center;background:white;border:2px solid #e2e8f0;color:#334155;cursor:pointer;box-shadow:0 3px 0 #e2e8f0;transition:all 0.1s;line-height:1.3;word-wrap:break-word">
                                    ${opt}
                                </button>
                            `).join('')}
                        </div>
                    `}

                    <!-- Scoreboard -->
                    <div style="margin-top:16px;padding-top:16px;border-top:1px solid #e2e8f0">
                        <p style="font-size:10px;font-weight:800;color:#94a3b8;letter-spacing:2px;text-transform:uppercase;margin-bottom:8px;text-align:center">KLASEMEN</p>
                        ${leaderHtml}
                    </div>
                </div>
            </div>
        `;
        updateFinalTimerDisplay(data.timerEnd);
        return;
    }

    // ==================
    // FINISHED
    // ==================
    if (data.status === 'finished') {
        stopFinalBacksound();
        const winner = sortedTeams[0];

        let rankHtml = sortedTeams.map((t, i) => {
            const gameScore = (t.score || 0) - (t.initialScore || 0);
            const sign = gameScore >= 0 ? '+' : '';
            return `
                <div class="flex items-center gap-3 p-4 rounded-2xl ${i === 0 ? '' : ''}" 
                    style="background:${i === 0 ? '#fef9c3' : '#f9fafb'};${i === 0 ? 'border:2px solid #facc15' : ''}">
                    <div class="text-2xl">${i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : `#${i + 1}`}</div>
                    <div class="flex-1">
                        <span class="font-bold text-brand-dark">${t.name}</span>
                        <div class="text-xs text-gray-400">Awal: ${t.initialScore || 0} ${sign}${gameScore} dari final</div>
                    </div>
                    <span class="text-2xl font-black" style="color:${t.color}">${t.score || 0}</span>
                </div>
            `;
        }).join('');

        container.innerHTML = `
            <div class="flex flex-col items-center justify-center min-h-[60vh] p-6">
                <div class="bg-white rounded-3xl p-6 w-full max-w-md shadow-xl">
                    <div class="text-center mb-6">
                        <div class="text-5xl mb-2">🏆</div>
                        <h2 class="text-2xl font-black text-brand-dark">Hasil Final CCA</h2>
                        ${winner ? `<p class="font-bold text-lg mt-2" style="color:#16a34a">Pemenang: ${winner.name} 🎉</p>` : ''}
                    </div>
                    <div class="space-y-3 mb-6">${rankHtml}</div>
                    <button onclick="leaveFinalGame()" class="w-full py-3 rounded-xl font-bold" style="background:#f3f4f6;color:#6b7280">Kembali ke Menu</button>
                </div>
            </div>
        `;

        if (typeof confetti === 'function' && winner) {
            confetti({ particleCount: 200, spread: 90, origin: { y: 0.6 } });
        }
        return;
    }
}
