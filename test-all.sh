#!/bin/bash 

final_ret=0
ran_test=true
print_json=false
print_logs=false
basedir=validation_tests
print_color=true
skip_to=""

    if [[ $# -gt 0 && -d $1 ]] ; then
       basedir=$1
     fi
while test $# -gt 0
do
    if [[ -d $1 ]] ; then
       basedir=$1
    else

    case "$1" in
        --json) print_json=true
            ;;
        --print-logs) print_logs=true
            ;;
        --settings) export TESTSUITE_SETTINGS_FILE=`readlink -f "$2"`
        shift
            ;;
	--color-off) print_color=false
	    ;;
	--skip-to) skip_to="$2"
	shift
	    ;;
        --help)
        echo "Usage:"
        echo "    ./test-all.sh [Test Directory (Optional.)] <--json> <--settings [settings file]> <--color-off>"
        echo "    --json: Print json output. Redirect to file manually if needed. e.g. ./test-all.sh --json > testout.json"
        echo "    --print-logs: Print contents of all clean/compiler/run logs to screen."
        echo "    --settings </path/to/some.settings.sh>: Use the specified settings.sh file to define compile and run options. Defaults to <testsuite>/settings.sh"
	echo "    --color-off: disable printing test results in color"
	echo "    --skip-to [test]: Start with the specified test, skipping over any listed earlier in lexical order."
        echo "Examples:"
        echo "    ./test-all.sh #Run all tests in the <testsuite>/validation_tests directory"
        echo "    ./test-all.sh /path/to/test/directory #Run all tests in the specified directory"
        echo "    ./test-all.sh /path/to/test/directory --json --settings /path/to/some.settings.sh #Run all tests in the specified directory, print output as json, use some.settings.sh as settings file"
        exit 0
    esac
    fi
    shift
done

if [ $print_color = true -a  -n "$TERM" ];
then
bold=$(tput bold)$(tput setaf 1)
green=$(tput bold)$(tput setaf 2)
yellow=$(tput bold)$(tput setaf 3)
normal=$(tput sgr0);
fi

. ./setup.sh

if [ $print_json = true ]; then
                echo "["
fi

#  If $1 is a directory, run tests or recurse into it.
iterate_directories() {
    testdir=$1
    local _ret
    if [ -d $testdir ] ; then
        cd $testdir
	if [ $print_json != true ]; then
	
	
        	echo "==="
        	echo $testdir
	fi
        
    cwd=`pwd`	
    if [ -e "$cwd/run.sh" ] ; then
	#echo "Running in $cwd"
        local itout
	itout=$(iterate_files)
         _ret=$?
	 echo $itout
         if [ $_ret -ne 0 ] ; then
            final_ret=$( expr $final_ret + 1 )
         fi

	#if [ $print_json = true ]; then
	#	echo "}},"
	#fi

    else
            for d in * ; do
		if [ ! -z $skip_to ] && [[ $d < $skip_to ]]; then
			continue
		fi
                iterate_directories $d
            done
        fi
        cd ..
    fi
}

# Check to see if this directory has clean, compile and run scripts.
# If so, set a flag so we don't recurse further.
iterate_files() {
    cwd=`pwd`
    local _ret

    if [ $print_json = true ]; then
        printf "{\"test\": \"$testdir\",  \"test_stages\": {"
    fi
    unset E4S_TEST_SETUP
    export SPACK_LOAD_RESULT=0
    source $cwd/setup.sh >&2
    _ret=$SPACK_LOAD_RESULT
    export E4S_TEST_SETUP=1
    #echo "SPACK LOAD RESULT RETURN: $_ret" >&2
            if [ $_ret -eq 215 ] ; then
             if [ $print_json = true ]; then
                         echo "\"setup\":\"missing\"}},"
             else
                 echo "Required Spack Packages ${yellow}Not Found${normal}" >&2
                 fi
             return $_ret
         fi
         if [ $_ret -ne 0 ] ; then

                 if [ $print_json = true ]; then
                 echo "\"setup\":\"fail\"}},"
             else
                 echo "Setup ${bold}failed${normal}" >&2
             fi
                 return $_ret
         fi


    if [ -e "$cwd/clean.sh" ] ; then
	    if [ $print_json = true ]; then
		    printf "\"clean\":"
	    else
            	echo "Cleaning $cwd" >&2
    	    fi
        ./clean.sh >& ./clean.log
        _ret=$?
        
        if [ $print_logs = true ]; then
             echo "---CLEANUP LOG---" >&2
             cat ./clean.log >&2
        fi
        if [ $_ret -eq 215 ] ; then
             if [ $print_json = true ]; then
		         echo "\"missing\"}},"
             else
                 echo "Required Spack Packages ${yellow}Not Found${normal}" >&2
	      fi
             return $_ret
         fi
         if [ $_ret -ne 0 ] ; then

   	         if [ $print_json = true ]; then
                   echo "\"fail\"}},"
                 else
                   echo "Clean ${bold}failed${normal}" >&2
     	         fi
                 return $_ret
          fi
     
	 if [ $print_json = true ]; then
                     printf "\"pass\","
         fi
     fi

     if [ -e "$cwd/compile.sh" ] ; then
	     if [ $print_json = true ]; then
             printf "\"compile\":"
    	 else
             echo "Compiling $cwd" >&2
         fi
            ./compile.sh >& ./compile.log
            _ret=$?
            if [ $print_logs = true ]; then
                 echo "---COMPILE LOG---" >&2
                 cat ./compile.log >&2
            fi

         if [ $_ret -eq 215 ] ; then
             if [ $print_json = true ]; then
                 echo "\"missing\"}},"
             else
                 echo "Required Spack Packages ${yellow}Not Found${normal}" >&2
	         fi
	         return $_ret
         fi
         if [ $_ret -ne 0 ] ; then
		 if [ $print_json = true ]; then
                     echo "\"fail\"}},"
                  else
                    echo "Compile ${bold}failed${normal}" >&2
                  fi
             return $_ret
          fi
	  if [ $print_json = true ]; then
                     printf "\"pass\","
          fi
      fi

      if [ $print_json = true ]; then
            printf "\"run\":"
      else
        echo "Running $cwd" >&2
      fi
        ./run.sh >& run.log
        _ret=$?
        if [ $print_logs = true ]; then
             echo "---RUN LOG---"
             cat ./run.log >&2
        fi

           if [ $_ret -eq 215 ] ; then
	     if [ $print_json = true ]; then
                     echo "\"missing\"}},"
             else
             echo "Required Spack Packages ${yellow}Not Found${normal}" >&2
             fi
             return $_ret
           fi
           if [ $_ret -ne 0 ] ; then
		   if [ $print_json = true ]; then
                     echo "\"fail\"}},"
                   else
                      echo "Run ${bold}failed${normal}" >&2
     		   fi
             return $_ret
           fi
	   if [ $print_json = true ]; then
                echo "\"pass\"}},"
          else
        
	   echo "${green}Success${normal}" >&2
	   fi
}

#set -x

iterate_directories $basedir
if [ $print_json = true ]; then
                echo "]"
fi
exit $final_ret
