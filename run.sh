# Function for printing status message
print() {
	echo ""
	echo ----- $1 ------
	echo ""
}

# --- Main Program ----

print "Clean up old files"

rm net1.xml net2.xml net3.xml
rm mpdccp-client.xml mpdccp-server.xml

print "Install Dependencies"

sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
sudo apt install virt-manager

sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

print "Create xml files for network configurations"

echo "<network>
  <name>net1</name>
  <bridge name='virbr1' stp='on' delay='0'/>
  <domain name='net1'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
  </ip>
</network>" > net1.xml

echo "<network>
  <name>net2</name>
  <bridge name='virbr2' stp='on' delay='0'/>
  <domain name='net2'/>
  <ip address='192.168.101.1' netmask='255.255.255.0'>
  </ip>
</network>" > net2.xml

echo "<network>
  <name>net3</name>
  <bridge name='virbr3' stp='on' delay='0'/>
  <domain name='net3'/>
  <ip address='192.168.102.1' netmask='255.255.255.0'>
  </ip>
</network>" > net3.xml

print "Remove old network configuration on system"

sudo virsh net-undefine net1
sudo virsh net-destroy net1

sudo virsh net-undefine net2
sudo virsh net-destroy net2

sudo virsh net-undefine net3
sudo virsh net-destroy net3

print "Define and start the networks"

sudo virsh net-define net1.xml
sudo virsh net-autostart net1
sudo virsh net-start net1

sudo virsh net-define net2.xml
sudo virsh net-autostart net2
sudo virsh net-start net2

sudo virsh net-define net3.xml
sudo virsh net-autostart net3
sudo virsh net-start net3

print "Enable packet forwarding and allow DCCP traffic"

sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -I FORWARD 1 -p dccp -s 192.168.100.0/22 -d 192.168.100.0/22 -j ACCEPT

print "Remove old virtual machines"

sudo virsh destroy mpdccp-server
sudo virsh undefine mpdccp-server --managed-save

sudo virsh destroy mpdccp-client
sudo virsh undefine mpdccp-client --managed-save

print "Restart default network"

sudo virsh net-destroy default
sudo virsh net-start default

print "Install and start Client VM and Server VM"

sudo gnome-terminal -- sh -c "virt-install \
 --name mpdccp-client \
 --memory 2048 \
 --vcpus 1 \
 --disk /home/rasmus/Downloads/mpdccp1c.qcow2,bus=sata \
 --import \
 --check all=off \
 --network default"

sudo gnome-terminal -- sh -c "virt-install \
 --name mpdccp-server \
 --memory 2048 \
 --vcpus 1 \
 --disk /home/rasmus/Downloads/mpdccp2s.qcow2,bus=sata \
 --import \
 --check all=off \
 --network default"

print "Wait 30 seconds for the virtual machines to start"

sleep 30

print "Shut down the virtual machines and wait 5 seconds"

sudo virsh shutdown mpdccp-server
sudo virsh shutdown mpdccp-client
sleep 5

print "Download existing network configuration for modification"

sudo virsh dumpxml mpdccp-client > mpdccp-client.xml
sudo virsh dumpxml mpdccp-server > mpdccp-server.xml

print "Modify content of mpdccp-client.xml"

# Remove interface tag
sed -i '/<interface.*>/,/<\/interface>/d' mpdccp-client.xml
# Remove insert config for the two networks
sed -i "/<serial/i \    <interface type='network'>\n        <source network='net2'\/>\n        <model type='rtl8139'\/>\n        <address type='pci' domain='0x0000' bus='0x00' slot='0x09' function='0x0'\/>\n    <\/interface>\n    <interface type='network'>\n        <source network='net1'\/>\n        <model type='rtl8139'\/>\n        <adress type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'\/>\n    <\/interface>" mpdccp-client.xml

print "Redefine mpdccp-client using mpdccp-client.xml"

sudo virsh define mpdccp-client.xml

print "Modify content of mpdccp-server.xml"

# Remove interface tag
sed -i '/<interface.*>/,/<\/interface>/d' mpdccp-server.xml
# Remove memballoon tag in order to avoid PCI double use error
sed -i '/<memballoon.*>/,/<\/memballoon>/d' mpdccp-server.xml
# Remove insert config for server network config
sed -i "/<serial/i \    <interface type='network'>\n        <source network='net3'\/>\n        <model type='rtl8139'\/>\n        <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'\/>\n    <\/interface>" mpdccp-server.xml

print "Redefine mpdccp-server using mpdccp-server.xml"

sudo virsh define mpdccp-server.xml

print "Start mpdccp-client and mpdccp-server"

sudo virsh --connect qemu:///system start mpdccp-client
sudo virsh --connect qemu:///system start mpdccp-server

print "Connect to mpdccp-client and mpdccp-server"

sudo gnome-terminal -- sh -c "virt-viewer --connect qemu:///system mpdccp-client"
sudo gnome-terminal -- sh -c "virt-viewer --connect qemu:///system mpdccp-server"

