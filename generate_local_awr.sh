generate_local_awr()
{
if [ $# -ne 4 ]; then
	echo Usage: $0 dbid dbname beginsnapid endsnapid
	exit
fi
l_dbid=${1}
l_dbname=${2}
l_beginsnapid=${3}
l_first=${l_beginsnapid}
l_next=0
l_endsnapid=${4}
while (( $l_first < $l_endsnapid ))
do
l_next=$(($l_first+1))
echo $l_dbid $l_dbname $l_first $l_next
sqlplus / as sysdba @generate_local_awr.sql $l_dbid $l_dbname $l_first $l_next
l_first=${l_next}
done
}

