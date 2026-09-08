allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Some plugins (e.g. iris_method_channel, pulled in transitively by
// agora_rtc_engine) read this legacy `ext` property to decide their own
// compileSdkVersion instead of using flutter.compileSdkVersion. Without it
// they default to an old SDK level, which fails AAR metadata checks against
// newer androidx dependencies.
rootProject.extra["compileSdkVersion"] = 36

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
