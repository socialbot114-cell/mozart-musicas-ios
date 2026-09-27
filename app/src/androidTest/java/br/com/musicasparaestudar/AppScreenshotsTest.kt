package br.com.musicaspara.estudar

import android.content.Intent
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class AppScreenshotsTest {
    @Test
    fun capturePrimaryScreens() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val device = UiDevice.getInstance(instrumentation)
        val outputDirectory = File(
            context.getExternalFilesDir(null) ?: error("External app storage is unavailable"),
            "github-actions-screenshots"
        )
        if (outputDirectory.exists()) {
            check(outputDirectory.deleteRecursively()) { "Could not clear screenshot directory" }
        }
        check(outputDirectory.mkdirs() || outputDirectory.isDirectory) { "Could not create screenshot directory" }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: error("Could not find the app launch activity")
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(launchIntent)

        waitForText(device, "Bom estudo")
        capture(device, outputDirectory, "01-inicio.png")

        clickText(device, "Explorar")
        waitForText(device, "Estude do seu jeito")
        capture(device, outputDirectory, "02-explorar.png")

        clickText(device, "Foco")
        waitForText(device, "Sessão de foco")
        capture(device, outputDirectory, "03-foco.png")

        clickText(device, "Biblioteca")
        waitForText(device, "Biblioteca de compositores")
        capture(device, outputDirectory, "04-biblioteca.png")
    }

    private fun clickText(device: UiDevice, text: String) {
        val element = device.wait(Until.findObject(By.text(text)), UI_TIMEOUT_MS)
            ?: error("Could not find '$text' to navigate")
        element.click()
        device.waitForIdle()
    }

    private fun waitForText(device: UiDevice, text: String) {
        check(device.wait(Until.hasObject(By.text(text)), UI_TIMEOUT_MS)) {
            "Timed out waiting for '$text'"
        }
        device.waitForIdle()
    }

    private fun capture(device: UiDevice, outputDirectory: File, filename: String) {
        assertTrue("Could not save $filename", device.takeScreenshot(File(outputDirectory, filename)))
    }

    private companion object {
        const val UI_TIMEOUT_MS = 15_000L
    }
}
