allprojects {
    repositories {
        google()
        mavenCentral()
        // Le SDK des Home APIs de Google, installé à la main : il n'est sur
        // aucun dépôt public. Ajouté seulement quand la construction le
        // demande — voir `app/build.gradle.kts`.
        if ((project.findProperty("googleHome") as String?).toBoolean()) mavenLocal()
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
