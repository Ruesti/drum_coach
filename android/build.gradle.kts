allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix for older Flutter plugins that don't declare a namespace (e.g. isar_flutter_libs 3.x).
// Skip :app — it already has a namespace and is evaluated early via evaluationDependsOn.
subprojects {
    if (project.path != ":app") {
        afterEvaluate {
            if (extensions.findByName("android") != null) {
                val android = extensions.getByType<com.android.build.gradle.BaseExtension>()
                if (android.namespace == null) {
                    android.namespace = group.toString()
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
