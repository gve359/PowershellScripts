# Создать на серверах магазинов 1Сный ярлык 1C "ОбменЦО".
# Создаёт там, где его нет.
# С опцией Scan сканирует без добавления.

Param(
    [switch] $Scan
)

Import-Module -Name '...\Libs\Get-Shops.lib.ps1' # импортируем класс Shop и готовый хэш набор allShops

[PSCredential] $credential = Get-Credential -Message 'Для использования данного скрипта требуется аутентификация.' -User ...

[string] $shortcutPath = '...\ОбменЦО.lnk'
[string] $1CPath = 'C:\Program Files (x86)\1cv8\common\1cestart.exe'
[string] $shortcutArgs = '...'


[Shop[]] $shops = Get-Shops -nums ($allShops.keys | sort)

foreach ($shop in $shops)
{
    [string] $message =  $shop.num.ToString() + ' - ' + $shop.pcname

    if ($shop.os -eq 'windows')
    {
    	if(Test-Connection -ComputerName $shop.pcname -Count 1 -Quiet)
        {
		    [string] $shortcutPath_i = $shortcutPath -replace '►server◄', $shop.pcname
	
			if(Test-Path (Split-Path -Path $shortcutPath_i -Parent))
			{

				if( -not (Test-Path $shortcutPath_i))
				{				
                    if ($Scan)
                    {
                        $message += ' - отсутствует ОбменЦО на рабстоле'
                    }
                    else
                    {
                        [string] $shortcutArgs_i = $shortcutArgs -replace '►server◄', $shop.pcname; $shortcutArgs_i = $shortcutArgs_i -replace '►shopNum◄', $shop.num
                    
					    Invoke-Command -ComputerName $shop.pcname -ScriptBlock { param($shortcutPath_i, $1CPath, $exe, $shortcutArgs_i)
    						$wshShell = New-Object -ComObject WScript.Shell
						    $Shortcut = $wshShell.CreateShortcut($shortcutPath_i)
						    $Shortcut.TargetPath = $1CPath
						    $Shortcut.Arguments = $shortcutArgs_i
						    $Shortcut.WorkingDirectory = (Split-Path -Path $1CPath -Parent)
						    $Shortcut.Save()
					    } -Arg $shortcutPath_i, $1CPath, $exe, $shortcutArgs_i `
					      -Credential $credential
	
					    $message += ' - ОбменЦО создан на рабстоле'
                    }                    
				}
				else{ $message += ' - ОбменЦО уже есть на рабстоле' }                
			}
			else{ $message += ' - Рабстол не расшарен' }
		}
		else{ $message += ' - Сервер не пингуется' }
    }
    else{ $message += ' - Linux пока не поддерживается' }

    Write-Host $message
}

