#!/bin/bash
set -u

# Use docker-compose networking with the container name
netbootServer="netboot-tftp"

### Check TFTP Functionality with a tftp client. Retrieve File and check if the file is available and not empty.
function tftpConnectWithEchoInfluxOutput() {
        tftpHostName="$1"
        tftpServerTestFile="$2"

        # This distinction is needed because all ipxe files are located in a subfolder "ipxe"
        if [[ $tftpServerTestFile == *.ipxe  ]]; then
                atftp -g -r "ipxe/$tftpServerTestFile" -l /tmp/"$tftpServerTestFile" "$tftpHostName" >/dev/null 2>&1
        else 
                atftp -g -r "$tftpServerTestFile" -l /tmp/"$tftpServerTestFile" "$tftpHostName" >/dev/null 2>&1
        fi

        # -s checks if the file is available and is not empty.

        if [[ -s "/tmp/$tftpServerTestFile" ]]; then
                tftpFileIsAvailable="1"
        else
                tftpFileIsAvailable="0"
        fi

        rm "/tmp/$tftpServerTestFile"

        formatInfluxData "$tftpHostName" "$tftpServerTestFile" "$tftpFileIsAvailable"
}

### Format Output of Above Function into Influx Format and echo the result. This is interpreded by telegraf.conf
function formatInfluxData() {
        tftpHostName="$1"
        tftpServerTestFile="$2"
        statusCode="$3"

        echo tftp_connect,url_base="$tftpHostName",tftp_file="$tftpServerTestFile" file_available="$statusCode"
}

## Main Script ##

filesToTest=("undionly.kpxe" "ipxe32.efi" "ipxe64.efi" "menu.ipxe" "advancedmenu.ipxe")

for fileToTest in "${filesToTest[@]}"; do
        tftpConnectWithEchoInfluxOutput "$netbootServer" "$fileToTest"
done
