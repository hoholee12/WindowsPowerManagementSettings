# adaptive power management script (for laptops with intel gpu) written by dj_manual

# run it via task scheduler 
#  PowerShell.exe -windowstyle hidden -executionpolicy remotesigned <scriptlocation>\xtu_scheduler.ps1
#  (Run whether user is logged on or not is VERY UNRELIABLE)

#this script requires intel xtucli.exe!!!
#read cpu clock.txt and ready up everything prior to configuring this script

#config files for adding special_programs, programs_running_cfg_cpu, programs_running_cfg_xtu
#				YOU CAN EDIT CONFIG REALTIME!!!: its in c:\xtu_scheduler_config\

#reference inside config area below vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

$processor_power_management_guids = @{
"06cadf0e-64ed-448a-8927-ce7bf90eb35d" = 80			#cpu high threshold; lower this for performance
"0cc5b647-c1df-4637-891a-dec35c318583" = 100
"12a0ab44-fe28-4fa9-b3bd-4b64f44960a6" = 50			#cpu low threshold; upper this for batterylife
"40fbefc7-2e9d-4d25-a185-0cfd8574bac6" = 1
"45bcc044-d885-43e2-8605-ee0ec6e96b59" = 100
"465e1f50-b610-473a-ab58-00d1077dc418" = 2
"4d2b0152-7d5c-498b-88e2-34345392a2c5" = 15
"893dee8e-2bef-41e0-89c6-b55d0929964c" = 5
"94d3a615-a899-4ac5-ae2b-e4d8f634367f" = 1
"bc5038f7-23e0-4960-96da-33abaf5935ec" = 100
"ea062031-0e34-4ff1-9b6d-eb1059334028" = 100
}

# stuff
$guid0 = '381b4222-f694-41f0-9685-ff5bb260df2e'		# you can change to any powerplan you want as default!
$guid1 = '54533251-82be-4824-96c1-47b60b740d00'		# processor power management
$guid2 = 'bc5038f7-23e0-4960-96da-33abaf5935ec'		# processor high clockspeed limit


#loop dat shit
foreach($temp in $processor_power_management_guids.Keys){
	powercfg /attributes $guid1 $temp -ATTRIB_HIDE
	powercfg /setdcvalueindex $guid0 $guid1 $temp $processor_power_management_guids[$temp]
	powercfg /setacvalueindex $guid0 $guid1 $temp $processor_power_management_guids[$temp]
}
powercfg /setactive $guid0

# your program = index
$special_programs = @{}

# find your own handmade powerplans here:
#  HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes
# index = cpu setting
$programs_running_cfg_cpu = @{}

# index = gpu setting
$programs_running_cfg_xtu = @{}



# create config files if not exist
function checkFiles ([string]$setting_string, [string]$value_string){
	if((Test-Path ("c:\xtu_scheduler_config\" + $setting_string + ".txt")) -ne $True){
		if((Test-Path "c:\xtu_scheduler_config") -ne $True) {
		New-Item -path "c:\" -name "xtu_scheduler_config" -ItemType "directory" }
		New-Item -path "c:\xtu_scheduler_config" -name ($setting_string + ".txt"`
		) -ItemType "file" -value $value_string
	}
}

# settings file created by default: (0 will be the base clockspeed! key start from 0 and increment by 1)
function checkFiles_myfiles{
	checkFiles "programs_running_cfg_cpu"`
"0 = 84
1 = 98
2 = 100
3 = 65
4 = 98"

	checkFiles "programs_running_cfg_xtu"`
"0 = 6.5
1 = 5.5
2 = 4.5
3 = 7.5
4 = 7.5"

	checkFiles "special_programs"`
"'acad' = 1
'launcher' = 1
'tesv' = 1
'fsx' = 1
'Journey' = 1
'ppsspp' = 1
'nullDC' = 1
'pcsxr' = 1
'Project64' = 1
'ace7game' = 1
'pcars' = 1
'cl' = 2
'link' = 2
'pcsx2' = 2
'dolphin' = 2
'ffmpeg' = 2
'7z' = 2
'vmware-vmx' = 2
'drt' = 3
'dirtrally2' = 3
'gta5' = 4
'gtaiv' = 4
'borderlands2' = 4"
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

findFiles "programs_running_cfg_cpu"
$programs_running_cfg_cpu = $global:found_hash
findFiles "programs_running_cfg_xtu"
$programs_running_cfg_xtu = $global:found_hash
findFiles "special_programs"
$special_programs = $global:found_hash


# initial cpu setting
$cpu_init = $programs_running_cfg_cpu['0']
$cpu_max = 100

# initial gpu setting(make sure nothing is running on boot that uses xtu besides this script,
# and you should disable all xtu profiles as well)
$xtu_init = $programs_running_cfg_xtu['0']
$xtu_max = ((& xtucli -t -id 59 | select-string "59" | %{ -split $_ | select -index 5} | out-string
) -replace "x",'').trim()

$loop_delay = 5		#seconds




$loop_delay_backup = $loop_delay


# initial powerplan to whatever guid0 is
powercfg /setdcvalueindex $guid0 $guid1 $guid2 $cpu_init
powercfg /setacvalueindex $guid0 $guid1 $guid2 $cpu_init
powercfg /setactive $guid0
xtucli -t -id 59 -v $xtu_init

# initial cpu max speed
$cpu = Get-WmiObject -class Win32_Processor
$max = $cpu['CurrentClockSpeed']

#Config Area Here^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

while ($True)
{
	checkFiles_myfiles
	checkSettings "programs_running_cfg_cpu"
	if ($global:isDateDifferent -eq $True) { $programs_running_cfg_cpu = $global:found_hash }
	checkSettings "programs_running_cfg_xtu"
	if ($global:isDateDifferent -eq $True) { $programs_running_cfg_xtu = $global:found_hash }
	checkSettings "special_programs"
	if ($global:isDateDifferent -eq $True) { $special_programs = $global:found_hash }
	#	init may have been changed
	$cpu_init = $programs_running_cfg_cpu['0']
	$xtu_init = $programs_running_cfg_xtu['0']
	
	
	$special_programs_running = $False
	foreach($key in $special_programs.Keys)		#   $key value remains globally after break
	{
		$temp = Get-Process -ErrorAction SilentlyContinue -Name ($key + '*')
		if ($temp -ne $null)
		{
			$special_programs_running = $True
			break
		}
	}
	
	$temp = powercfg /query $guid0 $guid1 $guid2
	$temp = Out-String -InputObject $temp
	$temp = $temp.SubString($temp.Length - 6, 6).trim()
	$temp = '{0:d}' -f [int]("0x" + $temp)
	if ($special_programs_running -eq $True)
	{
		$cpu = Get-WmiObject -class Win32_Processor
		$load = $cpu['LoadPercentage']
		$clock = $cpu['CurrentClockSpeed']
		#if throttling has kicked in, set everything to max clockspeed for a brief time
		#it fucks up the baked-in throttling system or whatever the fuck that is... it just works
		if($load -gt $processor_power_management_guids['06cadf0e-64ed-448a-8927-ce7bf90eb35d'] -And $clock -lt $max){
			powercfg /setdcvalueindex $guid0 $guid1 $guid2 $cpu_max
			powercfg /setacvalueindex $guid0 $guid1 $guid2 $cpu_max
			powercfg /setactive $guid0
			xtucli -t -id 59 -v $xtu_max
			$loop_delay = 0		#loop immediately
		}

		#change power plan
		elseif ($temp -match $programs_running_cfg_cpu[$special_programs[$key]] -eq $False)
		{
			powercfg /setdcvalueindex $guid0 $guid1 $guid2 $programs_running_cfg_cpu[$special_programs[$key]]
			powercfg /setacvalueindex $guid0 $guid1 $guid2 $programs_running_cfg_cpu[$special_programs[$key]]
			powercfg /setactive $guid0
			
			if ([float]$programs_running_cfg_xtu[$special_programs[$key]] -le [float]$xtu_max)
			{
				xtucli -t -id 59 -v $programs_running_cfg_xtu[$special_programs[$key]]
			}
			$loop_delay = $loop_delay_backup
		}
	}
	else
	{
		#change back to 'Balanced' if nothings running
		if ($temp -match $cpu_init -eq $False)
		{
			powercfg /setdcvalueindex $guid0 $guid1 $guid2 $cpu_init
			powercfg /setacvalueindex $guid0 $guid1 $guid2 $cpu_init
			powercfg /setactive $guid0

			if ([float]$xtu_init -le [float]$xtu_max)
			{
				xtucli -t -id 59 -v $xtu_init
			}
			$loop_delay = $loop_delay_backup
		}

	}

	sleep $loop_delay
}
