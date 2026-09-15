allprojects {
    repositories {
        google()
        mavenCentral()
        // Le SDK des Home APIs de Google : il n'est sur aucun dépôt public,
        // et son archive est déjà un dépôt Maven. Ajouté seulement quand la
        // construction en donne le chemin — voir `app/build.gradle.kts`.
        (project.findProperty("googleHomeRepo") as String?)?.takeIf { it.isNotBlank() }?.let {
            maven { url = uri(it) }
        }
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
