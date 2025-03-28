# Archive Notice

This repository is now archived and no longer maintained. It is preserved for historical reference only. For current Cloud.gov projects and documentation, please visit [cloud.gov](https://cloud.gov) or our repositories at [Cloud.gov on github](https://github.com/cloud-gov).



# CF Autoscale Action

A Github action for monitoring memory utilization of apps running in a Cloud Foundry instance and scaling up or down as needed.

Note - this action is currently in Beta. It has only been lightly tested and is still under development. But it does outline one approach to automating app scaling using the [Cloud Foundry API](https://v3-apidocs.cloudfoundry.org/version/3.99.0/index.html#get-stats-for-a-process) and [cf scale](https://cli.cloudfoundry.org/en-US/v6/scale.html).

## How it works

The `entrypoint.sh` script uses the [Cloud Foundry API](https://v3-apidocs.cloudfoundry.org/version/3.99.0/index.html) to pull the memory quota and utilization for you app, and [averages utilization across all existing instances](https://github.com/cloud-gov/action-auto-scale/blob/master/entrypoint.sh#L13-L21). If the average memory utilization fall outside of the maximum and minimum thresholds you define when you create your action, the script will [scale your app horizontally](https://docs.cloudfoundry.org/devguide/deploy-apps/cf-scale.html#horizontal) by adding or removing instances based on the increment you define when you create your action.

To use this action, you should use the [schedule trigger for workflows](https://help.github.com/en/actions/reference/events-that-trigger-workflows#scheduled-events-schedule) at an interval that best meets your needs.

## Usage

Follow the instructions for setting up a [cloud.gov service account](https://cloud.gov/docs/services/cloud-gov-service-account/). Store you username (CG_USERNAME) and password (CG_PASSWORD) as [encrypted secrets](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets). 

## Sample workflow

The following is an example of a workflow that uses this action. This example shows how to run the autoscale action every 15 minutes

```yaml
# This is a basic workflow to demonstrate how to use this action.

name: Auto Scale

on:
  schedule:
    - cron:  '*/15 * * * *' 
      
jobs:
  scale:
   runs-on: ubuntu-latest
   
   steps:
     - uses: cloud-gov/action-auto-scale@main
       with:
        cf_api: https://api.fr.cloud.gov
        cf_username: ${{ secrets.CG_USERNAME }}
        cf_password: ${{ secrets.CG_PASSWORD }}
        cf_org: your-org-name
        cf_space: your-space-name
        cf_app_name: your-app-name
        cf_app_max_threshold: 65
        cf_app_min_threshold: 15
        cf_instance_increment: 1

```

The `cf_app_max_threshold` and `cf_app_min_threshold` settings specify the maximum and minimum memory utilization thresholds that trigger scaling. The `cf_instance_increment` setting controls the number of instances to add or remove as scaling occurs.
