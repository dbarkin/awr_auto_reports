#Content of generate_compare_awr.sh

generate_compare_awr()
{
if [ $# -ne 6 ]; then
    echo Error! Wrong number of parameters
    echo Error! Usage: $0 1strun_dbid 1strun_beginsnapid 1strun_endsnapid 2strun_dbid 2strun_beginsnapid 2strun_endsnapid  
    echo Error! Note: dbid should the the value stored in AWR repository database  
    exit
fi

l_1_dbid=${1}
l_1_beginsnapid=${2}
l_1_first=${l_1_beginsnapid}
l_1_next=0
l_1_endsnapid=${3}
l_2_dbid=${4}
l_2_beginsnapid=${5}
l_2_first=${l_2_beginsnapid}
l_2_next=0
l_2_endsnapid=${6}

if [ $(($l_1_endsnapid-$l_1_beginsnapid)) -ne $(($l_2_endsnapid-$l_2_beginsnapid)) ]; then
    echo Warning! Number of snapshots in first run and second run is not the same!
    echo Warning! First run:  $(($l_1_endsnapid-$l_1_beginsnapid))
    echo Warning! Second run: $(($l_2_endsnapid-$l_2_beginsnapid))	 
    echo Warning! Will compare only snapshots ${l_1_beginsnapid}:${l_1_endsnapid} to ${l_2_beginsnapid}:${l_2_endsnapid} 
    l_exit_early=1
fi

sqlplus / as sysdba @generate_compare_awr.sql ${l_1_dbid} ${l_1_beginsnapid} ${l_1_endsnapid} ${l_2_dbid} ${l_2_beginsnapid} ${l_2_endsnapid}

if [ $l_exit_early -eq 1 ];then 
    exit
fi

while (( $l_1_first < $l_1_endsnapid ))
do
l_1_next=$(($l_1_first+1))
l_2_next=$(($l_2_first+1))
echo DB1 $l_1_dbid $l_1_dbname $l_1_first $l_1_next
echo DB2 $l_2_dbid $l_2_dbname $l_2_first $l_2_next
sqlplus / as sysdba @generate_compare_awr.sql $l_1_dbid $l_1_first $l_1_next $l_2_dbid $l_2_first $l_2_next
l_1_first=${l_1_next}
l_2_first=${l_2_next}
done
}
