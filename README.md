# WindowsPowerManagementSettings

in PowerSettings folder:
========================
these registry edits allows hidden processor powermanagement settings to show up in Windows APM. (Based on Microsoft Windows [Version 10.0.10586])

in MF840KHA:
============
my personal backup

config.txt has my EAPO audio settings

cpu clock.txt has all system/per game settings

use with xtu_scheduler.ps1 from 'powerplan for intel gpu'

run powershell_cleaner.ps1 if you experience slow powershell init(its recommended that you run this regularly every windows update...)


save battery with: batteryNotifyAt80.vbs

it notifies you to UNPLUG NOW! at battery level 80%

use with task scheduler as well


also has reference doc about how to set up lubbos fan control!

unlike macsfancontrol, lubbos is update-nag free

it looks like its ancient and that modern macs arent supported, NOPE only default sensors have incorrect value! fan control still works!
read reference doc to set it up

in powerplan for intel gpu:
===========================
i made all of this to prove that running heavy AAA titles on a very low tier potatobook is quite possible.
not just possible to run, but gameplay also can be very consistent and smooth... with the help of proper tuning!
