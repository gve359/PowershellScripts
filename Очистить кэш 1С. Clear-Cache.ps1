# Очистить кэш 1С. Можно применять в т.ч. на серверах.

Param
(    
    [String] $pc = $(
        Write-Host 'Введите имя компа'
        Read-Host
    ),
    [String] $username = $(
        Write-Host 'Введите username'
        Read-Host
    ),
    [switch] $invokeMode,  # Введён на случай, если либо пути будут недоступны, либо удалённый вызов команд. А так, отличий нет(хотя invoke лучше из-за сброса 1С, чтоб не мешал удалять).
    [PSCredential] $credential = $(
        if ($invokeMode -and ($credential -eq $null))
        { Get-Credential -Message 'Для использования данного скрипта требуется аутентификация.' -User ... }
    )
)
if ($invokeMode)
{
    Invoke-Command -ComputerName $pc -ScriptBlock { param($username)
        Stop-Process -Name 1cv8* -Force
        Start-Sleep -Seconds 3

        $paths = Get-ChildItem `
        "C:\Users\$username\AppData\Local\1C\1Cv8*\*", 
        "C:\Users\$username\AppData\Roaming\1C\1Cv8*\*" 
        #т.е. возьмёт все 1Cv8, 1Cv81, 1Cv82,... и их подпапки
      
        $paths = $paths | Where {$_.Name -as [guid]} | sort 

        $resultPaths = @()

        foreach ($path in $paths)
        {
            $subpaths = Get-ChildItem $path.FullName -Recurse | Where-Object {$_.Name -match "(^Config$)|(^ConfigSave$)|(^DBNameCache$)|(^SICache$)|(^vrs-cache$)"}         
            $resultPaths += $subpaths | foreach { Write-Output $_.FullName }    
        }
       
        $resultPaths | Remove-Item -Recurse -Force

	} -Arg $username `
	  -Credential $credential
}
else
{
    $paths = Get-ChildItem `
        "\\$pc\c$\Users\$username\AppData\Local\1C\1Cv8*\*", 
        "\\$pc\c$\Users\$username\AppData\Roaming\1C\1Cv8*\*" 
        #т.е. возьмёт все 1Cv8, 1Cv81, 1Cv82,... и их подпапки
      
    $paths = $paths | Where {$_.Name -as [guid]} | sort 

    $resultPaths = @()

    foreach ($path in $paths)
    {
        $subpaths = Get-ChildItem $path.FullName -Recurse | Where-Object {$_.Name -match "(^Config$)|(^ConfigSave$)|(^DBNameCache$)|(^SICache$)|(^vrs-cache$)"}         
        $resultPaths += $subpaths | foreach { Write-Output $_.FullName }    
    }
       
    $resultPaths | Remove-Item -Recurse -Force
}
