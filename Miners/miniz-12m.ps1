<#
MindMiner  Copyright (C) 2019  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

if ([Config]::ActiveTypes -notcontains [eMinerType]::nVidia) { exit }
if (![Config]::Is64Bit) { exit }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Cfg = [BaseConfig]::ReadOrCreate([IO.Path]::Combine($PSScriptRoot, $Name + [BaseConfig]::Filename), @{
	Enabled = $true
	BenchmarkSeconds = 90
	ExtraArgs = $null
	Algorithms = @(
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "equihash144" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "equihash192" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "equihash96" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "equihashBTG" }
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "zhash" }
)})

if (!$Cfg.Enabled) { return }

$url = "http://mindminer.online/miners/nVidia/miniz-12m.zip";
if ([Config]::CudaVersion -ge [version]::new(10, 0)) {
	$url = "http://mindminer.online/miners/nVidia/miniz-12m-10.zip"
}

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		if ($Algo) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			if ($Pool) {
				$extrargs = Get-Join " " @($Cfg.ExtraArgs, $_.ExtraArgs)
				$alg = [string]::Empty
				switch ($_.Algorithm) {
					"equihash144" { $alg = "--par=144,5" }
					"equihash192" { $alg = "--par=192,7" }
					"equihash96" { $alg = "--par=96,5" }
					"equihashBTG" { $alg = "--par=144,5 --pers=BgoldPoW" }
					"zhash" { $alg = "--par=144,5" }
				}
				if (!($extrargs -match "-pers" -or $alg -match "-pers")) {
					$alg = Get-Join " " @($alg, "--pers=auto") #"--smart-pers") 
				}
				[MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::nVidia
					API = "ewbf"
					URI = $url
					Path = "$Name\miniz.exe"
					ExtraArgs = $extrargs
					Arguments = "$alg --url=$($Pool.User)@$($Pool.Host):$($Pool.PortUnsecure) -p $($Pool.Password) -a 42000 --nocolor --latency --show-shares $extrargs"
					Port = 42000
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
					RunBefore = $_.RunBefore
					RunAfter = $_.RunAfter
					Fee = 2
				}
			}
		}
	}
}