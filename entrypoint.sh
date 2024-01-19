#!/bin/bash
# Version:  1.0.5
# Modified: 2024 Jan 19

VOLDIR="/var/scatool"
INCOMING="${VOLDIR}/incoming"
REPORTS="${VOLDIR}/reports"
LOGS="${VOLDIR}/logs"
ACTIVE_FILE="${LOGS}/.sca-analysis.pid" # Must match sca-analysis active file
MONITOR_LIVE="${LOGS}/.sca-monitoring-live.pid"
DATEFMT='"+%F %T.%N %z %Z"'
REPORTS_NEW=0
REPORTS_BEFORE=0
REPORTS_AFTER=0

trap clean_up SIGTERM

sca_log() {
    local TYPE="$1"; shift
    printf "%s [%s] Entrypoint:   %s\n" "$(date ${DATEFMT})" "$TYPE" "$*"
}

sca_note() {
    sca_log Note "$@"
}

sca_warn() {
    sca_log Warn "$@" >&2
}

sca_error() {
    sca_log ERROR "$@" >&2
}

clean_up() {
	sca_note "Shutting down"
	rm -f $ACTIVE_FILE $MONITOR_LIVE
	exit
}

process_reports() {
	sca_note "Analyzing files"
	REPORTS_BEFORE=$(ls -1 ${REPORTS} | wc -l)
	sca-analysis
	REPORTS_AFTER=$(ls -1 ${REPORTS} | wc -l)
	REPORTS_NEW=$(( REPORTS_AFTER - REPORTS_BEFORE ))
	sca_note "Processing complete, ${REPORTS}"
	sca_note "New SCA Reports: ${REPORTS_NEW}"
}

sca_note "Supportconfig analysis workload container starting"
sca_note "Monitoring interval: ${INTERVAL:=5} sec"
scatool -p
echo
if [[ -d $VOLDIR ]]; then
	DIR_ERR=0
	for DIR in $INCOMING $REPORTS $LOGS
	do
		if [[ -d $DIR ]]; then
			MODE=$(stat -c %a $DIR 2>/dev/null)
			if [[ "$MODE" != "777" ]]; then
				sca_warn "Setting correct permissions for: $DIR"
				chmod 777 $DIR
			fi
		else
			sca_warn "Creating missing directory: $DIR"
			mkdir -p $DIR && chmod 777 $DIR
		fi
	done
else
    sca_error "Missing ${VOLDIR}, try 'sudo ln -sf ~/.local/share/containers/storage/volumes/scavol/_data ${VOLDIR}'"
    clean_up
fi


if (( ${MONITORING:=0} )); then
	sca_log "Mode" "Monitoring ${INCOMING}"
else
	sca_log "Mode" "Single check ${INCOMING}"
fi

if (( $MONITORING )); then
    if [[ -e $MONITOR_LIVE ]]; then
			sca_error "Another container is already monitoring - ${MONITOR_LIVE}"
			sca_error "Try: podman ps shows no running container, then try: 'rm ${MONITOR_LIVE}' and restart"
			sca_error "Terminating"
			exit 5
    else
		while :
		do
			if [[ -e $ACTIVE_FILE ]]; then
				sca_note "Analysis in progress"
			else
				echo $$ > $MONITOR_LIVE
				FILES=$(ls -1 ${INCOMING})
				[[ -n $FILES ]] && process_reports
			fi
			sleep ${INTERVAL}
		done
	fi
else
    if [[ -e $MONITOR_LIVE ]]; then
		sca_error "Another container is monitoring - ${MONITOR_LIVE}"
		sca_error "Try: 'podman ps' shows no running container, then try: 'rm ${MONITOR_LIVE}' and restart"
		sca_error "Terminating"
		exit 5
    else
		FILES=$(ls -1 ${INCOMING})
		[[ -n $FILES ]] && process_reports || sca_note "No files found to analyze"
	fi
fi
clean_up

