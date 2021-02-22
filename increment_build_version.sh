#! /bin/bash

# ======================================================== #
# Finding version number parts                             #
# ======================================================== #

versionline=$(cat CITATION.cff | grep ^version)
version=$(echo $versionline | cut -d ' ' -f 2)
version_nobuild=$(echo $version | cut -d '+' -f 1)
buildnumber=$(echo $version | cut -d '+' -f 2)

if [ $buildnumber = $version ]
then
	echo "No build number found. Attributing 1"
	newbuildnumber=1
	version="$version+1"
else
	echo "Current build number is" $buildnumber ". Incrementing:"
	buildnumber=$((buildnumber+1))
	version="$version_nobuild+$buildnumber"
	newversionline="version: $version"
fi

echo -en "New software version: $version\nOverwrite? [y/N] "
read overwrite

if [ $overwrite = "y" ]
then
	echo "Overwriting."
	sed -i "s/$versionline/$newversionline/g" CITATION.cff
else
	echo "Aborting."
fi