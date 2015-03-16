#!/bin/sh

# Locations of commands used
PBSNODES=`which pbsnodes`
QSTAT=`which qstat`
AWK=/bin/awk

$PBSNODES -a | $AWK -v listflagged=$listflagged -v QSTAT=$QSTAT '
BEGIN {
	#
	# First get the list of jobids versus usernames from qstat
	#
	QSTAT = QSTAT " -r"			# Append -r flag (running jobs) to qstat.
	while ((QSTAT | getline) > 0) {		# Parse lines from qstat -r
		if (++line>5) {			# Skip first 5 header lines
			split($1,b,".")		# Jobid is b[1]
			match(b[1],/[0-9]+/)
			c = substr(b[1],RSTART, RLENGTH)
			#username[b[1]] = $2	# Username of this jobid
			username[c] = $2	# Username of this jobid
		}
	}
	close(QSTAT)
}
NF==1 { node=$1
        getline                         # Get the next input line
        while (NF >= 3) {               # Read a number of non-blank lines
                if ($1 == "np")            np[node] = $3
                else if ($1 == "properties")    properties[node] = $3
                else if ($1 == "ntype")         ntype[node] = $3
                else if ($1 == "jobs") {
			 split($0,a,",")
			 for(field in a){
				split(a[field],b,"/")
				split(b[2],C,".")
				match(C[1],/[0-9]+/)
				d = substr(C[1],RSTART, RLENGTH)
				user=username[d]
				jobs[user]+=1
				total += 1
			}
        	}
                getline                 # Get the next input line
	}	
}
END{
	for(user in jobs) {
		j=jobs[user]
		printf("%8s\t%4d\n",user,j)|"sort -nrk 2"
	}
	printf("\033[40;31m%8s\t%4d/1412\033[0m\n", "total", total)
}
'
