function ReplaceExeId($AssemblyName, $HeatOutputWxs, $MainExeFileId)
{
    Invoke-WithErrorsToErrorWindow {
        $xml = [xml](Get-Content $HeatOutputWxs)
        $fragment = $xml.Wix.Fragment | where { $_.ComponentGroup.Id -eq 'FilesComponentGroup' }
        $component = $fragment.ComponentGroup.Component | where { $_.File.Source -like "*\$AssemblyName.exe" }
        $file = $component.File
        $file.Id = $MainExeFileId
        $xml.Save($HeatOutputWxs)
    }
}

function FillInProductWxs($ProductWxs)
{
    Invoke-WithErrorsToErrorWindow {
        
        $placeholder = 'UPGRADE-CODE-PLACEHOLDER'
        $upgradeCode = [guid]::Newguid().Guid
        (Get-Content $ProductWxs) -replace $placeholder, $upgradeCode |
            Out-File $ProductWxs -Encoding utf8
    }
}

function Invoke-WithErrorsToErrorWindow([ScriptBlock] $scriptBlock)
{
    $ErrorActionPreference = "Stop"
    try { & $scriptBlock }
    catch { Write-ToErrorWindow $_ }
}

function Write-ToErrorWindow([System.Management.Automation.ErrorRecord]$errorRecord)
{
    $info = $errorRecord.InvocationInfo
    $filename = $info.PSCommandPath
    $lineNumber = $info.ScriptLineNumber
    $columnNumber = $info.OffsetInLine

    $message = $errorRecord.ErrorDetails.Message
    if ($message -eq $null) { $message = $errorRecord.Exception.Message }

    Write-Host "$filename($lineNumber,$columnNumber) : error : $message"
}