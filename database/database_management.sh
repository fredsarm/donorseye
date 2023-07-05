#!/bin/bash

# Check if 'dialog' is installed
if ! command -v dialog >/dev/null 2>&1; then
    echo "'dialog' is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y dialog
fi

# Temporary dialog configuration file
export DIALOGRC=$(mktemp)
cat > "$DIALOGRC" << 'EOL'
screen_color = (WHITE, BLACK, ON)
EOL

trap 'rm -f "$DIALOGRC" 2>/dev/null' EXIT

restore_database() {
    set +e

    # Set up temporary dialog configuration file
    export DIALOGRC=$(mktemp)
    cat > "$DIALOGRC" << 'EOL'
screen_color = (WHITE,BLACK,ON)
EOL

    # Capture and store user input
    USER_INPUT=$(dialog --title "Database Backup Configuration" --form "Please fill in the following fields:" 20 60 0 \
        "Host: " 1 1 "$HOST" 1 25 25 0 \
        "Username: " 2 1 "$USERNAME" 2 25 25 0 \
        "Database to Restore: " 3 1 "$DATABASE_TO_RESTORE" 3 25 25 0 \
        2>&1 >/dev/tty)

    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        IFS=$'\n' USER=($(echo "$USER_INPUT"))
        HOST=${USER[0]}
        USERNAME=${USER[1]}
        DATABASE_TO_RESTORE=${USER[2]}

        # Store the latest values in a file
        echo -e "$HOST\n$USERNAME\n$DATABASE_TO_RESTORE\n\n" > ./latest_values.txt
        
        # Prompt for the password
        PASSWORD=$(dialog --passwordbox "Enter your database role password:" 10 30 3>&1 1>&2 2>&3 3>&-)
        
        # Validate password input
        if [ -z "$PASSWORD" ]; then
            dialog --title "Error" --msgbox "Password is required!" 10 30
            clear
            exit 1
        fi

        # Validate database existence and create a preliminary backup
        DATABASE_EXISTS=$(PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USERNAME" -d "$DATABASE_TO_RESTORE" -t -c "SELECT 1 FROM pg_database WHERE datname='$DATABASE_TO_RESTORE'" | xargs)
        if [ "$DATABASE_EXISTS" == "1" ]; then
            RESTORE_LOG_FILE="./log/restore_log_$(date +%Y%m%d%H%M%S).log"
            BACKUP_FILE="./files/db_before_restore_$(date +%Y%m%d%H%M%S).sql"
            echo "Creating a preliminary backup of the existing database..." >> "$RESTORE_LOG_FILE"
            
            # Execute the backup
            if PGPASSWORD="$PASSWORD" pg_dump -h "$HOST" -U "$USERNAME" -d "$DATABASE_TO_RESTORE" -F p --encoding "UTF8" --section=pre-data --section=data --section=post-data --create --verbose --clean --no-owner --no-acl -f "$BACKUP_FILE" >> "$RESTORE_LOG_FILE" 2>&1; then
                OUTPUT="Preliminary backup created successfully."
                echo "$OUTPUT" >> "$RESTORE_LOG_FILE"
                
                # Provide the user with an option to select the backup file to restore
#               RESTORE_FILE=$(dialog --title "Select a Backup File to Restore" --fselect ./db.sql 10 60 3>&1 1>&2 2>&3 3>&-)
                RESTORE_FILE="./db.sql"
                # Validate the backup file selection
                if [ -z "$RESTORE_FILE" ]; then
                    dialog --title "Error" --msgbox "No backup file selected!" 10 30
                    clear
                    exit 1
                fi

                # Execute the restore
                echo "Restoring the selected database backup..." >> "$RESTORE_LOG_FILE"

                if PGPASSWORD="$PASSWORD" psql -h $HOST -U $USERNAME -d "postgres" -c "SELECT pg_terminate_backend (pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DATABASE_TO_RESTORE';" >> $RESTORE_LOG_FILE 2>&1; then
                    echo "Database successfully stopped." >> $RESTORE_LOG_FILE
                    if PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USERNAME" -d "postgres" -f "$RESTORE_FILE" >> "$RESTORE_LOG_FILE" 2>&1; then
                        OUTPUT="Database restored successfully!"
                        dialog --title "Success" --msgbox "$OUTPUT" 10 30
                        echo "$OUTPUT" >> "$RESTORE_LOG_FILE"
                    else
                        OUTPUT="Failed to restore database. Please check the log file for details."
                        dialog --title "Error" --msgbox "$OUTPUT" 10 30
                        echo "$OUTPUT" >> "$RESTORE_LOG_FILE"
                    fi
                else
                    OUTPUT="Failed to stop the database. Restore failed."
                    echo "$OUTPUT" >> $RESTORE_LOG_FILE
                    dialog --title "Stop Database Result" --msgbox "$OUTPUT" 10 40
                    clear
                    exit 1
                fi
            else
                dialog --title "Error" --msgbox "Failed to create a preliminary backup. Please check the log file for details." 10 30
            fi
        else
            dialog --title "Error" --msgbox "Error while testing if database exists. Check the log for a better probing. $" 20 60
        fi
    else
        dialog --title "Error" --msgbox "User input is required!" 10 30
    fi
    
    set -e
}

create_backup() {
    set +e
    export DIALOGRC=$(mktemp)
    cat > "$DIALOGRC" << 'EOL'
screen_color = (WHITE,BLACK,ON)
EOL

    trap 'rm -f "$DIALOGRC" 2>/dev/null' EXIT

    USER_INPUT=$(dialog --title "Database Backup Configuration" --form "Fill out the following fields." 20 60 0 \
        "Host: " 1 1 "$HOST" 1 25 25 0 \
        "Username: " 2 1 "$USERNAME" 2 25 25 0 \
        "Database to Backup: " 3 1 "$DATABASE_TO_BACKUP" 3 25 25 0 \
        "Database to Login: " 4 1 "$DATABASE_TO_LOGIN" 4 25 25 0 \
        2>&1 >/dev/tty)

    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        IFS=$'\n' USER=($(echo "$USER_INPUT"))
        HOST=${USER[0]}
        USERNAME=${USER[1]}
        DATABASE_TO_BACKUP=${USER[2]}
        DATABASE_TO_LOGIN=${USER[3]}
        echo -e "$HOST\n$USERNAME\n\n$DATABASE_TO_BACKUP\n$DATABASE_TO_LOGIN" > ./latest_values.txt

        PASSWORD=$(dialog --passwordbox "Enter your Role Password:" 10 30 3>&1 1>&2 2>&3 3>&-)
        # Check if the password is empty
        if [ -z "$PASSWORD" ]; then
            dialog --title "Error" --msgbox "You should type your password!" 10 30
            clear
            exit 1
        fi


BACKUP_LOG_FILE="./log/backup_log_$(date +%Y%m%d%H%M%S).log"
BACKUP_FILE="./files/db_backup_$(date +%Y%m%d%H%M%S).sql"
echo "Creating a backup..." > "$BACKUP_LOG_FILE"

if PGPASSWORD="$PASSWORD" pg_dump -h "$HOST" -U "$USERNAME" -d "$DATABASE_TO_BACKUP" -F p --encoding "UTF8" --section=pre-data --section=data --section=post-data --create --verbose --clean --no-owner --no-acl -f "$BACKUP_FILE" >> "$BACKUP_LOG_FILE" 2>&1; then
    OUTPUT="Backup created successfully."
    dialog --title "Backup Result" --msgbox "$OUTPUT" 10 40
    echo "$OUTPUT" >> "$BACKUP_LOG_FILE"
    clear
    exit 1
else
    OUTPUT="Backup failed."
    dialog --title "Backup Result" --msgbox "$OUTPUT" 10 40
    echo "$OUTPUT" >> "$BACKUP_LOG_FILE"
    clear
    exit 1
fi

# Display the output in a dialog box
    else
        echo "User clicked Cancel."
        clear
        exit 1
    fi

    set -e
}

create_role() {
    set +e

    export DIALOGRC=$(mktemp)
    cat > "$DIALOGRC" << 'EOL'
screen_color = (WHITE,BLACK,ON)
EOL

    trap 'rm -f "$DIALOGRC" 2>/dev/null' EXIT

    USER_INPUT=$(dialog --title "Database Role Creation" --form "\n
The role will have the permission to create databases. \n
You'll have to enter root password." 10 60 0 \
        "Role Name : " 1 1 "" 1 12 60 0 \
        2>&1 >/dev/tty)

    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        IFS=$'\n' USER=($(echo "$USER_INPUT"))
        USERNAME=${USER[0]}
    else
        dialog --title "" --msgbox "Operation Canceled." 6 25
        clear
        exit 1
    fi
    CREATE_ROLE_LOG_FILE="./log/create_role_log_$(date +%Y%m%d%H%M%S).log"

    echo "Creating role: $USERNAME" > $CREATE_ROLE_LOG_FILE 2>&1
    if  sudo su -c "psql -c \"CREATE USER $USERNAME CREATEDB;\"" - postgres >> $CREATE_ROLE_LOG_FILE 2>&1; then
        echo "Role created successfully." >> $CREATE_ROLE_LOG_FILE
        dialog --title "Role Creation Result" --msgbox "Role $USERNAME Created Successfuly." 10 40
        clear
        exit 1
    else
        echo "Failed to create role." >> $CREATE_ROLE_LOG_FILE
        dialog --title "Role Creation Result" --msgbox "Failed to create role." 10 30
        clear
        exit 1
    fi
    set -e
}

while true; do

if [ -f ./latest_values.txt ]; then
    readarray -t LATEST_VALUES < ./latest_values.txt
    HOST=${LATEST_VALUES[0]}
    USERNAME=${LATEST_VALUES[1]}
    DATABASE_TO_RESTORE=${LATEST_VALUES[2]}
    DATABASE_TO_BACKUP=${LATEST_VALUES[3]}
    DATABASE_TO_LOGIN=${LATEST_VALUES[4]}
fi

    CHOICE=$(dialog --title "Database Management" --menu "" 15 60 5 \
        "1" "Create Role" \
        "2" "Backup Database" \
        "3" "Restore Database" \
        2>&1 >/dev/tty)
    
    # Check exit status
    if [ $? -eq 0 ]; then
        case $CHOICE in
            1)
                create_role
                clear
                exit 1
                ;;
            2)
                create_backup
                clear
                exit 1
                ;;
            3)
                restore_database
                clear
                exit 1
                ;;
        esac
    else
        clear
        break
    fi
done