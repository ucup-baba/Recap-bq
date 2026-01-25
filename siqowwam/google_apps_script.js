/**
 * Google Apps Script untuk Siqowwam - Data Sync dari Flutter App
 * 
 * CARA SETUP:
 * 1. Buka Google Drive, buat Spreadsheet baru bernama "Siqowwam Data"
 * 2. Buka Extensions > Apps Script
 * 3. Hapus semua kode default, paste seluruh kode ini
 * 4. Klik Save (Ctrl+S)
 * 5. Klik Deploy > New Deployment
 * 6. Pilih tipe: Web App
 * 7. Execute as: Me, Who has access: Anyone
 * 8. Klik Deploy, copy URL yang muncul
 * 9. Paste URL tersebut di app Flutter
 * 
 * PENTING: Setiap kali update kode, harus Deploy > Manage Deployments > Edit > New Version
 */

// Nama-nama sheet
const TRANSACTIONS_SHEET = 'Transaksi';
const USERS_SHEET = 'Users';
const FUND_REQUESTS_SHEET = 'Fund Requests';
const USER_HISTORY_SHEET = 'Riwayat Per User';

/**
 * Handle HTTP GET requests - used for syncing data (avoid CORS issues)
 */
function doGet(e) {
    try {
        // Check if this is a data sync request
        if (e.parameter && e.parameter.action) {
            const action = e.parameter.action;
            const dataParam = e.parameter.data;

            if (!dataParam) {
                return createJsonResponse({ success: false, error: 'No data provided' });
            }

            // Decode and parse the data
            const data = JSON.parse(decodeURIComponent(dataParam));

            let result;
            switch (action) {
                case 'addTransaction':
                    result = addTransaction(data);
                    break;
                case 'syncUser':
                    result = syncUser(data);
                    break;
                case 'syncFundRequest':
                    result = syncFundRequest(data);
                    break;
                default:
                    result = { success: false, error: 'Unknown action: ' + action };
            }

            return createJsonResponse(result);
        }

        // Default response for health check
        return createJsonResponse({
            status: 'ok',
            message: 'Siqowwam Google Sheets Sync API',
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        return createJsonResponse({ success: false, error: error.toString() });
    }
}

/**
 * Handle HTTP POST requests (backup method)
 */
function doPost(e) {
    try {
        const data = JSON.parse(e.postData.contents);
        const action = data.action;

        let result;
        switch (action) {
            case 'addTransaction':
                result = addTransaction(data);
                break;
            case 'syncUser':
                result = syncUser(data);
                break;
            case 'syncFundRequest':
                result = syncFundRequest(data);
                break;
            default:
                result = { success: false, error: 'Unknown action: ' + action };
        }

        return createJsonResponse(result);

    } catch (error) {
        return createJsonResponse({ success: false, error: error.toString() });
    }
}

/**
 * Create JSON response with proper headers
 */
function createJsonResponse(data) {
    return ContentService
        .createTextOutput(JSON.stringify(data))
        .setMimeType(ContentService.MimeType.JSON);
}

/**
 * Inisialisasi sheet jika belum ada
 */
function initializeSheets() {
    const ss = SpreadsheetApp.getActiveSpreadsheet();

    // Transactions sheet
    let txSheet = ss.getSheetByName(TRANSACTIONS_SHEET);
    if (!txSheet) {
        txSheet = ss.insertSheet(TRANSACTIONS_SHEET);
        txSheet.appendRow([
            'ID', 'Tanggal', 'Tipe', 'Kategori', 'Jumlah',
            'Saldo Sebelum', 'Saldo Sesudah',
            'User ID', 'User Name', 'Deskripsi',
            'Approved By ID', 'Approved By Name'
        ]);
        txSheet.getRange(1, 1, 1, 12).setFontWeight('bold').setBackground('#4CAF50').setFontColor('white');
    }

    // Users sheet
    let usersSheet = ss.getSheetByName(USERS_SHEET);
    if (!usersSheet) {
        usersSheet = ss.insertSheet(USERS_SHEET);
        usersSheet.appendRow([
            'ID', 'Nama', 'Email', 'Role', 'Saldo',
            'Status', 'Created At', 'Role ID'
        ]);
        usersSheet.getRange(1, 1, 1, 8).setFontWeight('bold').setBackground('#2196F3').setFontColor('white');
    }

    // Fund Requests sheet
    let frSheet = ss.getSheetByName(FUND_REQUESTS_SHEET);
    if (!frSheet) {
        frSheet = ss.insertSheet(FUND_REQUESTS_SHEET);
        frSheet.appendRow([
            'ID', 'Tanggal', 'User ID', 'User Name', 'User Email',
            'Jumlah', 'Deskripsi', 'Status',
            'Reviewed By', 'Reviewed At', 'Review Note'
        ]);
        frSheet.getRange(1, 1, 1, 11).setFontWeight('bold').setBackground('#FF9800').setFontColor('white');
    }

    // User History sheet (Riwayat Per User)
    let uhSheet = ss.getSheetByName(USER_HISTORY_SHEET);
    if (!uhSheet) {
        uhSheet = ss.insertSheet(USER_HISTORY_SHEET);
        uhSheet.appendRow([
            'User Name', 'User Email', 'Tanggal', 'Tipe', 'Kategori',
            'Jumlah', 'Saldo Sebelum', 'Saldo Sesudah', 'Deskripsi', 'Transaction ID'
        ]);
        uhSheet.getRange(1, 1, 1, 10).setFontWeight('bold').setBackground('#9C27B0').setFontColor('white');
    }

    return { success: true, message: 'Sheets initialized' };
}

/**
 * Add or update transaction
 */
function addTransaction(data) {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName(TRANSACTIONS_SHEET);

    if (!sheet) {
        initializeSheets();
        sheet = ss.getSheetByName(TRANSACTIONS_SHEET);
    }

    // Check if transaction exists (update) or new (append)
    const existingRow = findRowById(sheet, data.id);

    const rowData = [
        data.id,
        formatDate(data.date),
        data.type === 'income' ? 'Pemasukan' : 'Pengeluaran',
        data.category,
        data.amount,
        data.balanceBefore || 0,
        data.balanceAfter || 0,
        data.userId,
        data.userName,
        data.description,
        data.approvedUserId || '',
        data.approvedUserName || ''
    ];

    let mainResult;
    if (existingRow > 0) {
        sheet.getRange(existingRow, 1, 1, rowData.length).setValues([rowData]);
        mainResult = { success: true, action: 'updated', id: data.id };
    } else {
        sheet.appendRow(rowData);
        mainResult = { success: true, action: 'added', id: data.id };
    }

    // Also add to User History sheet (Riwayat Per User)
    try {
        let uhSheet = ss.getSheetByName(USER_HISTORY_SHEET);
        if (!uhSheet) {
            initializeSheets();
            uhSheet = ss.getSheetByName(USER_HISTORY_SHEET);
        }

        // Check if this transaction already exists in user history
        const uhExistingRow = findRowByTransactionId(uhSheet, data.id, 9); // Column J (index 9) is Transaction ID

        const uhRowData = [
            data.userName,
            data.userEmail || '',
            formatDate(data.date),
            data.type === 'income' ? 'Pemasukan' : 'Pengeluaran',
            data.category,
            data.amount,
            data.balanceBefore || 0,
            data.balanceAfter || 0,
            data.description,
            data.id
        ];

        if (uhExistingRow > 0) {
            uhSheet.getRange(uhExistingRow, 1, 1, uhRowData.length).setValues([uhRowData]);
        } else {
            uhSheet.appendRow(uhRowData);
        }
    } catch (e) {
        Logger.log('Error adding to user history: ' + e.toString());
    }

    return mainResult;
}

/**
 * Helper: Find row by transaction ID in specified column
 */
function findRowByTransactionId(sheet, transactionId, columnIndex) {
    const data = sheet.getDataRange().getValues();
    for (let i = 1; i < data.length; i++) {
        if (data[i][columnIndex] === transactionId) {
            return i + 1;
        }
    }
    return -1;
}

/**
 * Sync user data
 */
function syncUser(data) {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName(USERS_SHEET);

    if (!sheet) {
        initializeSheets();
        sheet = ss.getSheetByName(USERS_SHEET);
    }

    const existingRow = findRowById(sheet, data.id);

    const rowData = [
        data.id,
        data.name,
        data.email,
        formatRole(data.role),
        data.balance,
        formatStatus(data.status),
        formatDate(data.createdAt),
        data.roleId || ''
    ];

    if (existingRow > 0) {
        sheet.getRange(existingRow, 1, 1, rowData.length).setValues([rowData]);
        return { success: true, action: 'updated', id: data.id };
    } else {
        sheet.appendRow(rowData);
        return { success: true, action: 'added', id: data.id };
    }
}

/**
 * Sync fund request
 */
function syncFundRequest(data) {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName(FUND_REQUESTS_SHEET);

    if (!sheet) {
        initializeSheets();
        sheet = ss.getSheetByName(FUND_REQUESTS_SHEET);
    }

    const existingRow = findRowById(sheet, data.id);

    const rowData = [
        data.id,
        formatDate(data.date),
        data.userId,
        data.userName,
        data.userEmail,
        data.amount,
        data.description,
        formatFundRequestStatus(data.status),
        data.reviewedBy || '',
        data.reviewedAt ? formatDate(data.reviewedAt) : '',
        data.reviewNote || ''
    ];

    if (existingRow > 0) {
        sheet.getRange(existingRow, 1, 1, rowData.length).setValues([rowData]);
        return { success: true, action: 'updated', id: data.id };
    } else {
        sheet.appendRow(rowData);
        return { success: true, action: 'added', id: data.id };
    }
}

/**
 * Helper: Find row by ID in column A
 */
function findRowById(sheet, id) {
    const data = sheet.getDataRange().getValues();
    for (let i = 1; i < data.length; i++) {
        if (data[i][0] === id) {
            return i + 1; // +1 because array is 0-indexed but rows are 1-indexed
        }
    }
    return -1;
}

/**
 * Helper: Format date string
 */
function formatDate(dateString) {
    if (!dateString) return '';
    try {
        const date = new Date(dateString);
        return Utilities.formatDate(date, 'Asia/Jakarta', 'dd/MM/yyyy HH:mm');
    } catch (e) {
        return dateString;
    }
}

/**
 * Helper: Format role
 */
function formatRole(role) {
    switch (role) {
        case 'super_admin': return 'Super Admin';
        case 'admin': return 'Admin';
        case 'viewer': return 'Viewer';
        case 'member': return 'Member';
        default: return role || 'Member';
    }
}

/**
 * Helper: Format status
 */
function formatStatus(status) {
    switch (status) {
        case 'pending': return 'Pending';
        case 'approved': return 'Aktif';
        case 'blocked': return 'Diblokir';
        default: return status || '';
    }
}

/**
 * Helper: Format fund request status
 */
function formatFundRequestStatus(status) {
    switch (status) {
        case 'pending': return 'Menunggu';
        case 'approved': return 'Disetujui';
        case 'rejected': return 'Ditolak';
        default: return status || '';
    }
}

/**
 * Run this function once to initialize the sheets
 */
function setup() {
    initializeSheets();
    Logger.log('Setup completed!');
}
