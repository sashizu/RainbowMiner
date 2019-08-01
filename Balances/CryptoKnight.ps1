﻿param(
    $Config
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Pools_Data = @(
    [PSCustomObject]@{coin = "Aeon";        symbol = "AEON"; algo = "CnLiteV7";    port = 5541;  fee = 0.0; rpc = "aeon"}
    [PSCustomObject]@{coin = "BitTube";     symbol = "TUBE"; algo = "CnSaber";     port = 5631;  fee = 0.0; rpc = "ipbc"; host = "tube"}
    [PSCustomObject]@{coin = "Graft";       symbol = "GRFT"; algo = "CnRwz";       port = 9111;  fee = 0.0; rpc = "graft"}
    [PSCustomObject]@{coin = "Haven";       symbol = "XHV";  algo = "CnHaven";     port = 5831;  fee = 0.0; rpc = "haven"}
    [PSCustomObject]@{coin = "Masari";      symbol = "MSR";  algo = "CnHalf";      port = 3333;  fee = 0.0; rpc = "msr"; host = "masari"}
    [PSCustomObject]@{coin = "Monero";      symbol = "XMR";  algo = "CnR";         port = 4441;  fee = 0.0; rpc = "xmr"; host = "monero"}
    [PSCustomObject]@{coin = "Swap";        symbol = "XWP";  algo = "Cuckaroo29s"; port = 7731;  fee = 0.0; rpc = "swap"; divisor = 32; regions = @("eu","asia")}
    [PSCustomObject]@{coin = "Scala";       symbol = "XTC";  algo = "CnFast2";     port = 16221;  fee = 0.0; rpc = "torque"}
)

$Pools_Data | Where-Object {$Config.Pools.$Name.Wallets."$($_.symbol)"} | Foreach-Object {
    $Pool_Currency = $_.symbol
    $Pool_RpcPath = $_.rpc

    $Pool_Request = [PSCustomObject]@{}
    $Request = [PSCustomObject]@{}

    try {
        $Pool_Request = Invoke-RestMethodAsync "https://cryptoknight.cc/rpc/$($Pool_RpcPath)/stats" -tag $Name
        $Divisor = $Pool_Request.config.coinUnits

        $Request = Invoke-RestMethodAsync "https://cryptoknight.cc/rpc/$($Pool_RpcPath)/stats_address?address=$($Config.Pools.$Name.Wallets.$Pool_Currency -replace "\..+$" -replace "\+.+$")" -delay 100 -cycletime ($Config.BalanceUpdateMinutes*60)
        if (-not $Request.stats -or -not $Divisor) {
            Write-Log -Level Info "Pool Balance API ($Name) for $($Pool_Currency) returned nothing. "
        } else {
            $Pending = ($Request.blocks | Where-Object {$_ -match "^\d+?:\d+?:\d+?:\d+?:\d+?:(\d+?):"} | Foreach-Object {[int64]$Matches[1]} | Measure-Object -Sum).Sum / $Divisor
            [PSCustomObject]@{
                Caption     = "$($Name) ($Pool_Currency)"
                Currency    = $Pool_Currency
                Balance     = $Request.stats.balance / $Divisor
                Pending     = $Pending
                Total       = $Request.stats.balance / $Divisor + $Pending
                Paid        = $Request.stats.paid / $Divisor
                Payouts     = @($i=0;$Request.payments | Where-Object {$_ -match "^(.+?):(\d+?):"} | Foreach-Object {[PSCustomObject]@{time=$Request.payments[$i+1];amount=$Matches[2] / $Divisor;txid=$Matches[1]};$i+=2})
                LastUpdated = (Get-Date).ToUniversalTime()
            }
        }
    }
    catch {
        if ($Error.Count){$Error.RemoveAt(0)}
        Write-Log -Level Verbose "Pool Balance API ($Name) for $($Pool_Currency) has failed. "
    }
}
