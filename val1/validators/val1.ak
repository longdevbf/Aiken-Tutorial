use cardano/assets.{PolicyId, AssetName}
use cardano/transaction.{Transaction, InlineDatum, OutputReference, Output}
use aiken/crypto.{ VerificationKeyHash,}
use cardano/address.{Address, VerificationKey}
use aiken/interval
use aiken/builtin
use aiken/collection/list
//Asset about ADA, NFT
pub type Asset{
    policy_id: PolicyId,//id nft
    token_name: AssetName,// name nft
    amt: Int, //ADA or lovelace
}

//data in a transaction of owner and beneficiary
pub type Datum{
    owner: VerificationKeyHash,
    beneficiary: VerificationKeyHash,
    lock_until: Int,//time lock
    message: ByteArray,
    nft: Asset,
    locked_ada: Int,
    plc: PolicyId,
}

pub fn value_sent_to_address(vkey: VerificationKeyHash, tx: Transaction) -> Int {
  tx.outputs
    |> list.filter(fn(output) {
         when output.address.payment_credential is {
           VerificationKey(pkh) -> pkh == vkey
           _ -> False
         }
       })
    |> list.map(fn(output) { assets.lovelace_of(output.value) })
    |> list.foldl(0, fn(a, b) { a + b })
}

validator dedicate{
    spend(datum_opt: Option<Datum>, redeemer: Void, own_ref: OutputReference, tx: Transaction)-> Bool{
        expect Some(datum) = datum_opt
        and{
            list.has(tx.extra_signatories, datum.beneficiary),
            interval.is_entirely_after(tx.validity_range, datum.lock_until),
            value_sent_to_address(datum.beneficiary, tx) >= datum.locked_ada,
            datum.nft.policy_id == datum.plc,
        }
    }
    else(_) {
    fail
  }
}
