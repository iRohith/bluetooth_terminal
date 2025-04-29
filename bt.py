#!/usr/bin/env python3

# sudo hciconfig hci0 piscan

# 1 - configure bt device: sudo nano /etc/systemd/system/dbus-org.bluez.service
# 2 - locate the line starting ExecStart , and replace it with the following:
# 2.1 - ExecStart=/usr/lib/bluetooth/bluetoothd --compat --noplugin=sap
# ExecStartPost=/usr/bin/sdptool add SP
#
# And run the script as su.
# sudo systemctl daemon-reload
# sudo systemctl restart bluetooth
# sudo systemctl restart dbus-org.bluez.service
# bluetoothctl power on && bluetoothctl discoverable on && bluetoothctl pairable on


import bluetooth
from time import sleep
import random
import struct
import subprocess

server_sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
server_sock.bind(("", bluetooth.PORT_ANY))
server_sock.listen(1)

port = server_sock.getsockname()[1]

# uuid = "94f39d29-7d6d-437d-973b-fba39e49d4ee"
uuid = "00001101-0000-1000-8000-00805F9B34FB"

# bluetooth.advertise_service(server_sock, "SampleServer", service_id=uuid,
#                             service_classes=[uuid, bluetooth.SERIAL_PORT_CLASS],
#                             profiles=[bluetooth.SERIAL_PORT_PROFILE],
#                             # protocols=[bluetooth.OBEX_UUID]
#                             )

subprocess.run("bluetoothctl power on && bluetoothctl discoverable on && bluetoothctl pairable on", shell=True)

bluetooth.advertise_service(
    server_sock,
    "SampleService",
    service_id=uuid,
    service_classes=[uuid, bluetooth.SERIAL_PORT_CLASS],
    profiles=[bluetooth.SERIAL_PORT_PROFILE]
)

print("Waiting for connection on RFCOMM channel", port)

client_sock, client_info = server_sock.accept()
print("Accepted connection from", client_info)

encoded_string = "12345678".encode('utf-8')

try:
    while True:
        my_float = random.random()
        float_bytes = struct.pack('f', my_float)
        message = bytes([0x08]) + bytearray(reversed(float_bytes)) + bytes([random.randint(0, 15)])
        data = client_sock.send(message)
        
        # data = client_sock.recv(1024)
        # if not data:
        #     break
        # if data[0] == 0x07:
        #     if data[1:len(encoded_string)+1] == encoded_string:
        #         client_sock.send(bytes([0x07]))
        #         print("valid password")
        #     else:
        #         client_sock.send(bytes([0x09]))
        #         print("invalid password")
        # print(str(int(data[0])) + ", idx = " + str(int(data[5])) + "; float = " + str(struct.unpack('f', bytearray(reversed(data[1:5])))[0]))
        # print(data)
        sleep(0.05)
except OSError:
    pass

print("Disconnected.")

client_sock.close()
server_sock.close()
print("All done.")


# from bluepy.btle import Peripheral, UUID, Service, Characteristic

# # Create a peripheral device
# peripheral = Peripheral()

# # Define a service UUID
# service_uuid = UUID("00001101-0000-1000-8000-00805F9B34FB")
# characteristic_uuid = UUID("00001101-0000-1000-8000-00805F9B34FB")

# # Add a service
# service = peripheral.addService(service_uuid)

# # Add a characteristic
# characteristic = service.addCharacteristic(characteristic_uuid, 
#                                              properties=Characteristic.PROP_READ | Characteristic.PROP_WRITE)

# # Start advertising
# peripheral.advertiseService(service)

# print("Advertising service...")
# peripheral.startAdvertising()

# try:
#     while True:
#         # Keep the script running
#         pass
# except KeyboardInterrupt:
#     print("Stopping advertising...")
# finally:
#     peripheral.stopAdvertising()
#     peripheral.disconnect()
