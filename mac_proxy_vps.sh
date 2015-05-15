#/bin/bash
#use autossh to connect the openshift vps. autossh will do automally reconection.
/usr/local/bin/autossh -M 1081 -D 1080 -i /Users/w/.ssh/identification -qNnt 54b5fcb35973cab7770002e0@python-mfrc531.rhcloud.com
