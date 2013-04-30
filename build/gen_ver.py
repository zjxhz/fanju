from subprocess import check_output, call
import argparse
import sys

parser = argparse.ArgumentParser()
# parser.add_argument("ver",type=string)
parser.add_argument("--out")
args = parser.parse_args()
# ver = args.ver 
# if ver:
#     new_version = ver
# else:
out = args.out
current_ver=check_output(["agvtool","vers","-terse"])
build_number=current_ver.split(".")[-1].strip()
build_int = int(build_number)
next_build = build_int + 1
last_dot_index=current_ver.rfind(".")
new_version=current_ver[0:last_dot_index+1] + str(next_build)

f=open(out,"w")
f.write("ver=" + new_version)
f.close()
# call(["agvtool", "new_version", "-all", new_version]) #this line cause encoding error, so not updated for now

