#!/bin/bash

for ROLE in 'swift-proxy' 'swift-storage'
do
  if $(/usr/bin/fuel role --rel 2 2>/dev/null| grep -q $ROLE)
  then
     echo "Role $ROLE exists, trying to update it from $INSTALLPATH/role_$ROLE.yaml."
     /usr/bin/fuel role --rel 2 --update --file $INSTALLPATH/role_$ROLE.yaml >/dev/null 2>&1
  else
     echo "Role $ROLE does not exist, trying to create it from $INSTALLPATH/role_$ROLE.yaml."
     /usr/bin/fuel role --rel 2 --create --file $INSTALLPATH/role_$ROLE.yaml >/dev/null 2>&1
  fi
done

/usr/bin/fuel rel --rel 2 --deployment-tasks --download --dir /tmp/ >/dev/null 2>&1
echo "Updating deployment tasks"
python $INSTALLPATH/updatetasks.py
/usr/bin/fuel rel --rel 2 --deployment-tasks --upload --dir /tmp/ >/dev/null 2>&1
rm -rf /tmp/release_2
