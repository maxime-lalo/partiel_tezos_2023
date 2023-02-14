#import "../../src/contracts/contract_1/main.mligo" "Main"
#import "./helpers/bootstrap.mligo" "Bootstrap"
#import "./helpers/helper.mligo" "Helper"

let test_not_invited = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    let () = Test.set_source(accounts.1) in
    Helper.accept_admin_failure(contr, Main.Errors.no_admin_invitation)

let test_has_been_invited = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    let _ = Test.set_source(accounts.0) in
    let _ = Helper.add_admin_success(accounts.1 , contr) in
    Helper.accept_admin_success(contr)