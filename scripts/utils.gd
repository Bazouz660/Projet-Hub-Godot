class_name Utils

static func get_normalized_noise_2d(noise: FastNoiseLite, x: float, z: float) -> float:
    return (noise.get_noise_2d(x, z) + 1.0) / 2.0

static func is_valid_bool(value: String) -> bool:
    return value == "true" or value == "false" or value == "True" or value == "False" or value == "1" or value == "0"

static func string_to_bool(value: String) -> bool:
    if value == "true" or value == "True" or value == "1":
        return true
    else:
        return false