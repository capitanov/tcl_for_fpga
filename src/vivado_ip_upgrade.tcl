# ----------------------------------------------------------------------------
# --
# -- Title    : TCL Script #2 for IP Cores 
# -- Author   : Alexander Kapitanov
# -- E-mail   : kapitanov@insys.ru
# --
# ---------------------------------------------------------------------------- 
# --
# -- Description :
# -- 
# -- 0. First stage disables ISE IP-cores *.XCO
# -- 1. TCL script used for upgrade Vivado IP-cores
# -- 2. TCL script should be in the next dir: - ./src/
# -- 3. Project dir should be named "vivado"
# --
# ----------------------------------------------------------------------------
#
# MIT License
# 
# Copyright (c) 2016 Alexander Kapitanov
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ---------------------------------------------------------------------------- 
# Useful Procedures and Functions are here
# ----------------------------------------------------------------------------

# findFiles can find files in subdirs and add it into a list
proc findFiles { basedir pattern } {

    # Fix the directory name, this ensures the directory name is in the
    # native format for the platform and contains a final directory seperator
    set basedir [string trimright [file join [file normalize $basedir] { }]]
    set fileList {}
    array set myArray {}
    
    # Look in the current directory for matching files, -type {f r}
    # means ony readable normal files are looked at, -nocomplain stops
    # an error being thrown if the returned list is empty

    foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
        lappend fileList $fileName
    }   
    
    # Now look for any sub direcories in the current directory
    foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
        # Recusively call the routine on the sub directory and append any
        # new files to the results
        # put $dirName
        set subDirList [findFiles $dirName $pattern]
        if { [llength $subDirList] > 0 } {
            foreach subDirFile $subDirList {
                
                #set SizeStr [string length $dirName]
                #set NewFile [string range $subDirFile $SizeStr+1 end]
                lappend fileList $subDirFile
            }
        }
    }
    return $fileList
}
# ----------------------------------------------------------------------------

# report_property -all [get_fileset sim_1]
set TclPath [file dirname [file normalize [info script]]]
set PrjDir [string range $TclPath 0 [string last / $TclPath]-1]

set FindTop [findFiles $PrjDir/vivado/ "*.xpr"]
puts $FindTop

open_project $FindTop

set_property is_enabled false [get_files  *.xco]
#set_property part xcku035-ffva1156-3-e [current_project]

report_ip_status
export_ip_user_files -of_objects [get_ips] -no_script -reset -quiet

set IpCores [get_ips]


for {set i 0} {$i < [llength $IpCores]} {incr i} {
    set IpSingle [lindex $IpCores $i]
    
    set locked [get_property IS_LOCKED $IpSingle]
    set upgrade [get_property UPGRADE_VERSIONS $IpSingle]
    if {$upgrade != "" && $locked} {
        upgrade_ip $IpSingle;#-log ip_upgrade.log
    }
}

puts "IP cores are Up-to-date!"

report_ip_status

set ip_cnt 0;

for {set i 0} {$i < [llength $IpCores]} {incr i} {
    set IpSingle [lindex $IpCores $i]
    set locked [get_property IS_LOCKED $IpSingle]
    if {$upgrade != "" && $locked} {
        incr ip_cnt
    }
}

if {$ip_cnt > 0} {
    puts "Failed to update IP cores!"
}

close_project