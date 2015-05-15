#!/bin/sh
i=1
# Locations of commands used
PBSNODES=`which pbsnodes`
QSTAT=`which qstat`
AWK=/bin/awk
echo -e "there are total 11 nodes in the system 
-----------------------------------------------------------"
echo -e "\e[40;35m job-exclusive \e[40;32m  free \e[40;31m  down \e[40;34m  partlyused \e[40;33m offline \e[40;36m unknown \e[m "
echo -e "---------------------------------------------------------------"

$PBSNODES -a | $AWK -v listflagged=$listflagged -v QSTAT=$QSTAT '
BEGIN {
	#
	# First get the list of jobids versus usernames from qstat
	#
	QSTAT = QSTAT " -r"			# Append -r flag (running jobs) to qstat.
	while ((QSTAT | getline) > 0) {		# Parse lines from qstat -r
		if (++line>5) {			# Skip first 5 header lines
			split($1,b,".")		# Jobid is b[1]
			username[b[1]] = $2	# Username of this jobid
		}
	}
	close(QSTAT)
#	OFS=""
#	ORS=""
	down=0
	jobexec=0
	free=0
	partused=0
	offfline=0
	unkown=0
	i=1
}
NF==1 {	node=$1				# 1st line is nodename
	nodename[node] = node		# Node name
	getline				# Get the next input line

	numcpus[node] = 0		#Number of cpus had used
	ncpu[node] = 0			#Number of cpus the node has
	coler[node]=0
	while (NF >= 3) {		# Read a number of non-blank lines
		if ($1 == "np")		np[node] = $3
		else if ($1 == "jobs"){		
			split($3,a,",")
			numcpus[node] = length(a)
			for(us in a){
				if(a[us] ~ /-/){
					split(a[us],c,"-")
					split(c[2],d,"/")
					num = d[1] - c[1]
					numcpus[node] += num
				}
			}
		}
		else if ($1 == "state") {
                        if ($3 == "job-exclusive")                      state[node] = "excl"
                        else if ($3 == "job-exclusive,busy")            state[node] = "busy"
                        else if ($3 == "busy")                          state[node] = "busy"
                        else if ($3 == "free")                          state[node] = "free"
                        else if ($3 == "offline")                       state[node] = "offl"
                        else if ($3 == "offline,job-exclusive")         state[node] = "offl"
                        else if ($3 == "offline,job-exclusive,busy")    state[node] = "offl"
                        else if ($3 == "down")                          state[node] = "down"
                        else if ($3 == "down,offline")                  state[node] = "down"
                        else if ($3 == "down,job-exclusive")            state[node] = "down"
                        else if ($3 == "down,offline,job-exclusive")    state[node] = "down"
                        else if ($3 == "down,offline,busy")             state[node] = "down"
                        else if ($3 == "down,offline,job-exclusive,busy")       state[node] = "down"
                        else if ($3 == "UNKN")                          state[node] = "UNKN"
			if(state[node] == "busy"){
				jobexec++
				coler[node]=35
			}else if (state[node] == "free"){
				free++
				coler[node]=34
			}else if(state[node] == "excl"){
				partused++
				coler[node]=35
			}else if(state[node] == "offl"){
				offline++
				coler[node]=33
			}else if(state[node] == "UNKN"){
				unknown++
				coler[node]=36
			}else if(state[node] == "down"){
				down++
				coler[node]=31
			}
                }
		getline			# Get the next input line
	}
	print node,numcpus[node],np[node],coler[node]
}'|while read node numcpus np coler
do
#echo $node $numcpus $np $coler
if [ $(($i%5)) = 0 ];then
	echo -e "\e[40;${coler}m ${node}-${numcpus}/${np} \e[m"
else
	echo -e "\e[40;${coler}m ${node}-${numcpus}/${np} \e[m\c"
fi	
i=$(($i+1))
done
echo
