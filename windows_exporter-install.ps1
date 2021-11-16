# This script should be triggered by windows_exporter-pre-deploy.ps1 script - and then hopefully be automatically deleted.
$MSIFilename = "windows_exporter-0.16.0-amd64.msi"
$MSIPath = "C:\Windows\Temp\$MSIFilename"
$MSILog = "C:\Windows\Temp\windows_exporter.log"
$EnabledCollectors = '[defaults],mssql,vmware,hyperv,iis'
$ScrapeServers = '10.0.0.15'
$MSIArguments = "/i", "$MSIPath", "/q", "/L*VX", "$MSILog", "REMOTE_ADDR=$ScrapeServers", "ENABLED_COLLECTORS=$EnabledCollectors",
"EXTRA_FLAGS=`"--collector.service.services-where `"`"Name LIKE `'MSSQL%`' or Name=`'w3svc`' or Name LIKE `'ColdFusion%`'`"`" --collector.iis.site-blacklist `"`"Default Web Site`"`"`""

& C:\Windows\System32\msiexec.exe @MSIArguments

Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force