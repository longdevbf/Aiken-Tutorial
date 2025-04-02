use aiken/collection/list
use cardano/transaction.{OutputReference, Transaction}
use aiken/crypto.{VerificationKeyHash}
use vodka_extra_signatories.{key_signed, one_of_keys_signed}


pub type Datum {
    patient: VerificationKeyHash,
    doctor: List<VerificationKeyHash>,
}

validator action1{
    spend(datum_otp: Option<Datum>, redeemer: Data, out_ref: OutputReference, tx: Transaction){
        expect Some(datum) = datum_otp
        let list_signs = list.push(datum.doctor, datum.patient) 
       or{
        key_signed(tx.extra_signatories, datum.patient) ,
        one_of_keys_signed(tx.extra_signatories, list_signs)
       }
        
        
    }
    else(_) {
        fail
    }

}