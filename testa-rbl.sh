#!/bin/bash

#PS4='File=$BASH_SOURCE: LineNo=$LINENO: '
#set -x

MODO=$1
IPHOST=$2

if [ $# -ne 2 ] || !([[ "$MODO" =~ ^(-s|-d|-r) ]]) || !([[ "$IPHOST" =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ ]]) ; then
	echo "$0 <-d|-r|-s> <IP|fqdn>"
	echo -e "Informe o modo.\n\t-d para detalhado\n\t-r para resumido, apenas quantitativo\n\t-s para modo silencioso\n"
	echo "Informe o ip ou fqdn do servidor a ser verificado"
	exit -1
fi

source /opt/rbl/rbl.conf
OUTPUTTEMP=/tmp/out1.tmp
OUTPUTTEMP1=/tmp/out2.tmp

date | tee $OUTPUTTEMP $OUTPUTTEMP1 > /dev/null

#gera lista de rbl
$(dirname $0)/gera-rbl-servers.sh $ARQSERVERS >> $OUTPUTTEMP

if [ -n "$(echo $IPHOST|egrep '[a-zA-Z]')" ]; then # usuario informou hostname
	IP_SERV=`dig @$DNS $IPHOST +short`
	IP_REV=`echo $IP_SERV | awk -F "." '{print $4"."$3"."$2"."$1}'`
else
	IP_REV=`echo $IPHOST | awk -F "." '{print $4"."$3"."$2"."$1}'`
fi

egrep -v -f $ARQIGNORE $ARQSERVERS | egrep -v '^$|^[!-@]' > $TMP

C=0

while read SERVIDOR; do
{
	RESP="$(dig @$DNS $IP_REV.$SERVIDOR +short A 2>&1)"
	if [ "$?" -eq 0 ]; then
		if [ -z "$RESP" ]; then
			echo "$SERVIDOR: OK" >> $OUTPUTTEMP
		else
			RESP="$(dig @$DNS $IP_REV.$SERVIDOR +short A 2>&1)"
			echo "$SERVIDOR: LISTADO" | tee -a $OUTPUTTEMP $OUTPUTTEMP1 > /dev/null
			echo "$RESP" | tee -a $OUTPUTTEMP $OUTPUTTEMP1 > /dev/null
			let C++
		fi
	fi
}
done < $TMP

echo Total de RBLs Listadas: $C >> $OUTPUTTEMP
if [ "$MODO" = "-d" ]; then
	cat $OUTPUTTEMP
elif [ "$MODO" = "-r" ]  ; then
	echo $C
fi

mv -f $OUTPUTTEMP  /tmp/rbldetalhado.txt

if [ $C -eq 0 ]; then
	rm $OUTPUTTEMP1 2> /dev/null
	rm /tmp/rbllistado.txt 2> /dev/null
else
	mv -f $OUTPUTTEMP1 /tmp/rbllistado.txt
fi

exit $C
