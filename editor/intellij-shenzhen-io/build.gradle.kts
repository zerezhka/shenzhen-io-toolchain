plugins {
    id("java")
    id("org.jetbrains.kotlin.jvm") version "2.3.0"
    id("org.jetbrains.intellij.platform") version "2.6.0"
}

group = "io.shenzhen"
version = "0.1.0"

repositories {
    mavenCentral()
    intellijPlatform {
        defaultRepositories()
    }
}

dependencies {
    intellijPlatform {
        // Build against the locally installed IDE (build 261 / 2026.1), since that
        // exact version is newer than any published downloadable artifact.
        local("/usr/share/idea")

        // LSP4IJ provides the LSP client runtime; the plugin depends on it.
        plugin("com.redhat.devtools.lsp4ij:0.14.2")
    }
}

intellijPlatform {
    pluginConfiguration {
        ideaVersion {
            sinceBuild = "243"
            untilBuild = provider { null }
        }
    }
}

kotlin {
    jvmToolchain(21)
}

// Running the IDE headless to index searchable options is slow and unnecessary here.
tasks.buildSearchableOptions {
    enabled = false
}
