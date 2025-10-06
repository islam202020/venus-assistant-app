plugins {
    id("com.android.application") version "8.3.0" apply false
    id("com.android.library") version "8.3.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.23" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
