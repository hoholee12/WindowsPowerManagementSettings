# adaptive power management script (for laptops with intel gpu) written by dj_manual

# run it via task scheduler 
#  PowerShell.exe -windowstyle hidden -executionpolicy remotesigned <scriptlocation>\xtu_scheduler.ps1
#  (Run whether user is logged on or not is VERY UNRELIABLE)

#this script requires intel xtucli.exe!!!
#read cpu clock.txt and ready up everything prior to configuring this script

#config files for adding special_programs, programs_running_cfg_cpu, programs_running_cfg_xtu
#				YOU CAN EDIT CONFIG REALTIME!!!: its in c:\xtu_scheduler_config\

#	INITIALIZERS
# your program = index
$special_programs = @{}

# find your own handmade powerplans here:
#  HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes
# index = cpu setting
$programs_running_cfg_cpu = @{}

# index = gpu setting
$programs_running_cfg_xtu = @{}

# nice settings
$programs_running_cfg_nice = @{}


# create config files if not exist
function checkFiles ([string]$setting_string, [string]$value_string){
	if((Test-Path ("c:\xtu_scheduler_config\" + $setting_string + ".txt")) -ne $True){
		if((Test-Path "c:\xtu_scheduler_config") -ne $True) {
		New-Item -path "c:\" -name "xtu_scheduler_config" -ItemType "directory" }
		New-Item -path "c:\xtu_scheduler_config" -name ($setting_string + ".txt"`
		) -ItemType "file" -value $value_string
	}
}


#reference inside config area below vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

$processor_power_management_guids = @{
"06cadf0e-64ed-448a-8927-ce7bf90eb35d" = 80			# processor high threshold; lower this for performance
"0cc5b647-c1df-4637-891a-dec35c318583" = 100
"12a0ab44-fe28-4fa9-b3bd-4b64f44960a6" = 50			# processor low threshold; upper this for batterylife
"40fbefc7-2e9d-4d25-a185-0cfd8574bac6" = 1
"45bcc044-d885-43e2-8605-ee0ec6e96b59" = 100
"465e1f50-b610-473a-ab58-00d1077dc418" = 2
"4d2b0152-7d5c-498b-88e2-34345392a2c5" = 15
"893dee8e-2bef-41e0-89c6-b55d0929964c" = 5			# processor low clockspeed limit
"94d3a615-a899-4ac5-ae2b-e4d8f634367f" = 1
"bc5038f7-23e0-4960-96da-33abaf5935ec" = 100		# processor high clockspeed limit
"ea062031-0e34-4ff1-9b6d-eb1059334028" = 100
}



# settings file created by default: (0 will be the base clockspeed! key start from 0 and increment by 1)
function checkFiles_myfiles{
	checkFiles "programs_running_cfg_cpu"`
"0 = 84
1 = 98
2 = 100
3 = 65
4 = 95
5 = 100
6 = 84"

	checkFiles "programs_running_cfg_xtu"`
"0 = 6.5
1 = 5.5
2 = 4.5
3 = 7.5
4 = 6.5
5 = 4.5
6 = 6.5"

	# adjust priority
	# idle, belownormal, normal, abovenormal, high, realtime
	checkFiles "programs_running_cfg_nice"`
"0 = idle
1 = high
2 = high
3 = high
4 = high
5 = idle
6 = realtime"

	checkFiles "special_programs"`
"'jdownloader2' = 0
'github' = 0
'steam' = 0
'origin' = 0
'mbam' = 0
'shellexperiencehost' = 0
'svchost' = 0
'subprocess' = 0
'gtavlauncher' = 0
'acad' = 1
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
'gtaiv' = 1
'pcsx2' = 2
'dolphin' = 2
'vmware-vmx' = 2
'drt' = 3
'dirtrally2' = 3
'gta5' = 4
'borderlands2' = 4
'cl' = 5
'link' = 5
'ffmpeg' = 5
'7z' = 5
'bandizip' = 5
'macsfancontrol' = 6
'lubbosfancontrol' = 6
'bootcamp' = 6
'obs' = 6
'remoteplay' = 6
'discord' = 6"
}

$loop_delay = 5		#seconds

#Config Area Here^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



# stuff
$guid0 = '381b4222-f694-41f0-9685-ff5bb260df2e'		# you can change to any powerplan you want as default!
$guid1 = '54533251-82be-4824-96c1-47b60b740d00'		# processor power management
$guid2 = 'bc5038f7-23e0-4960-96da-33abaf5935ec'		# processor high clockspeed limit
$guid3 = '893dee8e-2bef-41e0-89c6-b55d0929964c'		# processor low clockspeed limit


#loop dat shit
foreach($temp in $processor_power_management_guids.Keys){
	powercfg /attributes $guid1 $temp -ATTRIB_HIDE
	powercfg /setdcvalueindex $guid0 $guid1 $temp $processor_power_management_guids[$temp]
	powercfg /setacvalueindex $guid0 $guid1 $temp $processor_power_management_guids[$temp]
}
powercfg /setactive $guid0


$loop_delay_backup = $loop_delay

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
findFiles "programs_running_cfg_nice"
$programs_running_cfg_nice = $global:found_hash
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


function xtuproc($arg0){
	if ([float]$arg0 -le [float]$xtu_max)
	{
		$xtuproc = start-process xtucli ("-t -id 59 -v " + $arg0) -PassThru
		$xtuproc.PriorityClass = "idle"
	}
}

function cpuproc($arg0){
	powercfg /setdcvalueindex $guid0 $guid1 $guid2 $arg0
	powercfg /setacvalueindex $guid0 $guid1 $guid2 $arg0
	powercfg /setactive $guid0
}


# initial powerplan to whatever guid0 is
cpuproc($cpu_init)
xtuproc($xtu_init)



# initial cpu max speed
function checkMaxSpeed(){
	$cpu = Get-WmiObject -class Win32_Processor
	$global:max = $cpu['CurrentClockSpeed']
}

checkMaxSpeed

# switch
$sw = 0

while ($True)
{
	checkFiles_myfiles
	checkSettings "programs_running_cfg_cpu"
	if ($global:isDateDifferent -eq $True) { $programs_running_cfg_cpu = $global:found_hash }
	checkSettings "programs_running_cfg_xtu"
	if ($global:isDateDifferent -eq $True) { $programs_running_cfg_xtu = $global:found_hash }
	checkSettings "programs_running_cfg_nice"
	if ($global:isDateDifferent -eq $True) { $programs_running_cfg_nice = $global:found_hash }
	checkSettings "special_programs"
	if ($global:isDateDifferent -eq $True) { $special_programs = $global:found_hash }
	#	init may have been changed
	$cpu_init = $programs_running_cfg_cpu['0']
	$xtu_init = $programs_running_cfg_xtu['0']
	
	
	$special_programs_running = $False
	# there may be multiple target apps open. make a list of keys that fit the desc
	$xkey = @{}
	
	foreach($key in $special_programs.Keys)		#   $key value remains globally after break
	{
		$temp = Get-Process -ErrorAction SilentlyContinue -Name ($key + '*')
		if ($temp -ne $null)
		{
			$special_programs_running = $True
			
			#boost priority!!
			foreach($boost in $temp){
				try{
				$boost.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::`
				[string]$programs_running_cfg_nice[$special_programs[$key]]
				}
				catch{}
			}
			
			$xkey.add($key, 0)
		}
		start-sleep -m 20
	}
	
	#idle, belownormal, realtime priority will be regarded as idle processes,
	#and disregarded powerop when other main processes are also running!
	foreach($key in $xkey.Keys){
		if([string]$programs_running_cfg_nice[$special_programs[$key]] -ne "idle" -and`
		[string]$programs_running_cfg_nice[$special_programs[$key]] -ne "belownormal" -and`
		[string]$programs_running_cfg_nice[$special_programs[$key]] -ne "realtime"){
			break
		}
		
	}
	
	#temp = name of the process were looking for
	#temp2 = programs_running_cfg_cpu
	
	$temp2 = powercfg /query $guid0 $guid1 $guid2
	$temp2 = Out-String -InputObject $temp2
	$temp2 = $temp2.SubString($temp2.Length - 6, 6).trim()
	$temp2 = '{0:d}' -f [int]("0x" + $temp2)
	if ($special_programs_running -eq $True)
	{
		$cpu = Get-WmiObject -class Win32_Processor
		$load = $cpu['LoadPercentage']
		$clock = $cpu['CurrentClockSpeed']
		#if throttling has kicked in, set everything to max clockspeed for a brief time
		#it fucks up the baked-in throttling system or whatever the fuck that is... it just works
		if($load -gt $processor_power_management_guids['06cadf0e-64ed-448a-8927-ce7bf90eb35d'] -And $clock -lt $global:max){
			if($sw -eq 0){
				cpuproc($cpu_max)
				xtuproc($xtu_max)
				
				$sw = 1
				$loop_delay = 0		#loop immediately
			}
			else{
				cpuproc($programs_running_cfg_cpu[$special_programs[$key]])
				xtuproc($programs_running_cfg_xtu[$special_programs[$key]])
				
				$sw = 0
				$loop_delay = $loop_delay_backup		#rest a bit
			}
			
		}
		
		#change power plan
		elseif ($temp2 -match $programs_running_cfg_cpu[$special_programs[$key]] -eq $False)
		{
			cpuproc($programs_running_cfg_cpu[$special_programs[$key]])
			xtuproc($programs_running_cfg_xtu[$special_programs[$key]])
				
			$loop_delay = $loop_delay_backup
			checkMaxSpeed		# check max speed here
		}
	}
	else
	{
		#change back to 'Balanced' if nothings running
		if ($temp2 -match $cpu_init -eq $False)
		{
			cpuproc($cpu_init)
			xtuproc($xtu_init)
			
			$loop_delay = $loop_delay_backup
			checkMaxSpeed		# check max speed here
		}

	}

	
	start-sleep $loop_delay
}
