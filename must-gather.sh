#!/bin/bash

# todo specific user as a param?
# todo local story
# todo windows: .bat or powershell?
# todo test it, probably loads of bash errors!

output="Microclimate must gather information, gathered $(date)."

function setDefaults {
  release="microclimate"
  namespace="default"
  output_location="${release}-${namespace}-logs.txt"
  tiller_namespace="kube-system"
  workspace="microclimate-workspace"
  output=""
}

function printDisclaimer {
  echo -e "\nMicroclimate Must Gather: 0.0.1\n\n"

  echo -e "This script will gather the following information and store it in a file on your system at the optionally specified output location, which defaults to a generated name in the current directory where you've copied this script to."
  echo -e "All Microclimate related install information: including pods, Kubernetes' view of secrets (which does *not* include secret data), basic persistent volume information (which does *not* include data), and basic deployed application information (which does *not* include its data or source code)."
  echo -e "In sharing the results (which you must do manually!) you agree that you are happy to share this information with the distributor (e.g. IBM)."
  echo -e "Your version of bash, the result of uname -a, and your docker version will also be gathered."
  echo -e "It is your responsiblity to ensure no sensitive data is provided before sharing it!"

  echo -e "\n\n"
}

function addHeader {
  addToOutput "\n------${1} --------------------------------------\n"
}

function checkTools {
  echo -e "Checking for kubectl and helm pointing to a cluster"
  kubectl cluster-info > /dev/null 2>&1
  rc=$?
  if [[ $rc -ne 0 ]] ; then
    echo "kubectl cluster-info failed, check you have kubectl installed and pointing to your cluster where Microclimate is installed"
    exit;
  fi

  helm version ${HELM_FLAG} > /dev/null 2>&1
  rc=$?
  if [[ $rc -ne 0 ]] ; then
    echo "helm version failed, check you have helm installed and is configured to access your cluster where Microclimate is installed"
  #  exit;
  fi
}

function printArgs {
  echo -e "Release name: ${release}"
  echo -e "Namespace: ${namespace}"
  echo -e "Output location: $output_location"
  echo -e "Tiller namespace: ${tiller_namespace}"
}

function addToOutput {
  output="${output}\n${1}"
}

function getAllChartInfo {
  addHeader "Chart info"
  output="Chart info\n\n"
  addToOutput "$(helm get ${release} --tiller-namespace ${tiller_namespace} ${HELM_FLAG})"
}

function getKubePermissions {
  addHeader "Cluster roles and bindings"
  addToOutput "$(kubectl get clusterrole)"
  addToOutput "$(kubectl get clusterrolebinding)"
}

function getSecrets {
  addHeader "Secrets"
  addToOutput "$(kubectl describe secrets)"
}

function getClusterConfigs {
  addHeader "Cluster config secrets"
  addToOutput "$(kubectl describe secrets -l microclimate-cluster-config)"
}

function getServiceAccounts {
  addHeader "Service accounts"
  addToOutput "$(kubectl describe serviceaccounts --all-namespaces)"
}

function getDeployments {
  addHeader "Deployments"
  #addToOutput "$(kubectl describe deployments ${label_flag})"
  addToOutput "$(kubectl describe deployments)"
}

# Has to iterate over them all using labels
function getPodInfo {
  addHeader "Pods"
  addToOutput "$(kubectl describe pods)"
}

function getIngressInfo {
  addHeader "Ingress"
  addToOutput "$(kubectl describe ingress)"
}

function getServiceInfo {
  addHeader "Services"
  addToOutput "$(kubectl describe service)"
}

function getVolumeInfo {
  addHeader "Volumes"
  addToOutput "$(kubectl describe persistentvolume)"
  addToOutput "$(kubectl describe persistentvolumeclaim)"
}

function getClusterInfo {
  addHeader "Cluster information"
  addToOutput "$(kubectl cluster-info)"
}

function getMicroclimateLogs {
  pods="$(kubectl get pods -o jsonpath='{.items[*].metadata.name}' | grep ${release})"
  for pod in ${pods}
  do
    containers="$(kubectl get pods ${pod} -o jsonpath='{.spec.containers[*].name}')"
    for container in ${containers}
    do
      addHeader "Log information for ${pod} ${container}"
      addToOutput "$(kubectl logs ${pod} ${container})"
    done
  done
}

function getNodeInfo {
  addHeader "Node information"
  addToOutput "$(kubectl get nodes)"
  addToOutput "$(kubectl describe nodes)"
}

function outputToFile {
  echo -e "Output location is $output_location"
  echo -e "${output}" > $(echo -e ${output_location})
}

function getHelmList {
  addHeader "Helm listing"
  addToOutput "$(helm list --all ${HELM_FLAG})"
}

function getKubeReleases {
  addHeader "Kube releases"
  addToOutput "$(kubectl get release --all-namespaces -o json)"
}

function getKubeProjects {
  addHeader "Kube projects"
  addToOutput "$(kubectl get project --all-namespaces -o json)"
}

function addTillerLog {
  tillerpod="$(kubectl get pods --namespace ${tiller_namespace} -o jsonpath='{.items[*].metadata.name}' -l name=tiller)"
  addHeader "Tiller log"
  addToOutput "$(kubectl logs --namespace ${tiller_namespace} ${tillerpod})"
}

# Portal specific
function listFilesAtMCWorkspace {
  # this will get the name of the portal pod
  portalpod="$(kubectl get pods -o jsonpath='{.items[*].metadata.name}' -l app=${release}-ibm-microclimate) "
  # Get a list of users
  addHeader "List of users"
  users="$(kubectl exec ${portalpod} -- ls ${workspace})"

  addToOutput "$(kubectl exec ${portalpod} -- ls ${workspace})"

  for user in ${users}
  do
    addHeader "Project list for user ${user}"
    projects="$(kubectl exec ${portalpod} -- ls ${workspace}/${user})"
    addToOutput "${projects}"

    for project in ${projects}
    do
      # Add the contents of the project inf file
      addHeader "Project inf file for ${project}"
      addToOutput "$(kubectl exec ${portalpod} cat ${workspace}/${user}/.projects/${project}.inf)"
    done
  done
}

# Poke some endpoints
function pokePortal {
  echo -e "poking of portal endpoints not yet implemented"
}

function pokeDevops {
  echo -e "poking of devops endpoints not yet implemented"
}

function pokeFilewatcher {
  echo -e "poking of filewatcher endpoints not yet implemented"
}

function checkJobs {
  addHeader "Jobs"
  addToOutput "$(kubectl get jobs --all-namespaces ${label_flag})"
}

function getHelmVersion {
  addHeader "Helm version and location"
  addToOutput "Found Helm at $(which helm)"
  addToOutput "$(helm version ${HELM_FLAG})"
}

function getKubeVersion {
  addHeader "Kubectl version and location"
  addToOutput "Found kubectl at $(which kubectl)"
  addToOutput "$(kubectl version)"
}

function getAPIResponses {
  echo -e ""
}

function getHostInfo {
  addHeader "Basic host information"
  addToOutput "$(docker version)"
  addToOutput "$(uname -a)"
  addToOutput "$(bash --version)"
}

printDisclaimer
setDefaults

# Parse the args here, not in a function
while getopts ":r:n:o:t:s" opt; do
  case $opt in
    r)
      release=${OPTARG}
      ;;
    n)
      namespace=${OPTARG}
      ;;
    o)
      output_location=${OPTARG}
      ;;
    s)
      HELM_FLAG=--tls
    ;;
    t)
      tiller_namespace=${OPTARG}
      ;;
    \?)
      echo -e "Invalid argument provided: -${OPTARG}" >&2
      ;;
  esac
done

label_flag="-l app=${release}-ibm-microclimate"
# Only set the outout location if not supplied
if [ -z $output_location ]
then
  echo "ouutput location not provided"
  output_location="${release}-${namespace}-$(date +%Y%m%d%H%M%S)-logs.txt"
fi
# Set the context namespace for all kuubectl commands
kubectl config set-context $(kubectl config current-context) --namespace=${namespace}

checkTools
printArgs

getClusterInfo
getAllChartInfo
getHelmVersion
getKubeVersion

getDeployments
getPodInfo

getServiceInfo
getIngressInfo

getVolumeInfo

getKubePermissions

getServiceAccounts

# Artifacts
getHelmList
getKubeReleases
getKubeProjects

addTillerLog

getNodeInfo

getHostInfo

getMicroclimateLogs

listFilesAtMCWorkspace

outputToFile output_location
