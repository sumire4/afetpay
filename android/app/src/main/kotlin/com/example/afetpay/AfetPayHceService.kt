package com.example.afetpay

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log

/**
 * AfetPay HCE (Host Card Emulation) servisi.
 *
 * Gönderen telefon bu servis aracılığıyla sanal bir NFC Type 4 Tag gibi
 * davranır. Alıcı telefon nfc_manager ile NFC okuma başlattığında,
 * gönderen telefonu normal bir NDEF tag gibi okur.
 *
 * Protokol: NFC Forum Type 4 Tag APDU sırası
 *   1. SELECT NDEF APPLICATION (AID: D2760000850101)
 *   2. SELECT CC FILE          (file ID: E103)
 *   3. READ BINARY             (CC içeriği)
 *   4. SELECT NDEF FILE        (file ID: E104)
 *   5. READ BINARY             (NDEF uzunluk + veri)
 */
class AfetPayHceService : HostApduService() {

    companion object {
        private const val TAG = "AfetPayHce"

        // Status words
        private val SW_OK            = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val SW_FILE_NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        private val SW_WRONG_LENGTH  = byteArrayOf(0x67.toByte(), 0x00.toByte())
        private val SW_NOT_SUPPORTED = byteArrayOf(0x6D.toByte(), 0x00.toByte())

        // AID: D2760000850101 (NFC Forum NDEF Application)
        private val NDEF_AID = byteArrayOf(
            0xD2.toByte(), 0x76.toByte(), 0x00.toByte(), 0x00.toByte(),
            0x85.toByte(), 0x01.toByte(), 0x01.toByte()
        )

        // Capability Container file (15 byte, Type 4 Tag v2.0)
        // Max NDEF size = 0x01FF = 511 bytes
        private val CC_FILE = byteArrayOf(
            0x00, 0x0F,             // CC uzunluğu = 15
            0x20,                   // Mapping version 2.0
            0x00, 0xFF.toByte(),    // Max R-APDU data size (255)
            0x00, 0xFF.toByte(),    // Max C-APDU data size (255)
            0x04,                   // NDEF File Control TLV T
            0x06,                   // NDEF File Control TLV L
            0xE1.toByte(), 0x04,   // NDEF file ID: E104
            0x01.toByte(), 0xFF.toByte(), // Max NDEF file size: 511
            0x00,                   // Read access: free
            0x80.toByte()           // Write access: none
        )

        /**
         * Flutter tarafından Method Channel ile set edilir.
         * [2-byte uzunluk] + [NDEF record bytes]
         */
        @Volatile
        var ndefFile: ByteArray? = null

        /**
         * URI stringini NDEF Text Record olarak encode edip ndefFile'a set eder.
         * Flutter → native bu metodu çağırır.
         */
        fun setPayloadUri(uri: String) {
            val recordBytes = encodeNdefTextRecord(uri)
            val len = recordBytes.size
            ndefFile = byteArrayOf(
                (len shr 8).toByte(),
                (len and 0xFF).toByte()
            ) + recordBytes
            Log.d(TAG, "NDEF file hazır, toplam ${ndefFile?.size} byte")
        }

        /** NFC Forum NDEF Text Record encode (UTF-8, lang=en) */
        private fun encodeNdefTextRecord(text: String): ByteArray {
            val lang = "en".toByteArray(Charsets.US_ASCII)
            val textBytes = text.toByteArray(Charsets.UTF_8)
            val status = (lang.size and 0x3F).toByte()
            val payload = byteArrayOf(status) + lang + textBytes

            // MB=1 ME=1 CF=0 SR=1 IL=0 TNF=001 → 0xD1
            val header = 0xD1.toByte()
            val typeLen = 0x01.toByte()
            val payloadLen = payload.size.toByte() // SR: 1-byte length
            val type = 'T'.code.toByte()

            return byteArrayOf(header, typeLen, payloadLen, type) + payload
        }

        private fun ByteArray.toHex() = joinToString("") { "%02X".format(it) }
    }

    // Seçili dosya: 0=CC, 1=NDEF, -1=yok
    private var selectedFile = -1
    private var appSelected  = false

    override fun processCommandApdu(apdu: ByteArray?, extras: Bundle?): ByteArray {
        if (apdu == null || apdu.size < 4) return SW_NOT_SUPPORTED
        val ins = apdu[1]
        val p1  = apdu[2]
        Log.d(TAG, "← ${apdu.toHex()}")
        return when {
            ins == 0xA4.toByte() && p1 == 0x04.toByte() -> handleSelectAid(apdu)
            ins == 0xA4.toByte() && p1 == 0x00.toByte() -> handleSelectFile(apdu)
            ins == 0xA4.toByte() && p1 == 0x0C.toByte() -> handleSelectFile(apdu)
            ins == 0xB0.toByte()                         -> handleReadBinary(apdu)
            else -> SW_NOT_SUPPORTED
        }
    }

    private fun handleSelectAid(apdu: ByteArray): ByteArray {
        if (apdu.size < 5) return SW_FILE_NOT_FOUND
        val lc  = apdu[4].toInt() and 0xFF
        if (apdu.size < 5 + lc) return SW_FILE_NOT_FOUND
        val aid = apdu.copyOfRange(5, 5 + lc)
        return if (aid.contentEquals(NDEF_AID)) {
            appSelected  = true
            selectedFile = -1
            Log.d(TAG, "✅ NDEF Application seçildi")
            SW_OK
        } else {
            Log.d(TAG, "❌ Bilinmeyen AID: ${aid.toHex()}")
            SW_FILE_NOT_FOUND
        }
    }

    private fun handleSelectFile(apdu: ByteArray): ByteArray {
        if (!appSelected || apdu.size < 7) return SW_FILE_NOT_FOUND
        val f1 = apdu[5]; val f2 = apdu[6]
        return when {
            f1 == 0xE1.toByte() && f2 == 0x03.toByte() -> { selectedFile = 0; Log.d(TAG, "CC seçildi"); SW_OK }
            f1 == 0xE1.toByte() && f2 == 0x04.toByte() -> { selectedFile = 1; Log.d(TAG, "NDEF seçildi"); SW_OK }
            else -> { Log.d(TAG, "Bilinmeyen dosya"); SW_FILE_NOT_FOUND }
        }
    }

    private fun handleReadBinary(apdu: ByteArray): ByteArray {
        if (!appSelected) return SW_FILE_NOT_FOUND
        if (apdu.size < 5) return SW_WRONG_LENGTH
        val offset = ((apdu[2].toInt() and 0xFF) shl 8) or (apdu[3].toInt() and 0xFF)
        val reqLen = if (apdu[4].toInt() == 0) 255 else (apdu[4].toInt() and 0xFF)

        val file = when (selectedFile) {
            0 -> CC_FILE
            1 -> ndefFile ?: return SW_FILE_NOT_FOUND
            else -> return SW_FILE_NOT_FOUND
        }

        if (offset >= file.size) return SW_WRONG_LENGTH
        val end   = minOf(offset + reqLen, file.size)
        val chunk = file.copyOfRange(offset, end)
        Log.d(TAG, "→ READ offset=$offset len=$reqLen → ${chunk.size} byte gönderildi")
        return chunk + SW_OK
    }

    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "HCE deaktive, sebep=$reason")
    }
}
