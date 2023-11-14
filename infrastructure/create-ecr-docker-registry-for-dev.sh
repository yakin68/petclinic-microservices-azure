ACR_NAME="claruswayrepopetclinicappdev"  # Azure Container Registry adını buraya ekleyin
ACR_RESOURCE_GROUP="Azure-jenkins-server-project" # Kaynak grubu adınıza göre güncelleyin
ACR_REGION="northeurope"  # Azure bölgesini buraya ekleyin

# enter to azure cli
az login 
# Azure Container Registry kontrol et
az acr show --name $ACR_NAME --resource-group $ACR_RESOURCE_GROUP || \
az acr create --name $ACR_NAME --resource-group $ACR_RESOURCE_GROUP --sku Basic --location $ACR_REGION