#!/bin.sh
kwait() {
  kubectl rollout status deployment/springboot
}

ksetenv() {
  kubectl set env deployment/springboot JAVA_OPTS=${1}
  kwait
}

kreplicas() {
  kubectl scale --replicas=${1} -f deployment.yml
  kwait
}

kscalecpu() {
  local requests="${1}"
  local limits="${${2}:-${1}}"
  local jsonpath='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value":"'${requests}'"}, {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value":"'${limits}'"}]'
  echo $jsonpath
  kubectl patch deployment springboot --type='json' -p=jsonpath
  kwait
}
