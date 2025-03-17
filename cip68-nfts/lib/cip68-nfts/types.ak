use aiken/collection/dict.{Dict}

/// trạng thái mint của redeemerredeemer
pub type MintAction {
  Mint
  Burn
}

/// trạng thái lưu trữ của nft redeemerredeemer
pub type StoreAction {
  Update
  Remove
}

//kiểu dữ liệu
pub type MetaDatum {
  metadata: Dict<ByteArray, Data>,
  version: Int,
  extra: ByteArray,
}
