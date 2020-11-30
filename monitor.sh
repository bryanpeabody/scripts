#! /bin/bash


#
# Function: showUsage
#
# Catch all function to show the usage when bad parameters are passed in.
#
function showUsage {
   echo "Usage: $0 <path to log file> <email address(es)> <Time interval>"
   echo
   echo "Time intervals:"
   echo "       -min Run report for last 10 minutes."
   echo "       -hr Run report for last hour."
   echo "       -day Run report for last day."
   exit
}


#
# Check that the proper number of parameters are present.
#
if [ $# -ne 3 ]; then
        showUsage
fi


#
# Process the passed in parameters.
#
ERR_LOG=$1
TO_EMAIL=$2
TIME_INTERVAL=$3
TMP_FILE="/tmp/${RANDOM}.txt"
REPORT_TYPE=""


#
# Check that the log file exists and is valid.
#
if [ ! -e ${ERR_LOG} ]; then
   echo "That log file does not exist!"
   exit
fi


#
# Process the log based on the supplied time interval.
#
if [ "${TIME_INTERVAL}" == "-hr" ]; then
        #
        # Create the current date string, 2009-10-06 09, for example.
        #
        DATE_STR=`date "+%Y-%m-%d %H"`


        #
        # Look at the previous hour.
        #
        DATE_STR=`date --date="1 hour ago" +"%Y-%m-%d %H"`


        #
        # Set the report type
        #
        REPORT_TYPE="Hourly"


        echo "Hourly Log report for ${ERR_LOG} for time ${DATE_STR}" > ${TMP_FILE}
elif [ "${TIME_INTERVAL}" == "-min" ]; then
        #
        # Build the current date string.
        #
        DATE_STR=`date "+%Y-%m-%d"`
        MIN=`date +%M`
        HR=`date +%H`
        DAY=`date +%d`


        # Build the minutes digit to grep on.  The string will look like this: YYYY-MM-DD HH:M
        if [ $MIN -ge 50 ]; then
                DATE_STR="${DATE_STR} ${HR}:4"
        elif [ ${MIN} -ge 40 ]; then
                DATE_STR="${DATE_STR} ${HR}:3"
        elif [ ${MIN} -ge 30 ]; then
                DATE_STR="${DATE_STR} ${HR}:2"
        elif [ ${MIN} -ge 20 ]; then
                DATE_STR="${DATE_STR} ${HR}:1"
        elif [ ${MIN} -ge 10 ]; then
                DATE_STR="${DATE_STR} ${HR}:0"
        elif [ ${MIN} -ge 0 ]; then
                # Did we roll over into a new day, month or year?
                if [ ${HR} -eq 0 ]; then
                        DATE_STR=`date --date="1 day ago" +"%Y-%m-%d 23:5"`
                else
                        # Have to get rid of leading 0 so it does not think it is octal
                        let HR=`echo ${HR} | sed 's/^0//'`-1
                        # Pad with zero if less than 10
                        if [ $HR -lt 10 ]; then
                                HR="0$HR"
                        fi


                        DATE_STR="${DATE_STR} ${HR}:5"
                fi
        fi


        #
        # Set the report type
        #
        REPORT_TYPE="Ten Minute"


        echo "Ten Minute Log report for ${ERR_LOG} for time ${DATE_STR}0's" > ${TMP_FILE}
elif [ "${TIME_INTERVAL}" == "-day" ]; then
        #
        # Create the current date string, 2009-10-06, for example.
        #
        DATE_STR=`date "+%Y-%m-%d"`


        #
        # Set the report type
        #
        REPORT_TYPE="Daily"


        echo "Daily Log report for ${ERR_LOG} for time ${DATE_STR}" > ${TMP_FILE}
else
        echo "Bad time interval. Exiting."
        exit
fi


# Error and Fatal
echo >> ${TMP_FILE}
echo "FATAL: " >> ${TMP_FILE}
grep "${DATE_STR}" ${ERR_LOG} | grep FATAL | awk '{print $2}' FS=] | sort | uniq -c | sort -rn >> ${TMP_FILE}
FATAL_CNT=`grep "${DATE_STR}" ${ERR_LOG} | grep FATAL | wc -l`


echo >> ${TMP_FILE}
echo "ERRORS:" >> ${TMP_FILE}
grep "${DATE_STR}" ${ERR_LOG} | grep ERROR | awk '{print $2}' FS=] | sort | uniq -c | sort -rn >> ${TMP_FILE}
ERROR_CNT=`grep "${DATE_STR}" ${ERR_LOG} | grep ERROR | wc -l`


# Warnings
echo >> ${TMP_FILE}
echo "WARN: " >> ${TMP_FILE}
grep "${DATE_STR}" ${ERR_LOG} | grep WARN | awk '{print $2}' FS=] | awk '{print $1}' FS=: | sort | uniq -c | sort -rn >> ${TMP_FILE}
WARN_CNT=`grep "${DATE_STR}" ${ERR_LOG} | grep WARN | wc -l`


if [ ${FATAL_CNT} != 0 ] || [ ${ERROR_CNT} != 0 ] || [ ${WARN_CNT} != 0 ];  then
        cat ${TMP_FILE} | mail -s "${REPORT_TYPE} Error Report on `hostname`" ${TO_EMAIL}
fi


# Clean up after ourself
rm ${TMP_FILE}