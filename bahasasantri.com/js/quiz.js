// Quiz Logic - Refactored & Improved
import { state } from './state.js';
import { switchView, updateTimerDisplay, showConfetti, setTopBarShake, playSoundCorrect, playSoundWrong } from './ui.js';
import { speakCurrentWord, setupSpeakingUI } from './audio.js';
import { db } from './config.js';
import { doc, updateDoc, increment, collection, getDocs, query, orderBy } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";

// ========================================
// UTILITY FUNCTIONS
// ========================================

// Fisher-Yates Shuffle (Unbiased)
function shuffle(arr) {
    const result = [...arr];
    for (let i = result.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
}

// Similarity Score (Levenshtein Distance based)
function similarity(s1, s2) {
    const a = s1.toLowerCase().replace(/[^a-z0-9]/g, '');
    const b = s2.toLowerCase().replace(/[^a-z0-9]/g, '');

    if (a === b) return 1;
    if (a.length === 0 || b.length === 0) return 0;

    // Simple check for 80%+ match
    const longer = a.length > b.length ? a : b;
    const shorter = a.length > b.length ? b : a;

    if (longer.includes(shorter) && shorter.length >= longer.length * 0.8) {
        return 0.9;
    }

    // Exact match check
    return a === b ? 1 : (a.includes(b) || b.includes(a)) ? 0.7 : 0;
}

// Helper: Get Monday 00:01 of Current Week
function getWeekStart() {
    const d = new Date();
    const day = d.getDay();
    const diff = d.getDate() - day + (day == 0 ? -6 : 1);
    const monday = new Date(d.setDate(diff));
    monday.setHours(0, 1, 0, 0);
    return monday;
}

// ========================================
// TIMER CONTROL
// ========================================

export function startTimer() {
    if (state.timer) clearInterval(state.timer);

    state.timer = setInterval(() => {
        state.time--;
        const m = Math.floor(state.time / 60).toString().padStart(2, '0');
        const s = (state.time % 60).toString().padStart(2, '0');
        updateTimerDisplay(m, s);
        if (state.time <= 0) showResult();
    }, 1000);
}

export function stopTimer() {
    clearInterval(state.timer);
}

// ========================================
// QUIZ INITIALIZATION
// ========================================

export function startQuiz(mode) {
    state.mode = mode;
    state.isExam = (mode === 'mixed');

    // Weekly exam limit check
    if (state.isExam && state.currentUser && state.currentUser.role === 'student') {
        const lastExam = state.currentUser.lastExamDate;
        if (lastExam) {
            const lastExamDate = new Date(lastExam);
            const weekStart = getWeekStart();

            if (lastExamDate > weekStart) {
                // Already took exam this week - show warning dialog
                showExamLimitDialog(lastExamDate);
                return;
            }
        }
    }

    state.score = 0;
    state.index = 0;
    state.answers = [];
    state.time = 600; // 10 minutes
    state.isFinished = false;
    state.isNavigating = false;
    state.practiceCorrect = 0; // Track correct answers in practice mode

    // Use Fisher-Yates shuffle for unbiased randomization
    let pool = shuffle([...state.vocabulary]);

    if (state.isExam) {
        state.max = 15;
        const subset = pool.slice(0, 15);

        // Distribution: 10 MC, 3 Listening, 2 Speaking
        const qMc = subset.slice(0, 10).map(i => ({ ...i, type: Math.random() > 0.5 ? 'id-en' : 'en-id' }));
        const qList = subset.slice(10, 13).map(i => ({ ...i, type: 'listening' }));
        const qSpeak = subset.slice(13, 15).map(i => ({ ...i, type: 'speaking' }));

        state.questions = shuffle([...qMc, ...qList, ...qSpeak]);
        state.questions.forEach(() => state.answers.push(null));

        const badge = document.getElementById('timer-badge');
        if (badge) badge.classList.remove('hidden');
        startTimer();
    } else {
        state.max = 10;
        state.questions = pool.slice(0, 10).map(i => ({ ...i, type: mode }));

        const badge = document.getElementById('timer-badge');
        if (badge) badge.classList.add('hidden');
    }

    // Generate options ONCE per question
    state.questions.forEach(q => {
        if (['id-en', 'en-id', 'listening'].includes(q.type)) {
            let distractors = shuffle(
                state.vocabulary.filter(x => x.en !== q.en)
            ).slice(0, 3);
            q.options = shuffle([q, ...distractors]);
        }
    });

    // Render question navigation
    renderQuestionNav();

    switchView('quiz');
    loadQ(0);
}

// Render Question Navigation Buttons (1-15)
function renderQuestionNav() {
    const container = document.getElementById('question-nav-buttons');
    if (!container) return;

    container.innerHTML = '';

    for (let i = 0; i < state.max; i++) {
        const btn = document.createElement('button');
        btn.id = `q-nav-${i}`;
        btn.textContent = i + 1;
        btn.className = getNavButtonClass(i);
        btn.onclick = () => {
            if (state.isExam) {
                loadQ(i); // Allow jumping in exam mode
            }
        };
        container.appendChild(btn);
    }
}

// Update navigation button styles
function updateQuestionNav() {
    for (let i = 0; i < state.max; i++) {
        const btn = document.getElementById(`q-nav-${i}`);
        if (btn) {
            btn.className = getNavButtonClass(i);
        }
    }

    // Scroll current button into view
    const currentBtn = document.getElementById(`q-nav-${state.index}`);
    if (currentBtn) {
        currentBtn.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
    }
}

// Get class for nav button based on state
// Get class for nav button based on state
function getNavButtonClass(i) {
    // Buttons made even larger: w-14 h-14 (56px)
    const baseClass = 'w-14 h-14 rounded-full text-lg font-bold flex-shrink-0 transition-all flex items-center justify-center leading-none';
    const answered = state.answers[i] !== null;
    const isCurrent = i === state.index;

    if (state.isExam) {
        // ===== EXAM MODE =====
        if (isCurrent) {
            // Active: Brand BG + High Contrast Border + Scale
            return `${baseClass} bg-brand-primary text-white border-2 border-gray-800 dark:border-white transform scale-110 shadow-xl z-10`;
        } else if (answered) {
            // Answered: Blue/Brand
            return `${baseClass} bg-blue-500 text-white opacity-90 hover:opacity-100`;
        } else {
            // Pending: Gray - made darker for dark mode visibility
            return `${baseClass} bg-gray-200 text-gray-500 hover:bg-gray-300 dark:bg-gray-600 dark:text-gray-300`;
        }

    } else {
        // ===== PRACTICE MODE =====
        if (isCurrent) {
            return `${baseClass} bg-brand-primary text-white shadow-lg ring-4 ring-orange-200 transform scale-105 z-10`;
        } else if (answered) {
            const isCorrect = state.answers[i]?.correct;
            if (isCorrect) {
                return `${baseClass} bg-green-500 text-white`;
            } else {
                return `${baseClass} bg-red-500 text-white`;
            }
        } else {
            return `${baseClass} bg-gray-100 text-gray-500 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-400`;
        }
    }
}

// Show exam limit dialog
function showExamLimitDialog(lastExamDate) {
    const dialog = document.getElementById('exam-limit-dialog');
    if (dialog) {
        // Update the date in dialog
        const dateEl = dialog.querySelector('#last-exam-date');
        if (dateEl) {
            const options = { weekday: 'long', day: 'numeric', month: 'long' };
            dateEl.textContent = lastExamDate.toLocaleDateString('id-ID', options);
        }
        dialog.classList.remove('hidden');
        dialog.classList.add('flex');
    }
}

window.closeExamLimitDialog = function () {
    const dialog = document.getElementById('exam-limit-dialog');
    if (dialog) {
        dialog.classList.add('hidden');
        dialog.classList.remove('flex');
    }
}

// ========================================
// QUESTION LOADING
// ========================================

export function loadQ(i) {
    state.index = i;
    const q = state.questions[i];
    if (!q) return;

    const type = q.type;
    const saved = state.answers[i];

    // Debug logging
    console.log(`Loading Q${i + 1}/${state.max}`, q.type, q.id || q.en);

    // Count answered questions
    const answeredCount = state.answers.filter(a => a !== null).length;

    // UI Updates
    document.getElementById('progress-bar').style.width = ((i + 1) / state.max * 100) + '%';
    document.getElementById('question-indicator').textContent = `Soal ${i + 1}/${state.max} (${answeredCount} dijawab)`;
    document.getElementById('quiz-type-badge').textContent = type.toUpperCase();

    // Update question navigation bar
    updateQuestionNav();

    const txt = document.getElementById('question-text');
    const speak = document.getElementById('speaking-container');
    const cont = document.getElementById('options-container');
    const btnSpeak = document.getElementById('btn-speak');
    const nextBtn = document.getElementById('btn-next');

    // Reset Views
    txt.innerHTML = '';
    speak.classList.add('hidden');
    cont.innerHTML = '';
    btnSpeak.classList.add('hidden');
    btnSpeak.classList.remove('flex');

    // Exam vs Practice Navigation
    if (state.isExam) {
        document.getElementById('btn-prev').classList.remove('hidden');
        nextBtn.classList.remove('hidden');
        nextBtn.textContent = (i === state.max - 1) ? 'Finish' : 'Next';
    } else {
        document.getElementById('btn-prev').classList.add('hidden');
        nextBtn.classList.add('hidden');
    }

    // Render Question
    if (type === 'speaking') {
        txt.textContent = q.id;
        speak.classList.remove('hidden');
        speak.classList.add('flex');
        document.getElementById('speak-result').textContent = "Tekan Mic lalu ucapkan bahasa Inggrisnya";
        document.getElementById('speak-result').className = "text-center text-gray-500 mt-2";

        // Setup Speaking UI (show mic or fallback typing based on STT availability)
        setupSpeakingUI();
    } else {
        if (type === 'id-en') txt.textContent = q.id;
        else if (type === 'en-id') { txt.textContent = q.en; btnSpeak.classList.remove('hidden'); btnSpeak.classList.add('flex'); }
        else if (type === 'listening') { txt.innerHTML = '<i class="fas fa-headphones"></i>'; btnSpeak.classList.remove('hidden'); btnSpeak.classList.add('flex'); }

        // Render Pre-Shuffled Options
        if (q.options) {
            q.options.forEach(o => {
                const btn = document.createElement('button');
                const val = (type === 'id-en') ? o.en : o.id;
                const isSel = (saved?.value === val);

                // Base classes + dynamic state classes (no inline styles!)
                const baseClasses = 'w-full p-4 rounded-2xl font-bold text-left transition-all border-2 cursor-pointer relative z-10';
                const selectedClasses = 'bg-teal-50 border-teal-400 text-teal-600';
                const unselectedClasses = 'bg-white border-gray-100 text-gray-600 hover:bg-gray-50';

                btn.className = `${baseClasses} ${isSel ? selectedClasses : unselectedClasses}`;
                btn.textContent = val;

                btn.onclick = (e) => {
                    e.stopPropagation();
                    handleAns(val, (type === 'id-en' ? q.en : q.id) === val);
                };
                cont.appendChild(btn);
            });
        }
    }
}

// ========================================
// ANSWER HANDLING
// ========================================

export function handleAns(ans, isCorrect, isTyped = false) {
    if (state.isNavigating && state.isExam) return;

    const q = state.questions[state.index];

    // Typed answers require 100% exact match (case-insensitive)
    // Speech recognition allows 80% similarity
    const requiredThreshold = isTyped ? 1.0 : 0.8;

    if (state.isExam) {
        // ===== EXAM MODE =====
        if (q.type === 'speaking') {
            // For typed: compare lowercase exact match
            let isMatch;
            if (isTyped) {
                isMatch = ans.toLowerCase().trim() === q.en.toLowerCase().trim();
            } else {
                const simScore = similarity(ans, q.en);
                isMatch = simScore >= requiredThreshold;
            }

            const resDiv = document.getElementById('speak-result');

            if (isMatch) {
                // Store as object for clarity
                state.answers[state.index] = { value: q.en, correct: true, spoken: ans };
                resDiv.innerHTML = `✅ <span class="text-green-500 font-bold">${ans}</span>`;
                resDiv.className = "text-lg mb-6 min-h-[30px]";

                if (!state.isNavigating) {
                    state.isNavigating = true;
                    setTimeout(() => nextQuestion(), 1500);
                }
            } else {
                // Store wrong answer with metadata
                playSoundWrong();
                state.answers[state.index] = { value: null, correct: false, spoken: ans };
                const hint = isTyped ? `Jawaban: <span class="text-green-500">${q.en}</span>` : 'Coba lagi atau tekan Next';
                resDiv.innerHTML = `❌ <span class="text-red-500">${ans}</span> <br><span class="text-xs text-gray-400">${hint}</span>`;
                resDiv.className = "text-lg mb-6 min-h-[30px]";
            }
        } else {
            // MC / Listening
            state.answers[state.index] = { value: ans, correct: isCorrect };
            loadQ(state.index);
        }
    } else {
        // ===== PRACTICE MODE =====
        if (q.type === 'speaking') {
            let ok;
            if (isTyped) {
                ok = ans.toLowerCase().trim() === q.en.toLowerCase().trim();
            } else {
                const simScore = similarity(ans, q.en);
                ok = simScore >= requiredThreshold;
            }

            if (ok) {
                state.practiceCorrect++;
                playSoundCorrect();
                document.getElementById('speak-result').innerHTML = `✅ Benar! <span class="text-green-500 font-bold">${q.en}</span>`;
                showConfetti();
                setTimeout(() => {
                    if (state.index < state.max - 1) loadQ(state.index + 1);
                    else showResult();
                }, 1500);
            } else {
                playSoundWrong();
                document.getElementById('speak-result').innerHTML = `❌ Salah. <br>Harusnya: <span class="text-green-600 font-bold">${q.en}</span>`;
            }
        } else {
            // MC Feedback (Practice)
            const targetVal = (q.type === 'id-en') ? q.en : q.id;
            const container = document.getElementById('options-container');
            const buttons = container.getElementsByTagName('button');

            for (let btn of buttons) {
                // Remove default classes first
                btn.classList.remove('bg-white', 'border-gray-100', 'text-gray-600', 'hover:bg-gray-50');

                if (btn.textContent === ans) {
                    // Selected answer - show green if correct, red if wrong
                    if (isCorrect) {
                        btn.classList.add('bg-green-100', 'border-green-500', 'text-green-700');
                    } else {
                        btn.classList.add('bg-red-100', 'border-red-500', 'text-red-700');
                    }
                }

                // Show correct answer if user was wrong
                if (!isCorrect && btn.textContent === targetVal) {
                    btn.classList.add('bg-green-100', 'border-green-500', 'text-green-700');
                }

                btn.disabled = true;
                btn.classList.add('pointer-events-none');
            }

            if (isCorrect) {
                state.practiceCorrect++;
                playSoundCorrect();
                showConfetti();
                setTimeout(() => {
                    if (state.index < state.max - 1) loadQ(state.index + 1);
                    else showResult();
                }, 1000);
            } else {
                playSoundWrong();
                setTopBarShake();
                setTimeout(() => {
                    if (state.index < state.max - 1) loadQ(state.index + 1);
                    else showResult();
                }, 2500);
            }
        }
    }
}

// ========================================
// NAVIGATION
// ========================================

export function nextQuestion() {
    state.isNavigating = false;

    // On last question, finish the quiz
    if (state.index === state.max - 1) {
        showResult();
    } else if (state.index < state.max - 1) {
        loadQ(state.index + 1);
    }
}

export function prevQuestion() {
    state.isNavigating = false;
    if (state.index > 0) loadQ(state.index - 1);
}

// ========================================
// RESULT & RANKING
// ========================================

export async function showResult(forcedScore) {
    if (state.isFinished) return;
    state.isFinished = true;

    stopTimer();

    // Calculate Score
    let score = typeof forcedScore === 'number' ? forcedScore : 0;

    if (state.isExam && typeof forcedScore === 'undefined') {
        let correct = 0;
        state.questions.forEach((q, i) => {
            const ans = state.answers[i];
            if (ans && ans.correct) correct++;
        });
        score = Math.round((correct / state.max) * 100);
    } else if (!state.isExam && typeof forcedScore === 'undefined') {
        // Practice mode: Calculate actual score
        score = Math.round((state.practiceCorrect / state.max) * 100);
    }

    // Update UI
    const finalScoreEl = document.getElementById('final-score');
    if (finalScoreEl) finalScoreEl.textContent = score;

    // Feedback
    const feedbackEl = document.getElementById('feedback-text');
    let text = "Keep practicing!";
    if (score === 100) text = "Perfect Score! 🎉";
    else if (score >= 80) text = "Excellent! 👏";
    else if (score >= 60) text = "Good Job! 👍";
    else if (score >= 40) text = "Keep Learning! 📚";
    if (feedbackEl) feedbackEl.textContent = text;

    showConfetti();
    switchView('result');

    // --- RANKING LOGIC ---
    const rankBox = document.getElementById('rank-update-box');

    if (state.currentUser && state.currentUser.role === 'student' && state.isExam) {
        if (rankBox) rankBox.classList.remove('hidden');

        const userId = state.currentUser.id;

        if (userId) {
            console.log("Processing ranking for:", userId, "Score:", score);
            try {
                // Show loading
                const rankText = document.getElementById('rank-change-text');
                if (rankText) rankText.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Menyimpan...';

                const result = await processRanking(userId, score);
                updateRankUI(result, score);
            } catch (e) {
                console.error("Ranking Error:", e);
                const rankText = document.getElementById('rank-change-text');
                if (rankText) rankText.innerHTML = '<span class="text-red-500">Gagal menyimpan skor</span>';
            }
        }
    } else {
        if (rankBox) rankBox.classList.add('hidden');
    }

    // Show Review Button for Exam Mode
    const reviewBtn = document.getElementById('btn-review');
    if (reviewBtn) {
        if (state.isExam) {
            reviewBtn.classList.remove('hidden');
        } else {
            reviewBtn.classList.add('hidden');
        }
    }
}

// ========================================
// REVIEW JAWABAN
// ========================================

export function showReview() {
    const reviewList = document.getElementById('review-list');
    if (!reviewList) return;

    let html = '';

    state.questions.forEach((q, i) => {
        const userAns = state.answers[i];
        const isCorrect = userAns && userAns.correct;

        // Get the correct answer based on question type
        const correctAns = (q.type === 'id-en') ? q.en : q.id;

        // Get what the user answered
        let userAnswer = 'Tidak dijawab';
        if (userAns) {
            if (userAns.spoken) {
                userAnswer = userAns.spoken;
            } else if (userAns.value) {
                userAnswer = userAns.value;
            }
        }

        // Determine question text
        let questionText = '';
        if (q.type === 'id-en') questionText = q.id;
        else if (q.type === 'en-id') questionText = q.en;
        else if (q.type === 'listening') questionText = '🎧 ' + q.en;
        else if (q.type === 'speaking') questionText = '🎤 ' + q.id;

        html += `
            <div class="bg-white rounded-2xl p-4 shadow-sm border ${isCorrect ? 'border-green-200' : 'border-red-200'}">
                <div class="flex items-start gap-3">
                    <div class="w-8 h-8 rounded-full ${isCorrect ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'} flex items-center justify-center font-bold text-sm flex-shrink-0">
                        ${isCorrect ? '✓' : '✗'}
                    </div>
                    <div class="flex-1">
                        <div class="flex items-center gap-2 mb-1">
                            <span class="text-xs font-bold uppercase ${isCorrect ? 'text-green-600' : 'text-red-600'}">${q.type}</span>
                            <span class="text-xs text-gray-400">#${i + 1}</span>
                        </div>
                        <p class="font-bold text-brand-dark mb-2">${questionText}</p>
                        
                        <div class="text-sm">
                            <div class="flex items-center gap-2">
                                <span class="text-gray-400">Jawaban:</span>
                                <span class="${isCorrect ? 'text-green-600 font-bold' : 'text-red-500'}">${userAnswer}</span>
                            </div>
                            ${!isCorrect ? `
                                <div class="flex items-center gap-2 mt-1">
                                    <span class="text-gray-400">Benar:</span>
                                    <span class="text-green-600 font-bold">${correctAns}</span>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                </div>
            </div>
        `;
    });

    reviewList.innerHTML = html;
    switchView('review');
}

// Expose globally for HTML button
window.showReview = showReview;

async function processRanking(userId, newPoints) {
    const usersRef = collection(db, "santri_users");

    // 1. Get Current Ranks (Before Update)
    const snapPre = await getDocs(query(usersRef));
    let usersPre = [];
    snapPre.forEach(d => usersPre.push({ id: d.id, ...d.data() }));

    usersPre.sort((a, b) => (b.highscore || 0) - (a.highscore || 0));
    const preRank = usersPre.findIndex(u => u.id === userId) + 1;
    const preTotal = usersPre.find(u => u.id === userId)?.highscore || 0;

    // 2. Update Score AND Last Exam Date
    const userRef = doc(db, "santri_users", userId);
    const nowISO = new Date().toISOString();

    await updateDoc(userRef, {
        highscore: increment(newPoints),
        lastExamDate: nowISO
    });

    // Update Local State immediately
    if (state.currentUser) {
        state.currentUser.highscore = preTotal + newPoints;
        state.currentUser.lastExamDate = nowISO;
    }

    // 3. Calc Post-Update
    const postTotal = preTotal + newPoints;
    const usersPost = usersPre.map(u => {
        if (u.id === userId) return { ...u, highscore: postTotal };
        return u;
    });
    usersPost.sort((a, b) => (b.highscore || 0) - (a.highscore || 0));
    const postRank = usersPost.findIndex(u => u.id === userId) + 1;

    return { preRank, postRank, preTotal, postTotal };
}

function updateRankUI(data, addedScore) {
    const totalEl = document.getElementById('display-total-score');
    const addEl = document.getElementById('display-score-add');
    const rankText = document.getElementById('rank-change-text');

    if (totalEl) totalEl.textContent = data.postTotal;
    if (addEl) addEl.textContent = addedScore;

    if (data.postRank < data.preRank) {
        rankText.innerHTML = `<span class="text-green-500"><i class="fas fa-arrow-up"></i> Naik! #${data.preRank} &#10145; #${data.postRank}</span>`;
    } else if (data.postRank === data.preRank) {
        rankText.innerHTML = `<span class="text-gray-500">Tetap #${data.postRank}</span>`;
    } else {
        rankText.textContent = `#${data.postRank}`;
    }
}
