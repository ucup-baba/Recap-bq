// Global State Management
export const state = {
    // Current View
    currentView: 'login', // login, menu, quiz, result

    // Quiz State
    mode: 'mixed', // mixed (exam), id-en, en-id, listening, speaking
    isExam: false,
    isRemedial: false,        // NEW: apakah sedang remidi
    remedialAvailable: false, // NEW: apakah eligible untuk remidi  
    questions: [], // Array of question objects
    answers: [],   // Array of user answers
    index: 0,      // Current question index
    max: 0,        // Total questions
    score: 0,
    isFinished: false, // NEW: prevent double submission
    practiceCorrect: 0, // NEW: track correct answers in practice mode

    // Timer
    timer: null,
    time: 600, // 10 minutes default

    // Settings
    speechRate: 0.9, // 1.0 = normal, 0.7 = slow, 0.5 = very slow

    // Data
    users: {
        '00': { name: 'Super Admin', role: 'admin' }
    },
    vocabulary: [],

    // App Settings (loaded from Firestore)
    appSettings: {
        ccaEnabled: true,
        mathMode: 'battle' // 'battle' or 'practice'
    }
};
