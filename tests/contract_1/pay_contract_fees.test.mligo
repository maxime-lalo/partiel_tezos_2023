#import "../../src/contracts/contract_1/main.mligo" "Main"
#import "./helpers/bootstrap.mligo" "Bootstrap"
#import "./helpers/helper.mligo" "Helper"

let basic_pay = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    Helper.pay_contract_fees_success(contr, 1tez)

let wrong_amount = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    Helper.pay_contract_fees_failure(contr, 0tez, Main.Errors.wrong_fees_amount)

let already_paid = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    let _ = Helper.pay_contract_fees_success(contr, 1tez) in
    Helper.pay_contract_fees_failure(contr, 1tez, Main.Errors.fees_already_paid)