allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // Older plugins pin compileSdk 34; align them with the app's Flutter SDK.
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileSdkVersion(
                requireNotNull(
                    project(":app").extensions
                        .getByType<com.android.build.gradle.BaseExtension>().compileSdkVersion
                )
            )
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
