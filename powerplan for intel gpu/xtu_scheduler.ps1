# http://www.bigsoft.co.uk/blog/2013/09/30/change-power-plan-when-application-starts
# rewritten by manual

# run it via task scheduler 
#  PowerShell.exe -windowstyle hidden -executionpolicy remotesigned <scriptlocation>\xtu_scheduler.ps1 (Run whether user is logged on or not is VERY UNRELIABLE)

#install intel xtu
#read cpu clock.txt and set up everything prior to using this script

# throttle[0], maxpower[1], encoding[2]
# your program = powerplan
$special_programs = @{
	'drt' = 0
	'dirtrally2' = 0
	'acad' = 1
	'cl' = 2
	'pcsx2' = 1
	'launcher' = 1
	'dolphin' = 1
	'tesv' = 1
	'fsx' = 1
	'ffmpeg' = 2
}

# find your own handmade powerplans here:
#  HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes
$programs_running_cfg_guid = @{
	0 = 'c59be9f8-02d3-4004-b5ab-5eb15fe519da'		#throttle
	1 = '7a3436f1-c379-4f06-947e-fbb2755da1c0'		#maxpower
	2 = '7266deb3-176a-42f4-a910-f007de07a23b'		#encoding
}

$programs_running_cfg_xtu = @{
	0 = 7.5		#750mhz
	1 = 5.5		#550mhz
	2 = 4.5		#450mhz
}

$loop_delay = 5

# initial powerplan
powercfg -setactive '381b4222-f694-41f0-9685-ff5bb260df2e'
xtucli -t -id 59 -v 7.5

while ($True)
{
	$special_programs_running = $False
	foreach($key in $special_programs.Keys)		#   $key value remains globally after break
	{
		Get-Process -ErrorAction SilentlyContinue -Name $key
		$running = $?
		if ($running -eq $True)
		{
			$special_programs_running = $True
			break
		}
	}
	
	$current = powercfg -getactivescheme
	if ($special_programs_running -eq $True)
	{
		#change power plan
		if ($current -match $programs_running_cfg_guid[$special_programs[$key]] -eq $False)
		{
			powercfg -setactive $programs_running_cfg_guid[$special_programs[$key]]
			xtucli -t -id 59 -v $programs_running_cfg_xtu[$special_programs[$key]]
		}
	}
	else
	{
		#change back to balanced if nothings running
		if ($current -match '381b4222-f694-41f0-9685-ff5bb260df2e' -eq $False)
		{
			powercfg -setactive '381b4222-f694-41f0-9685-ff5bb260df2e'
			xtucli -t -id 59 -v 7.5
		}

	}
	
	sleep $loop_delay
}