projectname=$1
projectuniqeid=$2

resourcegroupname="$projectname-rg"
azcontainerregistryname="azcr$projectname"
appserviceplanname="$projectname-asp"
appname="$projectname-$projectuniqeid"
storageaccountname="storage$projectname$projectuniqeid"
mountpath="/home/site/wwwroot/notejam/db/"

az group create --name $resourcegroupname --location "West Europe"

az acr create --name $azcontainerregistryname --resource-group $resourcegroupname --sku Basic --admin-enabled true

#azccred=$(az acr credential show --name $azcontainerregistryname --query passwords[0].value -o json)

az appservice plan create --name $appserviceplanname --resource-group $resourcegroupname --sku S1 --is-linux
az webapp create --resource-group $resourcegroupname --plan $appserviceplanname  --name $appname --deployment-container-image-name "$azcontainerregistryname.azurecr.io/notejam-flask:105"

az webapp config container set --name $appname --resource-group $resourcegroupname --docker-custom-image-name "DOCKER|appsvcsample/static-site" --docker-registry-server-url "https://index.docker.io" --docker-registry-server-user $azcontainerregistryname #--docker-registry-server-password 'u9Ru8el4PCMucP/8H7ccrZZJcCnh3pJ4'

az webapp config appsettings set --resource-group $resourcegroupname --name $appname --settings WEBSITES_PORT=80 #WEBSITES_ENABLE_APP_SERVICE_STORAGE=false
az webapp config appsettings set --resource-group $resourcegroupname --name $appname --settings MODULE_NAME=runserver

#configure persist storage
az storage account create --name $storageaccountname --resource-group  $resourcegroupname
az storage container create --name $appname --account-name $storageaccountname
storagekeys=$(az storage account keys list --account-name $storageaccountname --query [0].value)

az webapp config storage-account add --resource-group $resourcegroupname --name $appname --custom-id "dbstorage" --storage-type AzureBlob --share-name $appname --account-name $storageaccountname --access-key $storagekeys --mount-path $mountpath
az webapp config storage-account list --resource-group $resourcegroupname --name $appname

#configure log
az webapp log config --name $appname --resource-group $resourcegroupname --docker-container-logging filesystem

#configure autoscale
az monitor autoscale create --resource-group $resourcegroupname --name "${appname}-AutoscaleSettings" --min-count 1 --max-count 4 --count 1 --resource-type Microsoft.Web/serverFarms --resource $appserviceplanname

az monitor autoscale rule create --resource-group $resourcegroupname --autoscale-name "${appname}-AutoscaleSettings" --scale out 1 --condition "CpuPercentage > 75 avg 5m"

az monitor autoscale rule create --resource-group $resourcegroupname --autoscale-name "${appname}-AutoscaleSettings" --scale in 1 --condition "CpuPercentage < 25 avg 5m"

#Configure Front Door
az extension add --name front-door
az network front-door create -g notejam-rg -n "$appname-fd" --backend-address "$appname.azurewebsites.net"