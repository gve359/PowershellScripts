<#
Список составлен из ... и из 1С > Регистр сведений > настройки (ЕГАИС). Пока вручную, из AD позже будет.
#>


class Shop {
	[int] $num
    [string]$pcname
    [string]$ip
    [string]$os
    [string]$ip_utm

    Shop([int] $num, [string]$pcname, [string]$ip, [string]$os, [string]$ip_utm){
		$this.num = $num
        $this.pcname = $pcname
        $this.ip = $ip
        $this.os = $os
        $this.ip_utm = $ip_utm
    }
}

function Get-Shops
{    
    [OutputType([Shop[]])]
    Param ([int[]] $nums)
    #--------

	[Shop[]]$result = @()
	foreach ($i in $nums)
	{
        if ($allShops.Contains($i))
        { $result = $result + $allShops.Item($i) }
	}
	
	$result
}

$allShops = @{} #хэш-таблица из объектов Shop
$allShops.Add(2, [Shop]::new(2, 'nameShop', 'ipshop', 'os', 'ip_utm'))
