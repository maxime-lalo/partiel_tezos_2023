#import "../../../src/contracts/contract_1/main.mligo" "Main"
#import "../../helpers/assert.mligo" "Assert"

type taddr = (Main.action, Main.Storage.t) typed_address
type contr = Main.action contract

let get_storage(taddr : taddr) =
    Test.get_storage taddr

let call (p, contr : Main.action * contr) =
    Test.transfer_to_contract contr (p) 0mutez

let call_amount(p, contr, amount : Main.action * contr * tez) =
    Test.transfer_to_contract contr (p) amount

let accept_admin_success(contr: contr) = 
    Assert.tx_success(call(AcceptAdmin, contr))

let accept_admin_failure(contr, error : contr * string) =
    Assert.tx_failure(call(AcceptAdmin, contr), error)

let add_admin_success(p, contr: address * contr) =
    Assert.tx_success(call(AddAdmin(p), contr))

let add_admin_failure(p, contr, error: address * contr * string) =
    Assert.tx_failure(call(AddAdmin(p), contr), error)

let remove_admin_success(p, contr: address * contr) =
    Assert.tx_success(call(RemoveAdmin(p), contr))

let remove_admin_failure(p, contr, error: address * contr * string) =
    Assert.tx_failure(call(RemoveAdmin(p), contr), error)

let pay_contract_fees_success(contr, amount: contr * tez) =
    Assert.tx_success(call_amount(PayContractFees, contr, amount))

let pay_contract_fees_failure(contr, amount, error: contr * tez * string) =
    Assert.tx_failure(call_amount(PayContractFees, contr, amount), error)

let set_text_success(contr, text: contr * string) =
    Assert.tx_success(call(SetText(text), contr))

let set_text_failure(contr, text, error: contr * string * string) =
    Assert.tx_failure(call(SetText(text), contr), error)