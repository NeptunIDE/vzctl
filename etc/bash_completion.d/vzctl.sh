# OpenVZ vzctl bash completion by Kir Kolyshkin <kir@openvz.org>
# Put this file to /etc/bash_completion.d/
# modified Thorsten Schifferdecker <tsd@debian.systs.org>

_get_ves()
{
	local cmd=$1
	case $cmd in
		create)
			# create a new VEID, by increasing the last one
			local veids=`/usr/sbin/vzlist -H -a -ovpsid | tail -1`
			[ -n "$veids" ] || veids=100
			echo $((veids+1))
			;;
		start|mount|umount|destroy)
			# stopped VEs
			/usr/sbin/vzlist -H -S -ovpsid
                        /usr/sbin/vzlist -H -S -oname | sed s/-//g
			;;
		stop|enter|exec*)
			# running VEs
			/usr/sbin/vzlist -H -ovpsid
                        /usr/sbin/vzlist -H -oname | sed s/-//g
			;;
		*)
			# All VEs
			/usr/sbin/vzlist -H -a -ovpsid
                        /usr/sbin/vzlist -H -a -oname | sed s/-//g
			;;
	esac
}

_vzctl()
{
	local cur prev cmd vzctl_cmds vzctl_create_opts vzctl_set_opts
	local iptables_names cap_names

	#echo "ARGS: $*"
	#echo "COMP_WORDS: $COMP_WORDS"
	#echo "COMP_CWORD: $COMP_CWORD"
	#echo "COMP_WORDS[1]: ${COMP_WORDS[1]}"
	
	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}

	vzctl_common_opts="--quiet --verbose --help --version"
	vzctl_cmds="create destroy mount umount chkpnt restore \
		set start stop restart status enter exec exec2 runscript"
	vzctl_create_opts="--ostemplate --config --private --root \
		--ipadd --hostname FIXME"
	vzctl_set_opts="--save --onboot --root --private \
		--userpasswd --disabled --ipadd --ipdel \
		--hostname --nameserver --searchdomain \
		--numproc --numtcpsock --numothersock --vmguarpages \
		--kmemsize --tcpsndbuf --tcprcvbuf --othersockbuf \
		--dgramrcvbuf --oomguarpages --lockedpages --privvmpages \
		--shmpages --numfile --numflock --numpty --numsiginfo \
		--dcachesize --numiptent --physpages --cpuunits --cpulimit \
		--iptables --netdev_add --netdev_del --veth_add --veth_del \
		--diskspace --diskinodes --quotatime --quotaugidlimit \
		--noatime --capability --devnodes --applyconfig --name"

	iptables_names="iptable_filter iptable_mangle ipt_limit
		ipt_multiport ipt_tos ipt_TOS ipt_REJECT ipt_TCPMSS
		ipt_tcpmss ipt_ttl ipt_LOG ipt_length ip_conntrack
		ip_conntrack_ftp ip_conntrack_irc ipt_conntrack ipt_state
		ipt_helper iptable_nat ip_nat_ftp ip_nat_irc ipt_REDIRECT"

	cap_names="chown dac_override dac_read_search fowner fsetid kill
		setgid setuid setpcap linux_immutable net_bind_service
		net_broadcast net_admin net_raw ipc_lock ipc_owner
		sys_module sys_rawio sys_chroot sys_ptrace sys_pacct
		sys_admin sys_boot sys_nice sys_resource sys_time
		sys_tty_config mknod lease setveid ve_admin"
		
									  

	case $COMP_CWORD in
	1)
		# command or global option
		COMPREPLY=( $( compgen -W "$vzctl_cmds $vzctl_common_opts" -- $cur ) )
		;;

	2)
		case "$prev" in
		--help|--version)
			COMPREPLY=()
			;;
		--*)
			# command
			COMPREPLY=( $( compgen -W "$vzctl_cmds" -- $cur ) )
			;;
		*)
			# VEID
			COMPREPLY=( $( compgen -W "$(_get_ves $prev)" -- $cur ) )
			;;
		esac
		;;

	*) # COMP_CWORD >= 3
		if [[ $COMP_CWORD -eq 3 && ! $prev != '^[1-9][0-9]*$' ]]; then
			# VEID
			COMPREPLY=( $( compgen -W "$(_get_ves $prev)" -- $cur ) )
		else
	
			# flag or option
			case $prev in
			--ostemplate)
				# get the template path from the vz.conf
				local vztmpl=`grep ^TEMPLATE /etc/vz/vz.conf | cut -d "=" -f 2`
				COMPREPLY=( $( compgen -W "$(ls -1 $vztmpl/cache/*.tar.gz | \
						    sed -e "s#^$vztmpl/cache/##" -e 's#.tar.gz$##')" -- $cur ) )

				;;
			--onboot|--disabled|--noatime)
				COMPREPLY=( $( compgen -W "yes no" -- $cur ) )
				;;
			--config|--applyconfig)
				local configs=$(ls -1 /etc/vz/conf/*.conf-sample | \
						    cut -d "-" -f 2- | sed -e 's#.conf-sample$##')

				configs=${configs/.conf-sample/}
				COMPREPLY=( $( compgen -W "$configs" -- $cur ) )
				;;
			--iptables)
				COMPREPLY=( $( compgen -W "$iptables_names" -- $cur ) )
				;;
			--netdev*)
				local devs=`ip addr show | awk '/^[0-9]/ && /UP/ && !/venet/ && !/lo/ \
						    { print $2 }' | sed s/://`

				COMPREPLY=( $( compgen -W "$devs" -- $cur ) )
				;;
			--capability)
				# capname:on|off
				COMPREPLY=( $( compgen -W "$cap_names" -- $cur ) )
				# FIXME: add :on or :off -- doesn't work :(
#				if [[ ${#COMPREPLY[@]} -le 1 ]]; then
#					if [[ $cur =~ ":" ]]; then
#						cap=${cur%%:*}
#					else
#						cap=${COMPREPLY[0]%%:*}
#					fi
					# Single match: add :on|:off
#					COMPREPLY=( $(compgen -W \
#					"${cap}:on ${cap}:off" -- $cur) )
#				fi
				;;
			--devnodes)
				# FIXME: device:r|w|rw|none
				local devs=''
				COMPREPLY=( $( compgen -W "$devs" -- $cur ) )
				;;
			--ipdel)
				# Get VEID
				local ve=${COMP_WORDS[2]}
				if [[ ! ${ve} != '^[1-9][0-9]*$' ]] ; then
					# --verbose or --quiet used
					ve=${COMP_WORDS[3]}
				fi
				# VENAME or VEID ?
				LIST_OPT=`echo $ve | awk '/[a-zA-Z]/ {print "-N"}'`
				local ips="`/usr/sbin/vzlist -H -o ip $LIST_OPT $ve | grep -vi -`"
				COMPREPLY=( $( compgen -W "$ips all" -- $cur ) )
				;;
			--private|--root)
				# FIXME
				# Dir autocompletion works bad since there is
				# a space added. Alternatively, we could use
				# -o dirname option to 'complete' -- but it
				# makes no sense for other parameters (UBCs
				# etc). So no action for now.
				;;
			*)
				if [[ "${prev::2}" != "--" || "$prev" = "--save" ]]; then
					# List options
					cmd=${COMP_WORDS[1]}
					if [ ${cmd::2} = "--" ] ; then
						# --verbose or --quiet used
						cmd=${COMP_WORDS[2]}
					fi
		
					case "$cmd" in
					create)
						COMPREPLY=( $( compgen -W "$vzctl_create_opts" -- $cur ) )
						;;
					set)
						COMPREPLY=( $( compgen -W "$vzctl_set_opts" -- $cur ) )
						;;
					chkpnt|restore)
						COMPREPLY=( $( compgen -W "--dumpfile" -- $cur ) )
						;;
					stop)
						COMPREPLY=( $( compgen -W "--fast" -- $cur ) )
						;;
					*)
						;;
					esac
				else
					# Option that requires an argument
					# which we can't autocomplete
					COMPREPLY=( $( compgen -W "" -- $cur ) )
				fi
				;;
			esac
		fi
	esac

	return 0
}

complete -F _vzctl vzctl

# EOF
