awk '/^nameserver/{print $2}' /etc/resolv.conf | sed 's/^/"/;s/$/"/' | paste -s -d "," -
