use aiken/collection/list
use aiken/crypto.{Blake2b_224, Hash, VerificationKeyHash}
use aiken/primitive/bytearray
use cardano/address.{Address}
use cardano/assets.{AssetName}
use cardano/transaction.{
  InlineDatum, Output, Transaction,
}
use hopistal/types.{PatientProfileDatum}

pub fn verify_signature(tx: Transaction, key: VerificationKeyHash) -> Bool {
  list.has(tx.extra_signatories, key)
}

pub fn verify_any_signature(
  tx: Transaction,
  keys: List<VerificationKeyHash>,
) -> Bool {
  list.any(keys, fn(key) { verify_signature(tx, key) })
}
pub fn find_output_by_address(
  outputs: List<Output>,
  address: Address,
) -> Option<Output> {
  list.find(outputs, fn(output) { output.address == address })
}


pub fn ensure_nft_at_script(
  outputs: List<Output>,
  script_address: Address,
  datum: PatientProfileDatum,
) -> Bool {
  when find_output_by_address(outputs, script_address) is {
    Some(output) ->
      assets.quantity_of(
        output.value,
        datum.nft_policy_id,
        datum.nft_asset_name,
      ) == 1
    None -> False
  }
}
pub fn ensure_valid_update(
  outputs: List<Output>,
  script_address: Address,
  datum: PatientProfileDatum,
) -> Bool {
  when find_output_by_address(outputs, script_address) is {
    Some(output) ->
      assets.quantity_of(
        output.value,
        datum.nft_policy_id,
        datum.nft_asset_name,
      ) == 1 && assets.quantity_of(
        output.value,
        assets.ada_policy_id,
        assets.ada_asset_name,
      ) >= datum.required_ada && when output.datum is {
        InlineDatum(new_datum_data) ->
          if new_datum_data is new_datum: PatientProfileDatum {
            new_datum.metadata != datum.metadata
          } else {
            False
          }
        _ -> False
      }
    None -> False
  }
}
pub fn ensure_nft_to_owner(
  outputs: List<Output>,
  datum: PatientProfileDatum,
) -> Bool {
  let owner_address = address.from_verification_key(datum.owner)
  when find_output_by_address(outputs, owner_address) is {
    Some(output) ->
      assets.quantity_of(
        output.value,
        datum.nft_policy_id,
        datum.nft_asset_name,
      ) == 1
    None -> False
  }
}

pub fn ensure_valid_updater_change(
  outputs: List<Output>,
  script_address: Address,
  datum: PatientProfileDatum,
  new_updaters: List<VerificationKeyHash>,
) -> Bool {
  when find_output_by_address(outputs, script_address) is {
    Some(output) ->
      assets.quantity_of(
        output.value,
        datum.nft_policy_id,
        datum.nft_asset_name,
      ) == 1 && when output.datum is {
        InlineDatum(new_datum_data) ->
          if new_datum_data is new_datum: PatientProfileDatum {
            new_datum.authorized_updaters == new_updaters
          } else {
            False
          }
        _ -> False
      }
    None -> False
  }
}



pub fn unique_token_name(
  tx_hash: Hash<Blake2b_224, Transaction>,
  index: Int,
  prefix: ByteArray,
) -> AssetName {
  bytearray.concat(
    prefix,
    bytearray.concat(tx_hash, bytearray.from_int_big_endian(index, 4)),
  )
}
