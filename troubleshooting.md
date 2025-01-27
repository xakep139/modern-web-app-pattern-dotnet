# Troubleshooting
This document helps with troubleshooting MWA deployment challenges.

## Error: no project exists; to create a new project, run 'azd init'
This error is most often reported when users try to run `azd` commands before running the `cd` command to switch to the directory where the repo was cloned.

### Workaround

Verify that you are in the directory where the `azure.yaml` file is located. You may need to `cd` into the directory to proceed.

## BadRequest: Azure subscription is not registered with CDN Provider.
This error message surfaces from the `azd provision` command when trying to follow the guide to provision an Azure Front Door.

Most [Azure resource providers](https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider) are registered automatically by the Microsoft Azure portal or the command-line interface, but not all. If you haven't used a particular resource provider before, you might need to register that provider.

**Full error message**
```
ERROR: deployment failed: error deploying infrastructure: failed deploying: deploying to subscription:

Deployment Error Details:
BadRequest: Azure subscription is not registered with CDN Provider.
```

### Workaround

1. Register the provider
    ```ps1
    az provider register --namespace Microsoft.Cdn
    ```

1. Wait for the registration process to complete (waited about 3-min)

1. Run the following to confirm the provider is registered
    ```ps1
    az provider list --query "[? namespace=='Microsoft.Cdn'].id"
    ```

    You should see a notice that the operation succeeded:
    ```
    [
    "/subscriptions/{subscriptionId}/providers/Microsoft.Cdn"
    ]
    ```

## Warning: Remote host identification has changed
This warning message is displayed when the SSH key fingerprint for the remote host has changed since the last time you connected. This can happen if you have re-provisioned the environment which will recreate the VMs and thus their fingerprints.

**Full warning message**
```sh
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
```

### Workaround

1. Remove the previous fingerprint which is stored in a file called `known_hosts` in your user's `.ssh` directory. Run the following command to remove the old fingerprint:
    ```sh
    ssh-keygen -R [127.0.0.1]:50022
    ```

## ERROR: initializing service 'rendering-service', failed to initialize secrets at project...
This error message is displayed when the `dotnet` tool is not found in the $PATH. The `dotnet` tool is required to build and deploy the application's three projects.

**Full error message**
```sh
ERROR: initializing service 'rendering-service', failed to initialize secrets at project '/home/azureadmin/web-app-pattern/src/Relecloud.TicketRenderer/Relecloud.TicketRenderer.csproj': exec: "dotnet": executable file not found in $PATH
```

### Workaround

1. Install the `dotnet` tool:
    ```sh
    sudo apt-get install -y dotnet-sdk-8.0
    ```
    > Full .NET Core SDK installation instructions can be found [here](https://learn.microsoft.com/dotnet/core/install/linux-ubuntu-2204).

## The deployment <azd-env-name> already exists in location
This error most often happens when trying a new region with the same for a deployment with the same name used for the AZD environment name (e.g. by default it would be `dotnetwebapp`).

When the `azd provision` command runs it creates a deployment resource in your subscription. You must delete this deployment before you can change the Azure region.

### Workaround

> The following steps assume you are logged in with `az` cli.

1. Find the name of the Deployment you want to delete

    ```sh
    az deployment sub list --query "[].name" -o tsv
    ```

1. Delete the deployment by name

    ```sh
    az deployment sub delete -n <deployment-name>
    ```

1. You should now be able to run the `azd provision` command and resume your deployment.

## ERROR: reauthentication required, run `azd auth login --scope https://management.azure.com//.default` to log in
This error can happen when you are using an account that has access to multiple subscriptions. The `azd auth` command is not able to retrieve a list of the subscriptions that you can access when that tenant is configured to require a Multi-Factor Auth experience that was not completed.

**Alternate error message text**

Depending on your workflow you may get a different error message for the same issue:

Option 1:
```sh
ERROR: resolving bicep parameters file: fetching current principal id: getting tenant id for subscription...
```
Option 2:
```sh
ERROR: getting target resource: getting service resource: resolving user access to subscription 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' : reauthentication required, run `azd auth login --scope https://management.azure.com//.default` to log in
```

### Workaround
You should complete the MFA experience for your default tenant, and the tenant that you wish to access by running both authentication commands:

1. Authenticate to your default tenant
    ```sh
    azd auth login --use-device-code
    ```

1. Authenticate to the tenant that owns the subscription you want to use
    ```sh
    azd auth login --use-device-code --tenant <tenant-id>
    ```