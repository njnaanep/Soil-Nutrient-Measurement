from flask import Flask, jsonify, request
import json
import paho.mqtt.client as mqtt
import os
import datetime

#region Variables
phLevel, N, P, K = 0, 0, 0 ,0
coordinate = ''
isCollecting = False
#endregion

#region MQTT Implementation

#MQTT Broker authentication
mqtt_username = "mqtt_username"
mqtt_password = "mqtt_password"

client = mqtt.Client()
client.username_pw_set(mqtt_username, mqtt_password)

app = Flask(__name__)

def runMQTT():
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect('localhost', 1883) 
    client.loop_start()

def on_connect(client, userdata, flags, rc):
    # rc is the error code returned when connecting to the broker
    print ("Connected!", str(rc))

    # Once the client has connected to the broker, subscribe to the topic
    client.subscribe([("Soil/NPK", 0), ("Soil/pH", 0), ("esp8266/Command", 0), ("esp8266/Status", 0), ("topic/test", 0)])

def on_message(client, userdata, message):
    print("Received message '" + str(message.payload) + "' on topic: " + message.topic)
            
    if message.topic == "Soil/NPK":        
        global N,P,K
        N,P,K = str(message.payload).strip("'b").split(",")
        
    if message.topic == "Soil/pH":
        global phLevel
        phLevel = str(message.payload).strip("'b")
    
#endregion

#region MAIN PAGE

@app.route('/start_collecting', methods =['POST'] )
def collect():
    global coordinate
    global isCollecting
    coordinate = request.form['coordinate']
    mode = request.form['mode']

    isCollecting = True if mode == 'collecting' else False
    print(mode)

    print(coordinate)
    
    client.publish("esp8266/Command","0")
    print('Collecting Data')
    
    return "Collecting Data"
    
@app.route('/stop_collecting', methods =['POST'] )
def stop():
    client.publish("esp8266/Command","1")
    print('Stop Collection')
    return "Stop Collection"

@app.route('/retrieve_current_data', methods =['GET'] )
def sendReadings():
    return jsonify({'parameter': 'NPK', 'value': f'{phLevel},{N},{P},{K}','coordinate': f'{coordinate}'})

#endregion

@app.route('/update_time', methods =['POST'] )
def updateTime():
    new_time = request.form['new_time']
    os.system('sudo date -s "{}"'.format(new_time))
    return ''

@app.route('/shutdown', methods =['POST'] )
def shutdown():
    os.system('sudo shutdown')
    return ''

@app.route('/reboot', methods =['POST'] )
def reboot():
    os.system('sudo reboot')
    return ''
        
if __name__ == "__main__":
    runMQTT()
    app.run(host="0.0.0.0", port=8080, debug=False)

