#!/bin/bash         
PATH=$PATH:/usr/sbin
MAXDAYS=15  
                                                             
MYSQLDIR="/var/lib/mysql"
BACKUPDIR="/var/backups/mysql"
EXCEPTIONS="mysql performance_schema lost+found"
EXCEPTIONS="performance_schema lost+found"
DEFOPTS="--routines"

function backup ()
{               
    COLLATION=$(mysql -e "SELECT @@collation_database AS Collation FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$D';" -s -N)
    case $D in                            
        "mysql")
            OPTS="--events"
            ;;
        *)
            #OPTS="--default-character-set=utf8mb4 $DEFOPTS"
            OPTS="--default-character-set=${COLLATION%%_*} $DEFOPTS"
            ;;
    esac
    echo "Backup de $D ($OPTS)"
    mkdir -p $BACKUPDIR/$D
    mysqldump $OPTS $D > $BACKUPDIR/${D}/${D}_${FECHA}.sql
}

function cleanup ()
{
    F=$(find $BACKUPDIR -type f -mtime +${1} -name "*.sql")
    echo "Borrando $F"
    rm $F 2> /dev/null
}

FECHA=$(date +"%Y%m%d")
logger Iniciando backup de mysql
if [[ $1 ]];then
    DBS=$@
else
    DBS=$(find $MYSQLDIR/* -maxdepth 1 -type d)
fi

    for DB in $DBS;do
        D=$(basename $DB)
        OK=1
        for E in $EXCEPTIONS;do
            if [[ $E == $D ]];then
                OK=0
            fi
        done
        if [[ $OK == 1 ]];then
            backup $D
        else
            echo "NO backup $D"
        fi
    done


cleanup $MAXDAYS
logger Backup de mysql finalizado
