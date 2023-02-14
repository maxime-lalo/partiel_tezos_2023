#import "../../src/contracts/contract_1/main.mligo" "Main"
#import "./helpers/bootstrap.mligo" "Bootstrap"
#import "./helpers/helper.mligo" "Helper"

let cant_remove_self = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    let () = Test.set_source(accounts.0) in
    Helper.remove_admin_failure(accounts.0 , contr, Main.Errors.cant_remove_self_admin)

let cant_remove_not_admin = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    let () = Test.set_source(accounts.0) in
    Helper.remove_admin_failure(accounts.1 , contr, Main.Errors.wasnt_admin)

let basic_remove = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    let _ = Test.set_source(accounts.0) in
    let _ = Helper.add_admin_success(accounts.1 , contr) in
    Helper.remove_admin_success(accounts.1 , contr)
