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
