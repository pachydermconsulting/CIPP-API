using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$APIName = $TriggerMetadata.FunctionName
Log-Request -user $request.headers.'x-ms-client-principal' -API $APINAME  -message "Accessed this API" -Sev "Debug"
Write-Host ($request | ConvertTo-Json -Compress)

try {        
    $GUID = New-Guid
    New-Item Config -ItemType Directory -ErrorAction SilentlyContinue
    $JSON = if ($request.body.rawjson) {
        Write-Host "PowerShellCommand"
        $request.body.rawjson
    }
    else {
        ([pscustomobject]$Request.body) | ForEach-Object {
            $NonEmptyProperties = $_.psobject.Properties | Where-Object { $null -ne $_.Value } | Select-Object -ExpandProperty Name
            $_ | Select-Object -Property $NonEmptyProperties 
        }
    }
    $JSON = ($JSON | ConvertTo-Json -Depth 10).tolower()
    Set-Content "Config\$($GUID).CATemplate.json" -Value ($JSON) -Force
    Log-Request -user $request.headers.'x-ms-client-principal' -API $APINAME  -message "Created Transport Rule Template $($Request.body.name) with GUID $GUID" -Sev "Debug"
    $body = [pscustomobject]@{"Results" = "Successfully added template" }
    
}
catch {
    Log-Request -user $request.headers.'x-ms-client-principal'  -API $APINAME -message "Failed to create Transport Rule Template: $($_.Exception.Message)" -Sev "Error"
    $body = [pscustomobject]@{"Results" = "Intune Template Deployment failed: $($_.Exception.Message)" }
}


# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })