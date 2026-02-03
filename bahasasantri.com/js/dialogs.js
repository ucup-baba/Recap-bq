// ========================================
// GENERIC DIALOG SYSTEM (replaces alert/confirm)
// ========================================

let confirmCallback = null;

// Show notification dialog (replaces alert)
window.showNotification = function (message, title = 'Notifikasi', icon = 'info') {
    const dialog = document.getElementById('notification-dialog');
    const titleEl = document.getElementById('notif-title');
    const messageEl = document.getElementById('notif-message');
    const iconEl = document.getElementById('notif-icon');
    const iconContainer = document.getElementById('notif-icon-container');

    if (!dialog || !titleEl || !messageEl || !iconEl || !iconContainer) return;

    // Set content
    titleEl.textContent = title;
    messageEl.textContent = message;

    // Set icon based on type
    const iconMap = {
        'info': { icon: 'fa-info-circle', bg: 'bg-blue-100', color: 'text-blue-500' },
        'success': { icon: 'fa-check-circle', bg: 'bg-green-100', color: 'text-green-500' },
        'warning': { icon: 'fa-exclamation-triangle', bg: 'bg-yellow-100', color: 'text-yellow-500' },
        'error': { icon: 'fa-times-circle', bg: 'bg-red-100', color: 'text-red-500' }
    };

    const iconConfig = iconMap[icon] || iconMap['info'];
    iconEl.className = `fas ${iconConfig.icon} ${iconConfig.color} text-2xl`;
    iconContainer.className = `w-16 h-16 ${iconConfig.bg} rounded-full flex items-center justify-center mx-auto mb-4`;

    // Show dialog
    dialog.classList.remove('hidden');
    dialog.classList.add('flex');
}

// Close notification dialog
window.closeNotificationDialog = function () {
    const dialog = document.getElementById('notification-dialog');
    if (dialog) {
        dialog.classList.add('hidden');
        dialog.classList.remove('flex');
    }
}

// Show confirmation dialog (replaces confirm)
window.showConfirmation = function (message, title = 'Konfirmasi', yesText = 'Ya', noText = 'Batal') {
    return new Promise((resolve) => {
        const dialog = document.getElementById('confirmation-dialog');
        const titleEl = document.getElementById('confirm-title');
        const messageEl = document.getElementById('confirm-message');
        const yesBtn = document.getElementById('confirm-yes-btn');

        if (!dialog || !titleEl || !messageEl || !yesBtn) {
            resolve(false);
            return;
        }

        // Set content
        titleEl.textContent = title;
        messageEl.textContent = message;
        yesBtn.textContent = yesText;

        // Store callback
        confirmCallback = resolve;

        // Show dialog
        dialog.classList.remove('hidden');
        dialog.classList.add('flex');
    });
}

// Handle confirmation yes
window.handleConfirmYes = function () {
    if (confirmCallback) {
        confirmCallback(true);
        confirmCallback = null;
    }
    // Close dialog without calling callback again
    const dialog = document.getElementById('confirmation-dialog');
    if (dialog) {
        dialog.classList.add('hidden');
        dialog.classList.remove('flex');
    }
}

// Close confirmation dialog
window.closeConfirmationDialog = function () {
    const dialog = document.getElementById('confirmation-dialog');
    if (dialog) {
        dialog.classList.add('hidden');
        dialog.classList.remove('flex');
    }
    if (confirmCallback) {
        confirmCallback(false);
        confirmCallback = null;
    }
}

export const showNotification = window.showNotification;
export const showConfirmation = window.showConfirmation;

