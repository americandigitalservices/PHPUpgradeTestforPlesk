#!/bin/sh

renice +19 -p $$ &> /dev/null

# Only available on C5+
if [ -x /usr/bin/ionice ]; then
  ionice -c3 -p $$ &> /dev/null
fi

## Config
startdir="`pwd`";
basedir="`dirname $0`";
datadir="$basedir/output";
timestamp="`date +%Y%m%d%H%M`";
scanroot="/var/www/vhosts"; ## set to root of client folders
runphpcs="$basedir/PHP_CodeSniffer/scripts/phpcs"; #path/to/phpcs
phpcs_opts="--standard=PHPCompatibility --ignore=*js,*css --report=summary -pn";

if [ -d "$datadir" ]; then rm -Rf $datadir; fi
mkdir $datadir

##do reports by directory
for folder in $(find $scanroot/ -mindepth 1 -maxdepth 1 -type d | sort | sed 's!.*/!!');
do
	echo "Scanning $folder:";
	if [ -d "$scanroot/$folder/httpdocs" ]; then
		report_name="$datadir/$folder-http";
		$runphpcs $phpcs_opts --report-xml=$report_name.xml --report-source=$report_name.txt $scanroot/$folder/httpdocs;
	fi
	if [ -d "$scanroot/$folder/httpsdocs" ]; then
		report_name="$datadir/$folder-https";
		$runphpcs $phpcs_opts --report-xml=$report_name.xml --report-source=$report_name.txt $scanroot/$folder/httpsdocs;
	fi
	if [ -d "$scanroot/$folder/subdomains" ]; then
		for subdomain in $(find $scanroot/$folder/subdomains/ -mindepth 1 -maxdepth 1 -type d | sort | sed 's!.*/!!');
		do 
			if [ -d "$scanroot/$folder/subdomains/$subdomain/httpdocs" ]; then
				report_name="$datadir/$folder-$subdomain-http";
				$runphpcs $phpcs_opts --report-xml=$report_name.xml --report-source=$report_name.txt $scanroot/$folder/subdomains/$subdomain/httpdocs;
			fi
			if [ -d "$scanroot/$folder/subdomains/$subdomain/httpsdocs" ]; then
				report_name="$datadir/$folder-$subdomain-https";
				$runphpcs $phpcs_opts --report-xml=$report_name.xml --report-source=$report_name.txt $scanroot/$folder/subdomains/$subdomain/httpdocs;
			fi
		done
	fi
	if [ -d "$scanroot/$folder/web_users" ]; then
		for web_user in $(find $scanroot/$folder/web_users/ -mindepth 1 -maxdepth 1 -type d | sort | sed 's!.*/!!');
		do
			report_name="$datadir/$folder-$web_user";
			$runphpcs $phpcs_opts --report-xml=$report_name.xml --report-source=$report_name.txt $scanroot/$folder/web_users/$web_user;
		done
	fi
done
