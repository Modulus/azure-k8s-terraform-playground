# Wat dis?
Terragrunt playground

## Linux 
Install terraform via your package manager
Install terragrund via brew (yes it works on linux, and this seems to be the best route for terragrunt in linux)

##  To run
cd env/test
terragrunt plan
terragrunt apply


## K8s
az aks get-credentials --admin --name MyManagedCluster --resource-group MyResourceGroup
kubectl cluster-info +++


## Managed Nginx ingress info
https://learn.microsoft.com/en-us/azure/aks/app-routing?tabs=default%2Cdeploy-app-default

## Application gateway info
https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-new

*raw config: https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml*


# Get application gateway id from AKS addon profile
appGatewayId=$(az aks show -n test-cluster -g test-playground -o tsv --query "addonProfiles.ingressApplicationGateway.config.effectiveApplicationGatewayId")

# Get Application Gateway subnet id
appGatewaySubnetId=$(az network application-gateway show --ids $appGatewayId -o tsv --query "gatewayIPConfigurations[0].subnet.id")

# Get AGIC addon identity
agicAddonIdentity=$(az aks show -n test-cluster -g test-playground -o tsv --query "addonProfiles.ingressApplicationGateway.identity.clientId")

# Assign network contributor role to AGIC addon identity to subnet that contains the Application Gateway
az role assignment create --assignee $agicAddonIdentity --scope $appGatewaySubnetId --role "Network Contributor"