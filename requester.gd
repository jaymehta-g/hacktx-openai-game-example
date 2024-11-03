extends Node2D

@onready var http_request = $HTTPRequest
@onready var button = $Button
@onready var image_request: HTTPRequest = $ImageRequest
@onready var tile_map: TileMap = $TileMap
@onready var text_edit: TextEdit = $TextEdit
@onready var waiting_label: Label = $WaitingLabel

@onready var key = FileAccess.open("res://secret/openai.txt", FileAccess.READ)\
	.get_as_text()\
	.strip_edges()

const tilewid := 64

const url := "https://api.openai.com/v1/images/generations"

var prompt = """
Generate a level tile for a 2D sidescroller game with a %s theme. 
This wall tile will be repeated several times to build the level. 
Generate only one single tile. Fill the entire space with the image. 
Keep it simple.
DO NOT add any additional detail. Use this prompt AS IS. 
""".replace("\n", " ").replace("  ", " ").strip_edges()

# Called when the node enters the scene tree for the first time.
func _ready():
	print_debug(prompt)
	button.pressed.connect(request)
	http_request.request_completed.connect(_on_request_completed)
	#var imgurl = "https://cdn.discordapp.com/attachments/1302330887890931843/1302449548064718909/img-D5WoP3UiVbJrKn839NiJuj6l.png?ex=6728d0ea&is=67277f6a&hm=5ed68856cdf2bbb8b07e74daa9cf3fbf32ab968ec9b6eab526b1af77b4af613b&"
	var imgurl = "https://cdn.discordapp.com/attachments/1302330887890931843/1302471232180064266/img-VicQUdgMQ4RXv8VXbmsZjeJo.png?ex=67283c5c&is=6726eadc&hm=a641155a2a4a126fa91a7ced8f433da265ecd185d6ac1df9e88d487e69de74d6&"
	#var image = await fetch_image(imgurl)
	#if not image:
		#push_error("Image null!")
		#get_tree().quit()
	#use_image_for_tilemap(image)
	image_request.request_completed.connect(_on_image_recieved)
	image_request.request(imgurl)

func _on_image_recieved(result, response_code, headers, body):
	print_debug("recieved image")
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")
	use_image_for_tilemap(image)
	waiting_label.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func request():
	waiting_label.visible = true
	print_debug("start")
	var theme := text_edit.text.strip_edges()
	print_debug(prompt)
	var headers := []
	headers += ["Content-Type: application/json"]
	headers += ["Authorization: Bearer " + key]
	var opts := {
		model = "dall-e-2",
		prompt = prompt % theme,
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
	image_request.request(imgurl)

func fetch_image(url: String) -> Image:
	var result: Image
	image_request.request_completed.connect(func(a,b,c,body):
		print_debug("recieved image")
		var image = Image.new()
		var error = image.load_png_from_buffer(body)
		if error != OK:
			push_error("Couldn't load the image.")
		result = image
	)
	image_request.request(url)
	await image_request.request_completed
	return result

func use_image_for_tilemap(img: Image):
	img.resize(tilewid, tilewid)
	var texture = ImageTexture.create_from_image(img)
	tile_map.tile_set.get_source(0).texture = texture
