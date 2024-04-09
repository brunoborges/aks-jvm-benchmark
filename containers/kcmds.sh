#!/bin.sh
kwait() {
  kubectl rollout status deployment/sampleapp
}

ksetenv() {
  kubectl set env deployment/sampleapp JAVA_OPTS=${1}
  kwait
}

kreplicas() {
  kubectl scale --replicas=${1} -f app-deployment.yml
  kwait
}

kscalecpu() {
  local requests="${1}"
  local limits="${${2}:-${1}}"
  local jsonobj="[{\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/resources/requests/cpu\", \"value\":\"${requests}\"}, {\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/resources/limits/cpu\", \"value\":\"${limits}\"}]"
  kubectl patch deployment sampleapp --type='json' -p=${jsonobj}
  kwait
}

kmemory() {
  local requests="${1}"
  local limits="${${2}:-${1}}"
  local jsonobj="[{\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/resources/requests/memory\", \"value\":\"${requests}\"}, {\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/resources/limits/memory\", \"value\":\"${limits}\"}]"
  kubectl patch deployment sampleapp --type='json' -p=${jsonobj}
  kwait
}

kdeploy() {
  kubectl delete -f deployment.yml
  kubectl apply -f deployment.yml
  kwait
}
