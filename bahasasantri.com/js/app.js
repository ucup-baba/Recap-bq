// Main App Entry
import { state } from './state.js';
import { fetchVocab } from './config.js';
import { startQuiz, nextQuestion, prevQuestion, showResult } from './quiz.js';
import { loadVoices, unlockAudio, checkAudio, speakCurrentWord, toggleRecording } from './audio.js';
import { switchView } from './ui.js';
import { initAdmin } from './admin.js';
import { initMath } from './math.js';

// Global Exposure for HTML onclick events
window.startQuiz = startQuiz;
window.nextQuestion = nextQuestion;
window.prevQuestion = prevQuestion;
window.checkAudio = checkAudio;
window.speakCurrentWord = speakCurrentWord;
window.toggleRecording = toggleRecording;
window.fetchVocab = fetchVocab;
window.switchView = switchView;

// Initialization
document.addEventListener('DOMContentLoaded', async () => {
    console.log("App v5: Math Battle Ready");
    await fetchVocab();
    initAdmin();
    initMath(); // Load Math Logic

    // Login Handling
    const loginBtn = document.getElementById('btn-login');
    if (loginBtn) {
        loginBtn.addEventListener('click', () => {
            const code = document.getElementById('login-code').value.padStart(2, '0'); // Helper: Pad 1 -> 01

            if (state.users[code]) {
                state.currentUser = state.users[code];

                // Admin vs User Route
                if (code === '00') {
                    switchView('admin');
                } else {
                    document.getElementById('menu-user-name').textContent = state.currentUser.name;
                    unlockAudio(); // Unlock audio context
                    switchView('menu');
                }
            } else {
                const err = document.getElementById('login-error');
                err.classList.remove('hidden');
                setTimeout(() => err.classList.add('hidden'), 2000);
            }
        });
    }

    // Navigation
    const btnBack = document.getElementById('btn-back-menu');
    if (btnBack) {
        btnBack.addEventListener('click', () => {
            const confirmExit = confirm("Yakin ingin keluar dari ujian?");
            if (confirmExit) switchView('menu');
        });
    }

    const btnNext = document.getElementById('btn-next');
    if (btnNext) btnNext.addEventListener('click', nextQuestion);

    const btnPrev = document.getElementById('btn-prev');
    if (btnPrev) btnPrev.addEventListener('click', prevQuestion);

    // Result Home Button (Conditional)
    const btnResultHome = document.getElementById('btn-result-home');
    if (btnResultHome) {
        btnResultHome.addEventListener('click', () => {
            if (state.currentUser && state.currentUser.role === 'admin') {
                switchView('admin');
            } else {
                switchView('menu');
            }
        });
    }

    // Math Battle Button
    const btnMath = document.getElementById('btn-math-battle');
    if (btnMath) {
        btnMath.addEventListener('click', () => switchView('math-lobby'));
    }
});

// ========================================
// PWA INSTALL PROMPT
// ========================================

let deferredPrompt = null;

window.addEventListener('beforeinstallprompt', (e) => {
    // Prevent default browser install prompt
    e.preventDefault();
    deferredPrompt = e;

    // Show custom install banner after short delay
    setTimeout(() => {
        showInstallBanner();
    }, 3000);
});

function showInstallBanner() {
    // Don't show if already installed or dismissed
    if (!deferredPrompt) return;
    if (localStorage.getItem('pwa-dismissed')) return;

    const banner = document.createElement('div');
    banner.id = 'install-banner';
    banner.className = 'fixed bottom-4 left-4 right-4 bg-white rounded-2xl shadow-xl p-4 z-50 flex items-center gap-4 border border-gray-100';
    banner.innerHTML = `
        <div class="w-12 h-12 bg-brand-primary/10 rounded-xl flex items-center justify-center flex-shrink-0">
            <i class="fas fa-download text-brand-primary text-xl"></i>
        </div>
        <div class="flex-1">
            <p class="font-bold text-brand-dark text-sm">Install Santri Pintar</p>
            <p class="text-xs text-gray-500">Akses lebih cepat tanpa browser!</p>
        </div>
        <button id="btn-install" class="px-4 py-2 bg-brand-primary text-white rounded-xl text-sm font-bold hover:bg-orange-600 transition-colors">
            Install
        </button>
        <button id="btn-dismiss-install" class="w-8 h-8 text-gray-400 hover:text-gray-600">
            <i class="fas fa-times"></i>
        </button>
    `;

    document.body.appendChild(banner);

    // Install button
    document.getElementById('btn-install').addEventListener('click', async () => {
        if (!deferredPrompt) return;

        deferredPrompt.prompt();
        const result = await deferredPrompt.userChoice;

        if (result.outcome === 'accepted') {
            console.log('PWA installed');
        }

        deferredPrompt = null;
        banner.remove();
    });

    // Dismiss button
    document.getElementById('btn-dismiss-install').addEventListener('click', () => {
        localStorage.setItem('pwa-dismissed', 'true');
        banner.remove();
    });
}

// Track if installed
window.addEventListener('appinstalled', () => {
    deferredPrompt = null;
    const banner = document.getElementById('install-banner');
    if (banner) banner.remove();
    console.log('PWA installed successfully');
});

