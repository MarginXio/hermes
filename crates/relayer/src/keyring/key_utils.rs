use bech32::{FromBase32, ToBase32};
use tiny_keccak::{Hasher, Keccak};

use super::errors::Error;

pub fn decode_bech32(input: &str) -> Result<Vec<u8>, Error> {
    let (_, data, _) = bech32::decode(input).map_err(Error::bech32_account)?;
    Vec::from_base32(&data).map_err(Error::bech32_account)
}

pub fn encode_bech32(account_prefix: &str, address: &[u8]) -> Result<String, Error> {
    bech32::encode(account_prefix, address.to_base32(), bech32::Variant::Bech32)
        .map_err(Error::bech32)
}

pub fn keccak256_hash(bytes: &[u8]) -> [u8; 32] {
    let mut hasher = Keccak::v256();
    hasher.update(bytes);
    let mut output = [0u8; 32];
    hasher.finalize(&mut output);
    output
}

pub fn eth_address_checksum(input: &Vec<u8>) -> String {
    let encode = hex::encode(input).to_lowercase();
    let address_hash = hex::encode(keccak256_hash(encode.as_bytes()));
    encode
        .char_indices()
        .fold(String::from("0x"), |mut acc, (index, address_char)| {
            let n = u16::from_str_radix(&address_hash[index..index + 1], 16).unwrap();
            if n > 7 {
                acc.push_str(&address_char.to_uppercase().to_string())
            } else {
                acc.push(address_char)
            }
            acc
        })
}
