import os
import sys
import argparse
import subprocess
import datetime
import time
import multiprocessing

# Initialize global variables
final_ret = 0
print_json = False
print_logs = False
basedir = 'validation_tests'
e4s_print_color = True
skip_to = ""
test_only = ""
skip_if = ""
testtime = datetime.datetime.now().strftime("%Y-%m-%d_%H:%M:%S")

# Function to execute shell scripts and handle errors
def run_command(command):
    """ Run a shell command and return the output and status code """
    #result = subprocess.run(command, shell=True)#,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    result = subprocess.run(command, shell=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = result.stdout.decode().strip()
    return result.returncode, output

def async_run_command(command,cwd):
    """ Run a shell command and return the output and status code """
    #result = subprocess.run(command, shell=True)#,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    os.chdir(cwd)
    result = subprocess.run(command, shell=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = result.stdout.decode().strip()
    return result.returncode, output


# Function to iterate through directories recursively
def iterate_directories(testdir):
    final_ret = 0
    return_string = ""
    original_dir = os.getcwd()
    if os.path.isdir(testdir):
        os.chdir(testdir)
        os.environ['testdir']=os.path.basename(testdir)
        cwd = os.getcwd()
        if print_json != True:
            return_string += "===\n" + testdir + "\n"

        # Check if there is a run.sh script to execute
        if os.path.exists(os.path.join(cwd, "run.sh")):
            ret_code, itout = run_command('~/testsuite/iterate_files.sh')
            return_string += itout
            print(return_string)
            if ret_code != 0:
                final_ret += 1
        else:
            print(return_string)
            files = sorted(os.listdir("."))
            # Iterate through subdirectories
            for d in files:
                if os.path.isdir(d):
                    if skip_to and d < skip_to:
                        continue
                    if skip_if and skip_if in d:
                        continue
                    if test_only and os.path.basename(d) in test_only:
                        continue
                    iterate_directories(d)
        os.chdir("..")
    return final_ret

# Function to iterate through directories recursively
def parallel_iterate_directories(testdir, Processes=4):
    results = []
    pool = multiprocessing.Pool(processes=Processes)

    final_ret = 0
    os.environ['testdir']=os.path.basename(testdir)
    original_dir = os.getcwd()
    
    if not os.path.isdir(testdir):
        return final_ret

    # Use a stack to simulate recursion
    stack = [testdir]

    while stack:
        current_dir = stack.pop(0)
        os.chdir(current_dir) 
        current_dir = os.getcwd()
        # Check if there is a run.sh script to execute
        if os.path.exists(os.path.join(current_dir, "run.sh")):
            results.append(pool.apply_async(async_run_command,  ('~/testsuite/iterate_files.sh', current_dir)))
        else:
            results.append("===\n" + os.path.basename(current_dir))
            files = sorted(os.listdir("."))
            # Iterate through subdirectories
            for d in files:
                if os.path.isdir(d):
                    if skip_to and d < skip_to:
                        continue
                    if skip_if and skip_if in d:
                        continue
                    if test_only and os.path.basename(d) in test_only:
                        continue
                    # Push the directory onto the stack instead of recursive call
                    stack.append(os.path.join(current_dir, d))


    for r in results:
        if type(r) != type(""):
            print(r.get()[1])
        else:
            print(r)
    return final_ret
# Main function to parse arguments and execute the script
def main():
    global print_json, print_logs, basedir, e4s_print_color, skip_to, test_only, skip_if

    # Argument parsing
    parser = argparse.ArgumentParser(description='Run all tests in the specified directory.')
    parser.add_argument('directory', nargs='?', default='validation_tests', help='Test directory to use')
    parser.add_argument('--json', action='store_true', help='Print JSON output.')
    parser.add_argument('--print-logs', action='store_true', help='Print all logs.')
    parser.add_argument('--settings', type=str, help='Path to settings file')
    parser.add_argument('--color-off', action='store_false', dest='e4s_print_color', help='Disable color output.')
    parser.add_argument('--skip-to', type=str, help='Skip to specified test.')
    parser.add_argument('--skip-if', type=str, help='Skip tests with the given substring in the directory name.')
    parser.add_argument('--test-only', type=str, help='Run only specified tests.')
    args = parser.parse_args()

    # Apply arguments to global variables
    basedir = args.directory
    print_json = args.json
    print_logs = args.print_logs
    e4s_print_color = args.e4s_print_color
    skip_to = args.skip_to or ""
    skip_if = args.skip_if or ""
    test_only = args.test_only or ""

    # Begin JSON output if needed
    if print_json:
        print("[",end="")

    os.environ['print_logs'] = str(print_logs).lower()
    os.environ['print_json'] = str(print_json).lower()
    os.environ['e4s_print_color'] = str(e4s_print_color).lower()

    # Call the main directory iteration function
    parallel_iterate_directories(basedir)

 #   results = []
  #  directories = sorted(os.listdir(basedir))
    #print(directories)

   # pool = multiprocessing.Pool(processes=4)
  #  for i, d in enumerate(directories):
      #  path = os.path.join(basedir,d)
     #   results.append(pool.apply_async(iterate_directories, (path,)))
    #    #results.append(pool.apply_async(temp, (i,)))
   #     
  #  pool.close()
    
    # Collect results and print in order
   # for result in results:
    #    result.get()

    # End JSON output if needed
    if print_json:
        print("{}]",end="")

    # Exit with the final return code
    sys.exit(final_ret)

# Execute the main function if the script is run directly
if __name__ == "__main__":
    main()

