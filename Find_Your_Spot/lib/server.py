from flask import Flask, request

app = Flask(__name__)


@app.route('/', methods=['POST'])
def listen_post():
    data = request.form
    print("Received POST request with data: ", data)
    return "POST request received!", 200


if __name__ == "__main__":
    app.run(port=23123, debug=True)
