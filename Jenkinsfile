#!groovy
@Library('github.com/cloudogu/ces-build-lib@4.2.0')
import com.cloudogu.ces.cesbuildlib.*

git = new Git(this, "cesmarvin")
git.committerName = 'cesmarvin'
git.committerEmail = 'cesmarvin@cloudogu.com'
gitflow = new GitFlow(this, git)
github = new GitHub(this, git)
changelog = new Changelog(this)

repositoryName = "k8s-alloy"
productionReleaseBranch = "main"

registryNamespace = "k8s"
registryUrl = "registry.cloudogu.com"

goVersion = "1.24"
helmTargetDir = "target/k8s"
helmChartDir = "${helmTargetDir}/helm"

node('docker') {
    timestamps {
        catchError {
            timeout(activity: false, time: 60, unit: 'MINUTES') {
                stage('Checkout') {
                    checkout scm
                    make 'clean'
                }

                new Docker(this)
                        .image("golang:${goVersion}")
                        .mountJenkinsUser()
                        .inside("--volume ${WORKSPACE}:/${repositoryName} -w /${repositoryName}")
                                {
                                    stage('Generate k8s Resources') {
                                        make 'helm-update-dependencies'
                                        make 'helm-generate'
                                        archiveArtifacts "${helmTargetDir}/**/*"
                                    }

                                    stage("Lint helm") {
                                        make 'helm-lint'
                                    }
                                }

                K3d k3d = new K3d(this, "${WORKSPACE}", "${WORKSPACE}/k3d", env.PATH)

                try {
                    stage('Set up k3d cluster') {
                        k3d.startK3d()
                    }

                    stage('Deploy minio & loki') {
                        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'harborhelmchartpush', usernameVariable: 'HARBOR_USERNAME', passwordVariable: 'HARBOR_PASSWORD']]) {
                            k3d.helm("registry login ${registryUrl} --username '${HARBOR_USERNAME}' --password '${HARBOR_PASSWORD}'")
                            k3d.helm("install k8s-minio oci://${registryUrl}/${registryNamespace}/k8s-minio --version 2025.6.13-1")
                            k3d.helm("install k8s-loki oci://${registryUrl}/${registryNamespace}/k8s-loki --version 3.3.2-2")
                        }
                    }

                    stage('Deploy k8s-alloy') {
                        k3d.helm("install ${repositoryName} ${helmChartDir}")
                    }

                    stage('Test k8s-alloy') {
                        // Sleep because it takes time for the controller to create the resource. Without it would end up
                        // in error "no matching resource found when run the wait command"
                        sleep(20)
                        k3d.kubectl("wait --for=condition=ready pod -l app.kubernetes.io/instance=k8s-alloy --timeout=300s")
                    }
                } catch(Exception e) {
                    k3d.collectAndArchiveLogs()
                    throw e as java.lang.Throwable
                } finally {
                    stage('Remove k3d cluster') {
                        k3d.deleteK3d()
                    }
                }
            }
        }

        stageAutomaticRelease()
    }
}

void stageAutomaticRelease() {
    if (gitflow.isReleaseBranch()) {
        Makefile makefile = new Makefile(this)
        String releaseVersion = makefile.getVersion()
        String changelogVersion = git.getSimpleBranchName()

        stage('Push Helm chart to Harbor') {
            new Docker(this)
                    .image("golang:${goVersion}")
                    .mountJenkinsUser()
                    .inside("--volume ${WORKSPACE}:/${repositoryName} -w /${repositoryName}")
                            {
                                make 'helm-package'
                                archiveArtifacts "${helmTargetDir}/**/*"

                                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'harborhelmchartpush', usernameVariable: 'HARBOR_USERNAME', passwordVariable: 'HARBOR_PASSWORD']]) {
                                    sh ".bin/helm registry login ${registryUrl} --username '${HARBOR_USERNAME}' --password '${HARBOR_PASSWORD}'"
                                    sh ".bin/helm push ${helmChartDir}/${repositoryName}-${releaseVersion}.tgz oci://${registryUrl}/${registryNamespace}"
                                }
                            }
        }

        stage('Finish Release') {
            gitflow.finishRelease(changelogVersion, productionReleaseBranch)
        }

        stage('Add Github-Release') {
            releaseId = github.createReleaseWithChangelog(changelogVersion, changelog, productionReleaseBranch)
        }
    }
}

void make(String makeArgs) {
    sh "make ${makeArgs}"
}
