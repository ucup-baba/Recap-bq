// Text-to-Speech (TTS) & Speech-to-Text (STT) Logic
import { state } from './state.js';
import { handleAns } from './quiz.js'; // Circular dependency handled via function call

let voices = [];
let audioUnlocked = false;
let recognition;
let isRecording = false;

// --- TTS ---

export function loadVoices() {
    const allVoices = window.speechSynthesis.getVoices();
    // Filter for English voices, preferring US/GB
    voices = allVoices.filter(v => v.lang.includes('en'));
    if (voices.length === 0) voices = allVoices; // Fallback to all
    console.log("Voices loaded:", voices.length);
}

if (window.speechSynthesis) {
    window.speechSynthesis.onvoiceschanged = loadVoices;
    loadVoices(); // Init try
}

export function unlockAudio() {
    if (audioUnlocked || !window.speechSynthesis) return;

    // 1. Wake up TTS with a silent utterance
    const u = new SpeechSynthesisUtterance('');
    window.speechSynthesis.speak(u);
    audioUnlocked = true;
    console.log("Audio Unlocked");
}

export function checkAudio() {
    loadVoices();
    if (!window.speechSynthesis) {
        alert("Maaf, Browser Anda TIDAK mendukung fitur suara.\n\nSolusi: Gunakan Google Chrome.");
        return;
    }
    if (voices.length === 0) {
        alert("Suara tidak terdeteksi (" + window.speechSynthesis.getVoices().length + " voices).\n\nHP ini mungkin tidak punya 'Google Speech Services'.\n\nSolusi: Gunakan Google Chrome.");
        return;
    }

    const u = new SpeechSynthesisUtterance("Audio check one two three");
    u.lang = 'en-US';
    u.rate = 1.0;
    u.volume = 1.0;

    u.onstart = () => alert("Suara sedang diputar...\nDengarkan 'Audio check'.");
    u.onerror = (e) => alert("Error pemutaran: " + e.error);

    window.speechSynthesis.cancel();
    window.speechSynthesis.speak(u);
}

export function speakCurrentWord() {
    const q = state.questions[state.index];
    if (!q || !window.speechSynthesis) return;

    // 1. Clear queue
    window.speechSynthesis.cancel();

    // 2. Retry loading voices if empty (Android Webview issue)
    if (voices.length === 0) loadVoices();

    // 3. Fallback Check
    if (voices.length === 0) {
        const btn = document.getElementById('btn-speak');
        if (btn) btn.classList.add('text-red-500');
        console.warn("No voices available");
    }

    const u = new SpeechSynthesisUtterance(q.en);
    u.lang = 'en-US';
    u.rate = state.speechRate || 0.9;
    u.pitch = 1.0;

    // Select best voice (Google US English priority)
    const preferredVoice = voices.find(v => v.name.includes("Google US English")) ||
        voices.find(v => v.lang === "en-US") ||
        voices[0];
    if (preferredVoice) u.voice = preferredVoice;

    // Visual Feedback
    const btn = document.getElementById('btn-speak');
    if (btn) {
        btn.classList.add('animate-pulse', 'text-brand-primary');
        u.onend = () => btn.classList.remove('animate-pulse', 'text-brand-primary');
        u.onerror = () => btn.classList.remove('animate-pulse', 'text-brand-primary');
    }

    // Force speak
    window.speechSynthesis.speak(u);
}

// --- STT (Speaking Mode) ---

export function toggleRecording() {
    const btn = document.getElementById('btn-record');
    const res = document.getElementById('speak-result');

    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
        alert("Browser ini tidak mendukung fitur Speaking (STT).\nGunakan Google Chrome.");
        return;
    }

    if (isRecording) {
        recognition.stop();
        return;
    }

    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    recognition = new SpeechRecognition();
    recognition.lang = 'en-US';
    recognition.interimResults = false;
    recognition.maxAlternatives = 1;

    recognition.onstart = () => {
        isRecording = true;
        btn.classList.add('animate-pulse', 'bg-red-600');
        res.textContent = "Mendengarkan...";
    };

    recognition.onresult = (event) => {
        const transcript = event.results[0][0].transcript;
        res.textContent = `"${transcript}"`;
        handleAns(transcript, true); // Auto submit match check inside logic
    };

    recognition.onend = () => {
        isRecording = false;
        btn.classList.remove('animate-pulse', 'bg-red-600');
        if (res.textContent === "Mendengarkan...") res.textContent = "Gagal mendengar, coba lagi.";
    };

    recognition.onerror = (e) => {
        console.error(e.error);
        res.textContent = "Error: " + e.error;
        isRecording = false;
        btn.classList.remove('animate-pulse', 'bg-red-600');
    };

    recognition.start();
}

// --- Fallback Typing Mode ---

// Check if STT is available
export function isSTTAvailable() {
    return ('webkitSpeechRecognition' in window) || ('SpeechRecognition' in window);
}

// Show appropriate Speaking UI based on STT availability
export function setupSpeakingUI() {
    const micBtn = document.getElementById('btn-record');
    const fallback = document.getElementById('speaking-fallback');

    if (isSTTAvailable()) {
        // STT available - show mic button
        if (micBtn) micBtn.classList.remove('hidden');
        if (fallback) fallback.classList.add('hidden');
    } else {
        // STT NOT available - show typing fallback
        if (micBtn) micBtn.classList.add('hidden');
        if (fallback) fallback.classList.remove('hidden');

        // Update result text
        const res = document.getElementById('speak-result');
        if (res) res.textContent = "Ketik bahasa Inggrisnya di bawah";
    }
}

// Submit typed answer (fallback) - requires exact match
window.submitTypedAnswer = function () {
    const input = document.getElementById('speaking-input');
    if (!input) return;

    const answer = input.value.trim();
    if (!answer) {
        alert("Ketik jawaban dulu!");
        return;
    }

    // Clear input
    input.value = '';

    // Submit to handleAns with isTyped=true for 100% exact match
    handleAns(answer, true, true); // (answer, isSpeaking, isTyped)
}

// Handle Enter key on input
document.addEventListener('DOMContentLoaded', () => {
    const input = document.getElementById('speaking-input');
    if (input) {
        input.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                window.submitTypedAnswer();
            }
        });
    }
});
