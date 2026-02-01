// Global State Management
export const state = {
    // Current View
    currentView: 'login', // login, menu, quiz, result

    // Quiz State
    mode: 'mixed', // mixed (exam), id-en, en-id, listening, speaking
    isExam: false,
    questions: [], // Array of question objects
    answers: [],   // Array of user answers
    index: 0,      // Current question index
    max: 0,        // Total questions
    score: 0,

    // Timer
    timer: null,
    time: 600, // 10 minutes default

    // Settings
    speechRate: 0.9, // 1.0 = normal, 0.7 = slow, 0.5 = very slow

    // Data
    users: {
        '00': { name: 'Super Admin', role: 'admin' }
    },
    vocabulary: []
};
