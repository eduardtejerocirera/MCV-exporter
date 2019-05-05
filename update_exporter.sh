echo UPDATING EXPORTER

#first discard all possible changes
git reset --hard
#then update from remote
git pull

read -p "Press any key to continue... " -n1 -s