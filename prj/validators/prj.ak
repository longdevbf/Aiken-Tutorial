use cardano/assets.{PolicyId, Value, AssetName}
use cardano/transaction.{Spend, Input, Transaction, InlineDatum, OutputReference, Output }
use aiken/crypto.{
  Blake2b_256, DataHash, Hash, ScriptHash, VerificationKeyHash,
}
use cardano/address.{Address, Credential, VerificationKey}
use aiken/interval
use aiken/builtin
use aiken/collection/list
//Asset about ADA, NFT
pub type Asset{
    policy_id: PolicyId,//id nft
    token_name: AssetName,// name nft
    amt: Int, //ADA or lovelace
}
//status transaction
pub type InheritanceStatus{
    Unlocked 
    Locked
    Claimed
    Refunded
}
//data in a transaction of owner and beneficiary
pub type Datum{
    owner: VerificationKeyHash,
    beneficiary: VerificationKeyHash,
    lock_until: Int,//time lock
    status: InheritanceStatus,
    message: ByteArray,
    nft: Asset,
    locked_ada: Int,
    plc: PolicyId,
}
pub type Action{
    //owner lock assets
    Lock
    //owner want to refund
    Refund
    //beneficiary claim assets when end lock_until
    Claim
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
    spend(datum_opt: Option<Datum>, redeemer: Action, own_ref: OutputReference, tx: Transaction)-> Bool{
        expect Some(datum) = datum_opt
        when redeemer is{
            Lock -> {
                and {
                    list.has(tx.extra_signatories, datum.owner), // owner sign
                    datum.status == Unlocked,
                    datum.nft.policy_id == datum.plc,
                    when list.head(tx.outputs) is {
                        Some(output)->
                        when output.datum is {
                            InlineDatum(d) -> {
                            let expected_datum = Datum { 
                                owner: datum.owner,
                                beneficiary: datum.beneficiary,
                                lock_until: datum.lock_until,
                                status: Locked,
                                message: datum.message,
                                nft: datum.nft,
                                locked_ada: datum.locked_ada,
                                plc: datum.plc,
                            }
                           builtin.equals_data(d,expected_datum)
                            }
                            _-> False

                        }
                            None -> False
                        }
                        }
                    }
                
    
            Refund -> {
                and{
                list.has(tx.extra_signatories, datum.owner),
                datum.status == Locked,
                interval.is_entirely_before(tx.validity_range, datum.lock_until),
                datum.nft.policy_id == datum.plc,
                value_sent_to_address(datum.owner, tx) >= datum.locked_ada,
              }
            }
            Claim -> {
                and {
                    list.has(tx.extra_signatories, datum.beneficiary),
                    datum.status == Locked,
                    interval.is_entirely_after(tx.validity_range, datum.lock_until),
                    datum.nft.policy_id ==datum.plc,
                    value_sent_to_address(datum.beneficiary, tx) >= datum.locked_ada,
                }
            }
        }
    }
}
 test lock_assets() {
    let owner = #"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    let beneficiary = #"fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210"
    let policy_id = #"ff0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    let nft = Asset{
        policy_id,
        token_name: "tran long",  // Note: This should be ByteArray
        amt: 1000,
    }
    let datum = Datum {
        owner,
        beneficiary,
        lock_until: 100,
        status: Unlocked,
        message: "aloalo",  // Note: This should be ByteArray
        nft,
        locked_ada: 1000, 
        plc: policy_id,
    }

    let expected_datum = Datum { 
        owner: datum.owner,
        beneficiary: datum.beneficiary,
        lock_until: datum.lock_until,
        status: Locked,
        nft: datum.nft,
        locked_ada: datum.locked_ada,
        message: datum.message,
        plc: datum.plc,
    }

    let output = Output {
        address: Address { payment_credential: VerificationKey(owner), stake_credential: None },
        value: assets.from_lovelace(1000000000),
        datum: InlineDatum(expected_datum),
        reference_script: None,
    }

    let tx = Transaction { 
        ..transaction.placeholder, 
        extra_signatories: [owner],
        outputs: [output],
    }

    let placeholder_utxo = OutputReference {
        transaction_id: #"",
        output_index: 0
    }

    dedicate.spend(Some(datum), Lock, placeholder_utxo, tx)
}