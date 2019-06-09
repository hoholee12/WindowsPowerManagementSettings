# http://www.bigsoft.co.uk/blog/2013/09/30/change-power-plan-when-application-starts
# https://devblogs.microsoft.com/scripting/use-powershell-and-wmi-to-get-processor-information/
# rewritten by manual

# run it via task scheduler 
#  PowerShell.exe -windowstyle hidden -executionpolicy remotesigned <scriptlocation>\xtu_scheduler.ps1
#  (Run whether user is logged on or not is VERY UNRELIABLE)

#install intel xtu
#read cpu clock.txt and set up everything prior to using this script

#config files for adding special_programs, programs_running_cfg_guid, programs_running_cfg_xtu
#is in c:\xtu_scheduler_config\ for realtime editing!
#reference inside config area below vvvv



# your program = index
$special_programs = @{}

# find your own handmade powerplans here:
#  HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes
# index = powerplan
$programs_running_cfg_guid = @{}

# index = gpu setting
$programs_running_cfg_xtu = @{}

#Config Area Herevvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

# settings file that will be created by default:
function checkFiles_myfiles{
	checkFiles "programs_running_cfg_guid"`
"0 = 'c59be9f8-02d3-4004-b5ab-5eb15fe519da'
1 = '7a3436f1-c379-4f06-947e-fbb2755da1c0'
2 = '7266deb3-176a-42f4-a910-f007de07a23b'"

	checkFiles "programs_running_cfg_xtu"`
"0 = 7.5
1 = 5.5
2 = 4.5"

	checkFiles "special_programs"`
"'drt' = 0
'dirtrally2' = 0
'acad' = 1
'cl' = 2
'link' = 2
'pcsx2' = 1
'launcher' = 1
'dolphin' = 1
'tesv' = 1
'fsx' = 1
'ffmpeg' = 2
'7zFM' = 2
'vmware-vmx' = 2"
}

# initial gpu setting
$xtu_init = 7.5		#750mhz		your 'Balanced' gpu setting
$xtu_max = 10.5		#1050mhz	top speed (even 50mhz off the ogspeed and you will be frying your cpu)

$cpu_increase_threshold = 30		#percentage. your real threshold set in powerplan

$loop_delay = 5		#seconds

#Config Area Here^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# create config files if not exist
function checkFiles ([string]$setting_string, [string]$value_string){
	if((Test-Path ("c:\xtu_scheduler_config\" + $setting_string + ".txt")) -ne $True){
		if((Test-Path "c:\xtu_scheduler_config") -ne $True) {
		New-Item -path "c:\" -name "xtu_scheduler_config" -ItemType "directory" }
		New-Item -path "c:\xtu_scheduler_config" -name ($setting_string + ".txt"`
		) -ItemType "file" -value $value_string
	}
}

checkFiles_myfiles

# used for checking whether settings file was modified
$global:lastModifiedDate = @{}
$global:found_hash = @{}		#copy $found_hash after calling findFiles
$global:isDateDifferent = $False	#flag for findFiles

# find settings file
function findFiles ($setting_string){
	$file = Get-Content ("c:\xtu_scheduler_config\" + $setting_string + ".txt")
	$global:lastModifiedDate.add($setting_string, (Get-Item ("c:\xtu_scheduler_config\"`
	+ $setting_string + ".txt")).LastWriteTime)
	if ($? -eq $True)
	{
		$global:found_hash = @{}
		foreach ($line in $file)
		{
			$global:found_hash.add($line.split("=")[0].trim("'", " "),`
			$line.split("=")[1].trim("'", " "))
		}
	}
}

function checkSettings ($setting_string){
	$currentModifiedDate = (Get-Item ("c:\xtu_scheduler_config\" + $setting_string + ".txt"`
	)).LastWriteTime
	if($global:lastModifiedDate[$setting_string] -ne $currentModifiedDate){
		$global:isDateDifferent = $True
		$global:lastModifiedDate.Remove($setting_string)
		findFiles $setting_string
	}
	else{
		$global:isDateDifferent = $False
	}
}

findFiles "programs_running_cfg_guid"
$programs_running_cfg_guid = $global:found_hash
findFiles "programs_running_cfg_xtu"
$programs_running_cfg_xtu = $global:found_hash
findFiles "special_programs"
$special_programs = $global:found_hash


$loop_delay_backup = $loop_delay

# initial powerplan 'Balanced'
powercfg -setactive '381b4222-f694-41f0-9685-ff5bb260df2e'		#'Balanced'
xtucli -t -id 59 -v $xtu_init

# initial cpu max speed
$cpu = Get-WmiObject -class Win32_Processor
$max = $cpu['CurrentClockSpeed']


while ($True)
{
	checkFiles_myfiles
	checkSettings "programs_running_cfg_guid"
	if ($global:isDateDifferent -eq $True) { $programs_running_cfg_guid = $global:found_hash }
	checkSettings "programs_running_cfg_xtu"
	if ($global:isDateDifferent -eq $True) { $programs_running_cfg_xtu = $global:found_hash }
	checkSettings "special_programs"
	if ($global:isDateDifferent -eq $True) { $special_programs = $global:found_hash }
	
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
		$cpu = Get-WmiObject -class Win32_Processor
		$load = $cpu['LoadPercentage']
		$clock = $cpu['CurrentClockSpeed']
		#if throttling has kicked in('Balanced' clockspeed must be set lower than 'Performance')
		if($load -gt $cpu_increase_threshold -And $clock -lt $max){
			powercfg - setactive '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'		#'Performance'
			xtucli -t -id 59 -v $xtu_max
			$loop_delay = 0		#loop immediately
		}

		#change power plan
		elseif ($current -match $programs_running_cfg_guid[$special_programs[$key]] -eq $False)
		{
			powercfg -setactive $programs_running_cfg_guid[$special_programs[$key]]
			xtucli -t -id 59 -v $programs_running_cfg_xtu[$special_programs[$key]]
			$loop_delay = $loop_delay_backup
		}
	}
	else
	{
		#change back to 'Balanced' if nothings running
		if ($current -match '381b4222-f694-41f0-9685-ff5bb260df2e' -eq $False)
		{
			powercfg -setactive '381b4222-f694-41f0-9685-ff5bb260df2e'		#'Balanced'
			xtucli -t -id 59 -v $xtu_init
			$loop_delay = $loop_delay_backup
		}

	}
	
	sleep $loop_delay
}
