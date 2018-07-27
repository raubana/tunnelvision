$modelname "models/tunnelvision/io_models/io_button.mdl"
$body 1 "io_button.smd"
$cdmaterials "models/tunnelvision/io_models/"

$scale 1

$texturegroup skinfamilies
{
	{ "io_button_off"  }
	{ "io_button_on" }
}

$sequence idle "io_button.smd" {
	loop
	fps 1
}

$surfaceprop metal

$collisionmodel	"io_button.smd" {}