#!/bin/bash

#Make sure to run in same folder as server or set a script path var instead of PWD

# Set server script name if different
server_script_name="b_http_serve.py"
#Seconds between diff check and restart
recheck_duration=3


set -e


function check_ps_and_restart_or_exit () {
        serve_proc=""
        ps_line=$( ps -aux | grep $server_script_name  )
ps_line=$( ps -aux | grep $server_script_name  )
        # echo "ps line output ~ " + $ps_line
        ps_line_idx=0
        found_ps_line_idx=0
        found_ps_id=0
        for entry in $ps_line
          do
             ps_line_idx=$((ps_line_idx+1))
            # echo "psline entry ${ps_line_idx}" ~ "$entry"
         # Have to look for the grep process too
             if [ $ps_line_idx == 2 ] || [ $ps_line_idx == 14 ];
               then
		      # echo "found proc id for validate ~ "$entry
                        found_ps_id=$entry
                        found_ps_line_idx=$ps_line_idx
             fi
            # echo "Found ps entry ~ "$found_ps_line_idx
            # echo "Ps loop line idx ~ "$ps_line_idx
            # echo "calculate entry diff ~ "$(( $ps_line_idx - $found_ps_line_idx  ))
          if [ $(($ps_line_idx - $found_ps_line_idx )) == 9 ]; then
                # echo "Looking for grep ps entry ~ "$entry
                if [[ $entry =~ .*"grep".* ]]; then
                        echo "Found grep proc continue"
                else
			# echo "killing with arg ~ "$1
                        kill $found_ps_id
                        if [[ $1 == "restart" ]]; then
			  echo "restart serve"
                          python3  $PWD/$server_script_name &
                	fi
		fi
           fi

        done

}


 # Kill and Restart Server Proc by ID 
function res_serve () {
	trap_sig=$(($?))
	 echo "res_serve called ~ trap sig ~ "$trap_sig

	check_ps_and_restart_or_exit "restart"
}



 #Kill and do not restart for exit signals

function ps_kill_serve () {

	trap_sig=$(($?))
	echo "kill_serve called ~~  "$trap_sig

	check_ps_and_restart_or_exit "norestart"
	exit
}



 while :
 	trap ps_kill_serve EXIT  1 2 3 5 9 10 ;	
 do
        old_cat_fs=""
        new_cat_fs=""

 for diritem in $(find . -type f -print)
  do
    if [[ ${diritem} != *".swp" ]]; then
	#echo "get dir names rec ~ "$diritem
   	item_sum=" $(shasum $diritem)"
	#echo "get rec item shasum "$item_sum
   	old_cat_fs=$old_cat_fs$item_sum
    fi  
done

sleep $recheck_duration

 for diritem in $(find . -type f -print)
  do
	#echo "get new dir names rec ~ "$diritem
	if [[ ${diritem} != *".swp" ]]; then  
          item_sum=" $(shasum $diritem)"
	  #echo "get rec item shasum "$item_sum
          new_cat_fs=$new_cat_fs$item_sum
        fi
  done

 if [ "$old_cat_fs" == "$new_cat_fs" ];
   then
        echo " ~ 0 ~ " 
 else
         echo " Reloading Server "
          res_serve
 	echo " Reload server complete "
 fi
 done

