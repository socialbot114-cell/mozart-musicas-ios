package br.com.musicaspara.estudar

import androidx.lifecycle.SavedStateHandle
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class FocusSessionViewModelTest {
    @Test
    fun selectingDurationResetsRemainingTime() {
        val session = FocusSessionViewModel(SavedStateHandle())

        session.setDuration(50)

        assertEquals(50, session.selectedDuration)
        assertEquals(50 * 60, session.remainingSeconds)
        assertFalse(session.isRunning)
    }

    @Test
    fun restoredStateKeepsSelectedDurationAndRemainingTime() {
        val session = FocusSessionViewModel(SavedStateHandle(mapOf("duration" to 90, "remaining" to 1234)))

        assertEquals(90, session.selectedDuration)
        assertEquals(1234, session.remainingSeconds)
    }
}
