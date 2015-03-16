#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my ($node , $ppn , $dir , $argu) = ('1' , '1' , $ENV{'PWD'} , '');
my ($script , @argu , $help , $name , $line , $N);
GetOptions(
	'node=s'	=>	\$node,
	'ppn=s'		=>	\$ppn,
	'script=s'	=>	\$script,
	'line=s'	=>	\$line,
	'arguments=s'	=>	\@argu,
	'help+'		=>	\$help,
	'jobs=s'	=>	\$N,
);

if ((!$script && !$line) || $help){
	&help;
	exit;
}elsif ($script && $line){
	print "$script and $line are not presence in the same time";
	exit;
}elsif ($script){
	($name) = ($script =~ /\/*([^\/]+)\.\w+$/);
}elsif ($line){
	($name) = ($line =~ /^ *([^\s]+) */);
	($name) = ($name =~ /\/*([^\/]+)$/);
	$script = $name . '.sh';
}

$script = &input($script);

#$name = $name . '_' . join(':' , @argu) if @argu > 0;
if (@argu){
	$argu = '-v ';
	for my $n (0..$#argu){
		$argu .= "pbs".($n+1)."=".$argu[$n].",";
	}
	$argu =~ s/,$//;
}
$name = $N if $N;
my $command = "qsub -N $name -j oe -l nodes=$node:ppn=$ppn -q batch -V -S /bin/bash -o $dir/PBS.out $argu $script";
print readpipe($command);

unlink($script) if $script =~ /^\.\.\./;

sub input{
	my $script = $_[0];
	my @file;
	if ($line){
		@file = split /;/ , $line;
	}else{
		open IN , "$script" or print("\n\t$script : No such file\n\n") , exit;
		@file = <IN>;
		close IN;
	}
	$script =~ /\/*([^\/]+\.\w+)$/;
	$script = '...' . $1;
	open OUT , ">$script";
	print OUT 'cd $PBS_O_WORKDIR' , "\n";
	print OUT "$_\n" for @file;
	close OUT;
	return $script;
}
sub help{
	print <<"	END!";
	

	Usage:	pbssubmit [-j job name] [-s shell script] [-l command] [-n node] [-p ppn] [[-a pbs1] [-a pbs2] ......] 


	END!
	
}
