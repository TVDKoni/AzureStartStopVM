# AzureStartStopVM
Allows you to start and stop VMs in a Runbook based on tags specified on the VMs

## Installation
* Create an automation account
* Create an automation connection or automation credentials
* Create a runbook with the contents of this script
** Configure in the runbook the connection name or
** Comment the connection part and uncomment the credential part and configure the credential name
* Configure in the runbook the time zone in which you want to specify the times
* Define a schedule for the runbook

##Usage
* To start a VM add the following tag to the VM: startTime = 06:00
* To stop a VM add the following tag to the VM: stopTime = 20:00
