#!/bin/sh

# Configure backup location and folder list

SCRIPT_DIR=/root/cron_scripts
BACKUPS="/var/confluence/backups"
CONFIG=${1:-/root/cron_scripts/confluence-backup.conf}
EMAILFILEPATH=${BACKUPS}"/Daily_File_Backup_Report.log"

set -x

# Read list of folders from config file

if [ ! -f $CONFIG ];
then
  echo "Confluence Backup Config file ($CONFIG) doesn't exist."
  exit
fi

# Loop through folders list
# rsync does incremental backups

for FOLDER in $(< $CONFIG);
do
  DATE=`date "+%Y-%m-%dT%H_%M_%S"` >> $EMAILFILEPATH
  rsync -azPpq --delete --link-dest=$BACKUPS/$FOLDERcurrent $FOLDER $BACKUPS/incomplete-$DATE

# Rsync is complete. Move backups to dated folder.

  mkdir -p $BACKUPS/completed
  mv $BACKUPS/incomplete-$DATE $BACKUPS/completed/$DATE
  rm -f $BACKUPS/incomplete-$DATE 
  ln -s $BACKUPS/completed/$DATE $BACKUPS$FOLDERcurrent 

done

# Send notification of backup status

/bin/mail -s "Daily Backup for Confluence Service" meberger@illinois.edu < $EMAILFILEPATH

echo "Confluence filesystem backup complete."

# Backup Confluence database.

# mysql database backups

BACKUP_DIR=$BACKUPS/data
DBCONFIG=${1:-/root/cron_scripts/confluence-db.conf}
mkdir -p $BACKUP_DIR

# Initalize static parameters
SCRIPT_DIR=/root/cron_files
USER=confluence_wiki_user
CFPASSFILE=/etc/confluence/backup/.cfpass
EMAILFILEPATH=${SCRIPT_DIR}"/Daily_Data_Backup_Report.log"
DATABASEFILEPATH=${SCRIPT_DIR}"/databases.txt"
DAYS_KEEP=7
#
cd ${SCRIPT_DIR}

# DATE=`date "+%Y-%m-%dT%H_%M_%S"`

# Read list of folders from config file

if [ ! -f $DBCONFIG ];
then
  echo "Confluence Database Backup Config file ($DBCONFIG) doesn't exist."
  exit
fi

# loop through databases

for DATABASE in $(< $DBCONFIG);
do
  DATE=`date "+%Y-%m-%dT%H_%M_%S"`
#
  /usr/local/mysql/bin/mysqldump --hex-blob --routines --triggers --default-character-set=utf8 ncsa_wiki > $BACKUP_DIR.dump`date +%d%b%y | tr A-Z a-z`.sql

    # Check for success

	if [ "$?" -eq 0 ]
	then
		# Verify that backup file was created

		FILENAME=${BACKUP_DIR}/${DATABASE}-${DATE}.sql
		if [ -e ${BACKUP_DIR}/${DATABASE}-${DATE}.sql ]
		then
			# Log the file information

			FILESIZE=$( stat -c%s "$FILENAME")
			echo "The file $FILENAME with size $FILESIZE (byte) was created." >> $EMAILFILEPATH
		else
			echo "The file $FILENAME failed to be created" >> $EMAILFILEPATH
		fi
	else 
		echo "Fail to backup the ${DB} database " >> $EMAILFILEPATH	
	fi

done

echo "Confluence database backup complete."

### end of the file ###
exit
