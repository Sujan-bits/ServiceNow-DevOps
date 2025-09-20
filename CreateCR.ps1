# This script creates a new change request in ServiceNow using a REST API call.

param(
    [string]$SNowInstance,
    [string]$destUName,
    [string]$destPwd,
    [string]$sourceDir
)

# Construct the URL for the REST API endpoint.
# The SNowInstance variable should be just the instance name (e.g., 'dev251858').
$serviceNowUrl = "https://$SNowInstance.service-now.com/api/now/table/change_request"

# Prepare the JSON payload for the new change request.
# You MUST customize these fields to match your organization's change request form.
$body = @{
    short_description = "Automated change request for pipeline deployment"
    description = "This change request was automatically created by an Azure DevOps pipeline for the deployment of the application."
    
    # IMPORTANT: You must replace "your_assignment_group_sys_id" with the sys_id of a valid assignment group.
    assignment_group = "b85d44954a3623120004689b2d5dd60a"
    
    # Change type (e.g., 'normal', 'standard', 'emergency').
    type = "normal"
    
    # Add other required fields here. For example, some instances may require:
    # justification = "Automated deployment requires this change."
    # priority = "4"
} | ConvertTo-Json

try {
    # Perform the API call to create the change request.
    # We're using Invoke-RestMethod for simplicity.
    $response = Invoke-RestMethod -Uri $serviceNowUrl -Method Post -Headers @{
        'Authorization' = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$destUName`:$destPwd"))
    } -ContentType 'application/json' -Body $body

    # Check if the request was successful
    if ($response.error -ne $null) {
        Write-Error "Error creating change request: $($response.error.message)"
        exit 1
    }

    # Extract the sys_id of the new change request
    $sysId = $response.result.sys_id

    if ($sysId) {
        Write-Host "Successfully created change request with sys_id: $sysId"
        # Set a pipeline variable so the next script can access it.
        Write-Host "##vso[task.setvariable variable=changeRequestSysId;isOutput=true]$sysId"
    }
    else {
        Write-Error "Failed to retrieve sys_id from the ServiceNow API response."
        exit 1
    }

} catch {
    Write-Error "An error occurred during the API call: $_"
    exit 1
}
