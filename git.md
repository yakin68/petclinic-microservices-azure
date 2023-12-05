git add .
git commit -m 'pipeline test'
git push origin dev

git add .
git commit -m 'added terraform files for dev server'
git push --set-upstream origin feature/msp-5   ## git push -u origin feature/msp-5  // buda yazılabilir
git checkout dev
git merge feature/msp-5
git push origin dev
```

      helm registry login helmchartrepo.azurecr.io \
        --username helmchartrepo \
        --password fo+P1uVVyyxyJL7XyZDnsgt0WuDQtZV9S16jquLNm5+ACRCbfyLm

      kubectl create ns petclinicdev
      kubectl delete secret regcred -n petclinicdev || true
      kubectl create secret generic regcred 
       \
        --from-file=.dockerconfigjson=/home/azureuser/.docker/config.json \
        --type=kubernetes.io/dockerconfigjson

      helm install petclinicapprelease  oci://helmchartrepo.azurecr.io/stable-petclinic --version ${BUILD_NUMBER} --namespace petclinicdev
      helm get manifest petclinicapprelease


helm registry login yakinpetclinicdockerimage.azurecr.io \
--username yakinpetclinicdockerimage \
--password 5Ex1gVA1viBHtVWZqA4EoZytiB0MfyJeh0EUkSHa/B+ACRBpJld7

helm install petclinicapprelease  oci://helmchartrepo.azurecr.io/stable-petclinic/petclinic_chart --version 42 --namespace petclinicdev

      echo "5Ex1gVA1viBHtVWZqA4EoZytiB0MfyJeh0EUkSHa/B+ACRBpJld7" | docker login yakinpetclinicdockerimage.azurecr.io \
      --username yakinpetclinicdockerimage \
      --password-stdin

