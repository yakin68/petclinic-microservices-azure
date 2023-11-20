ACR_NAME="yakindockerimage"
USER_NAME="yakindockerimage"
PASSWORD="NyRCXCW430XMZXXNx1S220LxMPye1A2fT+/M4YTgyS+ACRDwei4F"

az acr login --name $ACR_NAME | docker login $ACR_NAME.azurecr.io -u $USER_NAME  -p $PASSWORD

docker push "${IMAGE_TAG_ADMIN_SERVER}"
docker push "${IMAGE_TAG_API_GATEWAY}"
docker push "${IMAGE_TAG_CONFIG_SERVER}"
docker push "${IMAGE_TAG_CUSTOMERS_SERVICE}"
docker push "${IMAGE_TAG_DISCOVERY_SERVER}"
docker push "${IMAGE_TAG_HYSTRIX_DASHBOARD}"
docker push "${IMAGE_TAG_VETS_SERVICE}"
docker push "${IMAGE_TAG_VISITS_SERVICE}"
docker push "${IMAGE_TAG_GRAFANA_SERVICE}"
docker push "${IMAGE_TAG_PROMETHEUS_SERVICE}"

