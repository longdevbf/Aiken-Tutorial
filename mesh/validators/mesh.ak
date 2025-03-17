use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/transaction.{OutputReference, Transaction, Spend}

pub type Datum{
    owner: VerificationKeyHash,   
}
pub type Redeemer{
    text: ByteArray,
}

validator hello_world{
    spend(datum: Option<Datum>, 
    redeemer: Redeemer,
    _own_ref: OutputReference,
    self: Transaction,
    ){
        expect Some(Datum{owner}) = datum
        let say_hello = redeemer.text == "hello baby"
        let must_be_signed = list.has(self.extra_signatories, owner)
        say_hello && must_be_signed
    }
}