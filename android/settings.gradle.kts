pluginManagement {
    includeBuild("../flutter")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        id("com.android.application") version "8.3.0" apply false
        id("org.jetbrains.kotlin.android") version "1.9.23" apply false
        id("com.google.gms.google-services") version "4.4.2" apply false
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "venus_assistant_app"
include(":app")
