#!/bin/sh
#
# Stop Confluence service

/etc/init.d/confluence stop

# Configure backup location and folder list

SCRIPT_DIR=/etc/confluence/backup
BACKUPS="/backups"
CONFIG=${1:-/etc/confluence/backup/confluence-backup.conf}
EMAILFILEPATH=${SCRIPT_DIR}"/Daily_File_Backup_Report.log"

# Read list of folders from config file

if [ ! -f $CONFIG ];
then
  echo "Confluence Backup Config file ($CONFIG) doesn't exist."
  exit
fi

cp /dev/null $EMAILFILEPATH
echo "------------------------------------------------------------------------------------" >> $EMAILFILEPATH

# Loop through folders list
# rsync does incremental backups

for FOLDER in $(< $CONFIG);
do
# debug information
  echo "Backup $FOLDER" >> $EMAILFILEPATH
  DATE=`date "+%Y-%m-%dT%H_%M_%S"` >> $EMAILFILEPATH
  echo "To $BACKUPS-$DATE" >> $EMAILFILEPATH
  echo "Rsync -azPpq --delete --link-dest=$BACKUPS/$FOLDERcurrent $FOLDER $BACKUPS/incomplete-$DATE" >> $EMAILFILEPATH

  rsync -azPpq --delete --link-dest=$BACKUPS/$FOLDERcurrent $FOLDER $BACKUPS/incomplete-$DATE

# Rsync is complete. Move backups to dated folder.

echo "------------------------------------------------------------------------------------" >> $EMAILFILEPATH

# debug information
  echo "Move $BACKUPS/incomplete-$DATE $BACKUPS/current/$DATE" >> $EMAILFILEPATH
  echo "Delete $BACKUPS/incomplete-$DATE" >> $EMAILFILEPATH
  echo "Link $BACKUPScompleted/$DATE $BACKUPS$FOLDERcurrent" >> $EMAILFILEPATH

  mv $BACKUPS/incomplete-$DATE $BACKUPS/completed/$DATE
  rm -f $BACKUPS/incomplete-$DATE 
  ln -s $BACKUPS/completed/$DATE $BACKUPS$FOLDERcurrent 

done

# Restart Confluence service

echo "------------------------------------------------------------------------------------" >> $EMAILFILEPATH
echo "Starting Confluence service." >> $EMAILFILEPATH
/etc/init.d/confluence start

# Send notification of backup status

/bin/mail -s "Daily Backup for Confluence Service" meberger@illinois.edu < $EMAILFILEPATH

echo "Confluence filesystem backup complete."

# Backup Confluence database.

# mysql database backups
# Can restore individual databases provided database is created and all users exist.

BACKUP_DIR=$BACKUPS/data
DBCONFIG=${1:-/etc/confluence/backup/conf-db.conf}

# Initalize static parameters
SCRIPT_DIR=/etc/confluence/backup
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

cp /dev/null $EMAILFILEPATH
echo "------------------------------------------------------------------------------------" >> $EMAILFILEPATH
echo "Password is in $CFPASSFILE" >> $EMAILFILEPATH

# loop through databases

for DATABASE in $(< $DBCONFIG);
do
# debug information
  echo "Backup Database $DATABASE" >> $EMAILFILEPATH
  DATE=`date "+%Y-%m-%dT%H_%M_%S"`
  echo "User is $USER" >> $EMAILFILEPATH
  echo "$CFPASSFILE has the password." >> $EMAILFILEPATH
  echo "To ${BACKUP_DIR}/${DATABASE}-${DATE}.sql" >> $EMAILFILEPATH
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

	echo "------------------------------------------------------------------------------------" >> $EMAILFILEPATH

done

echo "------------------------------------------------------------------------------------" >> $EMAILFILEPATH

echo "Confluence database backup complete."

# Send notification of backup status

/bin/mail -s "Daily Backup for Database Service" meberger@illinois.edu <  $EMAILFILEPATH

### end of the file ###
exit

