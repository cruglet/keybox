class_name Encryption
extends RefCounted

const SALT_SIZE: int = 16
const KEY_SIZE: int = 32
const ITERATIONS: int = 10_000


static func generate_salt() -> PackedByteArray:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var salt: PackedByteArray = PackedByteArray()
	
	for i: int in SALT_SIZE:
		salt.append(rng.randi_range(0, 255))
	
	return salt


static func derive_key(master_key: String, salt: PackedByteArray) -> PackedByteArray:
	return _pbkdf2_hmac_sha256(
		master_key.to_utf8_buffer(),
		salt,
		ITERATIONS,
		KEY_SIZE
	)


static func hash_key(derived_key: PackedByteArray) -> PackedByteArray:
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(derived_key)
	return ctx.finish()


static func create_verifier(master_key: String, salt: PackedByteArray) -> PackedByteArray:
	var derived_key: PackedByteArray = derive_key(master_key, salt)
	return hash_key(derived_key)


static func verify_master_key(master_key: String, salt: PackedByteArray, verifier: PackedByteArray) -> bool:
	var derived_key: PackedByteArray = derive_key(master_key, salt)
	var hashed: PackedByteArray = hash_key(derived_key)
	
	return hashed == verifier


static func encrypt_data(data: PackedByteArray, derived_key: PackedByteArray) -> PackedByteArray:
	var aes: AESContext = AESContext.new()
	var iv: PackedByteArray = generate_salt()
	
	aes.start(AESContext.MODE_CBC_ENCRYPT, derived_key, iv)
	var padded_data: PackedByteArray = _pkcs7_pad(data)
	var encrypted: PackedByteArray = aes.update(padded_data)
	aes.finish()
	
	var result: PackedByteArray = PackedByteArray()
	result.append_array(iv)
	result.append_array(encrypted)
	return result


static func decrypt_data(encrypted_data: PackedByteArray, derived_key: PackedByteArray) -> PackedByteArray:
	var iv: PackedByteArray = encrypted_data.slice(0, SALT_SIZE)
	var payload: PackedByteArray = encrypted_data.slice(SALT_SIZE, encrypted_data.size())
	
	var aes: AESContext = AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, derived_key, iv)
	var decrypted: PackedByteArray = aes.update(payload)
	aes.finish()
	
	return _pkcs7_unpad(decrypted)


static func _pbkdf2_hmac_sha256(
	password: PackedByteArray,
	salt: PackedByteArray,
	iterations: int,
	key_length: int
) -> PackedByteArray:
	var result: PackedByteArray = PackedByteArray()
	var block_index: int = 1
	
	while result.size() < key_length:
		var u: PackedByteArray = _hmac_sha256(password, salt + _int_to_be(block_index))
		var t: PackedByteArray = u
		
		for i: int in range(1, iterations):
			u = _hmac_sha256(password, u)
			
			for j: int in u.size():
				t[j] ^= u[j]
		
		result.append_array(t)
		block_index += 1
	
	return result.slice(0, key_length)


static func _hmac_sha256(key: PackedByteArray, data: PackedByteArray) -> PackedByteArray:
	if key.size() == 0:
		push_error("_hmac_sha256: key is empty!")
		return PackedByteArray()
	
	var key_fixed: PackedByteArray = key
	if key_fixed.size() > 64:
		key_fixed = key_fixed.slice(0, 64)
	
	var crypto: Crypto = Crypto.new()
	return crypto.hmac_digest(HashingContext.HASH_SHA256, key_fixed, data)


static func _int_to_be(value: int) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(4)
	
	out[0] = (value >> 24) & 0xFF
	out[1] = (value >> 16) & 0xFF
	out[2] = (value >> 8) & 0xFF
	out[3] = value & 0xFF
	
	return out


static func _pkcs7_pad(data: PackedByteArray) -> PackedByteArray:
	var pad_len: int = 16 - (data.size() % 16)
	var padded: PackedByteArray = data.duplicate()
	for i: int in pad_len:
		padded.append(pad_len)
	return padded


static func _pkcs7_unpad(data: PackedByteArray) -> PackedByteArray:
	if data.size() == 0:
		return PackedByteArray()
	var pad_len: int = data[data.size() - 1]
	if pad_len <= 0 or pad_len > 16:
		return data
	return data.slice(0, data.size() - pad_len)
