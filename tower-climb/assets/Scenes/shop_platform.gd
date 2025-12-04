extends StaticBody2D
class_name ShopPlatform

# Optional flag so each shop platform only triggers once
var shop_used: bool = false

func is_shop_platform() -> bool:
	return true
