#!/bin/bash

# Obtem a lista de servidores utilizados pelo site http://multirbl.valli.org/
# filtra as linhas entre a ocorrencia das palavras alive e dead
# transforma as tags de tabela em campos no formato csv
# filtra apenas aquelas linhas cujos servidores respondem requisicoes sobre o ip na versao 4
# gera um arquivo final contendo apenas o endereco de cada servidor

#obtem variaveis de ambiente
source /opt/rbl/rbl.conf

[ -n "$1" ] && ARQSERVERS="$1"

echo "# $(date)" > /tmp/a.tmp

curl --connect-timeout 30 -o /tmp/lista.tmp 2>/dev/null 'http://multirbl.valli.org/list/' 2>/dev/null
ESTADO=$?

if [ $ESTADO -eq 0 ]; then
	sed -n -e '/alive/,/dead/{ /alive/d; /dead/d; p; }' /tmp/lista.tmp | sed -n -e 's/<tr><td>//g; s/<\/td><td>/\,/g; s/<\/td><\/tr>//g; p' | egrep ',ipv4,' | egrep ',b,' | awk -F ',' '{print $3}' >> /tmp/a.tmp
	[ -d "$ARQ" ] && cp $ARQSERVERS $ARQSERVERS.old
	cp /tmp/a.tmp $ARQSERVERS
else
	echo "Não foi possível atualizar a lista de servidores de rbl."
	exit $ESTADO
fi


