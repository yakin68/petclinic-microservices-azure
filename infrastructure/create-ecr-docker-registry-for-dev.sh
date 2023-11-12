ACR_NAME="claruswayrepopetclinicappdev"  # Azure Container Registry adını buraya ekleyin
ACR_RESOURCE_GROUP="Azure-jenkins-server-project" # Kaynak grubu adınıza göre güncelleyin
ACR_REGION="northeurope"  # Azure bölgesini buraya ekleyin

# Azure Container Registry kontrol et
az acr show --name $ACR_NAME --resource-group $ACR_RESOURCE_GROUP || \
az acr create --name $ACR_NAME --resource-group $ACR_RESOURCE_GROUP --sku Basic --location $ACR_REGION
az acr update --name $ACR_NAME --resource-group $ACR_RESOURCE_GROUP --set vulnerabilityScanStatus=Enabled
# Docker görüntüsünü etiketleme

docker tag $ACR_NAME $ACR_NAME.azurecr.io/petclinic-app-dev

# Docker görüntüsünü Azure Container Registry'e gönderme
docker push $ACR_NAME.azurecr.io/petclinic-app-dev
