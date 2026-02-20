const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Send OTP for Password Reset.
 * Generates a 6-digit code and saves it to Firestore.
 * In production, this should also send an email.
 */
exports.sendPasswordResetOtp = functions.https.onCall(async (data, context) => {
    const email = data.email;
    if (!email) {
        throw new functions.https.HttpsError('invalid-argument', 'Email is required.');
    }

    try {
        // 1. Check if user exists
        try {
            await admin.auth().getUserByEmail(email);
        } catch (e) {
            // Security: Don't reveal if user exists, but for debug we might throw
            // Return success to prevent enumeration, or throw if specific requirement
            if (e.code === 'auth/user-not-found') {
                throw new functions.https.HttpsError('not-found', 'Email không tồn tại trong hệ thống.');
            }
            throw e;
        }

        // 2. Generate Code
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 15 * 60 * 1000)); // 15 mins

        // 3. Save to Firestore
        await admin.firestore().collection('password_resets').doc(email).set({
            email: email,
            code: code,
            expiresAt: expiresAt,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 4. Send Email (Mock)
        console.log(`[Mock Email Service] Sending OTP ${code} to ${email}`);
        // TODO: Integrate with Nodemailer or SendGrid here
        
        return { success: true, message: 'OTP sent.' };

    } catch (error) {
        console.error("Error sending OTP:", error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', 'Unable to send OTP.');
    }
});

/**
 * Verify OTP and Reset Password.
 */
exports.resetPasswordWithOtp = functions.https.onCall(async (data, context) => {
    const email = data.email;
    const otp = data.otp;
    const newPassword = data.newPassword;

    if (!email || !otp || !newPassword) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing fields.');
    }

    if (newPassword.length < 6) {
        throw new functions.https.HttpsError('invalid-argument', 'Password must be at least 6 characters.');
    }

    try {
        // 1. Verify OTP
        const docRef = admin.firestore().collection('password_resets').doc(email);
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new functions.https.HttpsError('not-found', 'Invalid or expired OTP request.');
        }

        const record = doc.data();
        const expiresAt = record.expiresAt.toDate();
        const serverCode = record.code;

        if (new Date() > expiresAt) {
            throw new functions.https.HttpsError('deadline-exceeded', 'OTP has expired.');
        }

        if (serverCode !== otp) {
            throw new functions.https.HttpsError('permission-denied', 'Incorrect OTP.');
        }

        // 2. Update Password
        const userRecord = await admin.auth().getUserByEmail(email);
        await admin.auth().updateUser(userRecord.uid, {
            password: newPassword
        });

        // 3. Cleanup
        await docRef.delete();

        return { success: true };

    } catch (error) {
        console.error("Error resetting password:", error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', 'Failed to reset password.');
    }
});
