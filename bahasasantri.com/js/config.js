// Firebase Configuration & Initialization
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-app.js";
import { getFirestore, collection, getDocs, query, orderBy, limit, addDoc, deleteDoc, doc, onSnapshot, setDoc, updateDoc, increment } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";
import { getAuth, signInAnonymously } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-auth.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-analytics.js";
import { state } from './state.js';

const firebaseConfig = {
    apiKey: 'AIzaSyALAwhfIGOb5i7ls65-4t7t_Qqrl_VpA7Q',
    authDomain: 'recap-bq.firebaseapp.com',
    projectId: 'recap-bq',
    storageBucket: 'recap-bq.firebasestorage.app',
    messagingSenderId: '733581949032',
    appId: '1:733581949032:web:50163e0f53b622666123dd',
    measurementId: 'G-MWBNZ8RL31'
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
const auth = getAuth(app);
const analytics = getAnalytics(app);

export async function fetchVocab() {
    return retry(async () => {
        await signInAnonymously(auth);

        // Correct Query Path from original source
        const q = query(
            collection(db, "global/daily_vocab/history"),
            orderBy("createdAt", "desc"),
            limit(15)
        );

        const snapshot = await getDocs(q);

        let all = [];
        snapshot.forEach(d => {
            const data = d.data();
            // Flatten the vocab array structure
            if (data.vocab) {
                data.vocab.forEach(v => all.push({
                    en: v.english,
                    id: v.indonesian,
                    pron: v.pronunciation
                }));
            }
        });

        // Deduplicate
        all = all.filter((v, i, a) => a.findIndex(t => t.en === v.en) === i);

        state.vocabulary = all;
        console.log("Loaded Vocab:", state.vocabulary.length);

        // Cache vocab for offline use
        if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
            navigator.serviceWorker.controller.postMessage({
                type: 'CACHE_VOCAB',
                vocab: state.vocabulary
            });
        }

        if (state.vocabulary.length === 0) {
            console.warn("Vocab empty, using fallbacks");
            state.vocabulary = [{ en: "Cat", id: "Kucing" }, { en: "Dog", id: "Anjing" }];
        }

        return state.vocabulary;
    }, 3, 'fetchVocab');
}

// ========================================
// RETRY LOGIC WRAPPER
// ========================================

/**
 * Retry a function with exponential backoff
 * @param {Function} fn - Async function to retry
 * @param {number} maxRetries - Max attempts (default 3)
 * @param {string} context - Context for logging
 */
export async function retry(fn, maxRetries = 3, context = 'unknown') {
    let lastError = null;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return await fn();
        } catch (e) {
            lastError = e;
            console.warn(`[${context}] Attempt ${attempt}/${maxRetries} failed:`, e.message);

            if (attempt < maxRetries) {
                // Exponential backoff: 1s, 2s, 4s...
                const delay = Math.pow(2, attempt - 1) * 1000;
                showRetryMessage(`Mencoba ulang... (${attempt}/${maxRetries})`);
                await sleep(delay);
            }
        }
    }

    // All retries failed
    hideRetryMessage();
    console.error(`[${context}] All ${maxRetries} attempts failed`);
    throw lastError;
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// ========================================
// ERROR BOUNDARY / UI FEEDBACK
// ========================================

let retryOverlay = null;

function showRetryMessage(msg) {
    if (!retryOverlay) {
        retryOverlay = document.createElement('div');
        retryOverlay.id = 'retry-overlay';
        retryOverlay.className = 'fixed bottom-4 left-1/2 -translate-x-1/2 bg-gray-800 text-white px-6 py-3 rounded-full shadow-lg z-50 flex items-center gap-3 animate-pulse';
        document.body.appendChild(retryOverlay);
    }
    retryOverlay.innerHTML = `<i class="fas fa-sync fa-spin"></i> ${msg}`;
    retryOverlay.classList.remove('hidden');
}

function hideRetryMessage() {
    if (retryOverlay) {
        retryOverlay.classList.add('hidden');
    }
}

// Global Error Handler
window.onerror = function (msg, url, line, col, error) {
    console.error("Global Error:", msg, "at", url, line);

    // Only show user-friendly errors for critical failures
    if (msg.includes('Firebase') || msg.includes('network')) {
        showErrorToast('Koneksi bermasalah, coba refresh halaman.');
    }

    return false; // Allow normal error handling
};

window.onunhandledrejection = function (event) {
    console.error("Unhandled Promise Rejection:", event.reason);

    // Handle Firebase-specific errors
    if (event.reason && event.reason.code) {
        const code = event.reason.code;
        if (code === 'unavailable' || code === 'network-request-failed') {
            showErrorToast('Tidak ada koneksi internet.');
        }
    }
};

function showErrorToast(msg) {
    const toast = document.createElement('div');
    toast.className = 'fixed bottom-4 left-1/2 -translate-x-1/2 bg-red-500 text-white px-6 py-3 rounded-full shadow-lg z-50';
    toast.textContent = msg;
    document.body.appendChild(toast);

    setTimeout(() => toast.remove(), 4000);
}

