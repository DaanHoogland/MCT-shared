#!/bin/bash

# Script to fix hostname and uuid after deploying Xenserver 6.2

# Generate new uuid for both the host and dom0
sed -i "/INSTALLATION_UUID/c\INSTALLATION_UUID='$(uuidgen)'" /etc/xensource-inventory
sed -i "/CONTROL_DOMAIN_UUID/c\CONTROL_DOMAIN_UUID='$(uuidgen)'" /etc/xensource-inventory

# Get rid of the current state db
rm -f /var/xapi/state.db

# On the next boot, exec our fix script
echo "sh /etc/rc.local.fix >> /var/log/rc.local.fix" >> /etc/rc.local

# This is our fix script
cat <<EOT >> /etc/rc.local.fix
# Wait a bit before we start
sleep 5

# Set the hostname
xe host-param-set uuid=\$(xe host-list params=uuid|awk {'print \$5'}) name-label=\$HOSTNAME

# Our PIF
PIFUUID=\$(xe pif-list params=uuid | awk {'print \$5'})

# Reconfigure
xe host-management-reconfigure pif-uuid=\$PIFUUID
xe pif-scan host-uuid=\$(xe host-list params=uuid|awk {'print \$5'})
xe pif-reconfigure-ip uuid=\$PIFUUID mode=dhcp
xe host-management-reconfigure pif-uuid=\$PIFUUID

# Forget the old host
xe host-forget uuid=$(xe host-list params=uuid|awk {'print $5'}) --force

# Remove us from rc.local
sed -i '/local.fix/d' /etc/rc.local
EOT

reboot
