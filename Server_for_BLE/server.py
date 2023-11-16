from flask import Flask, request, redirect

app = Flask(__name__)

RSSI_UUID_data = []


@app.route('/rssi_uuid_data', methods=['GET', 'POST'])
def rssi():
    global RSSI_UUID_data
    if request.method == 'POST':
        RSSI_UUID_data = request.get_json()
        print(RSSI_UUID_data)
        return redirect('/rssi_uuid_data')
    else:
        return str(RSSI_UUID_data)


if __name__ == '__main__':
    app.run(host='10.0.0.231', port=8000)
