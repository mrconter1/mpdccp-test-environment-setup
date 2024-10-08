**# MPDCCP Test Environment Setup

This repository contains a script that automates the setup of a Multi-Path DCCP (MPDCCP) testing environment using virtual machines and custom network configurations.

## Features

- Sets up three virtual networks
- Installs and configures two virtual machines: client and server
- Configures network interfaces for MPDCCP testing
- Enables packet forwarding and allows DCCP traffic

## Prerequisites

- Ubuntu-based system
- Sudo privileges
- QEMU and libvirt installed

## Usage

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/mpdccp-test-environment-setup.git
   cd mpdccp-test-environment-setup
   ```

2. Ensure you have the required VM images (`mpdccp1c.qcow2` and `mpdccp2s.qcow2`) in your Downloads folder.

3. Run the script with sudo privileges:
   ```
   sudo bash setup_mpdccp.sh
   ```

4. Follow the on-screen prompts and wait for the setup to complete.

## Note

This script will modify system network configurations and create/destroy virtual machines. Use with caution in a controlled environment.

## Contributing

Contributions to improve the setup script or extend the test environment are welcome. Please feel free to submit issues or pull requests.
