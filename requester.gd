extends Node2D

@onready var sprite = $Sprite
@onready var http_request = $HTTPRequest
@onready var button = $Button
@onready var image_request: HTTPRequest = $ImageRequest

var key := "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"\
	.strip_edges()
const url := "https://api.openai.com/v1/images/generations"

# Called when the node enters the scene tree for the first time.
func _ready():
	button.pressed.connect(request)
	http_request.request_completed.connect(_on_request_completed)
	var imgurl = "https://oaidalleapiprodscus.blob.core.windows.net/private/org-ZlTf7kEC6OP7zW5RFgWfEfr1/user-rHnpR3S43LR7yL9O9VbvSBq8/img-MA3jFdg4DP4JPK9IDGidwEe7.png?st=2024-11-03T13%3A30%3A30Z&se=2024-11-03T15%3A30%3A30Z&sp=r&sv=2024-08-04&sr=b&rscd=inline&rsct=image/png&skoid=d505667d-d6c1-4a0a-bac7-5c84a87759f8&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skt=2024-11-03T00%3A56%3A51Z&ske=2024-11-04T00%3A56%3A51Z&sks=b&skv=2024-08-04&sig=Clg/kWDyingioYI53ApdJwBAsa5cGC6DvLwJKjyXYcQ%3D"


func _on_image_recieved(result, response_code, headers, body):
	print_debug("rcieved image")
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func request():
	print_debug("start")
	var headers := []
	headers += ["Content-Type: application/json"]
	headers += ["Authorization: Bearer " + key]
	var opts := {
		model = "dall-e-2",
		prompt = "a green seahorse",
		n = 1,
		size = "256x256",
	}
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(opts))

func _on_request_completed(result, response_code, headers, body):
	print(result)
	print(response_code)
	print(headers)
	print(body.get_string_from_utf8())
	var body_data = JSON.parse_string(body.get_string_from_utf8())
	var imgurl = body_data["data"][0]["url"]
	image_request.request_completed.connect(_on_image_recieved)
	image_request.request(imgurl)
