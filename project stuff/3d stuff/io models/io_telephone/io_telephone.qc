$modelname "models/tunnelvision/io_models/io_telephone.mdl"
$body 1 "io_telephone.smd"
$cdmaterials "models/tunnelvision/io_models/"

$scale 1

$sequence idle "io_telephone.smd" {
	loop
	fps 1
}

$surfaceprop plastic

$collisionmodel	"io_telephone.smd" {}